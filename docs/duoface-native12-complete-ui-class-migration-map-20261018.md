# DuoFace Native12 full binary class-to-QA interface migration map — 2026-10-18

**Approved direction:** retain only QA's proven independent CarPlay app/scene playback substrate; **delete**, rather than hide, QA-origin visual controls as each equivalent independent Native12-style implementation is completed. Never install or link original DuoNavi/DuoFace vendor binaries or vendor license managers in the independent QA. Preserve Native12 HUD8 stable package.

**Evidence:** `audit/native12-complete-deb-inventory/INVENTORY.json` (full signed DEB archived-file and PNG scan, filtered static Objective-C class/method candidates); original native DEB SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`, Original104 SHA256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`. Class/method enumeration is **metadata-only**; it is NOT 100% complete behavior extraction, executable coverage or an on-device source reconstruction.

**Inventory:** Native12 = 43 files, 25 PNG (18 app icons, 7 other assets), 6 dylibs, 7 plist. QA7 = 23 files, 14 PNG, 1 dylib. Original DuoNavi 1.0.4 = 50 files, 21 PNG. All **7 named Native12 non-app-icon PNGs are already inside QA7** by basename and SHA. Copying more PNGs will not fix the incorrect root renderer. Dominant PNG color bins are NOT UIKit runtime palette measurements.

## Native12 UI and non-license settings roles (beyond the prior six-class comparison)

| Native12 class (method count) | Original104 methods | Intended function | QA owner / replacement | State |
| --- | ---: | --- | --- | --- |
| `CBWindow` (**37**) | 40 | External window/safeArea/status-Dock | DFINativeWindowSurface + DFIStart | PARTIAL — CarPlay Home visible outside overlay |
| `CBSplitContainerView` (**6**) | 6 | Split container hitTest + touchesBegan | DFINativeSplitSurface | MISSING native-equivalent touch behavior |
| `CBSplitSplashScreenView` (**16**) | 16 | Native initial splash/loading/dismiss | No independent native splash parity | MISSING |
| `CBSlotPlaceholderView` (**16**) | 16 | Empty slot tile/label/tap | DFV12SplitController UIButton emptyButtons | QA placeholder, not original UI |
| `CBMultitaskingPillView` (**12**) | 12 | Native overlay pill tap/pan | DFV12SplitController custom picker | MISSING original pill behavior |
| `CBMultitaskingOverlayView` (**66**) | 66 | App/Recent/Layout chooser and sheet | DFINativePickerCard/MenuBar + DFINativePickerCardsController | PARTIAL; renderer/cards not native-equivalent |
| `CBOverlayScrollView` (**4**) | 4 | Card scrolling/touch cancellation | UIScrollView in DFINativePickerCardsController | Touch behavior unverified |
| `CBDockSystemMonitorView` (**19**) | 19 | Native Dock CPU/battery metrics | No independent exact UI owner | MISSING |
| `CBDockMetricItemView` (**11**) | 11 | Dock metric item/icon/value | No independent exact UI owner | MISSING |
| `CBSlotPillHitButton` (**3**) | 3 | Per-slot enlarged hit test | DFINativeSlotPillView button | PARTIAL; interactive hit forwarding unverified |
| `CBSlotPillView` (**36**) | 36 | Per-slot App/Expand/Restore flags & layout | DFINativeSlotPillView | PARTIAL visual; runtime unverified |
| `CBDividerView` (**27**) | 27 | Divider pan/tap/hold/orientation | DFINativeDividerTrack + DFINativeDividerLogo | PARTIAL; direct grip pan added; device unverified |
| `CBDividerButtonInfo` (**9**) | 9 | OnSwap/onRotate/relativePos model | DFV12SplitController dividerLogoPositions | PARTIAL; rotate behavior missing |
| `CBTouchCloneView` (**5**) | 5 | Touch cloning for app panes | QA scene host/touch forwarding | MISSING direct equivalence |
| `CBUIAppContainerView` (**6**) | 6 | Hosted pane container hitTest/touches | QA UIView pane + DFV12SceneHost | PARTIAL; active-app touch conflicts unresolved |
| `CBBridgedUIAppView` (**29**) | 31 | App viewport sizing + native frame/scene | DFV12SceneHost | PARTIAL; cramped app visible, root cause unknown |
| `CBBridgedSplitApp` (**49**) | 50 | Multi-pane focus, restore, pan, rotate, swap | DFV12SplitController + DFIFramesMake | PARTIAL; device parity failed |
| `CBDashboardSettings` (**61**) | 59 | Independent non-license preferences | DFV12SettingsController | PARTIAL; lacks native UI/functions |
| `CBLocalization` (**12**) | 11 | Native localized strings | DFIT + QA language defaults | PARTIAL; no full localization parity |
| `CBBridgeManager` (**75**) | 75 | App switching, callbacks, multi split coordinator | Independent source-owned DF* facade, NOT vendor license manager | PARTIAL; runtime parity unverified |

