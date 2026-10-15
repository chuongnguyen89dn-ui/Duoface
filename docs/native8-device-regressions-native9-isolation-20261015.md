# DuoFace mới — Native8: kết quả test máy và phương án tách logo khỏi GUI (2026-10-15)

## 1. Bằng chứng và ranh giới xác nhận

Người dùng **đã cài native8 từ Sileo và thử trực tiếp trên CarPlay**:
> “Xác nhận dùng đc. Trượt kéo logo. Nhưng mất đi tính năng chuyển đổi tỷ lệ khung. Và che mất đi nội dung. Ko còn nút phóng to youtube tròn hình. Kiểm tra lại”

Ảnh của người dùng trong cuộc chat cho thấy bố cục CarPlay hai khung: YouTube bên trái, ứng dụng nền xanh bên phải, logo DuoFace đã di chuyển xuống gần dưới vạch ngăn, viền đỏ quanh các khung, cụm điều khiển dạng viên ở đầu hai ô. Ảnh đơn tĩnh **không đủ** để xác định chính xác vì sao nút tròn không vẽ hoặc view đang nhận touch nào. Người dùng mới là nguồn xác thực ba lỗi runtime và thành công kéo logo; **KHÔNG được ghi bản native8 đầy đủ PASS**.

Bản phát hành native8: `com.duoface.independent`, `0.1.0~native8`, SHA256 `c4b5e07f20ca0c819e0e43c8cbbf7e560da961db8c7e74c82a7a4f6fc0274cec`, Sileo `https://chuongnguyen89dn-ui.github.io/carplaydsp/`. CI `38737290575` SUCCESS và Sileo verifier `38738052933` SUCCESS **chỉ xác nhận build/package**. Cần ưu tiên lỗi thật từ người dùng.

## 2. Nguyên nhân tầng mã: phần chắc chắn và giả thuyết kiểm thử

### 2.1 Không phải thay hàm chia trong Dashboard binary

`audit/payload-migration/NATIVE8_COMBINED_REGRESSION.json` xác minh `DuoFaceUI` và `DuoFaceDashboard.dylib` chỉ sửa chuỗi `__cstring`, giữ nguyên code `__text`, selector và vòng đời. `CBBridgedSplitApp.handleDividerPan:isVertical:state:` vẫn là hàm đổi `splitRatio`. Vì vậy hồi quy cử chỉ xuất hiện sau khi thay thư viện hook/đường chuyển sự kiện, **không phải do đổi công thức native splitRatio**.

### 2.2 Chặn nhầm gesture pan là một lỗi kiến trúc trong native8

Mã native8 `src/DFDividerLogoGrip.inc` cài `MSHookMessageEx(CBDividerView, handlePan:)` chuyển đến `DFLogoDividerPan`. Trên `UIGestureRecognizerStateBegan`, nó đánh dấu `dividerPanOwned` nếu `logoTouchActive && pressed` và sau đó bỏ qua **toàn bộ** `handlePan:` của native, bao gồm các state Began/Changed/Ended khi flag còn bật. `DFLogoGripCancel` không reset `logoTouchActive` và `pressed`, nên có rủi ro cờ chạm cũ kéo sang touch mới hoặc bỏ chuỗi native pan dù chạm bên ngoài logo. Đây là lỗ hổng được xác định ngay trong mã; **chưa có log thực tế chứng minh đúng trình tự cờ** trên máy người dùng, nhưng nó đủ để không tiếp tục intercept divider pan.

Cơ chế cũ đã tìm trong binary native6: `CBDividerView.initWithFrame:isVertical:` gắn native pan, `handlePan:` IMP `0x10152c` -> `onPanChanged` -> `CBBridgedSplitApp.handleDividerPan:isVertical:state:` IMP `0x103ee0`; `CBDividerView` UIButton gắn longpress riêng; `hitTest:withEvent:` trả đúng UIButton theo frame. Người dùng trước đó quan sát giữ/kéo **trên** logo không resize, còn pan đường chia bên ngoài dùng để resize. Vì vậy **không hook `handlePan:` nữa** là lựa chọn có căn cứ, trả nguyên trạng mọi state native.

### 2.3 Nút YouTube/che nội dung: native8 thay toàn bộ visual hook

`dist/payload-migration/native8/BAO_CAO.json` xác minh **native6 original VisualHook SHA256 `4ebf68b630c102dee1bbaac87dcadddd3e13f618331cacd9c47ae1a27437959d`**, native8 signed rebuilt VisualHook SHA256 `f879eb8fd619ab8c7d2abd7c09bc36890cb0426ec5e0aca8f6c2a3c0fc3fce37`. Ngoài cử chỉ 0,30s, source mới đã #include `DuoFaceBorderRunner.m`, hook `UIButton.setBackgroundColor:`, `CALayer.setBorderWidth:`, `CALayer.setBorderColor:`, và vẽ `CBSlotPillView` `_expandButton/_restoreButton`. Như vậy native8 đã thay **cả cơ chế styling/suppression** thay vì chỉ thêm logo. `DuoFaceBorderRunner` được thêm vào source sau bản visual trước đó; đây là thay đổi phạm vi thừa, có khả năng che/đè nội dung hoặc icon. Nhưng từ screenshot chưa thể chứng minh nó là nguyên nhân riêng của nút YouTube.

