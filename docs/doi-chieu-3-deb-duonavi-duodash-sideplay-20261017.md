# Đối chiếu 3 DEB CarPlay trước khi sửa DuoFace — 2026-10-17

## Phạm vi và bằng chứng truy xuất

Người dùng yêu cầu tận dụng DEB/dữ liệu có sẵn của **DuoNavi, DuoDash, SidePlay**, không tạo lõi CarPlay từ đầu. Repo chính `chuongnguyen89dn-ui/Duoface`, nhánh `feature/visual12-duodash-recovery`. Đây là kết quả đối chiếu **tài liệu static audit và source thật trên GitHub**, không giả nhận đã trích xuất lại các DEB nhị phân trong lượt này. GitHub connector không trả binary DEB; file binary có trong repo hoặc upload cần runtime/container để đọc byte. Không chỉnh Native12+Hub8 hay Sileo.

| Đối tượng | Nguồn đã xác minh | Phiên bản/hash | Giới hạn |
|---|---|---|---|
| DuoNavi gốc | `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb` tồn tại trên nhánh, 1,739,158 B; `docs/duoface_104_file_by_file_comparison.md`, `audit/payload-migration/ORIGINAL_RUNTIME_CONTRACT.json` | 1.0.4; SHA256 của DEB chưa xác minh lại lượt này | Audit lịch sử so sánh v12-first delta, không phải original-vs-original v12 |
| DuoDash | `audit/duodash-1.1.3/DUODASH_APPBRIDGE_VISUALTEST12_CROSSWALK_20261017.json`; nguồn tham chiếu `chuongnguyen89dn-ui/DauDat-CarPlay@5f683ad16a2c4f2b37e333e891cfb8f7ba3e0d6b` | 1.1.3+fullscreen1, source SHA256 tham chiếu `ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465` | Là bản repack; không xác minh binary gốc hay chạy trên iPhone lượt này |
| SidePlay | `docs/sideplay-1.0.4-1-static-deb-audit-20261017.md`; user-supplied `com.sideplay_1.0.4-1_iphoneos-arm64.deb` đã được audit | 1.0.4-1; 4,352,576 B; SHA256 `7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c` từ audit trước | Không có source .m/.h/.xm; chỉ binary/metadata/strings, không được tự sao chép để phát hành |
| DuoFace QA hiện tại | `dist/visual12-g1g2-qa/BAO_CAO.json`; `DFIRuntime.m`, `DFCarPlaySplitCoordinator.m` | 1.0.3-12~standalone2qa; SHA256 DEB `12b3e874175bae3059c499c10a365d62e724b2eb27cc3e67178dca2413423daa` | G1/G2 FAIL thực tế, không lấy CI pass làm runtime pass |

## Đường mở scene thực tế

| Giai đoạn | DuoNavi (audit) | DuoDash (audit) | SidePlay (static) | DuoFace source |
|---|---|---|---|---|
| Nhận diện CarPlay | `CBLicenseSyncManager +isCarPlayScreenConnected` | `DDz1 +carPlayConnected` | `CarPlayIsConnectedDidChange`, `currentCarPlayExternalDevice` | External `UIScreen`/SpringBoard, `DFIQAStart` |
| Request | `CBBridgeManager -requestStateChange:`, `CBBridgeManagerDashboard -requestActivation:` | `CNABSpringBoardObserver -onHostRequest:` / `-onHostRequestSplit:` | App/relay + `openSidePlay` | Darwin notifications QA + `DFCarPlaySplitCoordinator openApp:inPane:` |
| Host | `CBBridgeManagerDashboard -startBridging:`, `CBBridgeManager -loadNewAppFromCurrentRequest:` | `DDz2 -cnabBuildSceneHostForBid:displaySize:`, `SBDeviceApplicationSceneEntity` | `SBApplicationController`, `SBDeviceApplicationSceneEntity`, `SBAppViewController`, `FBScene`, `sceneHandle` | `DFV12SceneHost initWithBundleID:` -> `SBDeviceApplicationSceneEntity`, `SBAppViewController` |
| Display | `CBWindow`, `CBBridgedSplitApp`, `CBMultitaskingOverlayView` | `CNABUIApp -setBridgeState:width:height:orientation:`, `DDz1 -showLayoutPanes:natives:bids:` | Private scene geometry + CarPlay display | `UIRootSceneWindow`, 2 UIView panes, resize/sceneHandle |

