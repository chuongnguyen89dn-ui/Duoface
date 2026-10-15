# DuoFace Mới — vị trí logo trên vạch chia và khả năng kéo lên/xuống

Ngày phân tích: **15/10/2026**. Trạng thái: **đã xác minh tĩnh từ binary hiện hành, chưa triển khai thao tác kéo logo / chưa test CarPlay thiết bị**.

> **Lệnh người dùng:** NGỪNG build/package/export DEB, không phát hành Sileo cho đến khi người dùng yêu cầu rõ. Chỉ phân tích và chuẩn bị source/compile-only khi an toàn. Đây là nghiên cứu CHỈ ĐỌC trên DEB native6 đã có từ trước, tuyệt đối không phải bản DEB mới.

## 1. ĐÚNG điều khiển, không phải splash hay menu

Nút tròn giữa hai ô mang logo DuoFace: `CBDividerView` → ivar `_moveButtons` → native `UIButton` với overlay `VisualAssets/duoface-swap.png`. Code hiện có: `src/DuoFaceVisualHook.m`, hàm `DFDividerLayout` gọi **original** `layoutSubviews`, lấy `_moveButtons` và gọi `DFApplyButton` để thay **hình ảnh**, giữ native touch/long-press/pan/auto-hide. Đây KHÔNG phải splash `duoface-logo.png` hoặc logo ngang ở menu.

Gốc kỹ thuật tra cứu (CHỈ ĐỌC): `tiep tuc du an.md` các checkpoint **11/10/2026**, đặc biệt phân tích `CBDividerView initWithFrame:isVertical:`, `configureWithButtonConfigs:`, `updateGripLayout`; không dùng file cũ làm đầu mối bàn giao DuoFace Mới.

## 2. Xác minh lần này bằng binary DuoFace Mới đang lưu trong repo

Nguồn: **DEB đã tồn tại** `dist/payload-migration/native6/com.duoface.independent_0.1.0~native6_iphoneos-arm64.deb`, pinned SHA256 `88b0e9358c075e2131ddb9e6ac25689584765d1285120e2e3282ce8a5bb3df15`. Chỉ giải nén bằng `dpkg-deb -x`, không đóng DEB.

- Script READ-ONLY: `scripts/audit_duoface_divider_mobility.py`
- GitHub Actions run **38731604460**, job **116410470656**, **completed SUCCESS**; workflow `.github/workflows/duoface-divider-mobility-audit.yml` không có bước build DEB, signing hay Sileo.
- Report trên feature: `audit/divider/GRIP_MOBILITY_NATIVE6.json`, blob `a5e54c0de238c1e7401ab3cf4db266d774e62d36`.
- Bằng chứng ARM64: `audit/divider/GRIP_MOBILITY_NATIVE6_ARM64.txt`, blob `2dd90f64d313eb99e800c79a519764004d99350a`.
- SHA256 nhị phân hiện tại `DuoFaceDashboard.dylib` giải nén: `6278cf23ddd78026a67b95de704331d5143dac5e43b97eb25cf3c98f10228788`.
- ObjC metadata: `CBDividerView` chứa `_isVertical` offset 8, `_moveButtons` offset 16, `_buttonConfigs` offset 24, `_onPanChanged` offset 32, `_onActivity` offset 40.
- `CBDividerButtonInfo` có `_relativePos` offset **16**, getter `relativePos` **0xfe768** (`ldr d0,[x0,#0x10]`), setter `setRelativePos:` **0xfe770** (`str d0,[x0,#0x10]`). **Giá trị vị trí có thể thay đổi** khi cập nhật field thông qua selector gốc.
- `CBDividerView initWithFrame:isVertical:` IMP **0xfe7dc**: tại **0xfe950** `fmov d0,#0.5`, **0xfe958** gửi setter vào cấu hình mới; **giá trị mặc định 50%** chiều dài divider.
- `CBDividerView updateGripLayout` IMP **0xff460** đọc danh sách button/config và giá trị `relativePos` (kiểm tra giá trị nằm trong khoảng **0..1**, ngoài khoảng sẽ về giữa 0.5), dùng orientation/bounds và đưa nút vào frame qua ObjC `setFrame:` tại **0xff6c0**. Nút vuông **30×30 pt**, đổi **28×28 pt** khi chiều tham chiếu nhỏ hơn threshold; có mép an toàn khoảng **4 pt** trong logic clamp vị trí.
- `CBDividerView gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:` IMP **0xfea48**: `mov w0,#1; ret` → **cho phép gesture đồng thời**. Đây là cảnh báo khi thiết kế long-press drag.
- `CBDividerView handleMoveButtonLongPress:` IMP **0x1005f4**: đọc state rồi **chỉ thực hiện nhánh xử lý khi state == 1** tại **0x10062c–0x100630**; các state khác rẽ đến cuối hàm. Điều này **không chứng minh chức năng kéo liên tục lên/xuống đã có sẵn**. Long-press hiện tại có thể phục vụ hoạt ảnh / callback, không được xóa.
- `CBBridgedSplitApp handleDividerPan:isVertical:state:` IMP **0x103ee0** điều khiển **kéo đổi tỷ lệ hai ô**, khác với vị trí của icon. Phải giữ nguyên callback và splitRatio setter.

