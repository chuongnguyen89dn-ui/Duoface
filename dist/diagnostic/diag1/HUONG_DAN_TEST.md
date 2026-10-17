# DuoFace Diagnostic diag1 — hướng dẫn iPhone X

**Build xác minh:** GitHub Actions run [39006431451](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39006431451) SUCCESS (macos-15, Theos rootless arm64 + dpkg/ldid). Artifact lưu tại `dist/diagnostic/diag1/com.duoface.diagnostic_0.1.0~diag1_iphoneos-arm64.deb`, SHA256 `d70a4a4d24cdad3a650c871cefc0a33facab5aa9a1fb791e19ddcfc4010c8c6d`. **Chưa thử trên thiết bị; chưa lên Sileo.**

Package hoàn toàn tách biệt `com.duoface.diagnostic`, yêu cầu `com.duoface.independent` đã cài, chỉ cài `DuoFaceDiagnostic.dylib` và `DuoFaceDiagnostic.plist` ở `/var/jb/Library/MobileSubstrate/DynamicLibraries/`. Injection filter: `SpringBoard` duy nhất. Không có file của app DuoFace trong DEB này, không đổi cấu hình.

## Test trên iPhone X (khi xe đỗ)

1. Tải đúng file .deb từ GitHub repo DuoFace / nhánh feature, lưu vào Files/Filza. Cài bằng Sileo/Filza; nếu Sileo yêu cầu thì **respring một lần**. Chỉ trên iPhone X đang gặp lỗi; không cài trên iPhone 8 Plus đang tốt.
2. Kiểm tra `/var/mobile/Library/Logs/DuoFaceDiagnostic-SpringBoard.jsonl` đã có, có event `LOADED` hoặc `STATE_CHANGED`. Nếu không tạo log, **dừng test**; gửi ảnh thông báo khi cài và trạng thái lọc tweak/injection.
3. Khi xe đỗ và CarPlay đã kết nối, ghi nhớ giờ/phút/giây, **bấm DuoFace trên CarPlay Dashboard 2 lần, cách nhau 5–10 giây**; không phải nhấn liên tục. Kiểm tra các ứng dụng CarPlay khác vẫn mở tốt.
4. Gửi file JSONL tại đường dẫn trên; file `.previous` chỉ có nếu log đã lớn hơn 5 MiB. Gửi kèm khoảng thời gian thử và ghi chú giao diện có reload lại không. Có thể gửi thêm log SpeedOwner/SpeedSplit8 của đúng thời điểm.

## Giải thích kết quả

- `MANAGER_EXISTS_NO_WINDOW`: lớp manager tồn tại, chưa có `CBWindow`.
- `MANAGER_WINDOW_PRESENT`: window có, so sánh `window` với `active_window`, scene/root/external_screen/current_app.
- `UIKIT_NOTIFICATION`: UIKit báo chuyển màn hình hoặc foreground/background, **không phải bằng chứng nút DuoFace đã được nhấn**.
- `STATE_CHANGED`/10-second `HEARTBEAT`: snapshot trạng thái để đối chiếu mốc bấm, không cài hook chạm biểu tượng vì chưa xác minh selector và cần tránh rủi ro crash SpringBoard.
- Nếu sau khi bấm không có thay đổi ở manager/window, cần điều tra CarPlay icon activation/launch dispatch (một probe khác được chứng minh selector) thay vì khẳng định lý do từ log này.

## Gỡ an toàn

Sileo > Packages > DuoFace Diagnostic Log > Uninstall, respring. DuoFace độc lập vẫn giữ nguyên. Đây là bản chẩn đoán chưa thử nghiệm trên iPhone X; nếu SpringBoard không ổn định, disable/uninstall **gói diag riêng** qua trình quản lý tweak/jailbreak. Không xóa dữ liệu DuoFace và không reset cấu hình CarPlay.

## Phạm vi quyền riêng tư

Chỉ lưu mốc thời gian, PID, tên lớp UIKit/DuoFace, trạng thái cửa sổ/scene, kích thước màn hình, bộ đếm snapshot. Không đọc GPS, liên hệ, URL, định danh app đang mở hoặc nội dung ứng dụng.
