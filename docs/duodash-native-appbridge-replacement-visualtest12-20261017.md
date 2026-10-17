# DuoFace VisualTest12 — phương án App Bridge độc lập dựa trên kiến trúc DuoDash

## ƯU TIÊN MỚI 17/10/2026 — KHÔI PHỤC CHẠY ĐƯỢC TRƯỚC
**Yêu cầu mới nhất của người dùng, thay thế thứ tự triển khai cũ:** Không xây App Bridge độc lập hoàn chỉnh ngay; đó là giai đoạn tương lai. Ưu tiên số 1 hiện tại: **DuoFace VisualTest12 mở được trên màn CarPlay và có thể mở ứng dụng iPhone không được CarPlay hỗ trợ**, bằng cách **tái sử dụng có chọn lọc cơ chế đã chạy của DuoDash/Airaw** nếu chứng minh tương thích. Giữ nguyên bản Native12 Hub, giao diện split của DuoFace và các chức năng đang chạy; không mặc nhiên buộc người dùng cài CarBridge ngoài.

**Đối chiếu nguồn đã kiểm:**
- DuoDash 1.1.3+fullscreen1 DEB có tại `chuongnguyen89dn-ui/DauDat-CarPlay`; đối chiếu tĩnh tại `feature/duoface-exact-payload-migration:audit/duodash-1.1.3/DUODASH_APPBRIDGE_VISUALTEST12_CROSSWALK_20261017.json`: `CNABSpringBoardObserver` nhận host request, `DDz2 cnabBuildSceneHostForBid:displaySize:` tạo scene host, `CNABUIApp setBridgeState:width:height:orientation:` phục vụ app process, `DDz1 showLayoutPanes:natives:bids:` hiển thị. Đây là **hệ thống nhiều process**, không phải chỉ sao chép một nút hay một class.
- Airaw (báo cáo `docs/fullscreen-root-cause-20261014.md`) phục vụ fullscreen/chrome/scene geometry, **không có bằng chứng là host chung cho app iPhone ngoài danh sách CarPlay**; do đó chỉ là nguồn tham khảo layout/chrome, **không phải giải pháp mở YouTube ưu tiên**.
- Probe bản VisualTest12: iPhone đã nối CarPlay thật nhưng detector trả true, `CBBridgeManager.activated=false` và `DashboardPolicySignal=false`. Phải xác định liệu UI startup bị chặn trước hay host scene failure sau. Không được biến phỏng đoán 'do giấy phép duy nhất' thành kết luận.
- Bản gốc VisualTest12 dù copy lại các payload không bảo đảm chạy sau hạn thử; các bản license-gate patch từng thử vẫn chưa đạt chức năng. Không thử lại hàng loạt bản build không có cơ chế mới.
- Giấy phép/quyền dùng nhị phân DuoDash, Airaw **chưa được xác minh cho phép nhúng/redistribute**. Có thể đối chiếu hành vi, API, các file mà người dùng có quyền; **chưa sao chép dylib độc quyền vào DEB công khai** hay khẳng định sẽ tái dùng được binary nguyên trạng.

**Kế hoạch cứu chạy được — tối thiểu trước, nâng cấp sau:**
1. **Triage tại điểm lỗi:** từ các báo cáo đã lưu xác định đường `CBBridgeManagerDashboard requestActivation:` → `startBridging:`, `CBBridgeManager requestStateChange:` → `loadNewAppFromCurrentRequest:`, `CBWindow` create/show và CarPlay scene. Tách *không mở DuoFace UI* khỏi *DuoFace UI mở nhưng app pane không chạy*; không vá mù connection detector.
2. **Kiểm tra khả năng tích hợp chắt lọc:** xác định liệu DuoDash có interface request/scene host tương thích để adapter nhỏ của DuoFace gọi mà không chạy hai chủ scene; nếu chỉ dùng được khi cài toàn bộ DuoDash, không gọi đó là tích hợp tự chứa. Không đụng Hub hoặc ghép nhầm binary Airaw fullscreen với bridge của DuoDash.
3. Nếu reuse nhỏ có căn cứ: thực hiện candidate **riêng cho VisualTest12**, kiểm tra compile ABI/hook filter/collision; chỉ khi hợp lệ mới build DEB và xuất Sileo, thử trên iPhone đã hết hạn: **mở DuoFace → YouTube một pane → Waze+YouTube split**.
4. Nếu DuoDash không có interface tái sử dụng an toàn hoặc quyền phân phối không rõ: báo blocker thực tế, chọn phương án tạm thời trên thiết bị (sử dụng DuoDash nguyên bản đã hoạt động), sau đó mới phát triển native bridge độc lập. **Không tự coi bước tạm là đã khôi phục DuoFace**.


