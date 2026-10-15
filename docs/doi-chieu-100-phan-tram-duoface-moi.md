# Đối chiếu 100% DuoFace đã duyệt → DuoFace độc lập

**Nguồn chuẩn:** `dist/candidates/menu-native1/BUILD_AUDIT.json` + `CONTENTS.txt`, `runtime/fullscreen/`, `src/DuoFaceVisualHook.m`, `src/DuoFaceBorderRunner.m` và `dist/visual-1.0.3-12/assets/` ở chính repo `chuongnguyen89dn-ui/Duoface`.
**Đích:** `independent/engine/` trên nhánh `feature/duoface-independent-core`, gói mới `com.duoface.independent`.
**Lưu ý:** “Đã chuyển mã nguồn” KHÔNG đồng nghĩa “đã chạy đúng như bản cũ”. Chỉ nghiệm thu từng mục sau khi đối chiếu CarPlay trên thiết bị thật. Bản cũ và DEB cũ không bị thay đổi.

| Thành phần người dùng đã chốt | Vị trí gốc để đối chiếu | Vị trí chuyển sang lõi độc lập | Tình trạng |
| --- | --- | --- | --- |
| Logo ngang nguyên bản 960×240, đúng màu đỏ #E3020F | `assets/duoface-logo.png`; `DFPickerZoomMenu.xm` | `assets/transfer_approved_assets.py`, `runtime/DFIApprovedVisuals.h` | Đã chuyển byte; 7 SHA đã xác minh trong DEB alpha2 (run 38695321782); chưa test hiển thị |
| Logo picker alpha v2 (đã duyệt) | `assets/duoface-logo-picker-alpha-v2.png` | script chuyển ảnh / `DFIApprovedHeaderLogo()` | Đã đóng gói nguyên byte (CI PASS); chưa test kích thước hiển thị |
| Logo dọc, biểu tượng, toàn bộ ảnh swap/fullscreen/picker, asset manifest | `dist/visual-1.0.3-12/assets/**` | `assets/transfer_approved_assets.py` vào `Application Support/DuoFaceIndependent/` | Đã đóng gói 10/10 tệp và xác minh 7 SHA (run 38695321782 success); chưa nghiệm thu UI |
| Menu ngang Logo – App – Zoom – Style – Close | `DFPickerZoomMenu.xm` | `DFIInterface.inc`, `DFIApprovedVisuals.h` | Đã biên dịch alpha2 (CI PASS); chưa xác nhận bố cục thực tế |
| Font menu 10pt, icon SF Symbols, trạng thái chọn màu đỏ | `DFPickerZoomMenu.xm` | `DFIStyleApprovedTab`, `updateApprovedTabs` | Đã biên dịch alpha2 (CI PASS), chờ test thiết bị |
| Nền menu native dark, không viền/đường kẻ, không xanh lạ | `DFPickerZoomMenu.xm` / `menu-native1` | `DFIInterface.inc` thiết lập material dark và bỏ viền | **Chưa xác minh** giống đúng native picker |
| Chọn ứng dụng theo ô; đổi app | `DFPickerZoomMenu.xm` / `DuoFaceDashboard.dylib` | `DFIAvailableApps`, `DFISplitController.choose/openBundle` | Bản alpha1 đã mở được lần đầu; sau đó có crash trên thiết bị; **chưa đạt** |
| Dòng logo app – tên app – chấm xanh/đỏ | `DFPickerZoomMenu.xm` (`DFRestyleOneRecentAppRow`) | `DFIList cellForRowAtIndexPath:` | Đã viết lại; chờ test icon thật, kích thước/chấm |
| Refresh xanh khi app đang Live | `DFPickerZoomMenu.xm` | `DFIList.recentAction`, `DFISplitController.tasks` | Đã nối event tái mở host; chờ test lifecycle |
| Nút X trong vòng tròn đỏ khi app không ở ô | `DFPickerZoomMenu.xm` | `DFIList.recentAction`, `DFITerminate` | Đã nối event đóng app; chờ test hành vi |
| Clear All, chỉ đóng app do DuoFace quản lý | `DFPickerZoomMenu.xm` | `DFISplitController.tasks` + `DFITerminate` | Đã có nguồn, chờ kiểm thử tránh app đang chạy trên iPhone |
| Style / chọn bố cục nhiều ô | `DFPickerZoomMenu.xm` | `DFISplitController.layouts/setLayout` | Alpha1 có giao diện chia và thao tác; chờ kiểm nghiệm sau di trú |
| Swap / đổi hai ô | `src/DuoFaceVisualHook.m`, nút swap | `DFISplitController.swapPanes`, nút trong Style | Đã có nguồn, chờ test CarPlay |
| Nút thu/phóng toàn giao diện (KHÔNG nhầm phóng riêng ô) | `DFHostGeometry.xm`, `DFFullscreenTransport.mm`, `DFDashboardChrome.xm` | `runtime/DFIChrome.inc`, `DFIInterface.toggleZoom` | Adapter ẩn chrome đã viết; **chưa chứng minh tương đương hình học/fullscreen bản cũ** |
| Phóng riêng ô/focus/restore | `DuoFaceBorderRunner.m` / `audit/v12-split-focus-restore-chain-20261014.txt` | `DFISplitController.maximized/edgeTap/drag` | Có mã nguồn, chờ kiểm thử cách thao tác |
| Viền báo tập trung hoạt động màu đỏ chính xác | `src/DuoFaceBorderRunner.m` | Cần lớp overlay/pane tương đương trong `DFIInterface.inc` | **CHƯA CHUYỂN ĐẦY ĐỦ** |
| Close App không chồng nút X đóng menu | `DFPickerZoomMenu.xm` | `DFIInterface.inc` (sheet/toolbar độc lập) | Cần test vùng bấm và cơ chế ẩn menu |
| Ẩn/hiện app DuoFace trên iPhone theo yêu cầu | Bản mới alpha1 từng có `SBAppTags:hidden` | `independent/engine/app/Info.plist` đã bỏ hidden | Đã gỡ hidden, CI xác nhận Info.plist không ẩn, chưa xác minh trên máy |
| Tự mở/kết nối/ngắt CarPlay, lưu cài đặt UI | `DuoFaceDashboard` / code `DFIRuntime.m` | `DFIConnectionChanged`, `DFIStop`, prefs ID mới | Có nguồn chạy trong alpha1; chờ regression |
| Không cần DuoNavi/giấy phép/ngày/token/UID | `menu-native1` vẫn chứa `DuoFaceDashboard.dylib` và `com.duonavi.sync.plist` | package `com.duoface.independent` tự xây từ scene host riêng; verify_package.py | alpha1 đã xác minh không chứa DLL/plist DuoNavi, phải tái kiểm bản di trú |
| Giữ bản DuoFace đã duyệt an toàn | `main/dist/candidates/menu-native1/` | mã thử riêng `feature/duoface-independent-core`, asset path mới | **Đã bảo toàn**, không ghi đè cài đặt cũ |
| Cập nhật tiện lợi qua Sileo với package ID mới | `carplaydsp` Pages | `com.duoface.independent` | **Đạt cho alpha1** run 38688787996 và kiểm tra 38689115404; bản sau chưa được triển khai |

