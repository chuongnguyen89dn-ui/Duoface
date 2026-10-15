# DuoFace Mới native3 — xác minh sạch chữ thương hiệu cũ và test CarPlay

**Phiên bản:** `com.duoface.independent` — `0.1.0~native3`.

## Bản thay đổi chính xác

Đây là bản phát triển tiếp trực tiếp từ `native2` đang có trên Sileo. **Không dựng lại bất kỳ màn hình, picker hay nút Zoom/Style/Close nào.**

- Đổi **434** chuỗi thương hiệu `DuoNavi` → `DuoFace` trong phần dịch của app gốc `DuoFaceUI`.
- Đổi **428** chuỗi `DuoNavi` → `DuoFace` trong các phần dịch nhúng của `DuoFaceDashboard.dylib`.
- Đổi 1 câu log chẩn đoán `Airaw-compatible` → `DuoFace-friendly` trong `DuoFaceFullscreenBridge.dylib`; **cùng 16 byte**, không thay cấu trúc nhị phân.
- Bỏ tên package legacy ghi cứng khỏi script cài đặt. Thay bằng **kiểm tra sở hữu tệp qua `dpkg-query -S`**; nếu một package khác sở hữu các tệp gốc, bộ cài **từ chối**, không tự xóa gói cũ.
- Ký lại ba Mach-O đã thay chuỗi. `__TEXT,__text` của app và hai thư viện nguyên byte trên **hai slice arm64 và arm64e** (với app và Dashboard), và trên slice arm64 (FullscreenBridge) so với native2. 36 file data khác hoàn toàn không thay byte, gồm toàn bộ assets/logo/menu và native2 runtime addon.
- Kiểm tra mọi file trong DEB gồm tên file, symlink, ASCII và UTF-16 BE/LE, 59 data entries/5 control entries: **0 kết quả `duonavi` hoặc `airaw`**. Báo cáo: `dist/payload-migration/native3/BRAND_ZERO_AUDIT.json`.

**CI/DEB đã được kiểm chứng:**
- Build `38718598923` success; regression mã máy/installer `38718992400` success.
- `dist/payload-migration/native3/com.duoface.independent_0.1.0~native3_iphoneos-arm64.deb`
- SHA256 `7040338f37ebb1d1d2bee5adffd9cc0558b595b1ebcb9283169ab8d7f71bf2df`.
- GitHub blob `0f159d2672cb1fc1d0d68e2024258868d0cd710f`. Bản native2 giữ nguyên cho rollback: SHA256 `0d48d13e4c5965f8d787d86fa4c7776145cd843e98e7cae0b516779271264e60`.

## ĐIỀU QUAN TRỌNG: thương hiệu đã sạch, mã giấy phép chưa bị xóa sạch

Bản `native2` đã được xác nhận trên iPhone **không còn hiển thị ngày sử dụng và kích hoạt**. `native3` giữ nguyên bản đó. Tuy nhiên các lớp `CBLicenseSyncManager`, hàm `isLicenseCurrentlyValid`, các chuỗi tiếng Anh “license/subscription/trial” vẫn còn trong nhị phân `DuoFaceUI` và `DuoFaceDashboard.dylib` của baseline. Việc thay tên thương hiệu không xóa code cấp phép. Không đánh đồng hai loại kiểm tra.

Đây là bản thử giúp xác minh đổi sạch định danh vendor nhưng vẫn bảo toàn công năng CarPlay. Việc tách tiếp lõi giấy phép phải làm trong bản kiểm tra kế tiếp, khi biết kết quả thử `native3` trên hai máy.

## Các bước thử thực tế

1. Đỗ xe, mở Sileo, refresh nguồn `https://chuongnguyen89dn-ui.github.io/carplaydsp/`, kiểm phiên bản **native3** của gói `com.duoface.independent`, nâng cấp từ native2. Không cần gỡ app DuoFace Mới đang chạy, giữ package ID.
2. Mở DuoFace trên iPhone: kiểm logo/nhãn/menu và Cài đặt không còn ngày, kích hoạt; không có nhãn “DuoNavi” hoặc “Airaw” ở bất cứ màn nào.
3. Kết nối CarPlay và thử chọn app 2 ô, đổi ứng dụng nhiều lần, Swap, Zoom In/Out, Style, Close App, Refresh/X, Clear All, phóng focus/restore. Kiểm màn không hiện tên cũ.
4. Kiểm lại sau respring, ngắt và kết nối lại CarPlay. Kiểm trên cả hai máy (máy 2 trước đây từng không cài được bản cũ).
5. Nếu có lỗi, gửi ảnh và mô tả bước gây lỗi, log có prefix `DuoFaceNativeTrial` hoặc `DuoFaceNative2UI`; cung cấp crash log SpringBoard/CarPlay nếu có.

## Cách quay về native2

Bản native2 **không bị thay đổi trên GitHub**:
`https://github.com/chuongnguyen89dn-ui/Duoface/blob/2b9a1cd0ff84f7e12110655ed5ed32076aef7e61/dist/payload-migration/native2/com.duoface.independent_0.1.0~native2_iphoneos-arm64.deb`

SHA256: `0d48d13e4c5965f8d787d86fa4c7776145cd843e98e7cae0b516779271264e60`.

Nếu có lỗi sẽ đổi nguồn Sileo của **riêng gói `com.duoface.independent`** về URL/SHA native2 và chạy lại Pages/Live Verify; người dùng không cần tự sửa binary. Tất cả gói khác trong nguồn Sileo vẫn nguyên.