**Bổ sung kiểm chứng tĩnh ngay sau đổi ưu tiên:** báo cáo `feature/duoface-exact-payload-migration:audit/payload-migration/VISUALTEST12_CARPLAY_BOUNDED_METHOD_PARITY.json` cho biết 18/19 method Dashboard được chọn có mặt và vùng byte đối chiếu nguyên vẹn giữa VisualTest12 và Native12 Hub; `CBBridgeManager requestStateChange:`, `loadNewAppFromCurrentRequest:`, `shouldBridge:`, `CBBridgeManagerDashboard +isDashboardPolicySignalActive` nằm trong số method đối chiếu trùng. Phạm vi dùng ranh giới IMP xấp xỉ, **không chứng minh hành vi runtime bằng nhau**. Kết luận điều hành: **không copy lại chính các method này từ Hub sang VisualTest12 như một phép sửa**, vì không có khác biệt tĩnh được chứng minh; tập trung xác nhận bước kích hoạt thực tế rồi thử dùng host có chức năng thực như DuoDash. Dữ liệu mới này không phải là DEB hoặc device test.

**Trạng thái sau thay đổi yêu cầu:** mới đối chiếu logic và đổi ưu tiên; chưa sửa binary/source runtime, chưa có DEB mới, chưa có test thiết bị đạt. GitHub Actions xanh trước đó chỉ là QA/probe cũ. ZIP skills trung tâm đã được phát hiện nhưng phiên hiện tại không giải nén ZIP nhị phân được qua connector; sử dụng các tài liệu `DEB_IPA_SKILL.md`, `AGENTS.md` tương đương được đọc trực tiếp.

Ngày: 2026-10-17. Repo: chuongnguyen89dn-ui/Duoface. Trạng thái: phân tích tĩnh, CHƯA tích hợp/chưa build.

## Yêu cầu mới (thay thế tiếp tục thử sửa giấy phép đơn lẻ)
Người dùng xác nhận DuoDash có sẵn App Bridge và theo trải nghiệm sử dụng của họ không cần giấy phép dùng thử như DuoFace, cũng không cần cài CarBridge độc lập. Nếu đường bridge tích hợp DuoFace VisualTest12 bị khóa theo thời hạn không thể khôi phục, tạo cơ chế bridge độc lập có công dụng tương đương và dùng lại giao diện chia đôi DuoFace. Chỉ thay gói com.duonavi.app VisualTest12, KHÔNG thay com.duoface.independent (Native12 Hub).

## Nguồn thực tế
- DuoDash core App Bridge được nhà phát triển xác nhận ở https://sensetechlab.com/vi/duodash/features/ ; extension module khác là tùy chọn, không cần CarBridge riêng.
- DuoDash DEB tham chiếu tại chuongnguyen89dn-ui/DauDat-CarPlay commit 5f683ad16a2c4f2b37e333e891cfb8f7ba3e0d6b, file DuoDash_1.1.3_Fullscreen427_iphoneos-arm64.deb SHA256 ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465. Đây là bản FULLSCREEN REPACK, chưa được xác nhận đồng nhất với stock 1.1.3.
- Kiểm kê mã trước: feature:audit/duodash-1.1.3/DUODASH_NAVBUBBLE_MOUNT_CHAIN_READONLY.json; DUODASH_PERF_CPU_THERMAL_RAW_TRACE.json.
- Đối chiếu 4 tầng đã ghi và kiểm lại 11 class/selector/filter anchors tại feature:audit/duodash-1.1.3/DUODASH_APPBRIDGE_VISUALTEST12_CROSSWALK_20261017.json (commit d2a22d952a3b091f24c1d4db305f76e754e3e477, blob fe9560e0ac9b06860efd455ddb40bac12c8f0404).

## Các tầng chạy thật sự, không phải một công tắc
1. SpringBoard: CNABSpringBoardObserver nhận kết nối và lệnh host/request split; DuoFace tương ứng CBBridgeManager handleCarPlayConnectionChanged, requestStateChange.
2. Scene host: DuoDash DDz2 cnabBuildSceneHostForBid:displaySize: có tham chiếu SBApplicationController và SBDeviceApplicationSceneEntity; DuoFace tương ứng startBridging/loadNewAppFromCurrentRequest, nhưng chưa chứng minh scene/window còn tạo được lúc hết hạn.
3. App process: CNABUIApp setBridgeState:width:height:orientation: nhận trạng thái và điều chỉnh cửa sổ.
4. CarPlay UI: DuoDash DDz1 showLayoutPanes:natives:bids:; DuoFace có giao diện chia đôi của chính nó cần GIỮ, không thay bằng DDz1.

Kết nối thực tế trước đó: SpringBoard có external UIScreen và detector DuoFace true, nhưng CBBridgeManager.activated=false, DashboardPolicySignal=false. Không đủ chứng minh license là nguyên nhân duy nhất hay DuoFaceUI nhận trạng thái sau kết nối.