## Critical architecture gaps grounded in class metadata and CarPlay photo

1. **Launch and window**: Native `CBWindow` (37 methods), `CBSplitContainerView` (6 methods, including `hitTest:withEvent:`, `touchesBegan:withEvent:`), and `CBSplitSplashScreenView` (16 methods) jointly define entry/root behavior. QA `UIRootSceneWindow` + `DFINativeWindowSurface` is not equivalent; user image shows Home/Dock visible above and below split overlay. Do not hide real CarPlay status bar or change `windowLevel/safeArea` without logging and measured bounds.
2. **Touch and ratio**: Native `CBDividerView` (27 methods) handles `handlePan`, simultaneous gestures, press buttons and expanded hitTest. Separate `CBUIAppContainerView`, `CBTouchCloneView` and `CBSplitContainerView` show touch ownership crosses multiple views. QA ratio pan on 16pt track was covered by its grip. Source commit `f012926771759d37c0666e34e22ee4807564f3e2` adds grip gesture; `2f58974868193807fa4ec18d77dc360e00561b83` wires to `drag:`. This is NOT verified on CarPlay, and a code compile pass cannot prove hitTest/gesture ownership or ratio resizing.
3. **Placeholder / picker**: Native `CBSlotPlaceholderView` (16), `CBMultitaskingPillView` (12), `CBMultitaskingOverlayView` (66), `CBOverlayScrollView` (4) have distinct UI/action roles not reproduced by generic QA button + picker sheet. Need reconstruct each native part, including colors, blur, control widths, rows, hit areas, pagination and lifecycle.
4. **Colors/scale**: use verified image SHA and measured PNG pixel sizes, then inspect ARM64 constructors to establish compiled UIColor/alpha/gradient/font parameters before coding. The audit's sampled RGB PNG bins (currently mostly black) do not establish Native12 native UI colors. Per-device size still requires screenshot + `DuoFaceVisual12-runtime.log`.
5. **Settings**: Native `CBDashboardSettings` (61) and `CBLocalization` (12) are broader than QA generic 11 rows; enumerate keys and implement independent non-license UI, never vendor license logic.

## Migration gates

- P0: preserve iOS16 CarPlay playback substrate only, compare full window/safeArea/status/Dock and launch transition at device runtime, implement Native12-like splash/root/container hierarchy; **remove QA visuals rather than hide them**.
- P0: implement native-like divider hit area/gesture ownership, adjust ratio with live panes and preserve touch access to both apps. Current grip-pan source must pass CI *and* user vehicle test.
- P1: complete Native12 placeholder, per-slot pill, sheet/App/Recent/Layout, focus/restore, swap/rotate; compare actual native colors/blur/radii/layout from binary and physical screen.
- P1: complete independent settings/language and HUD8/scene lifecycle without license.
- Acceptance: same receiver, side-by-side native12 vs QA screenshots 8 layouts/chooser, two live apps and ratio drag, launch status/dock, settings/HUD and close/respring. Until then **QA7 REJECTED**, do not publish new QA Sileo version or modify stable.
