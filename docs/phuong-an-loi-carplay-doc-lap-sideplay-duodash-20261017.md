# Phương án DuoFace độc lập dựa trên nghiên cứu SidePlay và DuoDash

Ngày: 2026-10-17. Loại: quyết định kiến trúc / chưa triển khai, chưa build, chưa device QA.
Repo: chuongnguyen89dn-ui/Duoface. Handoff branch: feature/visual12-duodash-recovery.
Yêu cầu user: “Vậy hướng viết mới từ đầu dựa trên sideplay, duodash thì sao? Ta sẽ ko còn phụ thuộc ai ai? Tự nối của ta theo nền có sẵn hiện tại.”

## Quyết định đề xuất
Viết mới và sở hữu hoàn toàn lớp scene host/điều phối CarPlay, theo nguyên lý đã quan sát ở SidePlay 1.0.4-1 và DuoDash 1.1.3; **không** dùng hoặc phân phối binary/core/vendor runtime của họ hay DuoNavi; không cần cài tweak của bên thứ ba. **Không viết lại cả ứng dụng từ 0**: tận dụng những module source và tài nguyên DuoFace có sẵn, với UI v12 đã duyệt là chuẩn nghiệm thu. Tách trách nhiệm module, một owner SpringBoard, thử trên iPhone X hết trial trước khi đụng nhánh Hub.

Định nghĩa “không phụ thuộc ai”: Không phụ thuộc giấy phép/trial, máy chủ, service, package, dylib của DuoNavi, DuoDash, SidePlay, CarBridge thương mại. Vẫn phụ thuộc iOS 16, CarPlay, jailbreak/rootless/Substrate, các API hệ thống SpringBoard và các app như Waze/YouTube. Private API có nguy cơ thay đổi và không được hỗ trợ chính thức.

Apple docs: https://developer.apple.com/documentation/carplay/requesting-carplay-entitlements và https://developer.apple.com/documentation/carplay/cptemplateapplicationscene: CarPlay chuẩn yêu cầu entitlement theo thể loại ứng dụng; scene window không được cấp cho mọi category. Giải pháp iPhone jailbreak là đường không chính thức, có rủi ro cập nhật iOS.

## Mã nguồn DuoFace giữ lại làm nền
- replacement/visual12/engine/runtime/DFIRuntime.m: có SpringBoard scene host (SBApplicationController, SBDeviceApplicationSceneEntity, SBAppViewController, sceneHandle), render geometry và teardown. **Đây là mã có thật nhưng chưa chứng minh chạy ổn định trên máy**. DFV12SceneHost là điểm bắt đầu. DFIStart có guard từ chối nếu CBBridgeManager đã nạp, phải giữ an toàn single-owner.
- replacement/cb-compat/DFCBCompat.h, DFCBCompat.m: facade bind/unbind vào UIWindow và UIViewController đã có, **không phải launcher scene** và không tự tương thích ABI CB vendor. Có thể dùng hợp đồng source mà dự án sở hữu, phải tránh giả vờ đã giữ UX cũ.
- replacement/visual12/fullscreen/DFVisual12HostGeometry.m, runtime/fullscreen/DFFullscreenCoordinator.mm và DFFullscreenTransport.mm: source giao tiếp fullscreen/geometry/ACK. Các module cũ hook CB* cần thay adapter, không bê nguyên hook vào build độc lập.
- replacement/visual12/engine/DFILayouts.h, DFIGeometryTypes.h, engine/shared/DFISettings.m: source bố cục và settings để tái sử dụng sau khi tách khỏi DFIInterface.inc bản alpha sai UI.
- dist/visual-1.0.3-12/assets/VisualAssets/, logos/icons: ảnh/thiết kế/picker đã duyệt là baseline. Chỉ dùng thành phần có quyền tái sử dụng; đối chiếu giao diện chức năng thật trước khi nhận 100%.
- Native12+Hub8: dist/payload-migration/native12-speed8compact/; giữ DEB package com.duoface.independent 0.1.0~native12+speed8compact bất biến. SpeedHUD/SpeedOwner hiện còn phụ thuộc CBWindow cũ, không import nguyên binaries vào core mới.