**Quan trọng:** không có bằng chứng rằng một DEB là mã nguồn gốc của cả ba; không có cách hợp lệ để bê nguyên thư viện thương mại vào DuoFace mà mặc nhiên độc lập giấy phép. Adapter DuoDash trong `replacement/duodash-host/DFDuoDashHostAdapter.m` vẫn phụ thuộc `DDz2` và không phải lời giải standalone.

## Nguyên nhân G1/G2 đã khoanh vùng bằng source và log

Log thiết bị (tóm tắt ở handoff, file do user upload trong chat trước) có `owner-ready {{0,0},{507.33333333333331,240}}`, sau đó `G1-request com.waze` -> `G1-fail Phiên bản iOS này thiếu API mở vùng ứng dụng.`; G2 fail tại app đầu. Không có scene attach của QA. Runtime cũ có `scene attached ... class=FBScene` cho MiDrive/Apple Maps/YouTube, chứng minh cơ chế scene từng chạy, nhưng không chứng minh cùng package/đường khởi tạo.

Trong `replacement/visual12/engine/runtime/DFIRuntime.m`, dòng ~100–111:
- Lấy `SBApplicationController sharedInstance` rồi `applicationWithBundleIdentifier:`.
- Lấy `SBDeviceApplicationSceneEntity`, `SBAppViewController`.
- Guard **gộp 4 điều kiện**: app phải tồn tại, entity phải có `initWithApplicationForMainDisplay:`, controller phải có `initWithIdentifier:andApplicationSceneEntity:`, `setRequestedMode:` và `_setCurrentMode:`.
- Một trong các điều kiện fail => cùng một chuỗi lỗi tổng quát. `DFCarPlaySplitCoordinator` chỉ gọi constructor này; chưa có scene host nào được attach.

**Kết luận chắc chắn:** lỗi G1/G2 xuất hiện trước khi host attach và trước khi mở scene. **Chưa xác định** điều kiện nào fail, nên không được nói chắc chắn iOS16 thiếu API hoặc thay ngay selector. Tham chiếu SidePlay/DuoDash cho thấy cùng họ class, không chứng minh ABI/selector khớp trên máy test.

## Thay đổi tối thiểu thay vì làm lại

1. **Giữ** DFIRuntime, DFV12SceneHost, QA root, coordinator, giao diện DuoFace và tất cả gói Native12+Hub8; không thêm engine/owner thứ hai.
2. **Chẩn đoán ngay trong constructor có sẵn:** ghi rõ `application` nil hay class/selector nào không khả dụng; log SpringBoard process và OS version (không log thông tin cá nhân). Giữ fail-closed.
3. Khi có log chính xác, đối chiếu ABI/callsite của DuoNavi, DuoDash, SidePlay trong audit đã có và selector của SpringBoard đang chạy. Chỉ sửa **đúng nhánh điều kiện** có bằng chứng; giữ callback scene attached dựa trên `FBScene` thực.
4. Compile, build DEB QA revision mới (không đè Native12+Hub8), test G1 trên máy đã hết trial. Chỉ test G2 khi G1 thật sự attach/touch; nếu không pass không phát hành production.
5. Đối chiếu giao diện Visual12 đã duyệt chỉ sau khi host hoạt động, không thay bằng giao diện QA trắng/đen.

**Chưa hoàn tất:** chưa đọc bytes DuoNavi/DuoDash/SidePlay trong lượt này, chưa so hash DuoNavi, chưa chạy lại device test, chưa có fix selector cụ thể. Các dữ liệu GitHub này đủ để loại hướng xây lại engine và xác định đúng chỗ cần đo.
