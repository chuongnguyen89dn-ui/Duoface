# QA147 — kiểm tra đường ACK (2026-10-31)

Phạm vi: chỉ Home, Dock, khởi động và scene readiness. Kiểm tra mã nguồn ở commit 02893d86; **chưa chỉnh runtime, chưa build và chưa kiểm tra thiết bị**.

Bằng chứng từ `DFHomeStandalone144.m`:
- `begin:` gắn surface vào UIKit rồi ghi kết quả `pending-scene` mà không kiểm tra lại kết quả sau thao tác gắn.
- Sự kiện `sceneReady:` chỉ ghi kết quả hosted khi `verifiedPIDForHostedView:` có giá trị. Nếu PID chưa khả dụng, nó thoát và không tự lên lịch kiểm tra lại.
- Bộ kiểm tra hạn chờ 9 giây chỉ coi là lỗi khi scene không còn live, nên trường hợp scene live nhưng chưa nhận PID có thể không phát kết quả cuối.
- `sceneFailed:` dọn phiên trong lúc gắn surface có thể tạo trạng thái không còn khớp sau khi việc gắn view kết thúc.

`DFNativeDockSync147.h` yêu cầu kết quả hosted + PID dương và định danh đúng trước khi cập nhật Dock/Home. Log23 ghi nhận 16 scene-handle observations nhưng không có ACK hosted hoặc Dock-active, chưa có bằng chứng cho biết guard nào chặn ở máy thật.

**Kết luận giới hạn:** nguồn mã hiện có thiếu cơ chế retry PID và xác minh trạng thái cuối sau mount; có nguy cơ các trạng thái ACK bị ghi đè. Chưa chứng minh đây là nguyên nhân duy nhất của hành vi trên xe. Sai lệch kích thước 595x331.333 thành 331.333x595 và tám lỗi attach phải tiếp tục đo riêng.

Bước kế tiếp: bổ sung phép đo theo RequestID/generation cho kết quả mount, PID, scene live và Dock ABI; tạo kiểm thử đồng bộ thành công/thất bại và PID xuất hiện muộn trước khi thay đổi logic hoặc phát hành DEB.
