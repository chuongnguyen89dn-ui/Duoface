# DuoFace .67 — học kiến trúc DuoNavi, DuoDash, OmniCar theo bằng chứng, KHÔNG thử mò

**2026-10-26 | Báo cáo phân tích, KHÔNG vá runtime / KHÔNG DEB / KHÔNG test phỏng đoán.**

## Phạm vi & giới hạn

Người dùng yêu cầu **học CÁCH LÀM của DuoNavi, DuoDash và OmniCar rồi mới sửa** giao diện ứng dụng thật trong ô chia DuoFace. Không tạo hàng loạt probe, không chạy thử lặp lại selector từng phiên bản, không bê nguyên mã/giấy phép vendor. User xác nhận DuoFace Sileo `0.0.67~scenediag1`: **logo kéo dọc PASS, giao diện ứng dụng YouTube/70mai/Maps bị bó FAIL**. Bằng chứng đã có 1 SpringBoard `sceneHandle:didUpdateSettingsWithDiff:previousSettings:+440` abort; chưa chỉ ra tác nhân. Giữ logo/ratio/Zoom/Dock/picker/Style/menu đang hoạt động và `.67` Sileo để rollback.

Repo đích **`chuongnguyen89dn-ui/Duoface`**, nhánh `feature/duoface-jb-embedded-appbridge-20261020`. HEAD trước khảo sát `107e2998a71a788181fe3f498ec55d67a8cdfd15`. Repo `Omnicar`, `DauDat-CarPlay` và các nhánh gốc chỉ **đọc tham khảo**, không sửa.

## Phát hiện mới có giá trị: thiếu LỚP PROCESS CỦA APP ở package .67, ngoài lỗi remote-frame

**DuoNavi gốc 1.0.4**: Source đã lưu `sideplay/jb-embedded-appbridge/evidence/REFERENCE_DEB_AUDIT.json` blob `6a9bd0c78af5e454cbfe706c1fc973678e5f10ef`, SHA256 original DEB `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`. Đã đọc lại **literal `DuoNaviDashboard.plist` filter từ bản DEB audit**, gồm SpringBoard, CarPlay, **`com.google.ios.youtube`, `com.google.Maps`, VLC, Netflix và các app iPhone khác**. Như vậy kiến trúc **chuẩn bị inject vào nhiều app process**, không chỉ SpringBoard/CarPlay. Đây là chứng cứ filter/packaging, **KHÔNG phải** bằng chứng hàm nào thực thi trong YouTube hoặc thay kích thước UIWindowScene tại runtime. Gốc có Dashboard Mach-O `CBBridgeManager`/host `CBBridgedUIAppView`; bản Native12 là mẫu cùng dòng nhưng **khác binary** với DuoNavi 1.0.4 (các SHA không được hoán đổi). Audit native104 `sideplay/native104-geometry/audit/original104-geometry-methods.json`, blob `cdd55779ebfda8ca53c581225a419dc80fa22165`, vẫn ghi `method_class_mapping_not_yet_confirmed=true`; không gán các PC HUD8 cho v1.0.4.

**DuoDash 1.1.3**: Báo cáo tĩnh `feature/duoface-exact-payload-migration:audit/duodash-1.1.3/DUODASH_APPBRIDGE_VISUALTEST12_CROSSWALK_20261017.json`, verified blob `fe9560e0ac9b06860efd455ddb40bac12c8f0404`, chỉ dùng bản **1.1.3 Fullscreen427 REPACK** của `DauDat-CarPlay`, không byte-identical với stock original `16ffab22...`. Đường lớp đã inventored: SpringBoard `CNABSpringBoardObserver.onHostRequest:[Split:]` → host `DDz2.cnabBuildSceneHostForBid:displaySize:` (có `SBDeviceApplicationSceneEntity`) → **app-process component** `CNABUIApp.setBridgeState:width:height:orientation:` → CarPlay UI `DDz1.showLayoutPanes:natives:bids:`. Signals `com.sensetechlab.appbridge.host.request`, `...request.split`, `...uiapp.state`. **Sự xuất hiện của app-process callback + truyền width/height/orientation là chứng cứ hợp đồng nhiều process tồn tại, KHÔNG chứng minh exact window/trait mutator, renderer ACK hoặc video UI pixel-match.** Không port namespace/DDz/dylib, không thử chạy hai scene hosts.

