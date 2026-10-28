# 28/10/2026 — Đã giải mã thân hàm của 36 hook thực từ DEB Native12 gốc

## Đầu vào và mức độ chứng cứ
- DEB gốc **Native12 HUD8** từ commit `1286a3ef868cf7e29804bcddf7e20b2eae707ce1`, SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`.
- Thư viện gốc trong DEB `DuoFaceDashboard.dylib`, SHA256 `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`; method index gốc blob `efa45df59bc3c16887cc979bf3aedc0c93c92111`.
- Dùng địa chỉ `adr x2` tại mỗi lệnh cài `_MSHookMessageEx` để tìm **callback thật**; đối chiếu với `LC_FUNCTION_STARTS` và lấy toàn bộ lệnh ARM64 của callback từ chính binary gốc. Đã giải mã cả **36/36 callback** (không chỉ tìm selector/string).
- Log nguồn công khai trong repo `NATIVE12_ORIGINAL_36_HOOK_CALLBACKS_RUN_40666734377.json`, Actions `40666734377` PASS. Bổ sung các getter biến trạng thái `bridge_active/desired_orientation/logical_size/display_width_policy` trong `NATIVE12_ORIGINAL_36_HOOK_CALLBACKS_RUN_40666944716.json`, Actions `40666944716` PASS (lưu ý nhãn `is_split` trong JSON cũ này **sai**: địa chỉ 0x2a80b4 thực tế là *logical-size setter*, đã sửa ở script tiếp theo; không dùng như bằng chứng về split getter). Phiên bản mới có getter được đặt tên chính xác sẽ có run ID tiếp theo.
- Bản .89 `0.0.89~splitscene1` đã phát hành Sileo và **USER DEVICE FAIL** vì vẫn sai hướng YouTube chia hai ô. Không được gọi .89 là sửa thành công.

## Cách hoạt động cụ thể trong mã máy gốc — ĐÃ XÁC MINH

| Thành phần original | Callback thật | Nội dung có chứng cứ bằng ARM64 |
|---|---|---|
| `UIViewController.supportedInterfaceOrientations` | `0x2acc04` | Khi bridge-active, đọc hướng gốc yêu cầu, trả về `1 << max(orientation,1)` (Portrait=1 => mask=2). Khi không bridge, nhảy về IMP UIKit gốc |
| `UIViewController.__supportedInterfaceOrientations` | `0x2acc60` | **Cùng logic riêng biệt**, getter bridge tại `0x2acc74`, `1 << max(orientation,1)` tại `0x2acc8c`; khi không bridge, trả về IMP gốc tại `0x2acca0` |
| `UIWindowScene.interfaceOrientation` | `0x2ad7f0` | Khi bridge, trả về `max(requestedOrientation,1)` tại `0x2ad80c–0x2ad820`; khi không bridge, nhảy IMP gốc `0x2ad824–0x2ad83c` |
| `UIDevice.orientation` | `0x2ad8d0` | **Tương tự UIWindowScene**: bridge check `0x2ad8e4`, getter orientation `0x2ad8ec`, trả `max(orientation,1)`; ngoài bridge trả IMP gốc |
| `UIWindow._rotateWindowToOrientation:...:` | `0x2acfd8` | **Chặn ngay mỗi lần UIKit yêu cầu xoay**: nếu bridge-active tại `0x2ad008`, thay tham số hướng bằng hướng bridge tại `0x2ad010–0x2ad018`, rồi chuyển tiếp saved original IMP tại `0x2ad020–0x2ad050` |
| `UIWindow.setFrame:` và `setBounds:` | `0x2accbc`, `0x2acdd8` | Intercept các thay đổi khung hình tiếp theo. Có điều kiện bridge-active, kích thước hợp lệ, `UIWindowLevelNormal`, lọc cửa sổ trước khi chuyển tiếp saved IMP |
| `UIScreen.bounds` | `0x2ada20` | Khi bridge, **chỉ** cân nhắc `UIScreen.mainScreen` và kích thước policy `0x2a84a0` > 50. Phần trả về khung hình dùng cả policy chiều rộng và logical size; không áp dụng tùy tiện cho mọi màn hình. Ngoài điều kiện trên trả lại IMP gốc |
| `UIScreen.nativeBounds` | `0x2adaec` | Cùng điều kiện nhưng còn đọc `scale` và nhân kích thước logic thành pixel; có nhánh IMP gốc |
| `UIScreen._referenceBounds` | `0x2adbfc` | Cùng cơ chế điều kiện và kích thước logic, có nhánh IMP gốc |
| `UIWindowScene._isSuspended` và `_isDeactivated` | `0x2ad840`, `0x2ad888` | Trong bridge trả `NO` (không suspended/deactivated), ngoài bridge chuyển về IMP gốc |
| `CBAppStateListener` (ứng dụng) | `0x2abd98 → BL 0x2a9e38` | Khi nhận state do Host phát, cập nhật trạng thái rồi gọi bộ reflow cửa sổ. Đây là luồng áp dụng **cùng state**, không phải chỉ refresh window một lần |

**Getter xác minh trực tiếp từ binary**:
- `0x2a8068`: `ldrb w0` từ biến trạng thái bridge ở bộ nhớ tĩnh, trả `BOOL`.
- `0x2a8080`: tải hướng được yêu cầu từ biến process-local.
- `0x2a8098`: trả hai giá trị `double` kích thước logical.
- `0x2a84a0`: helper policy lớn (407 lệnh), khi bridge-active và logical width > 50 thì lấy logical width; ngoài nhánh đó truy vết `UIApplication.keyWindow`, cửa sổ bình thường và các kích thước hiển thị. Điều này **không tương đương** lấy khung hai ô rồi nhân một tỷ lệ tùy ý.

## Điểm thiếu kỹ thuật của DuoFace .89 được chứng minh
- App relay .89 chỉ dùng owner-scoped notification, `isSplit`, phép chỉnh `UIWindow` tạm thời và một lệnh `requestGeometryUpdateWithPreferences`. **Không có** chặn trả lời orientation mà YouTube đọc qua `UIViewController`, `UIWindowScene`, `UIDevice` hay chặn lần xoay đến sau từ `UIWindow._rotateWindowToOrientation`.
- App relay .89 cũng không mô phỏng nhất quán `UIScreen.bounds/nativeBounds/_referenceBounds` mà chính app phát video có thể đọc trong các bước thay đổi giao diện.
- Vì thế cách làm .89 chưa giống luồng thật của Native12. Đây là **chênh lệch chức năng đã xác minh**, không phải khẳng định hook nào gây sai pixel. Chưa có .89 SceneHost log mới hoặc video telemetry xác nhận nguyên nhân runtime.

## Quyết định thực hiện tiếp
1. Giữ nguyên .83 video lifecycle, Maps, Dock và các DEB rollback. **Không** sửa code hay phát hành .90 chỉ dựa trên suy đoán.
2. Giải mã sâu các nhánh kích thước, loại cửa sổ và teardown/restore của original; đối chiếu 2 hướng ứng dụng thấy từ `UIViewController` và `UIWindowScene`, với real .89 log khi có.
3. Viết cơ chế **độc lập, chỉ giới hạn YouTube**, có kiểm điều kiện bridge/scene, trả về UIKit gốc khi không active, và đo các sự kiện thật khi YouTube phát video; kiểm thử trên xe trước khi kết luận.
4. Đạt yêu cầu khi YouTube trong **hai ô ngay từ đầu** không cần SOLO hoặc vuốt xuống mà hiển thị đúng, không crash, không thay đổi Maps/Dock.

Không copy mã nhị phân, giấy phép, hoặc source của nhà sản xuất. Báo cáo là diễn giải điều khiển từ mã máy nhằm thiết kế một triển khai riêng.