## Tiêu chí nghiệm thu cuối cùng (không được nới lỏng)

1. Gói mới không có bất kỳ nhị phân/giấy phép/UID/server xác thực DuoNavi; khác package ID; nguồn/phụ thuộc đều hợp lệ.
2. Từng chức năng *ở trên* cho hành vi và hình thức đúng bản đã duyệt trên iPhone jailbreak + CarPlay thật; không crash khi mở/đổi/đóng app, không xung đột với bản cũ.
3. Toàn bộ ảnh người dùng phê duyệt được kiểm SHA256 và đóng gói nguyên byte sang `Application Support/DuoFaceIndependent/` (không ghi đè `DuoFace/` của bản cũ).
4. `dpkg-deb -f/-c/-x`, cấu trúc arm64/arm64e, chữ ký, tên gói, version, APT/Sileo đúng SHA, build log và device log được lưu lại.
5. Nếu còn dòng **CHƯA ĐẠT/CHƯA KIỂM CHỨNG**, không nói đã chuyển thành công 100%.

## Kết quả thực tế đến lúc viết

- **ĐÃ BUILD & TEST ĐÓNG GÓI, chưa chốt 100%:** run 38695321782 completed/success; mã alpha2, đủ 10 tệp ảnh/7 SHA kiểm chứng, logo, menu 4 mục, icon iPhone, Refresh/X/Clear All, adapter zoom. SHA256 DEB e0b9f509a847da56a90dc390394e808e5418cf402989e00fa321e89e0f4f5d19.
- **Lỗi người dùng đã báo:** crash sau thao tác chọn app nhiều lần; chưa có stack trace để kết luận. Mã đã bổ sung guard chọn trùng khi scene đang tạo, nhưng chưa được xác nhận trên thiết bị.
- **Tiếp theo:** kiểm tra UI/những hành vi còn thiếu trên thiết bị, xin log lỗi chọn app, sau đó kiểm tra Zoom geometry; đặc biệt viền đỏ và Zoom geometry, app lifecycle.