**Cách xử lý không đoán style**: trả nguyên file `DuoFaceVisualHook.dylib` của native6, kể cả nút tròn/bitmap/hooks theo bản đang ổn định, bằng kiểm SHA256 từng byte. Không tự thêm/sửa icon, border, menu, xử lý YouTube, hoặc các vùng content/frame khi chưa có phân tích riêng.

## 3. Mã nguồn thử mới: tách logo thành một dylib độc lập

- `src/DFDividerLogoGrip.inc` commit `72d5d4ca01c1ad3e6fc057aec1e325d47a22edb3`: guard `DF_LOGO_PRESERVE_NATIVE_DIVIDER_PAN` để **không đăng ký/không compile** `handlePan:` wrapper trong thành phần cô lập. Giữ nguyên đường `UIButton moveButtonTouchDown/Up/Cancelled`, longpress, ngưỡng `0.30`, `CBDividerButtonInfo.relativePos` / `updateGripLayout` đã được người dùng xác nhận chạy.
- `src/DuoFaceLogoGripOnly.m` commit `74a1bcca484c58f674da5c323be7f0898ff9dfc3`: dylib mới **chỉ hook layout của `CBDividerView` và những callback nút logo**, #define `DF_LOGO_PRESERVE_NATIVE_DIVIDER_PAN 1`. Chờ native UI visual hook v12/native6 hoàn tất layout rồi restore vị trí logo và chỉnh recognizer duration. Không thay bất kỳ fullscreen/picker/border/font/image/overlay; không cài pan wrapper; không cần thêm asset.
- `scripts/check_duoface_native9_isolation.py` commit `7e66e08541e68ca4c830caf1999937d4b00e2583`: QA hồi quy 16 tiêu chí tĩnh, chặn lại thư viện visual mới hoặc intercept pan.
- `.github/workflows/duoface-native9-logo-isolation-source-only.yml` commit `d5aece1681783e3ffc6ec5f81b323d482aedabe1`: iOS arm64 Clang `-fno-objc-arc -fblocks -Wall -Wextra -Werror` syntax + dylib build thử **không DEB, không Sileo**, kiểm `lipo`, `otool`, không có `DFLogoDividerPan` trong module.
- **ĐÃ TEST ĐỘC LẬP** GitHub Actions run **`38746174099`**, job **`116460290014`** completed **SUCCESS** toàn bộ steps. Bot commit audit **`9ca755eb95b4749e2fdd7aa6c0f8dc932cc50928`**, report `audit/native9/LOGO_ISOLATION_SOURCE_ONLY.json`, blob **`35fb1385d6818b2f8f5106709f8c6136a0212788`**, status **`SOURCE_ONLY_NATIVE9_LOGO_ISOLATION_ROUTE_PASS`**, 16/16 assertions tĩnh PASS. Đây **không** phải thiết bị PASS, không chứng minh native6 visual button sẽ tự hiện trở lại trên CarPlay.

## 4. Đúng bước kế nếu được yêu cầu tạo thử native9

1. Không dùng native8 rebuilt `DuoFaceVisualHook.dylib`. Baseline **native6 rootless DEB** SHA256 `88b0e9358c075e2131ddb9e6ac25689584765d1285120e2e3282ce8a5bb3df15` và pin SHA của original VisualHook như trên.
2. Tạo **version mới** (ví dụ `0.1.0~native9`), không ghi đè native8/native6. Cùng danh mục 39 visible license labels × 2 binaries = 78 locations, giữ nguyên tất cả code/ObjC metadata. Thêm duy nhất **`DuoFaceLogoGripOnly.dylib` + `DuoFaceLogoGripOnly.plist`** với filter tương đương chính xác original `DuoFaceVisualHook.plist` (đọc từ native6 trước khi viết); không chép nội dung filter theo dự đoán.
3. Đo byte diff: `DuoFaceVisualHook.dylib` và plist phải byte-identical native6, không thay các artwork, host, containers, borders, menu, original video controls; chỉ cho phép 2 binary __cstring data + 2 file addon + DEBIAN control/md5. Kiểm new arm64, entitlements, `dpkg-deb` metadata, id `com.duoface.independent`, checksum, SHA.
4. Nếu user đồng ý phát hành, **CI hoàn chỉnh PASS rồi mới thay đúng block package** trong repo Sileo `carplaydsp/main`, public index/DEB verifier mới, giữ native8/native6 rollback GitHub.
5. **Thiết bị mới là kết quả quyết định**: drag divider ngoài logo đổi tỷ lệ, logo giữ ≥0,3s kéo dọc không resize/swap, nút tròn YouTube xuất hiện và bấm phóng to/thu nhỏ bình thường, chữ/video không bị overlay ngoài ý muốn, swap tap, reconnect/rotation, Zoom/Style/Close, 39 label license vẫn ẩn. Nếu vẫn lỗi visual, cần lấy ảnh hoặc runtime trace tại view target; không kết luận do bạn thao tác sai.

## 5. Trạng thái lúc kết thúc nghiên cứu

- Source-only addon compile + 16 static assertions PASS; **CHƯA build DEB native9**, **CHƯA cập nhật Sileo**. Bản live vẫn native8 còn hồi quy; không báo đã fix trên máy.
- Mục tiêu của lượt này: **“Kiểm tra lại”** ba lỗi, không phải lệnh phát hành phiên bản ngay. Đợi yêu cầu hoặc quyết định bước đóng DEB trước khi tạo bản cài mới.
