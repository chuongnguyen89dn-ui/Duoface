# QA10 Native12 CarPlay Dock transfer — source-only handoff (2026-10-19)

## Yêu cầu mới thay thế nhận định cũ

- Người dùng đưa ảnh `IMG_7949.jpeg` chụp thanh bên trái CarPlay trên màn app: **đồng hồ/Wi‑Fi/pin, app gần đây, nút danh sách ứng dụng**. Đây là **Apple CarPlay Dock/status-bar/sidebar**, không phải nút pill trên cửa sổ DuoFace, không phải một thanh do DuoFace tự vẽ. Normal: **luôn có Dock bên trái**, hai ứng dụng nằm bên phải; Zoom/Fullscreen từ menu mới thay chế độ.
- Yêu cầu nguyên văn mới: “**Lấy nguyên bộ đang hoạt động của duoface qua. Sau đó xoá bỏ cái đang hoạt động**”. Áp dụng vào đúng nhánh SidePlay QA: chuyển nguyên cơ chế **source-owned** Native12 điều khiển Dock/usable bounds, sau đó **xóa hoàn toàn implementation QA9/QA10 cũ**. KHÔNG xóa app/DEB Native12 ổn định, KHÔNG gỡ SidePlay scene host khi chưa có host thay thế, không sao chép `CBBridgeManager` (trộn license và host).
- **CHƯA build DEB/IPA hoặc cập nhật Sileo**, đúng yêu cầu người dùng trước đó.

## Nguồn đối chiếu (đã truy cập GitHub)

- Native12 `runtime/fullscreen/DFDashboardChrome.xm` blob `2abbaa946f770d0faa9b74e8ca2b45e4a35c5220`: observer `DBStatusBarWindow`/`CARStatusBarWindow`, `DFDashboardSetChromeHidden`, `DFDashboardRestoreChrome`, snapshot trạng thái cửa sổ hệ thống; không tự vẽ thanh giả.
- Native12 `runtime/fullscreen/DFHostGeometry.xm` blob `6ca7011005ac0e1c99a70975cc3a7f2fc7d44a62`: `CBWindow.carPlayUsableBounds`, `carPlayScreenBounds`, `CBWindow.resizeWindows`, owner-check và rollback. Mach-O Native12 `DuoFaceDashboard.dylib`: `CBWindow`37 selector, bao gồm `carPlayContentInsets/carPlayUsableBounds`; source audit xác minh Native12 default **64 pt left inset** trong normal iOS16.
- `CBDashboardShared.appDockVC/currentAppDockVC` là lớp Native12 binary tham chiếu CarPlay app-dock controller, **không thể đem nguyên class này qua runtime SidePlay** (không liên kết binary). `CBDockSystemMonitorView` là view đo CPU/RAM/pin/nhiệt, **KHÔNG phải thanh Dock có app icons**. `CBBridgeManager` chứa license watchdog, tuyệt đối không sao chép nguyên class.
- SidePlay 1.0.4 có `SPDash.carDockMode`/ `carDockArea`/`carWindowFrameNow`, không được suy đoán hệ tọa độ `carDockArea`. App/scene vẫn do `SPDash/SPPane/SPCarSceneDelegate` sở hữu. Trên thiết bị chưa có runtime CGRect/window hierarchy.
- Apple WWDC23 **Optimize CarPlay for vehicle systems** https://developer.apple.com/videos/play/wwdc2023/10150/ nêu CarPlay system status bar có thể nằm dọc phía người lái hoặc ngang đáy màn. Thứ cần giữ **là hệ thống CarPlay**.

## Mã QA10 hiện đã thay đổi thật

Branch `feature/duoface-qa10-picker-divider-source-only` — chưa phát hành:
1. `sideplay/sileo-qa/DFSPNativeDock.h`: export `DFSPDockRequest(active,zoom,generation)` và `DFSPNativeDockUsableBounds(UIWindow *)`.
2. `sideplay/sileo-qa/DFSPNativeDock.xm`, create `6363fe78c07e3dc93f7dab59a6f0b7adc8ca9637`, geometry commit `c14a2d7bb753eb54cccbfd64d2ef94fb28616420`: **một owner Native12-derived cho toàn bộ chính sách Dock**:
  - lấy `UIWindowScene.windows`, quan sát chính `DBStatusBarWindow` hoặc `CARStatusBarWindow`, snapshot nguyên trạng `hidden`, ép Normal hiện (`hidden=NO`) và Zoom ẩn (`hidden=YES`), restore original khi detach.
  - Darwin notify `nativedock.v1.normal/zoom/detach` (chỉ tên) + `ack.normal/zoom/missing/detach` trong đúng tiến trình SpringBoard và CarPlay; bounded retry, log `NATIVE_DOCK` ở `/var/mobile/Library/Logs/DuoFaceSidePlayDisplayQA.log`.
  - `DFSPNativeDockUsableBounds`: trong window-local coordinates, dựa `safeAreaInsets` chính hệ thống; fallback left **64 pt** từ Native12 khi không có inset dock, tôn trọng right/bottom dock khi iOS cung cấp; chỉ nhận bounds hợp lệ và dock screen ngoài. **Không thể tự tạo thanh Apple nếu CarPlay scene không sở hữu/vẽ nó**.
