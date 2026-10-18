# DuoFace QA8 — bắt lại CarPlay window sau khi SidePlay nạp trễ (2026-10-18)

## Vì sao phải sửa sau QA7

Ảnh thật do user gửi `IMG_6129F0FC-044F-4AD0-8C4A-9C236DA1E383.jpeg` cho thấy SidePlay headers/panes không bị thay, không có DuoFace native pill/track; **visual DEVICE FAIL**. Không có log máy để chứng minh một nguyên nhân duy nhất.

**Nguồn được đọc:** `sideplay/tiep tuc du an.md` và hồ sơ Native12, QA7 `sideplay/sileo-qa/Tweak.xm` và `sideplay/sileo-qa/DuoFaceSidePlayDisplayQA.plist`, original SidePlay selector audit `sideplay/native12-display/audit/SIDEPLAY_SPLIT_OWNER_SELECTORS.json`, GitHub Sileo source `carplaydsp/.github/workflows/build.yml`.

Bằng chứng source QA7 có hai cơ chế có thể bỏ lỡ giao diện:
1. `DFSPTryInit` chỉ kiểm `objc_getClass("SPDash")` 30 lần, cách 1s rồi **dừng hẳn**. Nếu SidePlay nạp class sau 30s khi kết nối CarPlay, hook không cài, dù QA7 DEB/Sileo PASS.
2. Chỉ `%hook SPDash -setCarWindow:` gọi `DFSPInstall`; nếu event đã xảy ra trước `%init`, QA7 không bắt lại `carWindow` hiện hữu khi `layout:` / `layoutRootView` sau đó chạy.

Hai cơ chế này là **lỗ hổng source-verified, chưa chứng minh là nhánh đã xảy ra trong ảnh**. Cũng có thể hook cài đúng nhưng kiểm `DFSPExternal`, owner/window layering, hoặc dylib không inject; chỉ runtime log mới phân biệt được.

## Thay đổi QA8 trên branch riêng

Repo `chuongnguyen89dn-ui/Duoface`, `feature/duoface-native12-qa8-late-host-bootstrap`.
- `sideplay/sileo-qa/Tweak.xm`: giữ `SPDash` lazy poll 5s cho tới khi class sẵn sàng (thay timeout 30s), chỉ `%init` một lần; không sửa vendor dylib.
- Dùng `SPDash.carWindow` (getter tồn tại theo audit original 1.0.4) trong `SPDash.layout:` **và** `SPDash.layoutRootView`; nếu cửa sổ chưa có DuoFace UI, lên lịch duy nhất `DFSPInstall` trên main thread, kiểm owner và window hiện tại trước attach.
- Bảo toàn nguyên `%orig` host/scene SidePlay; giữ rollback/hide cũ, không tự resize `UIWindow.frame`, không vô hiệu giấy phép, không copy CB proprietary engine.
- Ghi dấu runtime để phân loại lý do: `QA8 CONSTRUCTOR`, `QA8 CLASS_WAIT`, `QA8 HOOKS_READY`, `QA8 BOOTSTRAP_WAIT`, `QA8 BOOTSTRAP_REJECT`, `QA8 BOOTSTRAP_STALE`, `QA8 BOOTSTRAP_ATTACH`, `QA7 owner-check attached=`, `Native12 approved frame mounted`. Đường dẫn log chính `/var/mobile/Library/Logs/DuoFaceSidePlayDisplayQA.log`. Log chỉ metadata trạng thái, không log tuyến đường/map/user secrets.
- `sideplay/native12-display/validation/check_qa8_late_host_bootstrap.py` so khớp selector có chứng cứ và source behavior; `check_qa7_visual_recovery.py` tiếp tục kiểm fail-soft UI; phiên bản độc lập `com.duoface.sideplaydisplay 0.1.6~native12bootstrap8`.
- Workflow `.github/workflows/sideplay-visible-zoom-qa-deb.yml` nhánh QA8 xây và kiểm DEB, **chỉ phát hành Sileo khi build SUCCESS, đúng SHA/ID/dependency và có bằng chứng publish Pages.**

## Cách đọc log sau khi gói QA8 thực sự được cài

- **Không có `QA8 CONSTRUCTOR`**: chưa có bằng chứng dylib vào SpringBoard. Cần xác minh bản cài/version, rootless injector/Filter/Respring, không đoán lỗi geometry.
- **Có `CONSTRUCTOR` và liên tục `CLASS_WAIT`, không `HOOKS_READY`**: SidePlay `SPDash` chưa được load trong tiến trình SpringBoard tại thời điểm quan sát. Cần kiểm session/process mà SidePlay đang hiển thị.
- **Có `HOOKS_READY` nhưng `BOOTSTRAP_WAIT`**: class đã có nhưng `SPDash.carWindow` chưa được tạo/gắn; cần thử reconnect CarPlay và xem event setter.
- **Có `BOOTSTRAP_REJECT`**: cửa sổ getter không thỏa xác nhận external `UIScreen`. Không ép global UIWindow/crop để che lỗi; cần đối chiếu owner và screen.
- **Có `BOOTSTRAP_ATTACH` và `QA7 owner-check attached=0`**: giao diện DuoFace có thể được gắn visual-only nhưng host geometry không được xác minh; không đảm bảo Zoom/bar.
- **Có `Native12 approved frame mounted` nhưng chỉ thấy SidePlay UI**: cần kiểm thật thuộc tính `DFSPUI.window`, z-order, `pane chipView.hidden`, đúng process, window root và hiệu lực overlay.
- **Đã thấy hai pill DuoFace nhưng bar chưa đúng**: đây là lỗi native CarPlay chrome owner chưa nối. Không tuyên bố thanh bar đã sửa.

## Điều kiện chấp nhận

1. Sileo gói QA8 đúng version; hai app có **hai pill DuoFace với hai nút mỗi ô**, ở giữa phía trên của từng ô; không lộ thanh cũ SidePlay và nút placeholder kép.
2. Thanh CarPlay hệ thống thực sự hiển thị ở Normal, không Home leak, Zoom chỉ khi user bấm; cả hai app chạy và resize đúng; swap/touch/scene close không exitmode.
3. Nếu kết quả bước 1 thất bại: lấy đúng log 20 dòng có marker trên và tình trạng phiên bản để sửa owner. **Không coi build PASS = device PASS**.
4. Các phần Native12 picker/Style/HUD8/8 styles vẫn chưa chuyển đủ, phải xử lý tiếp sau khi host injection ổn định.

**Trạng thái khi viết:** code/CI đang kiểm tra, QA7 vẫn là Sileo đang công khai. QA8 chưa có xác nhận build/deploy hoặc device test.
