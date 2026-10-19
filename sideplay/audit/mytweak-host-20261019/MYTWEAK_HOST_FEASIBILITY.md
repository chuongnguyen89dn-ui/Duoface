# MyTweak có thể thay SidePlay làm host CarPlay cho DuoFace không?

Kiểm tra 2026-10-19. **KẾT LUẬN: khả thi để thử như host ĐỘC LẬP, CHƯA CÓ bằng chứng hoạt động trên CarPlay thật, chưa được chọn làm host thay SidePlay.** Không can thiệp giấy phép Native12 hoặc SidePlay.

## Nguồn đã kiểm chứng

Người dùng đã gửi MyTweak trước đó. Tìm được trong Project Library nguồn `MyTweak_Independent_SceneHost_trial_source_20261018.txt` (tạo 2026-10-18, 61.897 bytes trên Library; sau materialize local UTF-8 60.452 ký tự), sha256 của **file UTF-8 materialized**: `ea561904b62717f617706ba453e004f037feef4a3c6cdab2c00327f0dac50e16`. File chứa 25 mục mã/header/Makefile/plist/tests; **không lưu lại toàn bộ code người dùng trên GitHub trong cuộc audit này**, chỉ ghi kết quả và đường dẫn tài liệu.

- Bản gốc `MyTweak 0.2.0` ở đầu README vẫn nói `MTSceneHost` “stub”, `code:1001`; nhưng phần `Experimental independent scene-host trial (2026-10-18)` và **mã `MTSceneHost.m` 333 dòng cuối file** đã thay stub bằng thử nghiệm private API của SpringBoard. Không được đánh giá nhầm hai phiên bản.
- Chạy đúng `python /mnt/data/mytweak_audit/mytweak/tests/test_scenehost_contract.py`: **6/6 unittest PASS**, 0.007 giây, **chỉ structural/static**. Không có bằng chứng build Theos/DEB, không có log SpringBoard/CarPlay của MyTweak trên thiết bị.
- GitHub `chuongnguyen89dn-ui/Duoface` search `MTSceneHost` không tìm thấy source MyTweak đã commit vào default branch; đây là **nguồn người dùng gửi trong Library**, không mặc định là nhánh QA11 hay M1 host-only đang chạy.
- Đối chiếu tài liệu header cộng đồng `theos/headers/SpringBoard/SBAppViewController.h`: có `initWithIdentifier:andApplicationSceneEntity:`, `setRequestedMode:`, `invalidate`; chỉ xác nhận API từng tồn tại, **không xác minh đúng iOS16.7.x và class/selector in situ**. Header khác khai báo `SBDeviceApplicationSceneEntity` factory khác nhau tùy bản hệ điều hành.

## Sơ đồ luồng MyTweak thử nghiệm (mã đã đọc, chưa chứng minh runtime)

```mermaid
flowchart TD
 A["SpringBoard: Tweak.x"] --> B["MTBridgeCoordinator"]
 B --> C["AVExternalDevice.currentCarPlayExternalDevice / CADisplay"]
 C --> D["FBSDisplayConfiguration + UIRootSceneWindow"]
 D --> E["MTBridgeRootViewController"]
 E --> F["MTSplitContainerViewController (2 slot)"]
 F --> G["MTAppPickerViewController / MTAppLibrary"]
 G --> H["MTAppLauncher (MTAppSession pending)"]
 H --> I["MTSceneHost.hostViewForBundleID"]
 I --> J["SBApplicationController.applicationWithBundleIdentifier"]
 J --> K["SBDeviceApplicationSceneEntity init/factory"]
 K --> L["SBAppViewController.initWithIdentifier:andApplicationSceneEntity:"]
 L --> M["setRequestedMode: 2 + sceneHandle.sceneIfExists"]
 M --> N{"scene-ready? (<=36 polls x 0.35s)"}
 N -->|YES| O["MTSceneSurface app view (chưa xác nhận pixels/touch)"]
 N -->|NO| P["error 112 / scene-failed"]
```

## Đánh giá từng lớp

| Lớp/khả năng | Mã MyTweak thực có | Xác minh được | Thiếu trước khi coi là host thực |
|---|---|---|---|
| SpringBoard inject | `Tweak.x` hook `applicationDidFinishLaunching:`, `MyTweak.plist` filter SpringBoard, Theos rootless | Byte/source có | Device boot/respring không crash |
| CarPlay display | `MTBridgeCoordinator` tra `AVExternalDevice` screenIDs + `CADisplay.uniqueId` | Có kiểm CarPlay display chứ không chọn bừa màn thứ hai | APIs thực tồn tại và trả về đúng CADisplay trên máy |
| CarPlay window | `FBSDisplayConfiguration.initWithCADisplay:isMainDisplay:`; `UIRootSceneWindow.initWithDisplayConfiguration:` | Có mã tạo window riêng SpringBoard | iOS có render đúng scene? Native Apple Dock có bị phủ bởi root full-screen UI? |
| App host | `MTSceneHost` tra `SBApplicationController`, tạo `SBDeviceApplicationSceneEntity` và `SBAppViewController` | Có mã tạo controller, attach child view, yêu cầu mode 2 | Hai class/selector tồn tại iOS16.7.x, class factory đúng thực tế và scene có mở được app |
| Scene ready | Poll `sceneHandle.sceneIfExists`, tối đa 36 x .35 s; log `scene-ready` | Biết scene handle tồn tại | **KHÔNG** chứng minh pixels, touch, audio, display focus/rotation |
| Resize/split | 2x logical pixel, 0.5 scale, resize scene settings/foreground, 2 panes 25–75% | Có code thực | **2x/0.5x chỉ giả định**; hở gesture/keyboard/orientation/retina; không phải UI Native12 |
| Cleanup | setRequestedMode:0, invalidate, stopAllHosts, restore settings | Có mã rollback và log | Kiểm SpringBoard crash/exitmode, app/background/reconnect/trùng scene |
| AppDock Apple | **Không có `appDockVC` hoặc hợp đồng CarPlay icon/status Dock** | Chưa có owner cho Dock | Native12 Dock chưa được MyTweak giải quyết |
| Giấy phép | Không gọi `CBBridgeManager`, `CBLicenseSyncManager`, không depends SidePlay | Có chứng cứ source **độc lập** | Private SpringBoard APIs và quyền thực thi vẫn có thể bị giới hạn iOS, jailbreak hoặc scene policy; không đồng nghĩa hoạt động chắc chắn |

