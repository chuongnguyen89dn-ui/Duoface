# Kiểm toán toàn diện nguyên bản Native12/HUD8 ↔ DuoFace 0.0.91 — 2026-10-28

**Phạm vi:** Đây là audit nhị phân và source thực tế, KHÔNG sửa runtime, build phát hành, cài đặt hay kiểm tra trực tiếp trên xe. Repo chuongnguyen89dn-ui/Duoface, branch feature/duoface-jb-embedded-appbridge-20261020; source .91 gốc 4dba11e1a95e237f966b44292b9b486a837a8f90.

## I. Lần này thực sự chạy lại so sánh 2 DEB hiện tại

- **Run mới GitHub Actions 40696267785 SUCCESS:** https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40696267785 . Hai DEB immutable SHA-verified, dpkg-deb -x, full file SHA, Mach-O inventories, 1385 original Objective-C methods and 18 current source-module inventory.
- Native12 original SHA256 2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad, commit 1286a3ef868cf7e29804bcddf7e20b2eae707ce1.
- DuoFace signed .91 SHA256 e15b9b2c2da351a64a125f5057c6c6e0f6d44aefbcc73de8fe023b6c4d5ab741; package 0.0.91~nativemapqa1.
- **Kết quả actual:** original 43 payload files / 8 Mach-O / 66 ObjC classes / 1385 methods; .91 34 files / 8 Mach-O; 13 byte-identical same-name pairs (mostly logo/art). Only 309/1385 original selectors occur as text strings in any new Mach-O. This is NOT 309 functioning ported methods nor a completion percentage.
- The scanner labels 25 gates KHONG_DAT because it does NOT prove runtime parity: that is NOT 25 missing implementations. Relevant actual source snippets have been rechecked and classified below.
- Archived immutable GHA evidence on Duoface feature branch: **commit 33a3c3f9e97cd0e3cb36c352b6746547a4b46380**, directory sideplay/audit/native12-091-fullscan-20261028/runs/40696267785/ with SUMMARY, FILE_INVENTORY, ALL_NATIVE12_1385_METHODS, CLASSES_AND_NEW_MACHO, FEATURE_GATES, CURRENT_091_SOURCE_UI_FUNCTION_INVENTORY and REPORT.
- New scanner exhaustively walks original ObjC method INDEX and both file payloads, **not** all C/blocks/stub/indirect runtime call sites. Prior original ARM64 forensics archived under sideplay/audit/native12-wiring-20261019 and original APP/OmniCar directories. OmniCar was NOT re-unpacked by this new run.

## II. Vì sao nối nhiều lần mà chức năng vẫn thiếu?

1. **Sai tiêu chí đóng tính năng:** có tên selector, PNG, source hoặc compile PASS bị coi như có UI/handler chạy thật. Không có chuỗi chứng minh input → callback → process/owner → scene/surface → visible frame → touch → close/restore.
2. **Đứt đường native Maps giữa tiến trình:** DFNativeMapPaneCoordinator tại CarPlay/CarPlayApp tạo UIKit native pane trong Dashboard root; DuoFace physical slots nằm ở SpringBoard UIWindow từ DFNative12Chrome. Không có compositor/sceneHostView transaction đưa native map vào actual DuoFace pane. ACK Applied=YES không đủ chứng minh map tiles.
3. **Thiếu lưu trạng thái và semantic:** DFCSaveLayout chỉ ghi bố cục, tỷ lệ, logo, preset và swapped; không ghi bundle ID app đã chọn cho từng slot. Nine layouts in source không có nghĩa reorder/running apps/native scene sizing được hoàn thiện.
4. **Source không phải payload:** HUD8 source có nhưng thiếu trong .91 signed DEB. Voice/settings không có owner module tương đương.
5. **Nhầm dữ liệu cũ với bản mới:** các thiếu hụt .41 về blur, badges, nhãn tiếng Việt đã được sửa trong DFAppPickerVC của .91. Kết quả cũ .81 6 Mach-O không được gán cho .91. User-verified .90 YouTube landscape được bảo vệ.

## III. 25 nhóm giao diện và chức năng — original → .91

