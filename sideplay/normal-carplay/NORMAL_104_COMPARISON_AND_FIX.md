# SidePlay 1.0.4-1 → giao diện CarPlay thường kiểu DuoNavi 1.0.4

**Quyết định mới 2026-10-18:** chỉ xử lý trạng thái **không fullscreen mặc định lúc kết nối CarPlay, còn thấy thanh dock/bar hệ thống**. Tạm dừng mọi việc phân tích fat-slice sâu, HUD, thay scene-host và chuyển UI DuoFace. Không chỉnh sửa DEB gốc, không đụng Native12/Visual12/Hub8/QA, không phát hành Sileo.

> **ĐÍNH CHÍNH THEO PHẢN HỒI NGƯỜI DÙNG (18/10/2026):** `Root.plist` của bản DEB có khai báo `PSSwitchCell key=carDock label="Thanh dock CarPlay" default=false`; **chưa có ảnh/log/thiết bị xác minh menu này thật sự xuất hiện trong SidePlay đang chạy và bật nó sẽ trả lại thanh bar hệ thống**. Hướng dẫn ở mục 5 “bật Thanh dock CarPlay” là **phương án kiểm chứng có điều kiện**, không phải chức năng đã kiểm chứng. Root.plist candidate đổi default không phải bản sửa fullscreen runtime; 4/4 test chỉ là unit/static. Không đòi người dùng thực hiện bước này như một giải pháp đã chắc chắn.

## 1. Vấn đề cần giải

Người dùng quan sát **SidePlay tự trải kín CarPlay khi kết nối**, trong khi giao diện DuoNavi 1.0.4 ban đầu còn nhìn thấy thanh bar/dock CarPlay; fullscreen chỉ xuất hiện sau khi đã dùng chức năng từ Airaw. Mục tiêu là **trạng thái bình thường trước fullscreen**, không phải tạo một nút fullscreen mới và không phải tắt tự mở SidePlay.

Quan trọng phải phân biệt ba thành phần:
- **Dock/bar hệ thống CarPlay:** khu vực giao diện hệ thống, không phải thanh điều khiển trong app.
- **Thanh điều khiển nội bộ SidePlay:** có `autoHideBar`, `barHideDelay`; không dùng hai khóa này để giải quyết dock hệ thống.
- **Khung host app:** tính theo vùng hiển thị hiện hữu; không hardcode chiều cao/chiều rộng vì head unit có kích thước khác nhau.

## 2. Đối chiếu bằng chứng của hai gói

| Đường | SidePlay 1.0.4-1 (quét trực tiếp từ gói) | DuoNavi 1.0.4 (audit đã lưu) |
|---|---|---|
| Điểm khởi đầu | `UIRootSceneWindow initWithDisplayConfiguration:`; `makeMainScreenWindow`, `carWindowFrameNow` | `CBWindow carPlayScreenBounds` → `carPlayContentInsets` → `carPlayUsableBounds` |
| Vùng cửa sổ | `carDockMode`, `carDockArea`, `carAppArea`, `carWindowFrame` trong `SidePlay.dylib` | Trừ inset khỏi bounds cho vùng app để sidebar/status bar còn hoạt động |
| Cờ bật/tắt dock | `Root.plist` chứa `carDock` label **Thanh dock CarPlay** với **default false** | Mặc định chưa áp dụng Airaw fullscreen; content nằm trong vùng usable (theo phân tích `audit/v12-geometry-chain-20261014.txt`) |
| Tự căn | `autoFitCar` true; `carZoom` 100; `safeAreaInsets` và `carFrames` có trong core | `safeAreaInsets`/usable geometry hiện hữu, không giả lập dock bằng UIView |
| Fullscreen độc lập | SidePlay có preset dock-off; chưa xác minh đủ callsite runtime | Airaw sử dụng `jp.airaw.host.fullscreen`, `jp.airaw.carplay.chrome` để **chủ động** đổi geometry + chrome |

Nguồn SidePlay: `sideplay/extracted-1.0.4-1/rootfs/var/jb/Library/PreferenceBundles/SidePlayPrefs.bundle/Root.plist`, `sideplay/audit/deb-1.0.4-1/macho-strings/002-SidePlay.dylib.strings.txt` (đặc biệt `carDock` quanh dòng 686, `carDockMode` 1565, `carDockArea` 1628), app `SidePlay.app/Info.plist` đăng ký `CPTemplateApplicationScene`. Nguồn DuoNavi: `audit/v12-geometry-chain-20261014.txt`, `docs/fullscreen-root-cause-20261014.md`. Đây là **tên và trạng thái có chứng cứ**, không phải bằng chứng đã disassemble xác thực nhánh `carDockArea`.

## 3. Phương án sửa tối thiểu đã thực hiện — CONFIG CANDIDATE

Nhánh phát triển **`feature/sideplay-normal-carplay-dock`** từ main tại `b2ead2804f6128b7e9145454c8aada4c9bc7e024`. Chỉ tạo các file mới ở `sideplay/normal-carplay/`:

