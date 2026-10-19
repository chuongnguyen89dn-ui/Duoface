# QA10 — sửa lớp chia SidePlay còn sót, giao diện chọn app, tỷ lệ chia ô và chẩn đoán CarPlay bar

**Mốc:** 2026-10-19 ICT. **Chỉ sửa mã nguồn, KHÔNG build DEB và KHÔNG cập nhật Sileo** theo chỉ đạo mới của user.

## Yêu cầu và quan sát ảnh người dùng

- Ảnh người dùng `IMG_1F90E815-73E0-41E5-B23B-92504CB278D9.jpeg` (gắn với cuộc trò chuyện, không copy ảnh có danh sách app cá nhân vào repo) cho thấy màn hình SidePlay **“Chọn app cho ô 1”** đang mở nhưng **hai nút pill/logo và đường chia xuyên qua nền app chooser** vẫn lộ; nút/logo có nền đen không giống DuoFace. User xác nhận **đường chia nhìn thấy thuộc SidePlay cũ**, không phải đúng thanh DuoFace, nên cần ưu tiên gỡ phần cũ thay thế thay vì ghép chồng.
- User bổ sung **kéo chia tỷ lệ chưa ổn định**, yêu cầu xem có xung đột cử chỉ/relayout SidePlay. User xác nhận **thanh bar CarPlay vẫn chưa xuất hiện**; không suy luận từ static code rằng nó đã được sửa.
- Không thay QA9 Sileo đang pin, không chạy build DEB, không sửa Native12/HUD8 hoặc SidePlay 1.0.4 gốc.

## Đối chiếu thực với DEB SidePlay 1.0.4 (read-only)

- Đã giải nén gói `com.sideplay 1.0.4-1` SHA256 `7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c` từ bản ZIP evidence đã lưu ở đợt kiểm toán, bằng `dpkg-deb -x`. Không chạy package maintainer scripts; **không sửa nhị phân vendor**.
- Lệnh máy phân tích: `/usr/local/swift/usr/bin/llvm-objdump --macho -d /mnt/data/qa10-sideplay-audit/sideplay/var/jb/Library/MobileSubstrate/DynamicLibraries/SidePlay.dylib` (stdout tạm `/mnt/data/qa10-sideplay-audit/SidePlay.arm64.disasm`). `SPDash.setRatio:` tại VM 0x2737c là `str d0, [x0, #0xb8]`; 0x27380 là `ret`. Đây chỉ là setter của ratio, **không layout app scene**. `SPDash.layout:` bắt đầu 0x23624; disasm thấy gọi `rootView`, `areaView`, `pickerView` và cập nhật các frame — xác nhận quản lý UI của SidePlay trong mỗi relayout. Không coi đây là full functional reverse-engineering.
- ABI được đối chiếu từ `sideplay/audit/qa7-vs-native12-methods-20261018/method-index.json`: `showPickerForPane:` `v24@0:8@16`, `dismissPicker` `v16@0:8`, `pickerAppTapped:` `v24@0:8@16`, `layoutChooser` `v16@0:8`, `revealChosenLayout:` `v20@0:8B16`, `pickerView` `@16@0:8`, `showingChooser` `B16@0:8`, `setRatio:` `v24@0:8d16`, `layout:` `v20@0:8B16`.
- Trước QA10, QA9 gọi `[manager setRatio:ratio]; [manager layout:ended];`. Biến `ended` là trạng thái gesture nhưng tham số thứ nhất của `SPDash.layout:` là cờ BOOL **animated**. Khi thả tay `ended=YES` vô tình bật một đợt animation sau drag. Đã sửa thành **`[manager layout:NO]`** liên tục, để việc kéo không có cú nhảy cuối.
- Chuỗi renderer cũ có thể tạo viền/đường chia bằng view/layer: metadata ObjC không cung cấp class view thực trên màn hình người dùng. Vì vậy bộ lọc ẩn đường SidePlay **có điều kiện và an toàn**, chưa chứng minh đã chặn mọi hình thức vẽ cũ nếu nó được render trực tiếp bằng layer trong pane.

## Mã đã sửa trên nhánh riêng QA10 (source-only)

**Nhánh:** `feature/duoface-qa10-picker-divider-source-only`, tạo từ `feature/duoface-qa9-chrome-divider-recovery` (QA7-backed).

1. `sideplay/native12-display/DFSPNativeFrame.m`
   - Xóa **`dividerLine` màu trắng mờ 1pt** do lớp QA tự vẽ; giữ `dividerTrack` **trong suốt và vẫn bắt drag**.
   - Loại `logo.backgroundColor colorWithWhite:0.17 alpha:0.96`; chuyển logo nền trong suốt, không shadow/border. Không sao chép ảnh nguồn ngoài DuoFace.
   - Bỏ `logoPan` thứ hai (cạnh tranh `dividerPan`); **tap logo hoán đổi**, **nhấn giữ 0.30s di chuyển logo**, **kéo track thay tỷ lệ**.
   - `dragDivider:` đóng băng toàn bộ `splitPanInitialUnion`, `splitPanInitialTouch`, `splitPanInitialRatio`, axis và pane order ở `Began`; tỷ lệ từ **delta** tới vị trí bắt đầu, không lấy điểm tuyệt đối theo khung thay đổi sau mỗi `SPDash.layout:`. Đảo dấu khi pane0 ở phải/dưới, chỉ cập nhật khi đổi >=0.003; hủy gesture hoàn về tỷ lệ cũ; đảm bảo giải phóng `splitPanActive` sau Ended/Cancelled/focus/modal.
   - Khi picker QA tự mở, ẩn pill/track/logo suốt quá trình layout.