| ID | Nhóm | Native12/OmniCar machine reference | Đánh giá .91 | Đường xử lý/thiếu sót chính |
|---|---|---|---|---|
| 01 | CarPlay admission / Home icon | CBWindow, CBBridgeManagerDashboard | **CÓ SOURCE / CHƯA THỬ .91** | DFNativeHostAppDelegate.m, DFFirstPartyAdmission; role, template and UIKit external scene not yet device accepted in .91 |
| 02 | Khởi động, splash và tiến trình | CBSplitSplashScreenView.startLoadingAnimation | **CÓ / CHƯA ĐỐI CHIẾU XE** | DFNative12Chrome.start draws horizontal logo, line/splash; timing/scene-owner animation parity not tested |
| 03 | Menu OUTER App/Zoom/Style/Close | CBWindow, CBMultitaskingOverlayView | **CÓ / CHƯA TRÙNG 100%** | DFNative12Chrome.m owns actual action callbacks; original exact outer pixel, fonts, hitboxes, animation not verified |
| 04 | INNER App/Layout/Recent, cards, paging | CBMultitaskingOverlayView 66 methods | **CÓ PHẦN LỚN** | DFAppPickerVC now has VN tabs, real icon, dark blur, 1pt border, 20pt corner, shadow, active/other badges and Recent; .41 complaints outdated |
| 05 | App picker grid / Add More / label options | CBDashboardSettings.gridCols/gridRows/hideIconLabels, addMoreAppsTapped: | **THIẾU MỘT PHẦN** | DFAppPickerVC still 4x2 cards and always labels; no 5/6-col or 2/3-row config, original Add More modal not wired |
| 06 | Danh sách bật/tắt app, tìm kiếm, danh mục | CBAppManager, CBAppsManagerViewController | **THIẾU** | DFAppLibrary installedUserApps sorted by name; no enabledBundleIDs, search/filter, category enable, bridgedApps prioritization |
| 07 | Host ứng dụng iPhone | CBBridgedUIAppView, CBUIAppContainerView | **CÓ / CHƯA NGHIỆM THU .91** | DFSceneHost / SBAppViewController / per-slot physical UIKit windows; previously working app subset |
| 08 | Video YouTube xoay, handshake | CBBridgeManager.sendStateToApp, CBAppStateListener | **CÓ; .90 DEVICE PASS** | DFSceneHost plus DFYouTubeOrientationRelay; user-confirmed video landscape .90; preserve six protected files |
| 09 | Touch trực tiếp ứng dụng/video/seek | CBTouchCloneView, CBBridgedUIAppView | **CÓ SOURCE / DEVICE TBD** | DFSceneHost.hitTest passive and surface routing; no full .91 touch/seek/media scene regression evidence |
| 10 | Thanh chia kéo tỷ lệ / snap | CBDividerView.handlePan, CBBridgedSplitApp.handleDividerPan | **CÓ SOURCE** | DFNative12Chrome.dividerPan + DFDividerDrag clamp/snap; phone geometry, not native Maps FBScene resize |
| 11 | Logo tròn Swap / giữ 3 giây di chuyển | CBDividerView.handleMoveButtonLongPress and app swap | **THIẾU HOLD 3S** | DFDividerDrag.h states No timer, selects drag axis when movement >7pt; tap swap works in source |
| 12 | Focus, restore, SOLO | CBBridgedSplitApp.focusSlot, restoreSplitAnimated | **CÓ PHONE / THIẾU NATIVE** | DFNative12Chrome.zoomPressed toggles focus; native Maps coordinator has no native SOLO/restore scene sizing contract |
| 13 | Zoom toàn màn & Dock ẩn/hoàn nguyên | DFFullscreenTransport + CBWindow.carPlayUsableBounds | **CÓ ACK / DEVICE TBD** | DFDockZoomCoordinator -> DFCarPlayDockOwner -> applyHostFullscreenToScreenBoundsAfterDockAck |
| 14 | 9 layout tags, 3–4 ứng dụng | Original ARM64 gallery jump table 0..8 | **CÓ SOURCE / DEVICE TBD** | DFLayoutEngine 0 solo + 8 split, 4 backing slots and secondary divider; map coordinator only 2 slots |
| 15 | Move/rotate/reorder 3–4 ô | CBBridgedSplitApp.moveSlot, rotateAllSlotsClockwise | **THIẾU** | Current swapped boolean + swapPressed does not implement all 3–4 slot rotate/reorder semantics |
| 16 | Thay app, Close/Restart/Close All, persist slots | CBBridgedSplitApp.persistSlotOrder, CBMultitaskingOverlayView.saveSlotIndex | **THIẾU MỘT PHẦN** | DFSceneHost atomic pending->ready, running card controls; DFCSaveLayout lacks per-slot bundle IDs and process-wide running PIDs |
| 17 | Pill 2 nút/slot, compact & hitboxes | CBSlotPillView (36 methods) | **CÓ SOURCE / DEVICE TBD** | DFNative12Chrome pillMenu, pillZoom per active visual slot; original six size-state pixel/hitbox parity unverified |
| 18 | Tự ẩn 4s, chạm gọi lại, viền/nhấp logo | CBBridgedSplitApp.noteUserActivity/startBlinkingSession | **CÓ SOURCE / DEVICE TBD** | controlsUntil +4s, borderUntil +2s, app touch observer, logo pulse 1.18; cadence custom |
| 19 | Home cleanup / không dư UI | CBWindow.destroyWindows/bridgeDidDeactivate | **CÓ SOURCE / DEVICE TBD** | DFNative12Chrome.stop hides own windows; native map VC rollback may refuse when system owner changes |
| 20 | Foreground, background, reconnect/no-crash | CBBridgeManager scene lifecycle | **CÓ PHONE / NATIVE CHƯA ĐỦ** | DFSceneLifecycle owner guards on iOS16, native map has conditional restore, no actual .91 on-car crash-free proof |
| 21 | AppDock Apple, statusbar and display geometry | CBWindow.carPlayUsableBounds, CBBridgeManagerDashboard.getDockEdge | **CÓ SOURCE / DEVICE TBD** | DFCarPlayDockOwner and DFCarPlayNativeMapViewportPlan measure same-screen Dock; source planner returns mapSceneSizedForPane=NO |
| 22 | Native Google Maps trong ô DuoFace | OmniCar SCPCarSplit.isCarPlayApp, adopt:slot: | **P0 THIẾU KẾT NỐI** | DFNativeMapPaneCoordinator reparents native DBApplicationSceneViewController into CarPlay Dashboard root, NOT SpringBoard DFNative12Chrome physical pane |
| 23 | Native scene resize/readback/foreign-owner lifecycle | OmniCar pushSceneSizes, verifySceneOfPane, scene:destroyedForViewController:ownScene: | **P0 THIẾU** | No native FBScene foreground-size transaction, readback or owner-generation destruction policy equivalent in .91 |
| 24 | HUD8 tốc độ bốn nguồn và Dock Monitor | DFSpeedNativeHUD, DFSpeedOwner, CBDockSystemMonitorView | **KHÔNG ĐÓNG GÓI .91** | speed8/DFNative8SpeedHUDView.mm exists but .91 DEB payload lacks HUD/SpeedOwner; data source/owner unverified |
| 25 | Trợ lý thoại & iPhone settings nâng cao | CBAssistantManager (69 methods), CBGeneralSettingsViewController, CBDashboardSettings | **THIẾU / MỘT PHẦN** | No comparable voice/mic/navigation/music handler or full app enable, auto-launch, blank-screen, grid, language preferences in .91 iPhone UI |