## Những điều học từ SidePlay và DuoDash
- SidePlay: core SidePlay.dylib injection SpringBoard, sử dụng các tên class private scene SBDeviceApplicationSceneEntity, SBAppViewController, sceneHandle và connection/reconnect/teardown; SidePlay.app có CarPlay scene. Trong DEB không có mã nguồn hoặc giấy phép toàn bộ sản phẩm; MIT chỉ áp dụng thành phần HUD; **không chép binary**. Nguồn: docs/sideplay-1.0.4-1-static-deb-audit-20261017.md.
- DuoDash: audit/duodash-1.1.3/DUODASH_APPBRIDGE_VISUALTEST12_CROSSWALK_20261017.json ghi rõ bốn tầng detect -> request -> scene host -> display. replacement/duodash-host/DFDuoDashHostAdapter.m vẫn **yêu cầu class DDz2 có sẵn**, chỉ giữ làm nghiên cứu, TUYỆT ĐỐI không đóng vào bản standalone.

## Kiến trúc DuoFace source-owned
1. DFCarPlayDisplayOwner (SpringBoard): kiểm màn hình CarPlay, tạo một external UIWindow, start/stop, quản lý reconnect, bảo đảm chỉ có một scene owner.
2. DFAppSceneHost (tái sử dụng DFV12SceneHost): mỗi app một UIViewController/sceneHandle; attach đúng pane, resize, terminate, cleanup, error/rollback có log rõ.
3. DFSplitCoordinator: mở/đóng 1-2 scenes, swap, ratio, focus/restore, lifecycle và geometry. Hợp đồng cố định: open(bundleID,pane), close(pane), resize, focus, swap.
4. DFVisual12UIAdapter: nối App, Zoom, Style, Close, picker, Clear All, pill/split/fullscreen vào coordinator. Bản GUI native từ DuoNavi đang trộn trong DuoFaceDashboard.dylib và license watchdog; **chưa chứng minh có thể copy nguyên UIKit compiled ra khỏi runtime vendor**. Nếu không thể tái sử dụng hợp lệ, phải viết renderer tương đương bằng nguồn riêng theo chuẩn UI đã duyệt; không tự đưa DFIInterface.inc alpha sai UI làm sản phẩm.
5. DFCarPlayLauncher/IPC: icon/launch, start/stop notification giữa CarPlay và SpringBoard dùng namespace DuoFace riêng (không dùng notification của DuoDash/SidePlay).
6. DFHubSpeed integration: chỉ khi Visual12 độc lập đã hoạt động và UX parity QA; bảo toàn package main cho tới khi kết thúc test.

## Acceptance gates (must pass in order)
G0: Lấy baseline DEB Visual12 và Native12+Hub8 pin SHA, audit dependencies; gói thử không chứa DuoNavi/SidePlay/DuoDash binary, server hoặc trial.
G1: iPhone X iOS16 hết trial, tweak độc lập chạy một app thật trong CarPlay, sceneHandle xuất hiện, thao tác được, không crash/respring.
G2: Waze + YouTube cùng có app scene thật, resize, swap, touch, reconnect/teardown hoạt động; không cài SidePlay/DuoDash/CarBridge riêng.
G3: UI Visual12 đúng bản duyệt (App/Zoom/Style/Close, recent apps/icons/status-dot, swap, picker, Clear All, split ratio, focus/restore/fullscreen). Không dùng QA standalone1 sai GUI như bằng chứng.
G4: static packaging QA + kiểm nghiệm iPhone X rằng chỉ nạp một owner, không phụ thuộc giấy phép/trial/nhị phân hãng khác. Rủi ro private API và quyền sử dụng ảnh/binary đã được xử lý.
G5: port có kiểm soát Hub8 sau khi pass G1-G4; hồi quy trên máy, giữ rollback SHA, không tự cập nhật Sileo trước nghiệm thu.