**OmniCar original 1.0.3**: SHA256 DEB `d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd`; stored original ARM64 proof ở `audit/OmniCar_AppBridge_exact_scene_settings_and_layout_20261023.md` (Omnicar blob `65fe107ccf8cdbc9dfbccc9b3f93f73bf006ddef`) và `audit/omnicar_original_scene_settings_block_20261023.json` (blob `155be3a9923151839be957d3d07ce6266845abe9`). `SCPCarSplit` thông báo geometry cho `ABHost.setFrame:forApp:live:handle:passInsets:`; `ABHost.layoutPane:` `0xec80`: tại `ed74..ed9c` frame logic = round(bounds/zoom), `edac..eddc` đặt scale/căn giữa, `f074` lưu `sceneBox` là **physical pane bounds**, `ef08` lấy `sceneHandle` → `ef60` `sceneIfExists` → `f048` `updateSettingsWithBlock:`; invoke `f210` `f248` ghi **actual scene settings.frame**, `f280` set interface orientation, `f2b8/f30c` set background/foreground policy. Đây là host-side scene transaction **đã có byte/selector/dataflow**, không phải chỉ phóng UIKit. Wrapper `SBSceneView._updateReferenceSize:andOrientation:` `0x7764` chỉ clamp giá trị orientation-like, **không** tính kích thước video; QA13–15 device FAIL, không port chúng.

**DuoFace independent .67**: Đã mở source `DFSceneHost.m` blob `e5a3ecdf32860ef0717b345ba750bccc5a65c39f` và exact signed `.67` provenance `sideplay/jb-embedded-appbridge/evidence/runs/40275876374/PACKAGING_PROVENANCE.json`, blob `79793ab7ef81e718e6b836f5abb2f2c88150f728`. 4 module merged + native host; **30 payload paths**. Đã fetch filter plist cho **đúng bốn dylib**:
- `sideplay/mytweak-independent-v1a/DFV1APreflight.plist` blob `2d285abac4b17b9c2e1337e39de7d3fc8c6903c8`: SpringBoard bundle only.
- `sideplay/mytweak-native-bridgeqa/DFNativeDashboardBridgeQA.plist` blob `66d117561c23ff558815b281172bf38639192399`: SpringBoard, CarPlay, CarPlayApp executables.
- `sideplay/firstparty-carplay-admission/DFFirstPartyAdmission.plist` blob `834002b8a8518cb426e23c719765a2e25729e78f`: SpringBoard/CarPlay executables.
- `sideplay/duoface-native-scene-host/DFTouchOwnerProbe.plist` blob `22cdeacd16d5fd245613c21726d6938f9be91967`: SpringBoard bundle/executable.
- `sideplay/duoface-native-scene-host/DFCarPlayDockOwner.plist` blob `6c8c39cbd283bfc947568b1032f2cefad3e8882f`: CarPlay/CarPlayApp/Dashboard executables.

**PRECISION:** Package `.67` **không chứa bất kỳ DuoFace dylib có filter explicit dành cho bundle YouTube/Maps/70mai**. Nên không thể nói nó đã có cơ chế app-process adaptation giống DuoDash/DuoNavi. Đây là kết luận từ **danh sách FILES và plists**, không chứng minh app process chắc chắn cần tweak để reflow; host-only OmniCar cũng gửi real FBScene update được. Việc “thiếu app injection” là **khác biệt kiến trúc đã xác minh**, còn **đây có phải nguyên nhân quyết định UI bị bó hay không vẫn là giả thuyết**.

## Sơ đồ ownership, học cái gì chứ không copy gì

| Hệ thống | Nguồn bundle/slot | Scene host owner | Điều chỉnh remote geometry | App-process side | Bài học có bằng chứng |
| --- | --- | --- | --- | --- | --- |
| DuoNavi 1.0.4 | `CBBridgeManager`/geometry khác bản HUD8 | Dashboard/SpringBoard bridge | Native12 HUD8 riêng chứng minh live `updateSceneSettingsFrame`; native104 chưa map chính xác | **Có filter app bundles** kể cả YouTube (hành vi cụ thể chưa chứng minh) | Không đồng nhất outer pane với app viewport, phải biết quyền sở hữu ở cả host/app |
| DuoDash 1.1.3 repacked | Observer request/split | `DDz2` app scene entity | Exact settings-frame function **chưa giải mã** | **`CNABUIApp.setBridgeState:width:height:orientation:`** | Cần width/height/orientation contract xuyên process và phân vai rõ, không chỉ nút enable |
| OmniCar 1.0.3 | `SCPCarSplit` frame + passInsets | `ABHost` AppBridge | `layoutPane` + real `FBScene.updateSettingsWithBlock` | Không khẳng định app-side component từ dữ liệu này | Geometry physical, logical, sceneBox và orientation là các state khác nhau |
| DuoFace .67 | `DFLayoutEngine` + `DFNative12Chrome` | `DFSceneHost`/SpringBoard | Local UIView + 3-arg reference dispatch **nhưng không live FBScene frame/readback** | **Không có dylib filter cho video-app bundle trong .67 payload** | Thiếu proof remote state & không có app-side bridge contract theo hai đối chứng |

## Chứng cứ lỗi nối hàm .67 cụ thể

