# Quy tắc thay thế giao diện SidePlay → DuoFace Native12 HUD8

**Quyết định của người dùng — 18/10/2026 (ưu tiên cao nhất):** *“Phần nào thêm mới vào thì ẩn phần cũ. Nếu những hàm tận dụng thì giữ nguyên hoặc đem từ duoface qua. Ẩn tức là test được ta phải xóa bỏ khỏi DEB sau này.”*

Quy tắc này áp dụng **mỗi lần** nối UI/function mới. Chuẩn là DuoFace Native12 HUD8 **đã được chấp nhận**, SidePlay chỉ là nền scene/app hosting. Không tạo 2 UI trùng lên nhau. Nguồn thiết kế tra **`tiep tuc du an.md` / `ban giao du an duoface moi.md`** trước, rồi mới tới tài liệu UI Native12 và audit SidePlay hiện có; KHÔNG quét lại DEB từ đầu.

## Ba trạng thái bắt buộc trong công việc

- **REPLACED_HIDDEN_TESTING**: đã có thành phần Native12 tương đương, **ẩn UI SidePlay cũ ở runtime** trong đúng CarPlay session; giữ cách khôi phục và rollback để test, không sửa bản DEB vendor gốc.
- **REUSED_FUNCTION**: không ẩn/xóa cơ chế nền vẫn cần để mở app, đổi frame, nhận cảm ứng, giữ scene, routing actions. Chỉ thay hình thức hiển thị và điều khiển. Nếu cần chức năng như Native12 mà SidePlay thiếu, viết source độc lập và nối đúng owner.
- **REMOVED_FROM_INDEPENDENT_PACKAGE_AFTER_DEVICE_PASS**: sau khi đã kiểm chứng Native12 UI + đầy đủ chức năng trên iPhone X/CarPlay và được người dùng chấp thuận, mã build DuoFace độc lập **không đóng gói/không dùng các module UI SidePlay bị thay**; không xóa nhị phân bên thứ ba trong bản gốc. Nếu SidePlay vẫn là phụ thuộc của gói QA, không được tuyên bố đã xóa riêng class/method khỏi SidePlay.dylib.

## Danh mục QA3 đã đối chiếu trên mã

| Thành phần Native12 | UI SidePlay cũ | Trạng thái nguồn QA3 | Cần nghiệm thu trước khi loại bỏ khỏi gói độc lập |
|---|---|---|---|
| Khung toàn CarPlay khởi động Normal, Zoom trong menu | Tự fullscreen `SPDash` | **REPLACED_HIDDEN_TESTING (khung điều khiển)**: hook `carDockMode`, `carWindowFrameNow`, `setCarWindowFrame:`, `layoutRootView`; vẫn gọi `%orig` để dựng host app | Trên xe thấy native bar khi kết nối; Zoom In fullscreen; Zoom Out trả bar; no exitmode |
| Pill Native12 từng ô | `SPPane.chipView` và `SPPane.layoutButton` | **REPLACED_HIDDEN_TESTING**: `[pane chipView].hidden=YES`, `[pane layoutButton].hidden=YES` khi NativeFrame đang hoạt động | Không chồng nút cũ, pill mới chọn đúng ô, không mất cảm ứng app |
| Placeholder Native12 | Label `Trống / Thêm app / Empty / Add app` cũ | **REPLACED_HIDDEN_TESTING** chỉ khi ô chưa có app; `DFSPHideSidePlayPlaceholder` không chủ động ẩn host scene | Placeholder Native12 đúng màu/cỡ; chọn app mở được |
| Bộ khung logo chia, kéo tỷ lệ, tap swap, hold 0.30s | Style cố định, chưa có drag | **NEW_INDEPENDENT_UI**: `DFSPNativeFrame`; **REUSED_FUNCTION** `SPDash.setRatio:`, `layout:`, `paneRequestsSwap:` | Kéo đổi ratio thực của **2 scene đang chạy**, tỷ lệ giữ sau relayout; chạm không bị app ăn |
| Menu Native12 App–Zoom–Style–Close | Nút Zoom QA1/QA2 nổi | **REPLACED_HIDDEN_TESTING**: mã nút nổi đã bỏ; picker Native12 ở `DFSPNativeFrame` | Menu chỉ 1 hàng, chỉ Zoom theo nút, không xuất hiện zoom nổi |
| Nội dung danh sách chọn ứng dụng | `SPDash.showPickerForPane:` với UI SidePlay | **REUSED_FUNCTION / OLD_UI_STILL_VISIBLE**: QA3 vẫn mở bộ chọn SidePlay thật. **CHƯA thay UI picker**; sau này cần mang visual picker Native12, giữ service app-selection | App list Native12 đúng giao diện, chọn app/cancel/scene hoạt động |
| Nội dung bảng Style | `SPDash.layoutChooser` | **REUSED_FUNCTION / OLD_UI_STILL_VISIBLE**: QA3 gọi chooser gốc. **CHƯA thay UI chooser**; khi có UI Style Native12 mới thì ẩn chooser gốc | Chọn style Native12, ratio drag vẫn hoạt động |
| Close/Swap/scene-host | `SPDash.paneRequestsClose:`, `paneRequestsSwap:`, `SPPane.appViewController` | **REUSED_FUNCTION** — giữ; có thể thay implementation bằng mã sở hữu DuoFace trong giai đoạn tách phụ thuộc | Không mất ứng dụng hiện tại, thao tác close/swap chính xác, không crash |
| HUD8 | SidePlay HUD relay/plugins | **NOT_YET_PORTED**: giữ nguyên cho đến khi có source HUD8 độc lập + đo trên thiết bị | HUD8 hiển thị và hoạt động độc lập, không đè / mất khi thoát app |