## 3. Kết luận kỹ thuật và phương án

**CÓ THỂ** cho logo trượt lên/xuống mà KHÔNG di chuyển toàn bộ divider, bằng cách điều chỉnh **`CBDividerButtonInfo.relativePos`**, gọi `updateGripLayout` (hoặc layout gốc) để chính UIKit tính frame/hit-test cho native UIButton. Không nên chỉ dịch UIImageView bên trong nút, vì sẽ tạo vùng hiển thị khác vùng chạm, dễ che chi tiết hay nhấn nhầm.

**Chưa thể khẳng định người dùng đã có thể kéo bằng bản native6**: native default đặt 0.5, handler long-press chỉ xử lý state == began; báo cáo chưa tìm được đường native cập nhật relativePos theo `Changed` của long-press. Cần bổ sung một **gesture mode di chuyển icon** nếu muốn thao tác thực tế.

Thiết kế an toàn đề nghị khi triển khai source (chưa áp dụng):
1. **Chạm ngắn** lên logo giữ nguyên hành vi native swap/đổi ô. Không sửa `moveButtonTouchUp:` hay `handleDividerSwapPressed:`.
2. **Kéo divider** theo trục điều chỉnh tỷ lệ ô tiếp tục gọi native `handleDividerPan:isVertical:state:`; không override logic ratio/min/max.
3. **Giữ logo rồi kéo dọc đường chia**: nhận `UIGestureRecognizerStateChanged` và tọa độ trong `CBDividerView`, tính `relativePos` = (tọa độ trục dọc - nửa kích thước nút) / (chiều dài trục - kích thước nút), clamp theo frame+4pt margin đã có, cập nhật đúng đối tượng `_buttonConfigs[index]` tương ứng `_moveButtons[index]`, gọi `updateGripLayout`. Nếu divider nằm ngang, xử lý dọc/trục chuyển theo orientation thật thay vì giả định cố định.
4. **Không để recognizer resize hoạt động cùng lúc khi ở chế độ giữ-kéo logo**: native `gestureRecognizer:shouldRecognizeSimultaneously...` hiện return YES. Phải chứng minh/tách được luồng touch khỏi `onPanChanged`; nếu chưa chặn được xung đột thì KHÔNG bật tính năng này.
5. Bảo toàn trạng thái blink/idle, layout sau xoay, focus/restore, vùng bấm, nhiều button, auto-hide. Nếu cấu hình `_buttonConfigs` tái tạo về 0.5 thì cần giữ offset ở scope hợp lý, không ghi vào bộ nhớ ngoài ABI.
6. Chạy test code-level/compile-only trước; thử thật CarPlay khi user yêu cầu DEB: logo lên/xuống, click swap, kéo tỷ lệ, mở hai app, xoay/ngắt-nối, Zoom/Style/menu; rollback native6.

**Không thực hiện:** thay `CBBridgedSplitApp` split ratio, di chuyển toàn bộ vạch divider, hook ảnh chồng không chuyển hit box, xóa longpress gốc, build DEB, Sileo publish.

## 4. Checkpoint tiếp theo

Đã đủ bằng chứng vị trí và khả năng điều chỉnh vị trí. Bước kế là tạo bản **mã nguồn thử nghiệm có cờ mặc định TẮT**, không tích hợp package hoặc khởi chạy workflow đóng DEB; giải quyết tranh chấp gesture/native pan trước khi đề nghị người dùng nghiệm thu. Không tự tuyên bố kéo logo đang hoạt động trên thiết bị.
