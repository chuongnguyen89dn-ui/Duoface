# HỒ SƠ TẬN RĂNG — HỌ PORTAL / SPLIT / UIAPP (DuoFaceDashboard, 1.0.3-12)

Đọc từ disassembly. Trạng thái: cơ chế chính đã khép; còn một điểm mở ghi ở cuối.

## 1. Bốn loại app được bridge (CBBridgeManager điều phối)
- `CBBridgedUIApp` (16 method) + `CBBridgedUIAppView` (29): host scene trực tiếp — app render vào scene trên màn xe, settings ghi qua updateSettingsWithBlock (xem hồ sơ hình học mục 7).
- `CBBridgedSplitApp` (49): nhiều app view trong CBSplitContainerView; mỗi view có renderSize riêng (hồ sơ hình học mục 3/9).
- `CBBridgedPortalApp` (6) + `CBBridgedPortalAppView` (12): chế độ portal — xem mục 2.
- `CBBridgedAssistantApp` (6) + `CBBridgedAssistantView` (15): trợ lý.
- `-[CBBridgeManager appForBundleIdentifier:frame:]` (IMP 0x19d984, ~91 lệnh) là hàm TRA CỨU theo tên class: đối chiếu chuỗi tên với 'CBBridgedPortalApp' / 'CBBridgedSplitApp' / 'CBBridgedAssistantApp', mặc định rơi về CBBridgedUIApp — tức manager phân biệt app đang chạy thuộc loại nào bằng tên class của đối tượng đã tạo, không tự quyết định loại tại đây.

## 2. Portal = app ở yên trên màn điện thoại + bắt hình toàn màn + chạm HID tổng hợp
- `-[CBBridgedPortalAppView captureFrame:]` (IMP 0x834d4, đọc hết): mở autorelease pool → gọi hàm private của UIKit **`__UICreateScreenUIImage`** (bắt hình TOÀN MÀN HÌNH điện thoại thành UIImage) → gán vào `imageView` của portal view. Vòng lặp được kéo bởi CADisplayLink của view (có sẵn property displayLink + start/stop).
- Hệ quả kiến trúc: trong chế độ portal, app đích chạy trong môi trường tự nhiên của nó (màn điện thoại, process của nó) — bàn phím, vòng đời, hướng màn đều là nguyên bản iOS; phía xe chỉ là một luồng hình chụp lại. Đây là lý do portal không dính bất kỳ bài toán phím/chạm/scene nào của đường host trực tiếp.
- Chạm chiều ngược: `-[CBTouchCloneView sendTouchEventAtPoint:isDown:]` (IMP 0x82d4c): đọc bounds của UIScreen.mainScreen làm cơ sở tọa độ, dùng `_mach_absolute_time` làm mốc thời gian, và tạo sự kiện bằng **`_IOHIDEventCreateDigitizerEvent`** — sự kiện chạm tổng hợp ở tầng HID (cùng tầng với ngón tay thật), kèm `_vm_read_overwrite` (đọc bộ nhớ tiến trình đích phục vụ việc dựng/điều phối sự kiện). App đích không phân biệt được chạm này với chạm vật lý.
- Cặp cơ chế này khớp nhau: hình đi lên bằng chụp màn hình, chạm đi xuống bằng HID — portal là một vòng "remote desktop" ở tầng hệ thống, không phải scene hosting.

## 3. Đối chiếu với phía ta
- Ta chỉ có đường host scene trực tiếp (tương ứng CBBridgedUIApp) + chia 2 (một phần của CBBridgedSplitApp). Không có portal, không có bắt hình, không có chạm HID.
- Mọi vòng khó của dự án (phím QA176–185, chạm trong app host, scene bị ngủ) đều là bệnh của đường host trực tiếp; đường portal của gốc né toàn bộ các bệnh đó bằng cách không di chuyển app khỏi màn điện thoại — đổi lại: app chiếm màn điện thoại khi đang hiện trên xe, và hình là ảnh chụp (độ trễ/độ nét phụ thuộc nhịp display link).

## 4. Điểm còn mở
- Vị trí quyết định chọn portal cho một bundle cụ thể: settings có portalAppEnabled/portalAppIdentifier và appSettings theo bundle; manager chỉ tra cứu theo tên class, nên quyết định tạo loại nào khả năng nằm ở phía request trong process app/UI — chưa đọc tới nơi. Không ảnh hưởng kết luận cơ chế ở mục 2.
