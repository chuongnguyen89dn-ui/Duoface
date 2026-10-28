# DuoFace .82 — đối chiếu các DEB tham chiếu và hợp đồng scene theo từng tầng (28/10/2026)

**Phạm vi:** READ-ONLY, ưu tiên **crash SpringBoard lúc mở/phát YouTube/Facebook/TikTok**. Không sửa UI, Dock, Zoom, logo, viewport; không cấy mã/nhị phân/license của dự án khác, không tự xây DEB mới. Không lặp lại .37 rollback. Đầu mối bàn giao là `sideplay/tiep tuc du an.md`.

## 1. Kiểm kê cấp repo, PHÂN BIỆT archive với số DEB gốc

- Đọc Git tree recursive **không truncated** tại tree `25a47517d0e8a8304c8100588eb964da30cb60cc` của DuoFace branch sau checkpoint `6bd422ec`. Có **2.710 entries và 881 file *.deb**. **881 không phải 881 binary/phiên bản gốc khác nhau**: phần lớn lặp lại các DEB lịch sử theo `evidence/runs/*`, các ứng viên nội bộ, QA và gói addon. Lượt này **không** khẳng định mở giải nén/kiểm SHA của toàn bộ 881 file.
- Các DEB trực tiếp liên quan, với byte/ARM64 audit **đã được CI trước đây kiểm tra**:

| Vai trò | DEB chính | Cơ sở xác minh trước đây | Giới hạn |
|---|---|---|---|
| **Native12 HUD8 reference** | `dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb` tại commit `1286a3ef...`; SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad` | `TRANSACTION_ARM64.json`, `HOOKS_AND_ARM64.json`, Dashboard dylib SHA256 `9e02a4bc...` | SHA áp dụng đúng bản Native12 này; không nói tất cả bản Native12 |
| **SidePlay original 1.0.4-1** | `com.sideplay_1.0.4-1_iphoneos-arm64.deb`, SHA256 `7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c` | `sideplay/audit/deb-1.0.4-1/summary.json` — 136 rootfs files, 7 Mach-O; `sideplay/native12-display/audit/SIDEPLAY_SCENE_FRAME_ARM64_CALLS_20261026.json` | Chỉ 4 IMP scene/frame đã đọc sâu; không có bằng chứng global lifecycle hook tương đương Native12 |
| **OmniCar original 1.0.3** | Repo `chuongnguyen89dn-ui/Omnicar/com.anlai.omnicar_1.0.3_iphoneos-arm64.deb`, SHA256 `d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd` | `Omnicar/audit/OmniCar_AppBridge_exact_scene_settings_and_layout_20261023.md` — CI `39929982072` | Có bản gốc và disasm layout/scene block nhưng chưa có **toàn bộ** callback lifecycle/observer |
| **DuoDash 1.1.3 Fullscreen427** | **REPACK, không phải stock**, SHA256 `ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465` | `sideplay/audit/duodash-duonavi-media-20261027/ORIGINAL_DUONAVI_VS_DUODASH_REPACK_IMP.json` — CI `40445716116` | Chọn lọc 5 IMP liên quan; không suy rộng sang bản DuoDash stock |
| **DuoNavi original 1.0.4** | `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb`, SHA256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd` | Cùng CI `40445716116`; 12 IMP mục tiêu | Mẫu lịch sử, không phải hướng phụ thuộc/license |
| **CarBridge official** | **Chưa có bytes chính hãng được xác minh** | `sideplay/audit/bridge-ui-scene-lifecycle-20261027/CARBRIDGE_OFFICIAL_DEB_PROVENANCE_BLOCKER_20261027.md` | Không được gọi DuoNavi là CarBridge official; **không phải blocker** của DuoFace |

- **DuoFace bản do dự án build:** .37 DEB `sideplay/jb-embedded-appbridge/evidence/runs/39748923126/` (SHA `2b6f274e...`, user từng phát YouTube nhưng xoay sai, chưa full PASS); .74 `40435764417` (đã giảm bó player nhưng crash), .77 `40447121107` (Live/foreground inconsistency), .80 `40497436374` (SpringBoard SIGABRT), .81 `40512981348` (user báo crash), .82 `40584794269` (SIGTRAP thiết bị có 3 IPS). Không được xem bản build xanh là chứng cứ CarPlay PASS.

## 2. Bao phủ bằng binary: vì sao lần scan 1385 ObjC method vẫn bỏ sót chỗ crash

