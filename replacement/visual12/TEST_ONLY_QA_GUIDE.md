# DuoFace Visual12 — DEB QA độc lập (không phải Native12 + Hub8)

## Mục tiêu

Chỉ chứng minh nguồn mở scene CarPlay do DuoFace tự kiểm soát có thể hiển thị và mở app trên thiết bị jailbreak iOS 16 hay không. **Bản chính vẫn là Native12 + Hub8.** Chỉ chuyển cơ chế đã kiểm chứng vào đó sau kết quả thử thiết bị. Không dùng bản QA làm giao diện DuoFace 12 chuẩn, không phát hành Sileo.

## File được xác minh (GitHub)

- Nhánh: `feature/visual12-duodash-recovery`
- Run CI: https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39037058354 — **SUCCESS**.
- DEB: `dist/visual12-standalone-qa/com.duoface.visual12_1.0.3-12~standalone1_iphoneos-arm64.deb`
- SHA-256: `c838a61db75bfdc04d3d4c8b87ca8c982de215e458402907ab4a79e861c4d32f`
- Dung lượng: 1.057.416 byte
- Package/Bundle ID mới: `com.duoface.visual12`
- Binary tweak: `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisual12.dylib`
- Thư mục app: `/var/jb/Applications/DuoFaceVisual12.app`
- Gói Sileo hiện hành **không thay đổi**; không có lệnh xóa/ghi đè Native12 Hub8.

## Kiểm thử an toàn

1. Dùng thiết bị jailbreak iOS 16 **thử nghiệm** hoặc môi trường không còn scene owner cũ hoạt động. Không gỡ, thay hay vô hiệu hóa Native12 + Hub8 đang dùng chỉ để chạy thử nếu chưa chấp thuận kế hoạch quay lại.
2. Cài DEB QA riêng bằng trình quản lý DEB tương thích, xác nhận ID `com.duoface.visual12`, không phải `com.duoface.independent` hay `com.duonavi.app`. Nguồn là file GitHub/ACTIONS, **không phải bản cập nhật Sileo**.
3. Vào Cài đặt của DuoFace Visual12, bật chế độ cho phép split nếu chưa bật. Kết nối CarPlay, thử mở giao diện và chọn **một ứng dụng** không hỗ trợ CarPlay, ví dụ YouTube; xác nhận khung hiển thị nội dung tương tác được.
4. Nếu bước 3 thành công, thử **hai ứng dụng** song song (Waze/YouTube), chuyển đổi từng khung, thoát app, ngắt/nối lại CarPlay. Không thử khi lái xe.
5. Nếu lỗi hoặc không hiện, báo rõ thiết bị iOS/jailbreak, có gói `com.duonavi.app` / `com.duoface.independent` đang nạp không, app có mở được một khung hay không; không kết luận chỉ dựa trên trạng thái VIP hoặc nhãn CI SUCCESS.
6. Gỡ **đúng** `com.duoface.visual12` khi dừng thử; không gỡ gói bản chính. Package QA được thiết kế với file/Prefs/app riêng.

## Giới hạn có thể làm thử nghiệm thất bại

Trong `replacement/visual12/engine/runtime/DFIRuntime.m`, `DFIStart()` cố ý từ chối chạy khi phát hiện runtime class `CBBridgeManager` cũ vẫn nạp vào SpringBoard, nhằm tránh chạy hai scene host xung đột. Do đó **máy đang cài/nạp VisualTest12 hoặc bộ lõi cũ có thể không khởi động bản test**, dù DEB cài thành công. Lỗi kiểu này cần được phân loại là *test environment blocked*, chưa phải bằng chứng scene engine độc lập không hoạt động.

UI được chuyển từ source độc lập và có sử dụng assets gốc đã duyệt; **chưa được xác minh giống V12 hoàn toàn**. Fullscreen mới chỉ được CI/link, chưa có ACK chrome trên xe. Hub8 chưa được ghép vào DEB test.

## Quyết định sau kết quả

Chỉ sau khi thử trên xe xác nhận app mở được, lifecycle và split ổn định, mới lập bản đồ để ghép phần lõi đã qua thử vào **Native12 + Hub8**. Giai đoạn ghép phải có bản backup và regression Fullscreen, menu, Hub; không phát hành một UI alpha sai thành bản sản phẩm.
