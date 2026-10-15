# DuoFace Mới native5 — danh sách thực tế và kế hoạch xóa dứt điểm sau khi test

**Nguồn xác minh:** `native4` do người dùng xác nhận chạy ổn định trên CarPlay, phiên bản `0.1.0~native4`; SHA256 `517cc6ccf84716e40b80116834cf1c874e9ae5027584dc94118cc8f6c4f7f244`.

**Bản thử hiện tại:** `0.1.0~native5`, DEB `dist/payload-migration/native5/com.duoface.independent_0.1.0~native5_iphoneos-arm64.deb`, SHA256 **`9b0b45cb4f9f26ae7c16d9aea8366d032e337f262397e253e0078958d5a46a26`** (1730336 bytes). Đã build CI `38724832704` PASS; regression `38725232790` PASS. **Chưa có test trên thiết bị đối với native5.**

## 1. Nhóm tạm vô hiệu hóa trong native5 — chờ bạn thử

- `XXRootViewController.isShowingExpiredModal`: thay thân method trả về false; 16 byte vùng hàm. Mục tiêu tránh trạng thái hết hạn có thể đưa ứng dụng vào hộp thoại không còn dùng.
- `XXRootViewController.setIsShowingExpiredModal:`: thay thân method bằng return; 16 byte vùng hàm. Tránh kích hoạt lại trạng thái modal.
- **26 chỗ chuỗi chỉ dùng cho văn bản hiển thị** (13 mỗi binary `DuoFaceUI` và `DuoFaceDashboard.dylib`): `License Expired`, `License Not Activated`, `License Status`, `DuoFace Pro License`, `SUBSCRIPTION & LICENSE`, `ENTER ACTIVATION CODE (GIFTCODE)`, `License Download Incomplete`, `Activation Failed`, câu Lifetime license và năm câu về gia hạn/kích hoạt. Giữ nguyên độ dài và NUL, thay chữ bằng dấu cách để kiểm thử. **Mới che text, chưa xóa vùng dữ liệu/khóa.**

**Mỗi mục có byte offset, kích thước, SHA256 trước/sau** trong `dist/payload-migration/native5/DANH_SACH_CHO_XOA.json`. Sau test PASS có thể nghiên cứu xóa hẳn các literal nếu xác nhận không còn người gọi và phương thức liên quan, nhưng không thay đổi vị trí dữ liệu tùy tiện.

## 2. Nhóm đã thay phần thân ở native4 nhưng còn metadata

- **248 implementation trong DuoFaceUI và 43 trong DuoFaceDashboard** (tổng **291**, liên quan đăng ký/giấy phép/thời hạn) đã thay bằng stub tương thích ABI và ARM64 NOP trong `native4` và giữ nguyên ở `native5`.
- Vẫn còn tên selector/class trong Objective-C metadata để tránh lỗi gọi động; đây **không còn là code nghiệp vụ gốc của 291 entrypoint**, nhưng không đồng nghĩa các đường license khác đều không còn.
- Sau khi native5 chạy tốt, xóa metadata chỉ khi có sơ đồ tất cả caller/references và có phương án giữ đúng ABI cho các hook. Không xóa class trọn gói khi còn lifecycle/caller.

## 3. Nhóm tuyệt đối không xóa theo tên lớp

- `CBLicenseSyncManager` còn `init`, `sharedInstance`, `.cxx_destruct`, các hàm `isCarPlayScreenConnected`, `isCarPlayScreen:`, `isCarPlayScreenConnectedExcludingScreen:`. **Dù tên lớp chứa “License”, một số chức năng còn là dò màn hình CarPlay**.
- Các `dealloc`, `.cxx_destruct` ở lớp subscription/expired/modal/cell phải bảo toàn vòng đời object khi chưa chứng minh không còn được tạo. Không vô hiệu hóa destructor vì dễ crash.
- Lớp Dashboard và các selector liên quan đến host/chia màn hình, Zoom, native picker luôn giữ nguyên.

## 4. Điều kiện để loại thật trong native6

1. Người dùng xác nhận `native5` mở trên **cả hai iPhone**; chọn và đổi hai ứng dụng trên CarPlay, App/Zoom/Style/Close, khởi động lại, kết nối lại CarPlay đều hoạt động như native4, không xuất hiện màn giấy phép/đăng ký.
2. Dùng `DANH_SACH_CHO_XOA.json` truy các caller để phân biệt literal chỉ hiển thị vs key logic, selector có thể bỏ vs selector vẫn cần ABI. **Loại hẳn phần nào chứng minh không còn tham chiếu và không ảnh hưởng native host**, không xóa ào 291 selector.
3. Native6 phải kiểm tất cả tệp/section, bắt buộc có bản rollback native5/native4, workflow build DEB rootless, hash, Sileo live verify và test trên thiết bị. Không được báo đã xóa sạch nếu còn code/metadata cần giữ.

## 5. Trở về bản đang chạy tốt

`native4` (được người dùng xác nhận hoạt động): `https://github.com/chuongnguyen89dn-ui/Duoface/blob/07cc5ba885c20f4f631126ada74cff185e2b04c7/dist/payload-migration/native4/com.duoface.independent_0.1.0~native4_iphoneos-arm64.deb`.

SHA256 `517cc6ccf84716e40b80116834cf1c874e9ae5027584dc94118cc8f6c4f7f244`. Nếu native5 lỗi, sửa duy nhất pin `com.duoface.independent` trong `chuongnguyen89dn-ui/carplaydsp/.github/workflows/build.yml` về URL/SHA native4, build và kiểm phát hành lại; không tự xóa các gói khác.
