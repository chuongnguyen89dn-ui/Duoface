# Kết luận kiểm toán toàn diện giao diện/chức năng Native12 HUD8 ↔ DuoFace .91 — 2026-10-28

**TRẠNG THÁI: FORENSIC READ-ONLY, không sửa runtime/không build DEB mới/không test xe.** Repo chuongnguyen89dn-ui/Duoface, branch feature/duoface-jb-embedded-appbridge-20261020. Kết quả quét nhị phân MỚI từ GitHub Actions run [40696267785](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40696267785), job 122843732296 SUCCESS, dữ liệu đã commit [33a3c3f9e97cd0e3cb36c352b6746547a4b46380](https://github.com/chuongnguyen89dn-ui/Duoface/commit/33a3c3f9e97cd0e3cb36c352b6746547a4b46380).

## 1. Phạm vi đã xác minh

- Original SHA-pinned Native12+HUD8 DEB: commit 1286a3ef868cf7e29804bcddf7e20b2eae707ce1, SHA256 2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad. iOS ABI index Git blob efa45df59bc3c16887cc979bf3aedc0c93c92111.
- DuoFace signed .91 exact file: sideplay/jb-embedded-appbridge/evidence/runs/40689380992/com.duoface.jb.embedded_0.0.91~nativemapqa1_iphoneos-arm64.deb, SHA256 e15b9b2c2da351a64a125f5057c6c6e0f6d44aefbcc73de8fe023b6c4d5ab741, source commit 4dba11e1a95e237f966b44292b9b486a837a8f90.
- CI đã chạy dpkg-deb extract cả hai, kiểm checksum, plist, Mach-O, danh sách byte của TẤT CẢ file, mapping 1385 original ObjC methods/IMP/type encoding với strings trong binary mới, và quét 18 source module.
- Original: 43 files, 8 Mach-O, 66 classes, 1385 ObjC methods, 1003 unique selectors. DuoFace .91: 34 files, 8 Mach-O. 309/1385 original selector names present as strings trong candidate, 13 basename byte-identical. **309 không phải tỷ lệ chức năng đã nối**, cùng tên selector không chứng minh callback. 
- **25/25 gate đều ghi KHÔNG ĐẠT vì scanner CỐ ĐỊNH full_functional_parity_proven=false**, tức KHÔNG ĐỦ CHỨNG CỨ tương đương runtime, KHÔNG PHẢI 25 chức năng đều thiếu hoặc hỏng. Full ObjC method inventory cũng không bao hết C/blocks/indirect calls; audit lịch sử còn 1087 optimized objc stub callsites uncertain. Không kiểm pixel/CarPlay device.

## 2. Giao diện và chức năng – đối chiếu 25 nhóm (original → độc lập .91)

| # | Nhóm | Có thực trong .91 | Khoảng thiếu/chưa nghiệm thu |
|---|---|---|---|
| 01 | Native CarPlay admission/Dock | DFFirstPartyAdmission, CarPlay SceneDelegate, DFCarPlayDockOwner | Native app route từ picker/slot chưa nối |
| 02 | Logo splash/loading animation | DFNative12Chrome.start splash UIWindow & logo line | Exact original timing/teardown chưa kiểm xe |
| 03 | OUTER App/Zoom/Style/Close + INNER Apps/Layout/Recent | DFNative12Chrome.menuAction; DFAppPickerVC | Pixel/hover/hitboxes/translation chưa proven |
| 04 | Real App cards, icon/badge/pages | UICollectionView, DFAppLibrary, state badges, paging | bridgedApps/categoryRank, gridCols4–6/gridRows, hideIconLabels, Add More action chưa đủ |
| 05 | Running/Recent/Close/Restart/Close All | Live DFSceneHost owned IDs và các hành động | PID/background/OS process termination ≠ original |
| 06 | Phone app live scene hosting | DFSceneHost, DFSceneLifecycle | Device testing các app chưa đủ |
| 07 | YouTube/video orientation/host app reflow | DFYouTubeOrientationRelay/Virtualization, SceneHost | .90 user-confirmed xoay đúng; .91 video device test chưa có |
| 08 | 1–4 pane splits, ratio, double-divider | DFLayoutEngine preset 0–8, dividerPan/secondaryDividerPan | 3/4 app real-scene geometry chưa device PASS |
| 09 | Swap/focus/close and original move/rotate | swapPressed, zoomPressed, closeHostedSlot | Không thấy nối đầy đủ rotateAllSlotsClockwise/moveSlot:direction: và edge-to-solo |
| 10 | Logo hold + move | logoTouchDown/Changed/Finished nhận axis drag tức thời | **THIẾU GATE GIỮ 3 GIÂY** theo yêu cầu user; restore/tap chống swap nhầm cần test |
| 11 | Hai pill/ô, 6 states, 4s show/hide | pillPressed, layoutControls, DFNativeActivityObserver | Ảnh/gesture từng trạng thái chưa device PASS |
| 12 | Viền đỏ khi thao tác | noteUserActivity/activity border code | Chưa đối chiếu alpha/fade/teardown thực |
| 13 | SOLO và khôi phục lại split | Focus/Restore handlers, 9-layout engine | Native Maps mode/hidden pane và các nhánh race chưa test |
| 14 | Style 9 card mini previews | DFNative12PresetPreview + selectStylePreset | Exact original raster/real four scene chưa pixel PASS |
| 15 | Whole-host Zoom hide system Dock / restore | DFDockZoomCoordinator + DFCarPlayDockOwner ACK | .91 device full screen + Dock/native z-order chưa proof |
| 16 | Persist selected apps in physical slots | DFCSaveLayout stores ratio, secondary, logoFraction, swapped, preset | **KHÔNG lưu bundleIDs per slot / restored selection khi reconnect** |
| 17 | Home/reconnect/scene invalidation | DFTouchOwnerProbe watchdog + DFSceneLifecycle / stop | Chưa device regression cho rapid Home/media |
| 18 | App geometry/scene size | DFSceneHost phone commitSceneGeometry | Native Map FBScene push sizes/readback missing |
| 19 | Native Map in a DuoFace visual pane | CarPlay-native DFNativeMapPaneCoordinator & guarded adapter | **P0:** reparent vào Dashboard root CarPlay; physical DuoFace panes dùng SpringBoard windows, không có native compositor cross-process route |
| 20 | Maps remains enabled in Customize with navigation | .91 opt-in UI, native same-process adopt | Tiles/live route/Home continuity NOT verified; one VC can rebind |
| 21 | HUD8 live speed/limit from GOFA, Google Maps, Vietmap, Waze | speed8/DFNative8SpeedHUDView.mm source exists | **KHÔNG CÓ HUD dylib trong 34-file .91 payload**; four feed functionality not proven |
| 22 | Assistant speech/audio/map/music/app launch | Original CBAssistantManager 69 selector | Chưa có first-party equivalent state machine in .91 package |
| 23 | General iPhone settings and Apps Manager | DFNativeHostRootController tabs + diagnostics/layout/map QA | Missing multi-app enable/bulk, category, autoLaunch, screenBlank, hideLabels, dockMonitor, map preference, voiceFeedback, localization |
| 24 | Native CarPlay vs phone app dispatch | Separate DFSceneHost phone route and map-only opt-in | **P0:** native vs phone classification not wired to shared app picker/state |
| 25 | Logs/build/sign/device gate | .91 signed Sileo; source+package current | Map pane log not exported by iPhone existing log exporter; no .91 real map/photo/device FULL acceptance |

### Original verified UI method anchors

- Original CBMultitaskingOverlayView.initWithFrame: @0xa0420 (material/card), setupCardContent @0xa2a58 (3 inner tabs), loadInstalledApps @0xa0c48, setupAppPickerCards… @0xa3e5c, appSelected: @0xa9ea8, pageControlChanged: @0xa5de4; 9 preset preview renderer 0x9efe0.
- CBBridgedSplitApp.layoutSplitViews @0x1044f8, handleDividerPan:isVertical:state: @0x103ee0, focusSlot:animated: @0x105890; CBWindow.carPlayUsableBounds @0xb0ef4, resizeWindows @0xb1aac.
- Original CBSplitSplashScreenView.startLoadingAnimation, DFFullscreenTransport, CBAssistantManager, DuoFaceSpeedHUD + SpeedOwner.
- Original OmniCar native-map comparison: SCPCarSplit.isCarPlayApp: @0xff20, adopt:slot: @0x1942c, paneSize:forBundle: @0x1b328, pushSceneSizes @0x1c550, scene:destroyedForViewController:ownScene: @0x1ad58. **Static original ARM64 method evidence, not license/source copied.**

### Code-level decisive native Maps problem

- sideplay/native-carplay-scene-v1/DFNativeMapPaneCoordinator.m lines ~217–242 creates target pane in DBDashboardRootViewController root.view (CarPlayApp) and reparents its native DBApplicationSceneViewController; ACK says native-controller-attached-visual-not-yet-device-verified.
- sideplay/duoface-native-scene-host/DFNative12Chrome.m lines ~378–864 creates app slot UIWindows on SpringBoard; DFSceneHost app scenes render there. There is **no wired native scene-to-DuoFace-physical-window bridge**. Thus ACK TRUE does **not** mean native Maps is visible next to YouTube.
- sideplay/native-carplay-scene-v1/DFCarPlayNativeMapViewportPlan.h returns nativeMapSlotAssigned NO, mapSceneSizedForPane NO, canAttachPane NO. Coordinator uses geometry for preflight, not successful native scene sizing.
- sideplay/duoface-native-scene-host/DFNative12Chrome.m DFCSaveLayout lines ~76–83 explicitly saves no app bundle IDs. logoTouchDown/Changed/Finished lines ~1642–1660 confirms drag immediate, no 3s hold condition.
- sideplay/duoface-native-scene-host/DFNativeHostRootController.m supplies map experiment panel but map-pane log export remains absent.

## 3. Why original source connections were incomplete

UI widget recreation and assets were joined independently first, while original host-ownership/callback/IPC/foreground-to-application and app settings were not completely ported. Visual similarity alone cannot establish functional parity. Original license checks are coupled with CBBridgeManager initialization/state change; do not import or bypass vendor license. An independent CarPlay app host must reproduce only verified behavior with its own lifecycle and handoff.

## 4. Required next order

1. P0 validate parked vehicle .91 native ACK + real tiles/head-unit photo, Maps owner FBScene hierarchy/window and side-by-side YouTube; if native map fails, stop guessing zoom/frame. Do not steal or clone CPWindow.
2. P0 prove native vs phone owner and make native-scene-to-real-DuoFace-pane compositor boundary, scene sizes readback, generation/teardown/restore; preserve proven .90 YouTube host/rotation.
3. P1 restore per-slot bundle IDs, 9 real layout scenarios, App/Style/Close/Recent semantics, logo 3s and 4s timer, device split/SOLO/Dock/Home/reconnect test.
4. P2 HUD8, first-party assistant and iPhone settings, only if safely authorized scope. Leave vendor license/subscription out.
5. Source tests → signed immutable DEB → Sileo → real device validation; no DEB merely for read-only audit.

## 5. Persisted exact evidence

- sideplay/audit/native12-091-fullscan-20261028/runs/40696267785/{SUMMARY.json,FILE_INVENTORY.json,ALL_NATIVE12_1385_METHODS.json,CLASSES_AND_NEW_MACHO.json,FEATURE_GATES.json,CURRENT_091_SOURCE_UI_FUNCTION_INVENTORY.json,REPORT.md} — committed on branch head 33a3c3f9e97cd0e3cb36c352b6746547a4b46380, verified readback.
- Historical original UI: sideplay/audit/native12-039-regressions-20261023/ORIGINAL_MENU_APP_VISUAL_INVENTORY_20261023.md; sideplay/audit/native12-real-deb-cardcount-20261022/ORIGINAL_NINE_LAYOUT_SHAPES.md; sideplay/audit/native12-wiring-20261019/{SUMMARY.json,WIRING_REPORT.md}.
- Current OmniCar crosswalk: sideplay/audit/native12-083-rotation-20261028/OMNICAR_ALL_UI_NATIVE_MAP_CROSSWALK_20261028.md. 
- Current integrated package provenance: sideplay/jb-embedded-appbridge/evidence/runs/40689380992/PACKAGING_PROVENANCE.json.

**SCAN PASS != FEATURE PARITY PASS. Run 40696267785 succeeded for repeatable binary/source forensics, not for physical playback, user controls or native Maps tiles.**
