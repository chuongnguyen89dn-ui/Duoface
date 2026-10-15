# DuoFace Mới native1 — hướng dẫn kiểm tra trực tiếp iPhone/CarPlay

**Bản dùng thử:** `com.duoface.independent` / `0.1.0~native1`. Mục tiêu: lấy **đúng bản DuoFace đã hoàn thiện** (UI app, native picker, chia hai ô, Zoom, Style, Close App, tài nguyên gốc) làm nguồn thật, không dựng lại giao diện alpha2.

## Kết quả đã xác minh trước thiết bị

- Source DEB `menu-native1` SHA256 `ce971b42230d355421b2b1d99793a1f62ffb75008365ea74a3467d859cc1de3a`.
- `dist/payload-migration/native1/com.duoface.independent_0.1.0~native1_iphoneos-arm64.deb` đã build CI trên macos-15; SHA256 `16fd5fcbad7eba98de91a2e7a1200793509640cc47decbcca30491a45a6b9a13`.
- 37 tệp payload nguyên gốc đã được so SHA từng byte; nhị phân UI, Dashboard, fullscreen, visuals và toàn bộ ảnh không bị viết lại. Thêm `A_DuoFaceNativeNoLease.dylib` để thử tách hoạt động khỏi đồng bộ thời hạn; bản gốc vẫn chứa mã legacy, **chưa xác minh tất cả đường này đều không được gọi trong thực tế**.
- Gói cũ `com.duonavi.app` và `com.duoface.app` vẫn không bị xóa/sửa. `DEBIAN/preinst` **từ chối cài** nếu một trong hai vẫn hiện là **installed**. Không có `Conflicts`/`Replaces` tự động gỡ, không tự sửa UID hay chứng nhận.

## Quy trình test (chỉ khi đã xác minh gói trên nguồn Sileo)

1. Trước khi thử, giữ sẵn nguồn Sileo cũ và phương án cài lại bản DuoFace đang hoạt động. **Không thử trên xe đang di chuyển**.
2. Nếu đang cài `com.duonavi.app` hoặc `com.duoface.app`, bản native1 sẽ **không ghi đè và không cho cài đồng thời**. Chỉ khi tự quyết định tháo gói cũ (có khả năng làm ngắt tính năng đang dùng), mới tiếp tục cài bản native1. Không gỡ tự động khi cập nhật Sileo.
3. Mở nguồn `https://chuongnguyen89dn-ui.github.io/carplaydsp/` trong Sileo, Refresh, kiểm gói **DuoFace Mới (Native thử nghiệm)**, version `0.1.0~native1`. Nếu vẫn `alpha2` thì chờ bước kiểm tra Pages trước, không thử DEB cũ.
4. Cài bản native1; để chắc chắn các thư viện được nạp mới, khởi động lại SpringBoard và kết nối lại CarPlay. Kiểm biểu tượng DuoFace trên iPhone/CarPlay và **giao diện menu thực tế phải giống bản DuoFace trước**, không hiện thanh nút floating tự dựng của alpha2.
5. Test khi đỗ xe: mở app bản đồ + app thứ hai, chạm/đổi từng ô nhiều lần; Style, Zoom In/Zoom Out, Close App, chấm live, Refresh/X, Clear All; ngắt/nối lại CarPlay. **Ghi lại bước đầu tiên bị crash/lỗi**.
6. Nếu có crash, gửi crash log SpringBoard/CarPlay hoặc một đoạn log có tiền tố `[DuoFaceNativeTrial]`. Lệnh NewTerm ngắn: `log show --last 5m | grep DuoFaceNativeTrial | tail -30` (nếu hệ thống hỗ trợ `log`). Nếu không có, ghi thời điểm và thao tác để đối chiếu crash reports.
7. Để trở về bản đang dùng, gỡ riêng `com.duoface.independent` trước, rồi cài lại package DuoFace cũ từ đúng nguồn. **Đừng giữ hai bộ binary native cùng chạy**.

## Tiêu chí để ghi nhận kết quả

- **Chưa được đánh dấu 100%** trước khi xác nhận bằng video/ảnh từ CarPlay rằng: hai app chạy live, logo/menu/icon đúng bản duyệt, fullscreen và restore đúng, không crash khi chọn nhiều lần.
- Nếu app crash: ghi tên process và stack/hook logs, đối chiếu `A_DuoFaceNativeNoLease` đã nạp vào đúng tiến trình hay chưa. Nếu vẫn xuất hiện luồng đồng bộ thời hạn, giữ binary nguyên gốc và chỉ điều chỉnh tầng điều phối trong bản thử tiếp theo.
- Tình trạng `native1` hiện tại là **THỬ NGHIỆM**. Không nói đã loại hoàn toàn logic cấp phép khỏi file nhị phân.
