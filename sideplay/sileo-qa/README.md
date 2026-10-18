# SidePlay Zoom QA1 — độc lập, thử trên Sileo

**Yêu cầu user (18/10/2026):** phải có DEB trên Sileo để thử, nút fullscreen phải xuất hiện/thao tác được. Đây là ưu tiên mới, thay thế các lệnh khóa đóng gói trước đó chỉ đối với **SidePlay QA1**. Không sửa bản Native12 HUD8, Visual12 hoặc QA đã cài.

## Nguồn thử thật

- Binary SidePlay gốc nằm riêng trong máy người dùng; **không tái phân phối SidePlay** trong gói QA.
- Mã tweak độc lập: `Tweak.xm`, `DuoFaceSidePlayDisplayQA.plist`, `Makefile`, `control`.
- Hook có căn cứ: class `SPDash` và method `-setCarWindow:`, `-layoutRootView`, chứng cứ original `sideplay/native12-display/audit/SIDEPLAY_WINDOW_OWNER_CLASSES.json` từ run `39118667180`.
- Chỉ inject `com.apple.springboard`; chỉ gắn UI khi `carWindow.screen != UIScreen.mainScreen`; không hook hay đổi mọi UIWindow và không sửa ứng dụng gốc.
- Khi SidePlay vừa hiện trên CarPlay: đặt thử windowLevel dưới `UIWindowLevelStatusBar` thay cho mức gốc quá cao, hi vọng native bar hiện; **đây là giả thuyết cần thử thật**, không phải hiệu quả đã xác thực.
- Tạo **một nút Zoom In/Zoom Out tạm** ở góc trên phải cửa sổ SidePlay để có chỗ chạm. Đây **KHÔNG phải menu App/Zoom/Style/Close Native12 chính thức**. Việc chuyển về đúng ô Zoom trong menu Native12 vẫn chưa làm vì menu chưa được port; không gọi là giao diện 100%.
- Bấm Zoom In: khôi phục `windowLevel` ban đầu và mở ra khung màn ngoài. Zoom Out: hạ `windowLevel` và khôi phục khung trước đó; không đụng split/scene embedding/HUD.
- Disconnect `SPDash.setCarWindow:nil`: khôi phục original level/frame và bỏ nút. Log ở `/var/mobile/Library/Logs/DuoFaceSidePlayDisplayQA.log`.

## Rủi ro và rollback

- Z-order CarPlay hệ thống **chưa đo trên thiết bị**, vì vậy chế độ Normal có thể làm SidePlay nằm dưới Dashboard, mất tương tác hoặc không hiện dock. Nếu lỗi: gỡ **`com.duoface.sideplaydisplay`** trên Sileo, respring; SidePlay vẫn nguyên bản.
- Package **`com.duoface.sideplaydisplay`**, version `0.1.0~zoomqa1`, architecture `iphoneos-arm64`, dependency SidePlay gốc đã cài. Không làm package Conflicts/Replaces với DuoFace Native.
- Chưa chứng minh chrome owner-ACK hay source-level equivalence với DuoFace Native12; phần `sideplay/native12-display/` mới compile-only, chưa nối vào process đúng.
- Chỉ dùng khi đỗ xe và có thể gỡ qua Sileo/iPhone; lần đầu respring cần quan sát SpringBoard crash/exitmode.
- Nếu QA bị crash, không tự nối lại hàng loạt tính năng; lấy log / SpringBoard .ips trước.

## Điều kiện xác minh phát hành

1. Github Actions build Theos rootless **SUCCESS** + hash SHA256 + nhận diện đúng package ID/dependency/dylib/filter.
2. Artifact được lưu bền vững dưới `sideplay/artifacts/zoomqa1/` trên branch phát triển.
3. Chèn một gói QA độc lập vào APT index tại `chuongnguyen89dn-ui/carplaydsp`, không ghi đè package Native/Visual/Hub. Pages deploy **SUCCESS** + xác minh mục package/SHA trong index.
4. Chỉ sau đó báo **đã lên Sileo**. Device PASS đợi user test thật.

**Không phát hành bản QA thay SidePlay chính thức hoặc tuyên bố đây là SidePlay đã sửa xong.**