## Rào cản chính xác / khả năng bất tương thích

1. **P0: No runtime evidence.** `host-created` chỉ là tạo pending UIView; `scene-ready` chỉ là handle tồn tại. Không hề có ảnh/video/log thiết bị xác minh thật app iPhone hiển thị trên CarPlay, cảm ứng, audio, two concurrent scenes, disconnect. Không được báo “host đã hoạt động”.
2. **P0: Private API signatures trên iOS16.** `SBDeviceApplicationSceneEntity` trong code thử nghiệm preflight `initWithApplicationForMainDisplay:` hoặc `newEntityWithApplicationForMainDisplay:`, nhưng header tham chiếu khác dùng `defaultEntityWithApplicationForMainDisplay:`. Nếu cả hai selector thử nghiệm không tồn tại trên thiết bị, trả `MTSceneHost error 104` trước khi có host. Không giả định chắc chắn đã hỏng; cần runtime introspection của đúng máy. `SBAppViewController` init cũng cần đối chiếu signature/type.
3. **P0: Display/CarPlay scene ownership.** `initWithApplicationForMainDisplay:` gắn nhãn MainDisplay, trong khi `UIRootSceneWindow` dùng CarPlay `CADisplay`: **không bảo đảm** iOS cho app view hoạt động/touch trên màn CarPlay, hoặc app Dock của Apple được giữ lại. MyTweak `MTBridgeRootViewController.view` nền đen toàn màn, rất có nguy cơ che Dock như QA SidePlay.
4. **P1: UI không phải Native12.** MyTweak có root picker và fixed dual slots riêng (8pt divider, 25–75%, fullscreen double-tap), **không mang UI đó sang DuoFace**. Chỉ cân nhắc `MTBridgeCoordinator + MTSceneHost + lifecycle` làm host backend, DuoFace Native12 sở hữu toàn bộ menu/split/HUD/picker/geometry.
5. **P1: ổn định SpringBoard.** `MTSceneHost` dựa `objc_msgSend` ép signature + KVC `_deviceAppViewController`; có thể crash SpringBoard nếu selector sai, app đóng hoặc scene reconnect. Test **không cài đồng thời** với QA11/Native12 hosts vì hai host có thể tạo window trùng.

## Bài kiểm tra tối thiểu bắt buộc trước quyết định đổi host

Giai đoạn A **diagnostic riêng, không Sileo production** trên iPhone test rootless iOS16.7.x, xe đỗ. Kiểm chặng:
`carplay-window-ready` → `host-created` → `mode-2-requested` → `scene-attached` → `scene-ready` → **có hình app thật** → touch/scroll → audio → resize ratio → 2 app đồng thời → `invalidate-done` → `all-hosts-stopped` → reconnect/respring. Ghi `/var/mobile/Library/Logs/MyTweakSceneHost.log` và SpringBoard/CarPlay logs/IPS nếu crash. **AppDock của Apple luôn phải nhìn thấy ở Normal**; nếu bị che, phải sửa đúng CarPlay window ownership / scene/usable region, không dùng 64pt overlay giả.

**GO:** những chặng trên PASS thực nghiệm → MyTweak host backend có thể thay `com.sideplay` (nếu các đoạn code host tự sở hữu và không có vendor dependency), rồi chuyển Native12 UI theo mốc M1–M6. **NO-GO:** preflight missing, scene timeout/error, host ready nhưng không render, thiếu touch, Dock mất hoặc SpringBoard crash → giữ SidePlay đang chạy làm backend hiện hành, nghiên cứu sửa MyTweak riêng. Bất kể GO hay NO-GO, **không chép `CBBridgeManager` license/ABI**.

## Hiện trạng lượt review

Đã tìm file user, đọc 25 phần nguồn, phân tích 333 dòng MTSceneHost, chạy 6/6 Python tests PASS. **Không sửa source MyTweak, không build DEB, không cập nhật Sileo**, chưa test thiết bị. Đường dữ liệu gốc: Project Library `MyTweak_Independent_SceneHost_trial_source_20261018.txt`; báo cáo lưu tại `sideplay/audit/mytweak-host-20261019/MYTWEAK_HOST_FEASIBILITY.md` trên branch `analysis/native12-complete-wiring-20261019`. Next: xác minh private API signatures bằng runtime logs hoặc binary dump trên đúng iPhone trước khi quyết định thay SidePlay backend.