## Phần đã chứng minh và chưa chứng minh
Đã có SOURCE: DFIRuntime/DFCBCompat/geometry/fullscreen/layout/settings/assets. Đã có STATIC AUDIT: SidePlay/DuoDash class/scene API. Lịch sử: có UI hai khung trống trên CarPlay nhưng chưa chứng minh hai app đồng thời ổn định. Chưa có proof iPhone X chạy standalone không trial, chưa tách được GUI native trong Dashboard, chưa có parity UI. LICENSE_BOUNDARY_AUDIT.json: license_subsystem_separable_by_file=false, independent_release_ready=false. Không thể khẳng định thay core và giữ nguyên byte giao diện sẽ thành công ngay.

## Bước thực thi cụ thể tiếp theo
A. Tách interface độc lập từ DFIRuntime.m cho scene owner và per-app host, tách khỏi renderer DFIInterface.inc; giữ static guard một owner. Viết test tĩnh cho module không có import vendor DDz2/CBBridgeManager impl.
B. Compile/link bằng .github/workflows/duoface-visual12-engine-bind-ci.yml, phân biệt compile pass với device success; chuẩn bị package QA riêng khi user yêu cầu build, không đè tên gói hiện hành.
C. Gửi device QA G1 rồi G2 (xe dừng) trên iPhone X, ghi log scene attach/fail và rollback. Sau G2 mới quyết định kỹ thuật & quyền sử dụng phần renderer UI v12 cần tự viết, không đánh tráo GUI.
D. Ghi từng commit/run/SHA/test vào ban giao du an duoface moi.md. Không chạy build/deploy hoặc sửa Native12+Hub8 trong lượt quyết định này.

Tình trạng 17/10: **chỉ ra quyết định thiết kế bằng đối chiếu GitHub và tài liệu Apple; CHƯA thay source, chưa build DEB, chưa deploy Sileo, chưa test thiết bị.**

## Hợp đồng API DuoFace cụ thể (bổ sung 17/10/2026)

**Người dùng hỏi:** “Vậy 3 app lia api j? Ta sẽ làm api j?” Bộ ba được hiểu theo ngữ cảnh = DuoNavi / DuoDash / SidePlay. Phải phân biệt **Apple CarPlay public API** (CarPlay templates cho app được cấp entitlement) với **SpringBoard private API dùng trong môi trường jailbreak** để host app scene tùy ý. Không tồn tại một bộ API “CarPlay bridge cho mọi app” chính thức công khai và ổn định.

### Bảng đối chiếu API đã xác minh bằng mã/binary audit
| Reference | Detect/request | Scene / host | Display / split |
|---|---|---|---|
| DuoNavi / gốc Visual12 | `CBLicenseSyncManager +isCarPlayScreenConnected`, `CBBridgeManager -requestStateChange:` | `CBBridgeManagerDashboard -startBridging:`, `CBBridgeManager -loadNewAppFromCurrentRequest:` | `CBWindow`, `CBBridgedSplitApp`, `CBMultitaskingOverlayView`, `CBBridgeManager -switchToSplitWithLeft:right:ratio:` |
| DuoDash 1.1.3 (audit là bản repack, không phải source gốc) | `CNABSpringBoardObserver -onHostRequest:` / `-onHostRequestSplit:`, `DDz1 +carPlayConnected` | `DDz2 -cnabBuildSceneHostForBid:displaySize:`, `SBDeviceApplicationSceneEntity` | `CNABUIApp -setBridgeState:width:height:orientation:`, `DDz1 -showLayoutPanes:natives:bids:` |
| SidePlay 1.0.4-1 (DEB user cung cấp) | `CarPlayIsConnectedDidChange`, `currentCarPlayExternalDevice` | `SBApplicationController`, `SBDeviceApplicationSceneEntity`, `SBAppViewController`, `sceneHandle`, `FBScene` | `FBSSceneSettings`, `FBSSceneParameters`, `SBDeviceApplicationSceneView`, `CPTemplateApplicationScene`/ `CPInterfaceController` (vỏ app) |

### API **của DuoFace** phải thiết kế (không phải tên API Apple)

**Tên không gian:** `DFCarPlay`. Đây là interface nội bộ Object​ive-C do DuoFace sở hữu, UI/Hub gọi vào mà không trực tiếp thao tác private framework.