3. `sideplay/sileo-qa/Tweak.xm` commit `0f7c1dbd2eba2a8850530d83b63919dc2722db5c`, remove old geometry commit `b1f5be4fd6963903d8542f6e123f23ed3b92c0ad`: import `DFSPNativeDock.h`, Normal `DFSPDockRequest(YES,NO,...)`, Zoom `DFSPDockRequest(YES,YES,...)`, detach `DFSPDockRequest(NO,NO,...)`; tất cả usable layout gọi `DFSPNativeDockUsableBounds` thay vì `DFSPSystemUsableRect`; không ép `window.frame` hay thay z-order.
4. `sideplay/sileo-qa/Makefile` commit `b053f88f4509d6f66d5dddb355f6abf4a8b95549`: compile **DUY NHẤT `DFSPNativeDock.xm`** (cùng frame/pill/host QA), không compile ChromeBridge; package ID/version chưa đổi vì chưa build.
5. **Đã XÓA hẳn** `sideplay/sileo-qa/DFSPChromeBridge.xm` commit `6e68af2e66b1a3973dba4f662072f2666bd05ad1` và `sideplay/sileo-qa/DFSPChromeBridge.h` commit `5daa3b1605555b8a1188c759021a53061ecf6c04` **chỉ trong nhánh QA10**, không động native12 ổn định. Không có hai bộ cùng chạy.
6. Validator cập nhật `sideplay/native12-display/validation/check_qa9_chrome_divider.py` kiểm một owner mới, không clone license, framebuffer no crop, Native12 inset, ABI và rollback; commit `e59ececa9b22b1786a3d1fa53bd43521c6d7c95b` và `e6250ede4562cc7366023c0b0f8fe0b9ef343e89`. Validator picker/divider QA10 cũ vẫn còn.
7. GitHub Actions `.github/workflows/sideplay-qa10-static-native-dock.yml` commit `5cffb8dcb8aeecbd13698e8abb8e2941ab3e7962`: chạy **chỉ Python static tests trên ubuntu**, **KHÔNG make / không build DEB**. Tại checkpoint chưa có GitHub Actions run SUCCESS được xác minh; chưa tuyên bố chạy validator Python trên runner.
8. Kiểm tra trực tiếp mã qua GitHub connector **12/12 JS assertions PASS**: old module không import/build, Dock module có source, Normal/Zoom/detach, Native 64pt geometry, không chạm CB license, picker/split vẫn giữ nguyên.

## Chưa xác minh / giới hạn

- Đây là **port cơ chế Native12 và thay thế implementation cũ**, **không phải sao chép nhị phân `DuoFaceDashboard.dylib`**. Native12 không chứa một “dock UIView” riêng có thể copy, vì Dock do Apple CarPlay render. Luồng CarPlay thực và iPhone X iOS16.7.x chưa được test; màn hình chụp chỉ xác nhận *đúng UI mong muốn*, không chứng minh statusbar subclass trên iOS thực tế.
- Bộ lọc `DuoFaceSidePlayDisplayQA.plist` vẫn `Mode=Any` cho SpringBoard/CarPlayApp/CarPlay/Dashboard; đúng tiến trình nào đang vẽ thanh Dock vẫn cần log class/window.
- Nếu không tìm thấy `DBStatusBarWindow/CARStatusBarWindow` hoặc user vẫn không thấy Dock sau khi ACK normal, không tiếp tục thêm đường chia/64pt tùy tiện: cần nhận iOS syslog `NATIVE_DOCK ...`, hierarchy/Z-order, tình trạng SidePlay window/root transparent. Phần visual-only fallback của QA có thể giữ root window opaque nếu không có owner hợp lệ, cần kiểm trên máy trước khi sửa mù.
- Gói Sileo đang là **QA9 0.1.7~native12chrome9**; bản QA10 chỉ mã nguồn, **KHÔNG compile, không deploy**. Stable Native12/HUD8 và SidePlay nguyên vẹn.

## Bước tiếp theo có thể làm ngay

1. Kiểm GitHub Actions static workflow sau push tại branch QA10, nếu thất bại đọc logs sửa tests; không chạy workflow build DEB.
2. Khi người dùng cho phép: build candidate phiên bản mới ở branch riêng, chỉ promote trên Sileo nếu package/filter/pass; cần test CarPlay **Normal phải hiện đúng Dock ảnh** (đồng hồ + 3 app + nút launcher), Zoom hide, Zoom Out restore, disconnect restore; kiểm logo, modal, ratio không chồng/giật.
3. Theo log `NATIVE_DOCK`: missing/timeout → tìm CarPlay process/window; ACK Normal nhưng Dock vẫn không hiện → kiểm vấn đề SidePlay scene/window occlusion với UIKit hierarchy, không nhận ACK là visual pass.