1. `SidePlayPrefs.bundle/Root.plist`: bản sao của `Root.plist` original nhưng **chỉ đổi** dictionary có `key=carDock` từ `default=false` thành `default=true`. Không đổi `autoOpen` (vẫn true), `autoFitCar`, `carZoom`, `autoHideBar`, bất kỳ HUD/giấy phép nào.
2. `tools/prepare_normal_mode.py`: kiểm tra đúng delta duy nhất, cho phép xuất **candidate** `com.sideplay.plist` với **`carDock=true`**; nếu cung cấp `--prefs-input` sẽ giữ nguyên toàn bộ thiết lập người dùng khác và từ chối ghi đè input. Chỉ xuất file test, **không tự áp lên iPhone / SpringBoard / Preferences**.
3. `tests/test_normal_carplay.py`: các test cấu hình, giữ các tùy chọn còn lại, từ chối overwrite, so với bản gốc.
4. `.github/workflows/sideplay-normal-dock-static.yml`: static-only, hash-check DEB, chạy các test; không đóng gói, không cài, không triển khai.

**Quan trọng:** đổi `Root.plist.default` là thay đổi **giá trị mặc định của giao diện cài đặt**, không tự sửa giá trị `carDock` đã được lưu trong `CFPreferences` của máy hiện tại. Để xác minh runtime, cần **bật tùy chọn `SidePlay > Hiển thị > Thanh dock CarPlay` trên máy thử**, sau đó ngắt/nối lại CarPlay. Nếu máy đã lưu `carDock=false`, chỉ build lại Root.plist sẽ không đủ. Không tự lệnh hóa việc ghi plist vào thư mục Preferences trên iPhone khi chưa biết trạng thái hiện tại.

### Cách tái tạo file cấu hình dùng cho kiểm thử

```bash
# Chạy tại root repo; chỉ kiểm tra cấu hình, không thay đổi gì:
python3 sideplay/normal-carplay/tools/prepare_normal_mode.py --verify

# Tạo candidate plist cho lần kiểm tra sau, không cài trực tiếp:
python3 sideplay/normal-carplay/tools/prepare_normal_mode.py \
  --prefs-output /tmp/com.sideplay-normal-carplay.plist
```

## 4. Kiểm chứng đã chạy và chưa chạy

- **GITHUB VERIFIED:** source commit `b776a3a230be66fedf420ad5ea5072c6a92b0703` tạo Root.plist dock-on candidate; `5253fe333d3aece32ca55aff7b593122dd07eacc` script; `6ef6bae467695eb95c0e559afb64e67b64eb5076` test; `22608ea936408905280e5d9bc9a58d9a105f20cd` CI.
- [GitHub Actions run 39115213941](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39115213941) job 117639526628: **SUCCESS**. Tests pass; DEB original SHA-256 `7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c` **không đổi**.
- **CHƯA XÁC MINH:** SidePlay thực tế khi bật `carDock=true` trên iPhone X có trả dock hệ thống hay chỉ thu hẹp cửa sổ; mức độ giữ status bar, touch alignment, reconnect, UI 1/2 app và tương thích nhiều head unit.
- **CHƯA CÓ:** DEB sửa, source code Mach-O SidePlay, bằng chứng thiết bị/ảnh màn hình, CI iOS build. Cấm ghi `runtime PASS` dựa vào unit test.
- Rủi ro: `Root.plist` không kiểm soát hệ thống Dashboard chrome; nếu SidePlay tạo `UIRootSceneWindow` với `windowLevel` che dock, phải xử lý `carDockArea` và level trên host riêng, không tự dịch chuyển pixels bằng số cố định.

## 5. Điểm tiếp tục duy nhất

- Kiểm chứng hành vi cấu hình **đã có sẵn** trước khi dùng binary patch: bật `Thanh dock CarPlay` tại SidePlay Settings và ngắt/nối lại CarPlay trên xe đang đỗ; chụp trạng thái màn hình, thử chạm dock, thử 1/2 app.
- Nếu có dock và pane chừa vùng đúng: áp dụng `Root.plist` & normal preference preset khi tạo gói thử độc lập **theo yêu cầu đóng gói**, không sửa bản original và không sử dụng mã giấy phép vendor.
- Nếu chưa có: chỉ lúc đó kiểm tra đúng callsite `carDockMode/carDockArea` và `windowLevel` (không mở lại toàn bộ reverse-engineering/HUD/scene), đối chiếu DuoNavi `carPlayContentInsets` để triển khai vùng usable qua **module mã mới**. Log cần: `car window %@ (Thanh dock CarPlay %@)`, screen bounds, safe area, frame actual.
- Không chuyển giao UI Native12/Visual12, không sửa giấy phép, không build/release Sileo cho tới khi trạng thái normal CarPlay thực sự được xác minh.