**CỐ Ý KHÔNG CHUYỂN:** toàn bộ CBLicenseSyncManager, CBSubscription, VIP/gift-code, license watchdog. Đây không phải phần chức năng độc lập phải sao chép; cần giữ thiết kế không có giấy phép vendor.

## IV. Sơ đồ đường gọi P0 và vướng mắc chính

- **Đường iPhone:** DFNative12Chrome.layoutControls → physical slot UIWindow trên SpringBoard → DFSceneHost.hostViewForBundleID → hosted FBScene/YouTubeOrientationRelay. `.90` đã có user on-car orientation PASS, các bảo vệ .91 không được xóa.
- **Đường native .91:** iPhone DFNativeHostRootController menu Maps native → command/notify → DFNativeMapPaneCoordinator.handle ở CarPlay/CarPlayApp → DFMapMeasureLiveDock/DFCarPlayNativeMapViewportPlan → DBApplicationSceneViewController/FBScene thật → DFNativeMapPaneAdapter.adoptNativeController **vào Dashboard root.view**. **Thiếu cạnh nối** đến DFNative12Chrome appSceneWindow trên SpringBoard; no native FBScene push/verify frames. Cannot clone/steal CPWindow across processes.
- **OmniCar gốc, các callsite đã phân tích trước bằng ARM64:** SCPCarSplit.isCarPlayApp: 0xff20 → openApp:slot: 0x164d4 → adoptViewController: 0x18d20 → adopt:slot: 0x1942c → sceneOfViewController: 0x1aaf4 → pushSceneSizes 0x1c550 / verifySceneOfPane:expected:retry: 0x1cce0, own-vs-foreign destroyed policy 0x1ad58. Runtime branch constraints not completely disassembled. Native-first routing means no design prerequisite to disable Maps CarPlay Customize, but DuoFace has no device proof yet.
- **Native Maps plan is a plan, not renderer:** DFCarPlayNativeMapViewportPlan explicitly returns mapSceneSizedForPane=NO, nativeMapSlotAssigned=NO, canAttachPane=NO. Coordinator still allows controlled manual UIKit reparent after geometry checks; that is experimental, not full map composite.

