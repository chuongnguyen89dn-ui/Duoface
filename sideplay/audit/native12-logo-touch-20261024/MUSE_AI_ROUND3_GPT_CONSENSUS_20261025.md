# DuoFace / Muse — GPT thẩm định vòng 2, đề xuất câu hỏi vòng 3 (2026-10-25)

**Trạng thái: chỉ nghiên cứu, không sửa source, không build, không phát hành.** Nhánh `feature/duoface-jb-embedded-appbridge-20261020`. Source đọc trực tiếp: `sideplay/duoface-native-scene-host/DFNative12Chrome.m` blob `01de5dc0e827680d7af7504abd5c645ee17d8eeb`; `DFSceneHost.m` blob `8158cf23288092fb374101ab090b09ab87696539`; `DFDeepTrace.h` blob `dbb9be0d589401dab8fbc5c589ff5d3b74b7edbe`. Muse đã rút các nhận định sai về drift, UIView sibling và ngưỡng 0,35s. .62 đã public nhưng chưa kiểm chứng trên máy.

## Kết quả thẩm định mới

1. **Net displacement đã tồn tại.** `logoTouchChanged:` (~1641–1644) tính `perp` và `parallel` từ `trackedScreenPoint - logoTouchStartScreen`, không phải offset giữa hai event. Lỗ hổng thực sự là chọn Ratio vĩnh viễn sau **một mẫu net displacement** >10pt, không phải thiếu phép tính net.
2. **Sticky latch khác ảnh hưởng Swap.** `logoMovedBeforeHold` tăng sau khi `hypot(perp,parallel)>7` (~1687–1693), không reset khi ngón tay trở lại; `logoTouchFinished` (~1710–1727) chặn Swap khi `moved=YES`. Đây là vấn đề mã có thể kiểm chứng, chưa biết tần suất máy thật.
3. **Log .62 chưa đủ phân tích quỹ đạo.** `logo-prehold-motion` chỉ ghi một lần, ở nhánh `else if` khi chưa Ratio. Nếu sample đầu vượt thẳng >10pt và chọn Ratio, marker này sẽ **không được ghi**. `logo-quick-ratio-drag-began-restored-v056` lại không có displacement/trace id. `logo-control raw-began/ended/cancelled` có id trên `DuoFaceDeepTrace.log`; các marker `chrome` không có id, nên phải correlate timestamp cùng run và ghi rõ giới hạn. `DFDeepTrace.h` gắn build `0.0.62~rawgrip1` và luân chuyển log 2MiB sang `.previous`.
4. **Dwell 150ms có bẫy callback:** UIKit không bảo đảm phát tiếp `touchesMoved` nếu ngón tay đứng yên sau khi đạt ngưỡng. Cần bộ hẹn giờ độc lập có kiểm tra touch generation, hoặc quy tắc commit được xác định lại; chưa có số liệu để cố định 14pt/6pt/150ms.
5. Rung tay không luôn quay về gốc trước 150ms; kéo chủ ý cũng có thể tạm lùi. Fit và kiểm trên cùng vài chục lượt là overfit; nếu sửa nên có corpus kiểm thử tách khỏi corpus hiệu chỉnh. `raw-cancelled` cho thấy touch mất, không đủ chứng minh nguyên nhân là parent pan.

## Thử nghiệm tối thiểu trước khi đổi source

Xác minh trên điện thoại đúng bản `0.0.62~rawgrip1`, đang ở giao diện chia đôi, khởi động đã xong, xe đỗ. Làm 3 lượt mỗi loại trước: giữ logo >3 giây rồi kéo dọc; giữ có rung nhẹ rồi kéo dọc; kéo Ratio ngay; chạm chờ 0,8 giây rồi kéo Ratio; chạm ngắn Swap. Nếu cần mới mở rộng 10 lượt/nhóm. Thu `DuoFaceDeepTrace.log`, `DuoFaceTouchOwner.log` kèm thời điểm và nhãn thao tác. Xác nhận: `raw-began`, `raw-cancelled`, `logo-3s-timer-suppressed`, `logo-quick-ratio-drag-began-restored-v056`, `logo-3s-hold-began-real-touch-timer`, `logo-3s-moved-position`, `logo-tracking-ended`. Nếu mọi chức năng PASS, không cần vá logo. Nếu ratio latch xảy ra trong hold dự định, kế tiếp chỉ thêm log quỹ đạo không đổi hành vi.

## Video / crash

`DFSceneHost.m` chặn cập nhật kích thước live remote scene; ba IPS cũ cho thấy SpringBoard SIGABRT +440 nhưng chưa rõ assertion. Cơ chế lưu trước trạng thái thử nghiệm và tắt thử nghiệm sau crash giúp hạn chế lặp lại, **không ngăn được lần crash đầu tiên**; việc khôi phục settings qua private write có thể lại gây crash. Vòng này không kích hoạt thay đổi runtime video.

## Câu hỏi gửi Muse vòng 3

1. Bạn xác nhận nguồn `perp/parallel` đã là net từ thời điểm touch-down chứ?
2. Hãy sửa protocol Bước 1 vì marker `logo-prehold-motion` thiếu nếu Ratio được nhận ngay. Làm sao correlate một cách trung thực?
3. Hãy thiết kế state machine/timer cho trường hợp vượt ngưỡng rồi **đứng yên không có touchesMoved**; giải thích không gây hồi quy kéo Ratio sau 0,8s.
4. Xử lý thế nào `logoMovedBeforeHold` và Swap khi có rung rồi quay lại?
5. Làm sao tách tập dữ liệu hiệu chỉnh và tập xác minh để tránh overfit? Có chấp nhận trường hợp .62 PASS thì giữ nguyên mã?
6. Những điều kiện an toàn nào vẫn chưa biết đối với giao diện video và crash?

**Next:** gửi Muse câu hỏi vòng 3; chờ dữ liệu thực .62 mới quyết định một thay đổi an toàn; giữ nguyên Ratio/Swap/Zoom/Dock.