Audit `sideplay/audit/native12-vs-new-20261021/results-0.0.81/SUMMARY.json` từ **chính .81 DEB**: Native12 có **43 rootfs files, 8 Mach-O, 66 classes, 1385 ObjC methods / 1003 selectors**; .81 có **30 files, 6 Mach-O**, 306 selector text trùng. 25 strict *full functional parity* gates đều **chưa được chứng minh** — `0/25` KHÔNG có nghĩa là 25 tính năng đều không hoạt động. Ví dụ UI/4 cửa sổ đã có trong nguồn .81. Đây là mức kiểm toán, không phải thống kê crash.

Quan trọng hơn: bản `1385 ObjC methods` **không bao phủ C/static constructor và các replacement IMP hook**. Native12 riêng initializer `0x2c7c54` đã có **11 đăng ký MSHookMessageEx**, trong đó 10 call và một tail call. Những tuyến bị bỏ qua trong cách đếm cũ chính là các tầng transaction/observer ở đầu crash.

## 3. Đối chiếu **toàn bộ 11 hook** đã giải mã trực tiếp trong Native12 Dashboard

Bằng chứng ARM64: `sideplay/audit/native12-082-transaction-20261028/TRANSACTION_ARM64.json`, Dashboard SHA `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`. Kiểm trên mã first-party `DFSceneHost.m`, `DFSceneLifecycle.m`, `DFTouchOwnerProbe.m`, `DFCarPlayDockOwner.m`, `DFNativeHostAppDelegate.m`, `DFNative12Chrome.m`, `DFAppViewportRelay.m` tại blob HEAD nhánh. **Cột DuoFace chỉ kết luận phạm vi module đã tra, không thay thế audit mọi private runtime hook trên toàn máy.**

| # | Hook original class / selector | Replacement | DuoFace .82: khả năng tương ứng | Mức liên quan crash |
|---|---|---|---|---|
| 1 | FBScene `updateSettings:withTransitionContext:completion:` | `0x2c7e08` | **Có** trong `DFSceneLifecycle.m`, nhưng chỉ `mutableCopy` khi owned foreground=NO, khác original giữ/mutate incoming object | Cao; trực tiếp trong cả 3 stack |
| 2 | FBScene `_applyUpdateWithContext:completion:` | `0x2c8410` | **Không có** ở lifecycle source; original chỉnh `context.settings` trước previous IMP `0x2c8540` | Cao; final internal transaction **chưa có ACK** |
| 3 | `_UIScenePresentationView scene:didPrepareUpdateWithContext:` | `0x2c85d0` | Không có callback tương ứng ở lifecycle source; original gọi previous trước rồi `_updateFrameAndTransform` | Chưa chứng minh cho SIGTRAP |
| 4 | SBSuspendedUnderLockManager `interceptUpdateForScene:withNewSettings:` | `0x2c8668` | Không có hook tương ứng trong mã 7 module xét | Chưa có evidence lock trên stack |
| 5 | SBSuspendedUnderLockManager `_shouldBeBackgroundUnderLockForScene:withSettings:` | `0x2c8768` | Không có hook tương ứng trong 7 module | Chưa có evidence lock |
| 6 | SBSuspendedUnderLockManager `shouldBeUnderLockForScene:` | `0x2c8870` | Không có hook tương ứng trong 7 module | Chưa có evidence lock |
| 7 | SBDeviceApplicationSceneViewController `setContentReferenceSize:withInterfaceOrientation:` | `0x2c895c` | `DFSceneHost.m:265-286` **gọi** selector theo availability; **không** thay thế IMP global | Có thể liên quan render/rotation, không được gán SIGTRAP |
| 8 | SBDeviceApplicationSceneViewController `setContentReferenceSize:withContentOrientation:andContainerOrientation:` | `0x2c8a50` | `DFSceneHost.m:266-281` gọi guarded child selector; không hook toàn cục | Có thể liên quan render |
| 9 | SBDeviceApplicationSceneHandle `_mainSceneSupportsInterfaceOrientation:` | `0x2c8b4c` | Không có tương ứng trong 7 module | Có thể liên quan orientation, không có trace trap |
| 10 | SBAppViewController `sceneHandle:didUpdateSettingsWithDiff:previousSettings:` | `0x2c8ca8` | **Không có scoped observer adapter**; `DFSceneHost.m:156` đã đặt `automatesLifecycle:NO` nhưng OS observer vẫn nhận callback | **Rất cao: exact faulting method +720** |
| 11 | SBAppViewController `sceneHandle:didDestroyScene:` | `0x2c8ef8` | `DFSceneHost.m:507-540` có unregister + mode0/cleanup nhưng không có callback destroy/replacement scoped | Quan trọng với close/replace; chưa chứng minh là opening trap |