## V. Thứ tự hoàn thiện và tiêu chí nghiệm thu

1. **P0 bản đồ:** On-car .91 while parked, Maps enabled in CarPlay Customize, capture ACK reason, genuine scene/controller/host/window pointer and map tiles vs phone YouTube panel. If ACK accepted but blank, stop treating reparent as renderer; fix actual native compositing ownership, no arbitrary zoom or cross-process CPWindow.
2. **P1 native lifecycle:** verify native scene foreground/generation/host lease, native frame push+readback, own/foreign destroyed, Home/reconnect/restore. Keep .90 working YouTube and system Dock geometry.
3. **P1 giao diện đầy đủ:** test all 9 presets × 1–4 real scenes × empty/pending/ready, inner/outer menus, App picker action, per-pane focus/restore, swap/reorder, 3-second hold of logo, 4-second hide/wake, true Dock Zoom, splash/video/seek/exitmode; keep screenshots/logs itemized.
4. **P2 trạng thái/cài đặt:** persist chosen bundle IDs per slot, configure grid/labels/app groups and Recent data semantics, integrate HUD8 renderer+data+safe owner, implement chosen voice/settings features with independent code. Exclude vendor licensing.
5. New runtime changes must pass source/unit/ABI, signed DEB hash, Sileo verification, physical head-unit tests. **This audit only built/reviewed forensic evidence, did not change shipping code or Sileo.**

## VI. Evidence paths / exact replay

- CI full binary scan: .github/workflows/duoface-091-native12-original-comprehensive-static-audit-20261028.yml; original method comparator sideplay/audit/native12-vs-new-20261021/compare_native12_new_full.py. Run 40696267785 ubuntu-24.04; command supplies SHA-pinned original DEB and method-index from git show, .91 immutable archive, --new-sha256 e15b... --expected-new-files 34.
- Saved all 1385 records: sideplay/audit/native12-091-fullscan-20261028/runs/40696267785/ALL_NATIVE12_1385_METHODS.json.
- Original machine links: sideplay/audit/native12-wiring-20261019/WIRING_REPORT.md, sideplay/audit/native12-app-2debs-20261023/APP_BINARY_AUDIT_VERDICT_20261023.md, sideplay/audit/native12-083-rotation-20261028/OMNICAR_ALL_UI_NATIVE_MAP_CROSSWALK_20261028.md.
- Current scene/UI/native source: sideplay/duoface-native-scene-host/{DFNative12Chrome.m,DFAppPickerVC.m,DFLayoutEngine.m,DFSceneHost.m,DFTouchOwnerProbe.m,DFCarPlayDockOwner.m,DFDockZoomCoordinator.m,DFNativeHostRootController.m,speed8/DFNative8SpeedHUDView.mm}, sideplay/native-carplay-scene-v1/{DFNativeMapPaneCoordinator.m,DFNativeMapPaneAdapter.m,DFCarPlayNativeMapViewportPlan.h}.
- `.91` physical Google Maps+YouTube split and nav continuity not yet verified; `.90` rollback signed SHA c9a6c8f624ce3224ec5cdc7aee9c3280306068c99c9842d4b4f802914c560f27.