1. `DFCarPlayDisplayOwner`: nhận kết nối/ngắt CarPlay, `startWithError:`, `stop`; đảm bảo **single scene owner**, gọi từ SpringBoard.
2. `DFCarPlaySceneHost`: `openBundleID:inContainer:completion:`, `resizeTo:`, `close`; dùng nguồn `DFV12SceneHost` đã có trong `DFIRuntime.m`, tạo `SBDeviceApplicationSceneEntity` + `SBAppViewController` và giữ `sceneHandle`, quản lý error/teardown.
3. `DFCarPlaySplitCoordinator`: `openApp:inPane:completion:`, `closePane:`, `setSplitRatio:`, `swapPanes`, `focusPane:`, `restoreSplit`, `closeAll`; quản lý đúng **hai scene** và UI state, không thuộc vendor class.
4. `DFCarPlayUIAdapter`: đổi lệnh `App/Zoom/Style/Close`, menu/picker/resize/focus của Visual12 đã được duyệt thành các lời gọi coordinator; **không** dùng `DFIInterface.inc` alpha như UI cuối. Nếu compiled UI legacy không thể tách khỏi `CBBridgeManager`/license, UI cần triển khai tương đương bằng source có quyền sử dụng, không cam kết copy nguyên byte.
5. `DFCarPlayLauncher` và `DFCarPlayIPC`: kích hoạt UI/scene và chuyển sự kiện SpringBoard ↔ CarPlay bằng namespace riêng `com.duoface.carplay.*` (không gọi notification/protocol vendor).
6. `DFCarPlayFullscreen`/ `DFCarPlayDiagnostics`: geometry/ACK, rollback có phân biệt fullscreen toàn host vs focused pane; log từng giai đoạn (display, window, entity, controller, sceneHandle, attached, policy, teardown).

**Ví dụ hợp đồng Objective-C ở mức thiết kế, CHƯA phải mã đã compile:**
```objc
@protocol DFCarPlayBridgeAPI <NSObject>
- (void)startWithCompletion:(void (^)(NSError *error))done;
- (void)openApp:(NSString *)bundleID inPane:(NSUInteger)pane
     completion:(void (^)(NSError *error))done;
- (void)setSplitRatio:(CGFloat)ratio;
- (void)swapPanes;
- (void)focusPane:(NSUInteger)pane;
- (void)restoreSplit;
- (void)closePane:(NSUInteger)pane;
- (void)stop;
@end
```
`NSError *` trong callback có thể là null; **mọi thao tác scene phải chạy trên SpringBoard main queue**; dùng async completion để tránh báo mở app thành công khi chỉ có cửa sổ đen. Các selector hệ thống private cần kiểm `respondsToSelector`/OS phiên bản trước khi gọi.

### Phạm vi độc lập / điều kiện xác minh
- **Không cần runtime/binary/trial/licensing** DuoNavi, SidePlay, DuoDash hoặc CarBridge thứ ba; **vẫn phụ thuộc iOS16, CarPlay, jailbreak/rootless, SpringBoard private APIs và những app dùng trong scene.** Private APIs không được Apple hỗ trợ hoặc bảo đảm tương thích.
- API công khai Apple (`CPTemplateApplicationScene`, `CPInterfaceController`, `CPWindow`) chỉ dành cho CarPlay app đủ điều kiện/entitlement; không tự cấp quyền hiển thị YouTube/Waze trong 2 pane của ứng dụng khác. Apple docs: https://developer.apple.com/documentation/carplay/requesting-carplay-entitlements và https://developer.apple.com/documentation/carplay/cptemplateapplicationscene.
- **Đã có code:** `DFIRuntime.m` scene host, `DFCBCompat.m` facade, fullscreen/geometry/layout. **Chưa có:** hợp đồng source `DFCarPlayBridgeAPI` thực thi, adapter UI native Visual12 độc lập với vendor, device test pass (1 app rồi 2 app). Đã từng compile proof nhưng chưa chứng minh runtime trên iPhone X hết trial. Không đè `com.duoface.independent` Native12+Hub8.