**Không port 11 hook.** Original có policy manager/under-lock và hosted-markers riêng; mục tiêu độc lập là xác định invariant và tạo owner/transaction adapter first-party an toàn. Hook under-lock toàn cục có thể gây lỗi mới.

## 4. Đối chiếu luồng 5 kiến trúc thực tế thay vì chỉ đếm method

1. **Native12:** `CBBridgedUIAppView` quản lý start/hosting/Live, public FBScene update **và** internal `context.settings`, targeted observer/scene destruction + prepare, focus/audio-only/refresh split owner. Các marker hosted gốc được **consumer** tại observer đọc, không phải nhãn tùy ý. Cần hiểu hợp đồng, không sao chép marker hay semantics vendor.
2. **OmniCar original:** `ABHost.layoutPane:` tách pane vật lý ↔ logical view, sceneBox; block `0xf210` cập nhật frame + orientation + `setBackgrounded:NO` + `setForeground:YES` (source `Omnicar/audit/OmniCar_AppBridge_exact_scene_settings_and_layout_20261023.md`). Bằng chứng chỉ host layout/settings, **chưa** chứng minh observer policy.
3. **DuoDash REPACK:** `onHostRequest` / `onHostRequestSplit` → `DDz2.cnabBuildSceneHostForBid:displaySize:` tạo real SBAppViewController mode2; **CNABUIApp** consumer `setBridgeState:width:height:orientation:` có ON/OFF, tách app-process. Chưa có callback-trap parity chứng minh.
4. **SidePlay original:** `SPPane.layoutInFrame:scaleMode:` → `applySceneFrame:` / `restoreSceneFrame` → `setSceneFrame:orientation:`; giữ `sceneFrameChanged` để hạn chế stale restore. Chưa có bằng chứng nó dùng targeted SBAppViewController observer giống Native12.
5. **DuoNavi original:** `CBBridgeManager.renderSizeForBundleID:` + `CBBridgedSplitApp.layoutSplitViews` nối `setAudioOnlyBackgroundMode:`, `refreshSceneLayout` và scene update; quản lý focus/audio/layout hợp đồng rộng hơn frame-only. **Không** yêu cầu tái tích hợp giấy phép hoặc gói gốc.

Điểm chung có căn cứ: các bản tham khảo quản lý **nhiều tầng owner/scene/settings**, không đơn thuần `UIView.frame` hoặc 4 `UIWindow`. Không đủ chứng cứ để kết luận một trong 5 gói **không bao giờ** crash.

## 5. Quan hệ nhân quả mới từ chính log và IPS .82 — trọng điểm không còn là chỉnh UI

Nguồn upload main `06dee0402cc4bdebcec41992f10797c0d04fc7bf`: `sideplay/log/DuoFaceAudit 6.txt` + 3 IPS .82. Đều iOS 16.7.16, SIGTRAP tại `SBAppViewController sceneHandle:didUpdateSettingsWithDiff:previousSettings:+720` (SpringBoard +625280):

| PID | `scene-attached` foreground | `corrected-copy=1` trên cùng scene | Crash capture | Kết luận |
|---|---|---|---|---|
| 66091 | 1, scene `0x282c9a880` | 07:39:09.810386 +07 | 07:39:14.2582 +07 | sửa đề xuất không ngăn crash |
| 66107 | 1, scene `0x282062a00` | 07:39:49.748221 +07 | 07:39:50.8870 +07 | tương tự |
| 66125 | 1, scene `0x281521140` | 07:40:26.029433 +07 | 07:40:28.6428 +07 | tương tự |

Trong cả ba IPS, đường gọi **trực tiếp** là:
`SBWorkspaceKeyboardFocusController._moveKeyboardFocusDeferringEnvironmentSceneSettingFromScene:toScene:target:newSceneIsSB:activeDisplayChanging:` → `FBScene(UIApp).updateUISettingsWithBlock:` → `FBScene.updateSettingsWithBlock:` → **DuoFace `DFUpdateScene`** → **`AppData.dylib` `ImmortalizerHooks` cùng selector** → Apple `FBScene updateSettings...` → Apple `SBAppViewController` observer `+720` → SIGTRAP.

