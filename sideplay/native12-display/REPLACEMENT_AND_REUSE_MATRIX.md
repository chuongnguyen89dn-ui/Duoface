# SidePlay → DuoFace Native12 HUD8: ẩn trước, kiểm thử, sau đó mới loại khỏi bản độc lập

**Quy tắc đã xác nhận từ người dùng (18/10/2026):** phần UI nào đưa từ Native12 vào thì phải ẩn phần UI cũ tương ứng của SidePlay ngay trong bản thử. Không giữ hai lớp giao diện cùng thực hiện một chức năng. Hàm SidePlay cần thiết và hoạt động đúng thì tái sử dụng; hàm chưa có/khác Native12 thì viết module DuoFace độc lập hoặc adapter trên host SidePlay. **Chỉ sau khi QA được nghiệm thu thật mới bỏ mã UI cũ khỏi gói DuoFace độc lập cuối cùng**. Không sửa/xoá nhị phân SidePlay gốc trong quá trình QA.

| Nhóm | Phần cũ SidePlay trong bản thử | Phần Native12/HUD8 thay thế | Kết nối giữ lại | Tình trạng |
|---|---|---|---|---|
| Nút nhanh mỗi ô | **Ẩn** `SPPane.chipView`, `SPPane.layoutButton` | Pill đúng bộ khung Native12 | `SPDash.showPickerForPane:` | Đã nối; chưa device PASS |
| Thông báo ô trống | **Ẩn có chọn lọc** label/button ô trống, không ẩn scene/app view | Placeholder Native12 | `SPPane.view`, `SPPane.appViewController` | Đã nối; chưa device PASS |
| Zoom fullscreen mặc định | **Chặn quyền quyết định hình học cũ khi Normal**, không phá scene host | Native12 normal + Zoom In/Out từ menu | `SPDash.setCarWindowFrame:`, `layoutRootView` | Đã thử static; thanh native chưa device PASS |
| Thanh chia giao diện | Không để vạch chia/cử chỉ cũ chồng lên thanh mới | Thanh có logo Native12, logo giữ ≥0,30s vuốt dọc; vạch chia pan đổi tỷ lệ; tap logo swap | `SPDash.setRatio:`, `layout:`, `paneRequestsSwap:` | Bộ khung/đường gọi đã có; 2 app resize chưa device PASS |
| Menu chọn chức năng | Giao diện Native12 phải là menu người dùng nhìn thấy, không giữ menu SidePlay cũ chồng lên | App / Zoom / Style / Close, biểu tượng và cỡ Native12 | App: `showPickerForPane:`; Style: `layoutChooser`; Close: `paneRequestsClose:` | Đã nối các callback; cần kiểm tra Style picker và overlay tương ứng |
| Scene/app hosting | **KHÔNG ẨN/KHÔNG XÓA** | Chỉ thay UI điều khiển bên ngoài | `SPPane.contentView`, `canvasView`, scene lifecycle | Bắt buộc giữ để app hoạt động |

## Hoàn tác trong QA

Mã `sideplay/sileo-qa/Tweak.xm` (QA3 branch) lưu mỗi `UIView.hidden` cũ trong `NSMapTable` weak-key **trước khi ẩn**, ẩn đúng UI trùng và giữ các view ứng dụng. `DFSPRemove` (đóng scene / chuyển window) phục hồi từng trạng thái đã lưu; nếu lần khởi tạo Normal thất bại thì gọi `DFSPRemove` trước khi để UI cũ tiếp tục chạy. Không ghi vĩnh viễn `hidden` vào Preferences hoặc sửa DEB nguyên bản.

**Lưu ý thực thi:** đây mới là khôi phục visibility qua sự kiện do tweak nhận được; chưa chứng minh mọi đường crash/respring đều gọi teardown. Gỡ QA qua Sileo và respring để fallback về SidePlay nguyên bản nếu gặp lỗi. Xác nhận UI Native12 hoạt động thật bằng ảnh/log iPhone X rồi mới đánh dấu bỏ hoàn toàn UI SidePlay cũ khỏi **gói dự án độc lập tự build**, không phải tìm cách xóa các lớp nhị phân proprietary trong SidePlay gốc.

## Thử nghiệm tối thiểu

1. Lúc vừa CarPlay kết nối: thấy bộ khung Native12, không nhìn thấy chip + label ô trống + picker UI SidePlay phủ chồng. Thanh hệ thống hiện.
2. App menu hoạt động, Zoom In/Out đúng; Style, Close đúng chức năng.
3. Kéo thanh chia đổi tỷ lệ thực giữa hai app; giữ kéo logo dịch vị trí nhưng tỷ lệ không đổi; tap swap.
4. Tháo/kết nối lại, đóng scene hoặc gỡ QA: các view UI SidePlay cũ xuất hiện lại với đúng `hidden` gốc.
5. Không SpringBoard crash / exitmode. Ghi log, ảnh và kết quả trên thiết bị để xem xét loại cũ về sau.
