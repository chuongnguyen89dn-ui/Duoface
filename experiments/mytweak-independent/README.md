# MyTweak 0.2.0 — CarPlay bridge viết lại từ đầu (bản alpha)

Tweak tự viết 100% từ đầu, **không copy code, assets, chuỗi giao diện hay
cơ chế giấy phép của bất kỳ tweak nào khác**. Mục tiêu: thay thế phần CarPlay
bằng code gốc của mình, thay vì cố tách code giấy phép ra khỏi tweak gốc
(việc đó đã được chứng minh là không tách an toàn được).

## Kiến trúc

```
SpringBoard khởi động
        │  (Tweak.x hook applicationDidFinishLaunching:)
        ▼
MTBridgeCoordinator (singleton)
  - nghe UIScreenDidConnect / DidDisconnect
  - màn ngoài (CarPlay) xuất hiện → dựng MTBridgeWindow gắn lên màn đó
        │
        ▼
MTBridgeWindow (UIWindow trên màn CarPlay)
        │  rootViewController
        ▼
MTBridgeRootViewController
  - chứa MTSplitContainerViewController
  - mở MTAppPickerViewController khi slot yêu cầu
        │
        ▼
MTSplitContainerViewController
  - 2 slot trái/phải (MTAppSlotViewController)
  - kéo thanh giữa để đổi tỉ lệ (25%–75%)
  - double-tap vào slot để toàn màn hình / về chia đôi
        │
        ▼ (chọn app trong picker)
MTAppLibrary → liệt kê app đã cài (LSApplicationWorkspace, runtime lookup)
        │
        ▼
MTAppLauncher → tạo MTAppSession
        │
        ▼
MTSceneHost  ← ĐIỂM NỐI: host scene của app vào slot (xem bên dưới)
```

## Bảng trạng thái (trung thực)

| Module | Trạng thái |
|---|---|
| Phát hiện màn CarPlay, dựng/dọn window | Xong (public API: `UIScreen`, `UIWindow`) |
| Chia 2 slot, kéo divider, toàn màn hình | Xong (UIKit thuần) |
| Màn chọn app, liệt kê app đã cài | Xong (runtime lookup, không cần private header) |
| Host scene của app vào slot (`MTSceneHost`) | **Stub** — trả lỗi rõ ràng, chưa host thật |
| Mở được app lên màn CarPlay | **Chưa** — phụ thuộc `MTSceneHost` |

Vì sao `MTSceneHost` là stub: host scene của app khác cần private scene APIs
của SpringBoard và **bắt buộc test lặp trên máy jailbreak thật** — không thể
viết một lần ăn ngay trên giấy. Stub hiện tại không giả vờ: slot sẽ hiện rõ
"Đã chọn nhưng chưa hiển thị được giao diện app" thay vì crash hay treo.
Hướng làm tiếp đã ghi trong `MTSceneHost.h`.

## Cấu trúc file

| File | Vai trò |
|---|---|
| `Tweak.x` | Entry: hook `SpringBoard`, khởi tạo coordinator |
| `MTBridgeCoordinator.h/.m` | Quan sát màn ngoài, dựng/dọn window |
| `MTBridgeWindow.h/.m` | UIWindow gắn lên màn CarPlay |
| `MTBridgeRootViewController.h/.m` | Màn gốc, điều phối picker |
| `MTSplitContainerViewController.h/.m` | Chia 2 slot, kéo divider, toàn màn hình |
| `MTAppSlotViewController.h/.m` | Một ô chứa app |
| `MTAppPickerViewController.h/.m` | Màn chọn app |
| `MTAppLibrary.h/.m` | Liệt kê app đã cài |
| `MTAppLauncher.h/.m` | Mở app vào session |
| `MTSceneHost.h/.m` | Điểm nối host scene (stub trung thực) |
| `MyTweak.plist` | Filter: chỉ inject vào `com.apple.springboard` |
| `Makefile` | Build bằng Theos, scheme **rootless** (`/var/jb`) |
| `control` | Metadata gói .deb |

## Cách build

**Qua GitHub Actions (không cần máy Mac):**