**Mới khẳng định được**: (i) tác nhân tạo *lượt giao dịch* ở call stack là SpringBoard keyboard/focus; không phải `DFSceneSurface.commitSceneGeometry:`, (ii) .82 can thiệp vào transaction này và gọi tiếp chuỗi hook của AppData, (iii) foreground copy log đã thực thi. **Không xác định được** từ IPS ai đã *đầu tiên* tạo foreground NO, AppData có đổi settings tiếp hay không, giá trị `context.settings` sau apply, hoặc điều kiện BRK +720 là foreground/occlusion/scene state gì. `AppData.dylib` cũng hiện diện trong ảnh `.80`, không được gán toàn bộ lỗi cho .82 hoặc AppData chỉ vì có tên.

**Giả thuyết cụ thể có thể bác bỏ:**
- H1: `automatesLifecycle:NO` nhưng callback Apple observer đi nguyên đường gây xung đột state khi focus-driven scene update. So Native12 observer `0x2c8ca8` có nhánh hosted/manual lifecycle riêng, trong khi .82 không có. Mức ưu tiên P0 nhưng **+720 chưa disasm**.
- H2: Chỉ đổi foreground bit trên bản `mutableCopy` mà không theo dõi committed internal settings/occluded/backgrounded/deactivation state khiến tuple scene thiếu đồng bộ; original có biên `_applyUpdateWithContext:` thứ hai. Phải có readback trước khi kết luận.
- H3: Chuỗi liên tiếp các interceptor `DFUpdateScene` → `ImmortalizerHooks` làm thay đổi settings/hook order. Cần test A/B **chỉ** disable AppData SpringBoard injection và khôi phục trên thiết bị do chủ sở hữu kiểm soát, không được tự đổ lỗi.
- H4: `DFSceneHost.m:441` snapshot `sceneSettingsBefore` nhưng `stop` tại :536 chỉ log `close-no-private-settings-restore`; có thể ảnh hưởng reconnect/replace, **không** là bằng chứng opening trap.

**Lỗi độc lập:** PID66027 ChatGPT `scene-failed ... bogus reference size` sau tạo host. Không lấy lỗi admission/size này để sửa UI/video của các app đang chạy hoặc kết luận là nguyên nhân YouTube SIGTRAP.

## 6. Tiêu chuẩn kết luận root cause và điểm tiếp tục

1. Lấy Apple **SpringBoard iOS 16.7.16** đúng UUID `22034ABA-9A9A-3B94-93A5-A0DE02BEFD2E`, đọc instruction tại image offset 625280 / observer +720 hoặc đủ assertion message để định danh chính xác invariant. **IPS hiện tại chỉ có PC/trap; không chứa bytes/điều kiện**.
2. Đọc **trước/sau** public update, `context.settings` internal apply và observer callback (controller, handle, scene pointer, generation, `automatesLifecycle`, foreground/backgrounded/occluded, focus state). Không swallow exception, không `return` toàn cục, không mutate foreign scenes, không sửa visual.
3. So sánh trace với A/B AppData injection (nếu chủ máy cho thử) và YouTube open → play → close/replace. Xác minh callback ownership và teardown đúng khi scene được thay và ứng dụng khác xuất hiện.
4. **Chỉ sau khi có bằng chứng định danh invariant** mới quyết định first-party state/observer adapter và phát hành candidate; xác minh source static, build, signed DEB, Sileo và thiết bị **tách biệt**.

### Provenance lượt này

- GitHub branch `feature/duoface-jb-embedded-appbridge-20261020`, handoff trước `6bd422ecfb8e23512e0d692b4bb66b33fe75f75f`.
- Truy vấn GitHub code/tree, đọc source HEAD, báo cáo ARM64 đã persist, `0.0.81` static full inventory, OmniCar original audit và .82 log/IPS đã đọc ở checkpoint trước. Không re-extract tất cả 881 DEB; không chạy scripts vendor; chưa có iPhone trực tiếp; không chạy DEB build.
- Central ZIP skills `02-ios-deb-ipa-carplay.zip` và `05-research-debug-testing.zip` được xác minh có blob/base64 trên GitHub nhưng **chưa mở nội dung ZIP** do không có giải nén binary liên công cụ trong phiên này. Markdown fallback `DEB_IPA_SKILL.md`, `AGENTS.md`, `PROJECT_INSTRUCTIONS.md`, `SKILL_INDEX.md` đã đọc và áp dụng.