2. `sideplay/sileo-qa/Tweak.xm`
   - Hook **đúng chữ ký ABI SidePlay** `showPickerForPane:`, `dismissPicker`, `pickerAppTapped:`, `layoutChooser`, `revealChosenLayout:(BOOL)`. Khi bảng chọn SidePlay mở, đặt `DFSPLegacyModalOpen`, **ẩn và vô hiệu hóa hit-testing của toàn bộ DFSPUI**, ngừng `bringSubviewToFront` trên picker. Khi đóng qua dismiss, chọn app, chọn Style hoặc callback layout gián tiếp, khôi phục overlay.
   - `DFSPHideLegacySplitStrips` dò view SidePlay trong `rootView` và tối đa 4 cấp `areaView`, 256 nodes; chỉ ẩn decor leaf mỏng 1–4pt ngay đúng boundary đã xác định từ **hai SPPane thực**. Không ẩn/patrol pane scene, app content, control, UIScrollView hoặc UIView có gesture recognizer; các view ẩn có snapshot để rollback disconnect. Không dùng xóa view vendor/đóng scene.
   - Giữ SidePlay `window.windowLevel` nguyên gốc `DFSPOriginalLevel` trong Normal/Zoom, thay vì **QA9 `UIWindowLevelStatusBar-1`** (có nguy cơ chồng lên dock CarPlay nằm ở cửa sổ mức thấp hơn). Cơ chế chrome IPC QA9 giữ nguyên, chưa có device ACK mới.
   - Chẩn đoán trên lần thả tay: log `QA10 SidePlay ratio drift requested/accepted/afterLayout/split` nếu host trả tỷ lệ chênh. `SPDash` tiếp tục là scene owner, không thay actual scene frame hoặc license code.

## Kiểm thử và giới hạn thực tế

- **Đã chạy 21/21 cổng kiểm tra tĩnh trực tiếp trên source trả về bởi GitHub connector**, gồm state modal, selector ABI, loại bỏ line/logo dark disk, safe strip filter, freeze drag/đảo pane, cancel, no end-animation, giữ window original level, rollback và toán ratio cho 800pt. Các lần kiểm trước 14/14 và 17/17 cũng qua; báo cáo 21/21 mới nhất.
- File test có thể chạy lại: `python3 sideplay/native12-display/validation/check_qa10_picker_divider.py`. Workflow **chỉ kiểm thử nguồn, không build**: `.github/workflows/sideplay-qa10-source-tests.yml` (branch QA10). **Chưa xác nhận Actions run/job thành công**: `fetch_commit_workflow_runs` hiện trả `workflow_runs=[]`; không nhận workflow created là test đã chạy.
- **Chưa build DEB, chưa có artifact QA10, chưa cập nhật Sileo QA10, chưa cài/khởi động ứng dụng hay CarPlay thực, chưa có ảnh/logo kiểm chứng sau sửa.** `com.duoface.sideplaydisplay` trong `control` vẫn version **QA9 `0.1.7~native12chrome9`**, Sileo `carplaydsp:main:.github/workflows/build.yml` vẫn pin QA9 commit `f99aba274febda46e21f2fa9249a94ed86f50363`, hash `ab5dba7165d5a860d93a1047c5ca95f17540b560edc4b371521bcbcc833e3346`.
- Với **thanh bar CarPlay**, thay đổi chắc chắn là không nâng `windowLevel` của SidePlay lên sát status bar; **không thể khẳng định CarPlay dock/Sidebar hiện lại**, vì chưa đo `SPDash.carDockMode`, `carDockArea` và class/level/status UIWindow thực trên iPhone. QA9 `DFSPChromeBridge` mới xử lý hidden của `DBStatusBarWindow/CARStatusBarWindow`, chưa chứng minh nó là đúng Sidebar mà user yêu cầu.

## Tiếp nối không được làm lại từ đầu

1. **Không build/deploy khi user chưa cho phép**. Kiểm tra lại code, bản handoff và test-only workflow QA10; nếu workflow chưa chạy, kết quả 21/21 mới là static JS checker chứ chưa phải CI hay compile.
2. Khi user cho phép build: đổi version QA10 thành 0.1.8 (hoặc mới hơn), copy workflow Theos QA9 sang branch QA10 nhưng giữ không thay gói ổn định; build, verify DEB/sha, rồi mới chuyển Sileo theo yêu cầu.
3. **Test thực tế khi xe đỗ:** chụp cả trạng thái không mở picker, mở picker, đóng, hoán đổi 2 ô, kéo ratio nhiều lần, kéo logo hold 0.30s. Thu log `DuoFaceSidePlayDisplayQA.log` + syslog `[DuoFaceQA9Chrome]` (không lấy thông tin cá nhân). Phân biệt decor SidePlay được hide có marker `QA10 hidden SidePlay decorative split strip`; nếu không có marker mà còn line, cần nghiên cứu layer thật (không gỡ bừa `SPDash.areaView`).
4. Nếu vẫn thiếu thanh CarPlay, dựa `SPDash carDockMode/carDockArea/carWindowFrameNow`, thực tế z-order/Owner của CarPlay/Dashboard, không tiếp tục đoán/đổi 64pt. Ưu tiên sửa bar trước khi gọi DuoFace full parity.
