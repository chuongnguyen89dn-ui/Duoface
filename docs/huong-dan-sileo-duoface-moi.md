# Hướng dẫn thử nghiệm bản DuoFace Mới qua Sileo

**Tình trạng tài liệu:** Chỉ áp dụng khi bản DuoFace Mới `0.1.0~alpha1` thực sự đã được xuất bản và kiểm tra trong nguồn Sileo. Không hiểu tài liệu này là xác nhận đã phát hành.

## Phân biệt các bản

- **DuoFace đang sử dụng (nền cũ):** mã gói `com.duonavi.app`, giữ nguyên trên repo DuoFace; không tự gỡ, không tự ghi đè.
- **DuoFace Mới (thử nghiệm):** **mã gói hoàn toàn riêng `com.duoface.independent`**, bản `0.1.0~alpha1`, chưa bảo đảm hoạt động hai app trên CarPlay thật, giao diện mới chưa hoàn thiện. Đây là sản phẩm thử nghiệm dùng mã nguồn scene độc lập thuộc cùng chủ kho.
- **Nguồn Sileo đã có:** `https://chuongnguyen89dn-ui.github.io/carplaydsp/` (repo xuất bản `chuongnguyen89dn-ui/carplaydsp`). Chỉ khi kiểm tra chỉ mục `Packages` có `Package: com.duoface.independent` mới có thể chọn cập nhật trong Sileo. **Không cần tải DEB thủ công mỗi lần.**

## Các nguyên tắc an toàn

1. Đừng coi bản thử này là bản thay thế DuoFace đang hoạt động. Mã `com.duoface.independent` độc lập hoàn toàn, không đặt `Conflicts`/`Replaces` buộc xóa phần mềm hiện tại.
2. Sau cài, tính năng được **tắt mặc định**. Đây là chủ đích để tránh hai bộ quản lý cửa sổ đồng thời xung đột trong SpringBoard.
3. Trước khi bật thử, phải có cách tắt/gỡ hoặc thiết bị thử riêng; không bật đồng thời bộ chia cũ hoặc Airaw/DuoDash/CarPlay Split với bộ chia mới. Không cung cấp hướng dẫn tự xóa bất cứ gói đang hoạt động nào khi chưa có lệnh của chủ dự án.
4. Trong iPhone Settings, mục **DuoFace Mới**, gạt `Bật DuoFace Mới` mới cho phép mở. Khi CarPlay kết nối, chọn biểu tượng **DuoFace Mới**; trên một số bản iOS, cần khởi động lại tiến trình CarPlay sau cài để icon xuất hiện.
5. Kiểm tra **hai app đang chạy thật**, thao tác từng ô, đổi kích thước, thu phóng/đổi app, âm thanh, bản đồ; không chấp nhận ảnh tĩnh hoặc hai khung trống làm bằng chứng. Nếu thiếu class/hook, không cưỡng ép chạy tiếp.
6. Có thể xuất log từ trang Cài đặt hoặc xem `/var/mobile/Library/Logs/DuoFaceIndependent-runtime.log`; **không gửi UDID/UID, dữ liệu giấy phép, tài khoản**.

## Chặng tiếp theo sau bản alpha

- Đọc log runtime iOS mục tiêu và xác minh scene host hai ứng dụng độc lập.
- Chuyển toàn bộ giao diện đã chốt của DuoFace (logo, App/Zoom/Style/Close, chấm xanh/đỏ, Clear All, refresh/X, nền bản gốc, viền đỏ) sang lớp scene mới, không quay lại `CBBridgeManager`.
- Nâng phiên bản mỗi lần xuất bản để Sileo nhận cập nhật; xác minh hash DEB và chỉ mục Pages sau mỗi lần.
