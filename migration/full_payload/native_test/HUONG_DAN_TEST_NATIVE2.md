# DuoFace Mới native2 — kiểm tra trực tiếp và quay về native1

## Bản đang phát hành

- Gói Sileo: `com.duoface.independent`.
- Version: `0.1.0~native2`.
- Nguồn: `https://chuongnguyen89dn-ui.github.io/carplaydsp/`.
- Binary DEB: `dist/payload-migration/native2/com.duoface.independent_0.1.0~native2_iphoneos-arm64.deb`.
- SHA256 chính xác: `0d48d13e4c5965f8d787d86fa4c7776145cd843e98e7cae0b516779271264e60`.
- Bằng chứng build: `38710799434` SUCCESS; GitHub Pages build + deploy `38711100288` SUCCESS; tải lại Sileo APT/DEB và hash run `38711414564` SUCCESS.
- Giữ nguyên 37 tệp gốc thuộc DuoFace; *không thay đổi* tệp nhị phân UI, Dashboard, FullscreenBridge, VisualHook, picker, menu, tất cả logo/ảnh. Chỉ bổ sung phần xử lý UI settings trong chính add-on riêng đã tồn tại ở native1.

## Test trên thiết bị đang đỗ xe

1. Tại Sileo đã có nguồn `https://chuongnguyen89dn-ui.github.io/carplaydsp/`, Refresh và kiểm tra **DuoFace Mới (Native thử nghiệm)** có Version **`0.1.0~native2`**; nâng cấp từ native1.
2. Trong DuoFace trên **iPhone**, vào phần **Cài đặt**. Xác minh không còn hàng thông tin đăng ký/giấy phép/thời hạn (ví dụ DuoFace Pro hoặc subscription) và không có hộp thoại đòi gia hạn khi mở app. Các hàng *Ngôn ngữ, Trạng thái CarPlay, DuoFace Team, SpringBoard, Cài đặt* phải vẫn thao tác như trước. Nếu để trống một hàng hoặc nút lệch thì chụp ảnh.
3. Kết nối CarPlay, chọn 2 ứng dụng vào hai vùng và thử đổi vài lần. So sánh menu nền native, logo ngang, App – Zoom – Style – Close, bố cục, focus, restore, viền, chia tỉ lệ với native1. **Không thử trong lúc lái xe.**
4. Respring và kết nối lại CarPlay; xác nhận không crash hoặc xuất hiện thông báo thời hạn. Nếu lỗi, ghi tên app, màn hình, thời điểm và thao tác gần nhất. Log native2 nếu có tiền tố `[DuoFaceNative2UI]`; log native1 core nếu có `[DuoFaceNativeTrial]`.

## Cách quay về native1 khi lỗi

**Native1 đã được giữ nguyên tuyệt đối trên GitHub, không ghi đè:**

- `dist/payload-migration/native1/com.duoface.independent_0.1.0~native1_iphoneos-arm64.deb` tại commit `6c6a1f6a1a4802373be14ddfb92c71e28a880d49`.
- SHA256: `16fd5fcbad7eba98de91a2e7a1200793509640cc47decbcca30491a45a6b9a13`.
- Link GitHub: `https://github.com/chuongnguyen89dn-ui/Duoface/blob/6c6a1f6a1a4802373be14ddfb92c71e28a880d49/dist/payload-migration/native1/com.duoface.independent_0.1.0~native1_iphoneos-arm64.deb`.
- Có thể quay lại bằng cách khôi phục nguồn Sileo cho package `com.duoface.independent` trỏ về native1 cùng hash đã kiểm và chạy lại Pages/verify, hoặc thực hiện downgrade gói (không tự gỡ/xóa package cũ nếu chưa có xác nhận từ người dùng).
- **Không tự cập nhật lại `com.duonavi.app`**, không sửa root source `tiep tuc du an.md` cũ.

## Những phần vẫn cần thêm bằng chứng

- Đã compile và kiểm byte gốc, nhưng **chưa test native2 trên iPhone/CarPlay thực**.
- Các phương thức/chuỗi kiểm tra cấp phép vẫn được chứa trong hai nhị phân original `DuoFaceUI`, `DuoFaceDashboard.dylib`; native2 mới chỉ triệt tiêu **lớp hiển thị ngày và đường mở giao diện đăng ký**. Add-on native1 giữ chức năng cốt lõi đã chạy thành công trên hai máy. Không báo đã xóa toàn bộ mã licence khỏi binary.
- Chỉ sau khi native2 được xác nhận hoạt động tốt trên 2 máy mới tiếp tục dọn các điểm đồng bộ/network còn lại theo các vòng thử nghiệm có bản rollback.
