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


## Mã nguồn đã viết và mức kiểm chứng (18/10/2026)

- `DFSPDisplayState.h` + `DFSPDisplayState.c`: bộ điều khiển trạng thái **toàn màn hình CarPlay** độc lập, không xử lý 2 pane; khởi động luôn bước `SHOW_SYSTEM_BAR` → `APPLY_HOST_NORMAL`, Zoom In `APPLY_HOST_FULL` → `HIDE_SYSTEM_BAR`, Zoom Out `SHOW_SYSTEM_BAR` → `APPLY_HOST_NORMAL`.
- Chỉ nhận ACK có `transaction` đúng; NACK kích hoạt rollback để không báo sai Zoom thành công. Disconnect vô hiệu ACK cũ, hủy trạng thái fullscreen. **Platform owner cần khôi phục host/chrome best-effort trước khi dispose scene**, còn boot kế tiếp luôn yêu cầu normal.
- `tests/test_display_state.c` kiểm 5 kịch bản: khởi động thường không tự fullscreen; Zoom vào/ra có ACK; lỗi Zoom In rollback; lỗi Zoom Out không báo thành công; bỏ ACK sai/ACK phiên cũ.
- **ĐÃ TEST:** GitHub Actions [39117769540](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39117769540), job `117646938527`, build `cc -std=c11 -Wall -Wextra -Werror -pedantic -O2` + 5 tests **PASS**, kiểm source không liên kết vendor binary **PASS**.
- **CHƯA TÍCH HỢP RUNTIME:** chưa có callback xác thực `DFSP_APPLY_HOST_NORMAL/FULL` sang **SidePlay UIWindow/scene owner** và `SHOW/HIDE_SYSTEM_BAR` sang Dashboard/CarPlay đúng phiên; chưa có mã xử lý z-order SidePlay `UIWindowLevelAlert+10`, chưa test thật, chưa build DEB. Không tự gọi “đã fix dock/fullscreen”.
- **Không dùng** C file thử nghiệm `sideplay/native104-geometry/DFNative104Geometry.[ch]` làm chuẩn giao diện đã duyệt. Chuẩn vẫn là Native12 HUD8. **Nút Zoom Native12** hiện hữu sẽ là entrypoint, không tự tạo nút UI thứ hai.

### Chỉ định nơi ghép khi runtime có owner thật

| Phần việc | Source tham khảo DUOFACE ĐÃ CÓ | Cách triển khai trong SidePlay độc lập |
|---|---|---|
| Zoom click | `runtime/fullscreen/DFPickerZoomMenu.xm` và `DFFullscreenCoordinator.mm` | Gọi `DFSPDisplayZoomIn/ZoomOut` từ nút Zoom hiện hữu |
| State ACK / session | `runtime/fullscreen/DFFullscreenTransport.mm` | Gắn callback ACK đúng token vào hai process thực; không gửi local notification rồi giả định cross-process |
| Geometry | `docs/fullscreen-root-cause-20261014.md` về `CBWindow` usable area | Tính normal content từ **CarPlay native insets** do system owner cung cấp; không import `CB*` |
| Chrome | `runtime/fullscreen/DFDashboardChrome.xm`, báo cáo Airaw đã lưu | Chỉ tác động đúng native bar của session khi nhận lệnh Zoom; khôi phục nguyên trạng trên Zoom Out/disconnect |
| SidePlay overlay | `sideplay/normal-carplay/audit/geometry-objc-window-trace.txt` | Xác minh owner & z-order của SidePlay UIWindow trước khi nối các thao tác; không điều chỉnh UIWindow global |

**Điểm tiếp theo:** gắn hai callback owner cho host và chrome, thử normal boot/Zoom in/Zoom out trên iPhone X với log ACK và chụp thanh bar thực. Đó là phần ghép runtime còn thiếu, không phải phân tích lại nguyên DEB.
