# Thử Dock/Home bằng Observer 0.0.2~dockabi2

Đây là bộ đo riêng, chưa sửa lỗi DuoFace QA146. Gói: `com.duoface.qa.duonaviobserver`, phiên bản `0.0.2~dockabi2`; không thay thế gói DuoFace.

1. Khi xe đang đỗ, trong Sileo làm mới nguồn `https://chuongnguyen89dn-ui.github.io/carplaydsp/`.
2. Tìm **DuoNavi Observer (Read Only)**, cài/cập nhật đúng **0.0.2~dockabi2**, rồi Respring một lần. Không dùng bản dockabi1.
3. Giữ DuoFace QA146 đang dùng; không cài hoặc kích hoạt thêm DuoNavi/CarBridge cùng lúc. Kết nối lại CarPlay để bắt đầu phiên đo. Bộ đo đợi có màn hình ngoài rồi ghi 24 mẫu trong khoảng 72 giây.
4. Trong 60 giây đầu: mở một app ngoài từ CarPlay Home; nhấn nút Home và ghi nhớ màn hình trở về; chọn lại app qua Dock nếu có; mở app ngoài thứ hai. Ghi tên hai app và phân biệt nút Home trên màn hình với phím Home vật lý của xe.
5. Trên iPhone mở **DuoNavi Observer** (màn hình có tiêu đề **Observer 0.0.2 · Dock ABI**), bấm **Xuất log**. Dùng menu chia sẻ lưu/gửi tệp TXT như các lần lấy log trước. Lưu TXT vào `Duoface/sideplay/log/`, không lưu vào Gpt-training-.
6. Kèm ghi chú đang thử QA146, hai app vừa mở, thứ tự thao tác, Dock có hiện app không, Home trả về đâu và có app nào xoay sai. Nếu muốn so với DuoNavi gốc, làm phiên riêng sau khi tắt bridge DuoFace; không bật hai bridge cùng lúc.

Phân tích sau khi nhận log:

```bash
python3 sideplay/duonavi-observer/analyze_native_dock.py --log /path/to/export.txt --output /path/to/result.json
```

Phải có các bản ghi `native_dock_class_abi`, `native_dock_scene_node`, `native_dock_sample_complete`. Nếu không có, kiểm tra đúng phiên bản/có Respring/đúng tiến trình; không kết luận API không tồn tại chỉ từ log trống. Bộ đo ghi khai báo class/hàm và cây controller công khai; chưa chứng minh receiver nằm trong ivar riêng, tham số lúc gọi, ACK app-side hay độ trễ lần chạm đầu.

Build nguồn: https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41193875955

SHA256 DEB: `f3e3e04b74ef76b09f529954e708ae0521f13d139313405f18b1390b28999f40`.