- `DFNative12Chrome.m:1058–1062,1164–1194`: layout vùng vật lý/one shared UIWindow đúng; `DFSceneHost.m:214–258`: appController UIView `round(2×pane)` + transform; thay local frame không có nghĩa app window nhận new coordinateSpace.
- `DFSceneHost.m:259–383`: send child3 `setContentReferenceSize:withContentOrientation:andContainerOrientation:` cho stable scene rồi `committedReferenceSize=size` tại dòng 370, không đọc `FBScene.settings.frame` hay app `UIWindowScene.bounds`, không có renderer ACK. Điều kiện same-size dòng 265 có thể bỏ qua sự lệch này.
- `DFSceneHost.m:385–503`: code scene frame setter nằm SAU return của `if(self.ready)`; live path không chạy. Đừng chỉ xóa return và mở `updateSettingsWithBlock`: crash `sceneHandle:didUpdateSettingsWithDiff:+440` là rủi ro chưa giải.
- So `CBBridgedUIAppView.refreshSceneLayout` original HUD8 PC `0xade74 updateLayout → 0xade84 updateSceneSettingsFrame → 0xadedc setNeedsLayout → 0xadf08 layoutIfNeeded`, original block `0xadc74` có set actual scene frame, thì `.67` đang thiếu **một tầng update remote**, không phải cần copy giao diện YouTube.

## Kết luận thiết kế đúng, không chơi thử

**Không có cơ sở để chuyển ngay sang app-injection trên mọi ứng dụng**: trục trặc có thể khắc phục bằng host-owned settings transaction kiểu OmniCar; ghi đè traits trong app-process có thể làm crash, DRM hoặc break Maps. Cũng **không có cơ sở** cho việc chỉ xóa return `.67` rồi bật tất cả private setters của HUD8 vì đã có SIGABRT và thiếu teardown. Giữ `.67` nguyên vẹn.

Chốt hai tầng trong **cùng hợp đồng first-party**:
1. **Cơ chế lý thuyết chắc chắn:** `DFAppViewportPolicy` do DuoFace viết, lấy `{bundleID, physicalSlot, focus, preset, paneRect, dockUsable, sessionGeneration}`, tính `desiredNativeRect`, reference size, orientation policy; không hardcode every app Landscape hay coi `CGSize=2×slot` là mọi state. **Một writer** ở `DFSceneHost`, xử lý `desired → requested → readback → accepted` cho exact hosted scene; drag tick chỉ transform local, transaction khi drag kết thúc/Zoom ổn định, cancel khi Close/Swap/scene replacement.
2. **Gate quyết định host-only vs app-side:** phải phân tích **đúng bản original** app-process DuoNavi/DuoDash bên app như thế nào; filter + setter name chưa đủ chứng minh thực thi traits. Nếu host readback đã đủ mà UI vẫn portrait, mới xét adapter app process **allowlist + fail-closed + no global hook** như một cơ chế *riêng*; không triển khai hai con đường đồng thời.

### KHÔNG LÀM (theo yêu cầu)
- Không lập bản build/log/tracer lẻ để đoán; không thêm menu, không đổi icon/zoom/logo/timer; không bật setter thử từng ngày; không thử các orientation 1..4 không có logic.
- Không gọi completion chỉ vì selector returned, test static PASS, hay static plist cho thấy `com.google.ios.youtube`.
- Không test điện thoại/xe khi chưa có **thay đổi kỹ thuật có cơ sở, tiêu chí quan sát đầu ra và rollback**. Tình trạng **hôm nay**: phân tích dữ liệu có sẵn, không thử máy.

### Điểm tiếp tục chính xác
Đọc tiếp **một luồng còn thiếu** có ý nghĩa quyết định trong archive: (a) `DuoDash CNABUIApp.setBridgeState:width:height:orientation:` thật sự tác động ở app process hay chỉ notify UI, (b) DuoNavi 1.0.4 app-bundle injected branch có sửa `UIWindowScene`/traits/remote frame hay chỉ media policy. **Chỉ khi có machine-code/dataflow owner + ABI chứng minh và matching iOS16**, mới chọn host-only owned scene transaction hoặc app-process companion. Không cần lấy lại log cũ của logo, không cần quét API linh tinh; source/DEB hiện có, dùng đúng bản, không chạy dò vô nghĩa. Nếu original binary không thể truy cập byte từ GitHub tool (binary connector UTF-8), ghi giới hạn, không khẳng định giải mã. Mọi kết quả lưu trong repo **Duoface**.

**Skill source** `chuongnguyen89dn-ui/Gpt-training-/SKILL_INDEX.md` và `DEB_IPA_SKILL.md`, `AGENTS.md` đã đọc; ZIP 02/05 được định vị nhưng connector binary `fetch_blob` từng lỗi UnicodeDecodeError, không nhận là đọc ZIP. Không có source/device/DEB/Sileo change.
