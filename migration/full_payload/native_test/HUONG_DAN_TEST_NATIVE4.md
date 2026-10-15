# DuoFace Mới 0.1.0~native4 — DEB thử nghiệm loại mã giấy phép

## Bản DEB

- Package ID: `com.duoface.independent` (nâng cấp từ native3, không đổi bundle ID)
- Architecture: `iphoneos-arm64` (rootless)
- File: `dist/payload-migration/native4/com.duoface.independent_0.1.0~native4_iphoneos-arm64.deb`
- SHA256: `517cc6ccf84716e40b80116834cf1c874e9ae5027584dc94118cc8f6c4f7f244`
- Kích thước: `1732240` byte.
- Build: `https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38721372578` SUCCESS
- Hồi quy độc lập: `https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38721748764` SUCCESS
- Bằng chứng: `dist/payload-migration/native4/BAO_CAO.json` và `audit/payload-migration/NATIVE4_EXECUTABLE_REGRESSION.json`

## Chính xác đã thay đổi gì

- 248 implementation của phương thức thuộc màn hình đăng ký/thanh toán/thời hạn trên `DuoFaceUI` đã được thay bằng đoạn `return` tương thích ABI + NOP trên 276.524 byte vùng hàm.
- 43 phương thức của quản lý giấy phép/cảnh báo liên quan trên `DuoFaceDashboard.dylib` (316.564 byte vùng hàm) được thay tương tự.
- Các selector Objective-C và metadata vẫn giữ để tránh lỗi khi những caller động cố gắng gọi tới; **không tuyên bố đã xóa sạch 100% chuỗi hoặc mã license**. Một phương thức trong bản gốc đã có sẵn body inert.
- Preserve lifecycle và các phương thức xác định CarPlay screen connected, ứng dụng/cấu trúc picker/Zoom/Style/Close, tài nguyên ảnh, các hook đã duyệt. 37 tệp payload còn lại nguyên byte; các instruction không thuộc phương thức được sửa nguyên byte.
- `DuoFaceUI` và `DuoFaceDashboard.dylib` được chuyển từ universal `arm64+arm64e` về `arm64` chung, được ký lại. Đây là rủi ro thử nghiệm: iPhone arm64e thường có thể chạy arm64 nhưng chưa có chứng cứ runtime của native4.
- DEB giải nén không còn chữ `DuoNavi` hoặc `Airaw` theo scan ASCII/UTF16/path/control của dự án.
- Gói cũ `com.duonavi.app` trên Sileo vẫn giữ nguyên, không tự xóa. `native3` vẫn có file gốc trên GitHub.

## Thử trên điện thoại (xe đang đỗ)

1. Mở nguồn `https://chuongnguyen89dn-ui.github.io/carplaydsp/` trong Sileo và Refresh, chờ bản `0.1.0~native4` hiện.
2. Xem DuoFace trên iPhone có vào được, logo/mục Cài đặt đúng, không còn mục ngày/kích hoạt. Nếu ứng dụng tự tắt, ghi thời điểm và crash.
3. Kết nối CarPlay: chọn ứng dụng bên trái và bên phải, thay ứng dụng qua lại; thử App – Zoom In/Out – Style – Close App, các nút Refresh/X/clear; kiểm màu nền menu, logo, viền, chia màn.
4. Thử respring, ngắt kết nối và kết nối lại CarPlay. Thử trên cả hai iPhone đã dùng được native1. Nếu có crash, ghi bước và cung cấp crash log SpringBoard/CarPlay/DuoFaceUI.
5. Chỉ sau test thành công mới đánh dấu `native4 DEVICE PASS` trong hồ sơ. CI success chỉ chứng minh đóng gói/byte-level QA.

## Khôi phục native3 nếu lỗi

- `native3` bản đang dùng trước khi làm native4: `https://github.com/chuongnguyen89dn-ui/Duoface/blob/9a5d2d027b7c0932dcfd6f21a5b1e474d7342fc2/dist/payload-migration/native3/com.duoface.independent_0.1.0~native3_iphoneos-arm64.deb`.
- SHA256: `7040338f37ebb1d1d2bee5adffd9cc0558b595b1ebcb9283169ab8d7f71bf2df`.
- Hệ thống Sileo có thể phục hồi bằng việc **chỉ** sửa pinned URL/SHA/Version cho package `com.duoface.independent` trong `carplaydsp/.github/workflows/build.yml`, rồi đợi build, deploy Pages và kiểm Packages/DEB. Không đổi các package khác. Nếu thiết bị không chịu hạ version, có thể dùng chức năng downgrade/cài DEB bằng trình quản lý gói sau khi kiểm checksum; sao lưu ứng dụng/dữ liệu trước.