## Nguồn có thể học / tái sử dụng
- https://github.com/EthanArbuckle/carplay-cast — Apache-2.0, mã SpringBoard+CarPlay scene host ở src/CRCarplayWindow.mm, src/hooks/SpringBoard.xm, src/hooks/CarPlay.xm. Dự án ghi iOS 14+, TARGET cũ 13.5.1; chưa xác thực chạy trên iOS16 Dopamine hiện tại. Nếu tái sử dụng mã phải giữ thông báo bản quyền, LICENSE và ghi thay đổi Apache-2.0. Mẫu cũ một host/window, KHÔNG tương đương sẵn với 2-pane DuoFace.
- https://github.com/pavunato/carsurf — tác giả công bố đã test iPhone X iOS16.7.12 (RootHide), scene app qua SpringBoard/CarPlay và cấu trúc app-side state. GitHub repo kiểm tra 2026-10-17 không có LICENSE và metadata license=null, vì vậy chỉ dùng như tài liệu kiến trúc, KHÔNG copy mã khi chưa có phép.

## Quyết định và tiêu chí tích hợp
Giữ DuoFace UI/split/picker, thay đúng lớp yêu cầu host/scene bị chặn bằng một **bridge adapter độc lập do dự án kiểm soát**. Phải tránh chạy đồng thời 2 bộ host trong SpringBoard/CarPlay, không chèn nhị phân DuoDash.dylib nguyên khối. Không thay toàn bộ dòng cho app hỗ trợ CarPlay chính thức; tránh gây crash Waze/Vietmap khi sửa scene role (cảnh báo của CarSurf).

Điểm cần làm tiếp, theo thứ tự:
1. Trace khi bấm app trong VisualTest12: CBBridgeManagerDashboard requestActivation/startBridging; CBBridgeManager requestStateChange/loadNewAppFromCurrentRequest; CBWindow create/show và thông điệp app-side. Đối chiếu ABI/owner/process trên iOS16.
2. Dùng thuật toán scene host do dự án tự viết hoặc phần Apache-2.0 tương thích để cấp scene cho bundleID, truyền state và kích thước tới app rồi gắn content vào pane DuoFace; bảo toàn Waze.
3. Test/compile iOS arm64, đóng DEB com.duonavi.app bản VisualTest12 ở nhánh feature, xác minh giữ nguyên Hub và 35 payload ngoài chỗ thay; QA trên máy đã hết hạn + CarPlay có dây, trước tiên YouTube trong 1 pane, sau đó split Waze+YouTube. Chỉ công bố chạy được sau kiểm nghiệm thiết bị.

Trạng thái kiểm chứng hiện tại: đã đối chiếu tĩnh kiến trúc, chưa tạo module scene host hoàn chỉnh, chưa build hay đưa Sileo, chưa chứng minh ứng dụng đã mở được.

## Checkpoint 2026-10-17 17:59 ICT — xác minh GitHub hiện tại
- Phạm vi kiểm tra: CHỈ kiểm kê GitHub, KHÔNG sửa nguồn, KHÔNG build, KHÔNG deploy. Repo `chuongnguyen89dn-ui/Duoface`, nhánh `main`.
- HEAD quan sát: `68eba99de18c42e00dd5672837eef25dd00a8777` (chỉ cập nhật `status/duoface-actions.json`, không phải bản App Bridge). Commit `4182f042b6c4b590d4bc93f80f7a129acd50902a` cập nhật bàn giao chính; tài liệu thiết kế này được thêm tại `4d7c57c9aad79d5ce77d578b1146940afdddc12f`.
- GitHub Actions snapshot `status/duoface-actions.json` kiểm lúc `2026-10-17T10:54:08.181030Z` (17:54:08 ICT), ghi `642` lần chạy cộng dồn. Tra cứu API kế tiếp: `status=in_progress` và `status=queued` đều trả `total_count=0` tại thời điểm kiểm.
- Run `39026647222` (DuoFace Actions status snapshot) completed SUCCESS, **chỉ là workflow tổng hợp trạng thái**. Run `39023881819` (Verify public VisualTest12 CarPlay connection probe DEB) completed SUCCESS, job `verify` thành công, **chỉ xác nhận tải/kiểm DEB thăm dò đang có và Hub độc lập chưa đổi**, KHÔNG xác nhận App Bridge mới hoặc thử nghiệm thực tế. Run `39026100282` (speed8-iphonex-handoff-checkpoint) FAILURE, không coi là kết quả kiểm tra adapter mới.
- **Trạng thái tính đến checkpoint:** đường thay App Bridge vẫn ở mức nghiên cứu/đối chiếu tĩnh, KHÔNG có commit triển khai scene host độc lập, KHÔNG build DEB tích hợp mới, KHÔNG publish Sileo cho adapter, KHÔNG chứng minh mở YouTube trên iPhone hết hạn. Hub `com.duoface.independent` KHÔNG thay đổi trong lượt này.
- **Tiếp theo:** trace callback `CBBridgeManagerDashboard requestActivation/startBridging` → `CBBridgeManager requestStateChange/loadNewAppFromCurrentRequest` → `CBWindow`; xác minh ABI, process owner và scene creation trên iOS16; viết adapter scene host của dự án (hoặc thành phần Apache-2.0 khi đủ điều kiện), kiểm CI arm64 và kiểm xung đột Waze; sau khi có build hợp lệ mới kiểm thử máy thật với YouTube một ô rồi split hai ô. Không biến workflow SUCCESS thành device PASS.