**Cấm báo “đã thay thế toàn diện” khi một thành phần vẫn là `OLD_UI_STILL_VISIBLE` hoặc mới compile.** QA3 hiện vẫn là bản chuyển giao diện một phần.

## Cách xử lý đúng từng lần tiếp tục

1. Tra hồ sơ Native12/HUD8 và ánh xạ selector/controller SidePlay **đã lưu**, xác minh chức năng nào là UI, chức năng nào là host.
2. Tạo Native12 UI hoặc action tương ứng và nối callback tới real host.
3. Ẩn UI SidePlay tương ứng **chỉ khi UI mới hoạt động** và giữ snapshot `hidden/frame/owner` để rollback, không ẩn global UIWindow, app scene hay nhầm chrome hệ thống.
4. Build DEB **QA riêng** trên nhánh SidePlay; kiểm compile, static + smoke thực trên xe.
5. Nếu pass, đánh dấu `DEVICE_PASS` có ảnh/log và commit; khi viết **gói độc lập** không đóng gói UI cũ. Nếu fail, rollback/mở lại UI cũ, phân tích log mà không xóa nhị phân.
6. Nếu app picker / Style / HUD chưa được viết như Native12, ghi **chưa port** thay vì ẩn toàn bộ và làm mất khả năng dùng.

## Trạng thái triển khai tại lần ghi

- QA3 source: `sideplay/native12-display/DFSPNativeFrame.[hm]` và `sideplay/sileo-qa/Tweak.xm`; package `com.duoface.sideplaydisplay` version `0.1.1~native12frame3`, hash DEB `c41826d474aced13a48ddbf39ef72cb913f8cf9c933411da4c969cdff1ad443d`.
- Build Theos: [Actions 39120852019](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39120852019) **SUCCESS**. Static ABI bridge [39121117842](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39121117842) **SUCCESS**.
- Sileo workflow [39121041655](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/39121041655) **chưa xác minh completed deployment** tại lần ghi; cần xác nhận riêng.
- QA3 **chưa có DEVICE_PASS** cho dock, menu, app picker, drag, swap, hay HUD8.

**Nguồn chính**: `sideplay/tiep tuc du an.md`. Đừng cập nhật hai hồ sơ root chỉ vì thay đổi SidePlay.