1. Tạo repo mới trên GitHub, upload toàn bộ thư mục này lên
   (gồm cả `.github/workflows/build.yml`).
2. Vào tab **Actions** → chọn **Build .deb** → **Run workflow**.
3. Đợi job chạy xong → tải file `.deb` ở mục **Artifacts**.

> Ghi chú: để Muse tự đẩy code lên GitHub giùm, bạn cần tạo repo `mytweak`
> và một fine-grained token rồi gửi cho Muse (việc này còn đang chờ từ 16/10).

**Build tay (có Theos):**

```bash
export THEOS=~/theos   # đường dẫn tới Theos đã cài
cd mytweak
make package           # .deb nằm ở packages/
```

## Cài lên iPhone jailbreak (rootless)

1. Chép file `.deb` vào máy (SSH/Filza…).
2. `dpkg -i com.nguyen.mytweak_0.2.0_iphoneos-arm64.deb` hoặc cài bằng Sileo/Zebra.
3. Respring. Nếu thấy alert "MyTweak — Bridge coordinator đã chạy" → tweak đã
   inject thành công vào SpringBoard.
4. Kết nối CarPlay: trên màn xe phải hiện cửa sổ với 2 slot + màn chọn app.

Muốn tắt alert mỗi lần respring: mở `Tweak.x`, đặt `MT_SHOW_LOAD_ALERT` = 0,
build lại.

## Gỡ bỏ

Gỡ `MyTweak` trong Sileo/Zebra rồi respring.

## Test xong thì báo gì về cho Muse

Để đi tiếp vòng sau, cần biết trên máy thật:

1. Alert có hiện sau respring không? (inject OK?)
2. Kết nối CarPlay: cửa sổ + 2 slot có hiện trên màn xe không?
3. Màn "Chọn app" có liệt kê được app đã cài không?
4. Log: lọc `MyTweak` trong log rồi gửi những dòng lạ về.

## Lộ trình

- **v0.2 (bản này):** nền móng + toàn bộ UI quản lý + điểm nối `MTSceneHost`.
- **v0.3:** implement host scene thật (cần nhiều vòng test trên iPhone X).
- **v0.4+:** forward touch, xoay màn hình, vòng đời app (app tắt → slot trống),
  lưu layout đã chọn.

## Experimental independent scene-host trial (2026-10-18)

This code is a standalone MyTweak test candidate, **not** a native DuoFace UI
patch or a license workaround. It does not install alongside the old Native12
host. The initial `MTSceneHost` error-1001 stub has been replaced with guarded
SpringBoard calls to `SBAppViewController` / `SBDeviceApplicationSceneEntity`.
`MTBridgeCoordinator` now requires an identified CarPlay `CADisplay` and creates
one `UIRootSceneWindow` with `FBSDisplayConfiguration`, not a generic external
`UIWindow`. The existing two-pane shell/picker remains MyTweak's original UI.

The host is asynchronous: a returned UIView means **pending**, not that the
third-party app scene is already attached. `scene-ready` is logged only after
`sceneHandle.sceneIfExists` returns a scene, and geometry is applied. A 12.6s
absence returns `scene-failed` and displays the error in the slot. Closing a
slot or disconnecting CarPlay calls `setRequestedMode:0` and `invalidate`.

**Validation, not claims:** `python3 tests/test_scenehost_contract.py` verifies
source invariants; it cannot compile Theos or simulate iOS16. The private APIs
may differ on iPhone X iOS 16.7.x; first run can crash SpringBoard and must be
isolated to an optional test package with original build recoverable. No device,
CI, Sileo or CarPlay success is claimed by this source.

Test log (if writable): `/var/mobile/Library/Logs/MyTweakSceneHost.log`, also
logged to SpringBoard with `[MyTweakScene]` prefix. Minimal acceptance sequence:
connect CarPlay -> `carplay-window-ready` -> select an app -> `host-created` ->
`mode-2-requested` -> `scene-attached` -> `scene-ready`; close/switch ->
`invalidate-done`; disconnect -> `all-hosts-stopped`. If it fails, preserve the
exact error log + SpringBoard `.ips` and report the last observed event.

Do not install this test candidate concurrently with DuoFace Native12/HUD8.
