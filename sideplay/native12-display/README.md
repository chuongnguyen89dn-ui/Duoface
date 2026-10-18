# Native12 toàn màn CarPlay — ranh giới hiển thị SidePlay

## Yêu cầu được xác nhận 18/10/2026

- Chuẩn giao diện: **DuoFace Native12 + HUD8** (bản được chấp thuận), không phải bố cục SidePlay.
- Phạm vi lần này: **TOÀN BỘ giao diện màn CarPlay**, không phân ô/split ratio/picker.
- Vừa kết nối: **Normal** — còn thanh bar/sidebar CarPlay gốc; không phóng to.
- Chọn **Zoom In** trong menu đã duyệt: đổi toàn bộ host CarPlay sang fullscreen + xử lý native chrome.
- Chọn **Zoom Out**: khôi phục đúng geometry/insets và thanh CarPlay ban đầu.
- Mất CarPlay/thoát scene/respring: bỏ trạng thái fullscreen, khôi phục mặc định; tuyệt đối không lưu fullscreen làm mặc định.
- Không đưa CBWindow/CBBridgeManager/license của DuoNavi vào lõi độc lập.

## Nguồn đã đọc, không quét DEB lại

1. `tiep tuc du an.md` ở repo root: quy tắc Zoom only in menu, không có nút fullscreen phụ, restore và bảo vệ 3 menu gốc.
2. `feature/visual12-duodash-recovery:ban giao du an duoface moi.md`: lịch sử QA/Native12 HUD8.
3. `docs/fullscreen-root-cause-20261014.md`: các lỗi khi dùng event tên Airaw nhưng chưa có owner/chrome/scene.
4. `runtime/fullscreen/DFFullscreenCoordinator.mm`, `DFFullscreenTransport.mm`, `DFDashboardChrome.xm`, `DFPickerZoomMenu.xm`: hợp đồng native Zoom host-ACK, chrome-ACK và rollback.
5. `docs/airaw_fullscreen_multicomponent_conclusion.md`: fullscreen đòi cả geometry và system chrome; không suy từ selector name rằng đã hoạt động.

## Hợp đồng module hiển thị độc lập

- **Normal:** toàn bộ root CarPlay thuộc scene/window gốc, nhưng vùng nội dung chỉ là usable bounds của CarPlay, không áp dụng SidePlay alert+10 làm quyết định hiển thị.
- **Zoom In:** chỉ lệnh do người dùng bấm; xác minh active SidePlay host trước khi thay geometry; nhận ACK host mới xử lý chrome; chỉ gọi FULL khi cả hai thành công.
- **Zoom Out:** hiện lại chrome hệ thống rồi khôi phục frame/insets đã lưu; chỉ gọi NORMAL khi cả hai thành công.
- **Reconnect/scene close:** khôi phục mặc định và vô hiệu hóa ACK của session cũ.
- **Tách owner:** SpringBoard-host là nơi điều khiển cửa sổ; Dashboard/CarPlay là nơi quản lý chrome. Không gửi local notification và giả định hai process nhận cùng một object.
- Nút **Zoom** dùng nhãn accessibility **Zoom In / Zoom Out** và menu Native12 hiện hữu. Không xây menu mới.

## Những gì chưa thể gọi là sửa chạy được

Original SidePlay là Mach-O đã biên dịch. Module giao diện độc lập chỉ có thể điều khiển một host khi xác định đúng owner/session thật; yêu cầu này **chưa được nghiệm thu trên thiết bị**. Đã có ảnh người dùng xác nhận SidePlay bật `Thanh dock CarPlay` nhưng dock vẫn mất. Bật setting không giải quyết được vấn đề.

**Không merge thay SidePlay gốc, không build DEB, không phát hành Sileo khi chưa có host/chrome runtime ACK và test thật.**
