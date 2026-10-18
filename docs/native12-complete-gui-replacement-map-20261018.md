# Native12 HUD8 → DuoFace independent QA — full payload inventory and GUI replacement map

Checkpoint 2026-10-18. **User-rejected QA7 interface**. QA remains only the verified *potential* source-owned CarPlay scene host; **all QA-authored presentation must be identified for removal/replacement, not made `hidden`**. The original Native12/1.0.4 binaries are immutable read-only references. No linking or runtime dependency on their proprietary or licensed components.

## Evidence and exact scope

- Full static DEB scan: `audit/native12-complete-deb-inventory/INVENTORY.json`, `REPORT.md`. Script: `scripts/audit_native12_complete_deb_inventory.py`; macOS workflow `.github/workflows/duoface-native12-complete-deb-inventory.yml`; [Actions 39104759233](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39104759233) completed success.
- SHA-pinned native: `dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb`, SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`.
- SHA-pinned user-tested rejected QA7: `dist/visual12-native-shell7-visual-qa/com.duoface.visual12_1.0.3-12~ui8native7_iphoneos-arm64.deb`, SHA256 `57ae2b34487b3c24fc584ab2d1bf6b44abe6797c8c7d14628004e2bb78c62137`.
- Reference functional chain: immutable `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb` SHA256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`.
- **File inventory exhaustive:** Native12 43 regular files, 21 directories, 6 dylibs, 7 plist, 25 PNG (18 app-icon size variants, **7 UI-artwork images**); QA7 23 regular files, 15 dirs, 1 dylib, 4 plist, 14 PNG, of which 5 are app/prefs icon variants and 9 are UI/artwork candidates. Original104 50 files, 38 dirs, 2 dylibs, 2 plist, 21 PNG.
- **All 7 exact Native12 UI artwork filenames already exist in QA7**; the common UI filenames have matching hash; QA's extra alpha/grabcut preview assets are NOT Native12. Missing 16 icon variants are launcher dimensions, not the cause of 2-pane UI/scene errors. Thus the root problem is the UI renderer and callbacks, not merely missing images.
- `llvm-objdump` lists **49 native class/protocol-style metadata candidates** (not a guaranteed runtime class count; stripped and Swift may be omitted), QA7 19, original104 60. Method list is static and includes only what Objective-C metadata exposes, not a proof of 100% executable branches. A previous metadata counter incorrectly counted ivar names as classes, so never quote earlier false “492 classes”.

## Native12 class-by-class function/presentation migration map

| Original class/method count from real Dashboard (when available) | Owner currently on QA7 | Action required | State |
| --- | --- | --- | --- |
| `CBWindow` (37) | `DFINativeWindowSurface`, `DFIStart`, alpha `UIRootSceneWindow` | Rebuild independent real CarPlay window level/visible content/safeArea/stack and dock/sidebar passthrough; current QA `UIWindowLevelAlert+100` and uncertain safeArea must not be treated native | P0 FAIL |
| `CBSplitContainerView` (6) | generic `DFINativeSplitSurface` | Rebuild native hitTest/host subview management; keep touches routed to actual live scenes | P0 missing native behavior |
| `CBSplitSplashScreenView` (16) | QA root startup/empty buttons | Recreate native startup/loading/dismiss lifecycle; eliminate alpha QA startup overlay obscuring CarPlay chrome | P0 MISSING |
| `CBBridgedSplitApp` (49) | `DFV12SplitController`, `DFIFramesMake` | Reconstruct 8 layouts, native ratio bounds, focus/restore, swap, divider pan, persistence | P0 partial |
| `CBSlotPlaceholderView` (16) | generic QA `UIButton` text `＋ Chọn ứng dụng` | Rebuild visual slot empty state and tap using original placeholder view metadata/geometry | P0 MISSING |
| `CBSlotPillView` (36) and `CBSlotPillHitButton` (3) | `DFINativeSlotPillView` | Map all six compact/expand/focused states, action/hit slop/long press; compare actual screenshots | P1 partial |
| `CBDividerView` (27) and `CBDividerButtonInfo` (9) | track/Logo | Native 28/30pt button, relativePos, swap/long-hold, **ratio pan on live apps and grip** | P0 partial; source grip pan wired |
| `CBMultitaskingOverlayView` (66), `CBOverlayScrollView` (4), `CBMultitaskingPillView` (12) | `DFINativePickerCard/MenuBar/PickerCardsController` | Rebuild overlay header/tab App/Zoom/Style/Close, exact cards, paging, Recent and dismiss behavior | P0 FAIL |
| `CBBridgedUIAppView` (29) and `CBUIAppContainerView` (6) | `DFV12SceneHost`, UIView pane | Preserve **scene playback only**, validate 2× sizing/transform, content hit-test and render bounds; compare original104 | P0 not validated |
| `CBTouchCloneView` (5) | custom SB host hooks | Recreate independent input forwarding where original does, no vendor class dependency | P1 unknown |
| `CBDashboardSettings` (61) | generic QA `DFV12SettingsController` (4 sections/11 rows) | Rebuild **non-license** native settings, source/scale/monitor/labels/prefs, exclude vendor license/trials | P1 FAIL |
| `CBDockSystemMonitorView` (19), `CBDockMetricItemView` (11) | none with proven parity | Rebuild if native display has these enabled; do not blindly show extra QA widgets | P2 missing |
| `DFSpeedNativeHUD` (metadata present, direct method count not extracted) | `DFV12NativeHUD8` source-owned visual clone | UI geometry/preferences from Native8; data transport absent, two-live-scene gating; device parity not passed | P1 partial |
| `CBLicenseSyncManager`, `CBLicenseShieldIconView`, `CBLicenseWarningModalView` | MUST NOT EXIST as runtime dependency | Exclude licensed/trial checks, payment/expiry and vendor remote activation from independent project; do not copy their class code | excluded |

**Core six family total = 37 + 49 + 29 + 66 + 36 + 27 = 244 recorded ObjC method entries.** This is not the total number of UI methods across all classes. Their compiled behavior is the missing connection; renaming `DFINative*` classes does not transfer these implementations.

## Quantities: exact / source-derived / still unverified

- **Pill:** Native12 real `CBSlotPillView.updateBoundsSize` six widths **38/44/64/72/76/80 pt**, heights **19/22 pt**, radius **11 pt**. Native separator **0.5 pt** stroke, white alpha **0.25**.
- **Divider:** real `CBDividerView.updateGripLayout` buttons **28×28** when along-divider length <280 pt, otherwise **30×30**; hit region expands **12 pt**. Logo approved **tap=swap**, **hold ≥0.30 seconds=move logo along divider**; user needs *direct perpendicular drag=resize split*. QA7 had 16pt-only track beneath grip so logo interception is an actual interaction gap. Independent QA source now adds a ratio pan on the grip plus keeps the original semantics; not device verified.
- **Header menu:** approved 30pt height, logo 120×30 when receiver width allows, tab widths 43/51/47/51pt; these come from approved Native12 customization source, **not proof of every pixel on all resolutions**.
- **Eight split layouts:** source-own `DFIFramesMake`, `fraction`, `secondary`; correct original Native12 min ratio and per-configuration clipping **still not proven**. No arbitrary default reset; keep saved ratios.
- **Images:** exact bytes/dimensions in INVENTORY.json. UI assets: `duoface-fullscreen.png` 88×88; `duoface-picker.png` 256×70; `duoface-swap.png` 120×120; `duoface-icon.png` 256×256; `duoface-logo-picker-alpha-v2.png` 627×228; `duoface-logo-vert.png` 640×640; `duoface-logo.png` 960×240. Pixel-sampled RGB bins are in INVENTORY.json. **PNG pixel colors are not runtime UIKit `UIColor` values**. Approved red RGB **227,2,15** from `runtime/fullscreen/DFPickerZoomMenu.xm`; other native dynamic blur/background/tint colors require class-specific ARM64 code inspection.
- **CarPlay chrome:** User's actual screenshot shows Home tiles exposed top/bottom behind a narrow gray overlay, while expected Native12 includes its own accurate CarPlay usable bounds and interaction-safe bar. Do **not** declare resolved from static safeArea constants. Native original104 `CBWindow.carPlayContentInsets` fallback left64 only when no configured/safe-area insets; QA uses a hardcoded windowLevel and generic UIView with different ownership. Need real `window.bounds`, `window.safeAreaInsets`, usable frame and scene frames from `/var/mobile/Library/Logs/DuoFaceVisual12-runtime.log` and native original reference to fix without masking or blocking status icons.

## Deleted QA UI; retain only independent scene playback infrastructure

- Commit `bd9b3c00531a16c7fb99ab40f73b6450e07cc31a`: **physically deleted** QA bottom-center floating ellipsis property, creation, layout, front ordering, and `edgeTap` handler; no `hidden` band-aid. Replaced old test anchors `scripts/audit_native12_ui_dimensions.py` and `replacement/visual12/tests/test_native_shell_structure.py`; proof ARM64 CI [39104604941](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39104604941) success. Changes not packaged/Sileo.
- Commit `f012926771759d37c0666e34e22ee4807564f3e2` / `2f58974868193807fa4ec18d77dc360e00561b83`: native-view-owned logo now supports `UIPanGestureRecognizer` calling existing `drag:` ratio owner; `requireGestureRecognizerToFail:` protects 0.30s long-press movement; direct line pan and swap tap remain. Test `ab399c3bd36926fd43aad5ae8653d779d0e0521f`, [Actions 39104900061](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39104900061) **success** for static and ARM64 compile/link only. Physical CarPlay drag **not yet confirmed**.
- QA startup content, generic empty UIButton, stock layout preview, picker sheet and Settings still exist in source. They are **marked for deletion/replacement**, not claimed gone. The old QA7 DEB on Sileo is unchanged; stable `com.duoface.independent` also unchanged.

## Mandatory next implementation gate

1. Scan ARM64 Native12 `CBSplitSplashScreenView` and `CBSlotPlaceholderView` **complete init/layout callbacks, frames, colors, and lifecycle**, then implement independently and replace QA root empty/splash views.
2. Scan original104 + Native12 `CBWindow.createWindows/resizeWindows/show/hide` and CarPlay display hierarchy. Replace **QA window/compositor behavior** while keeping independently verified app-scene hosting; log actual frame/chrome before declaring bar fixed.
3. Rebuild `CBMultitaskingOverlayView` components, slot hit regions and touch border. Run full layout/ratio/focus/inset tests; compare pictures at native receiver resolution.
4. Only once QA source passes tests and original UI structure can be physically evaluated, build a new separate QA DEB with new version, verify SHA and then discuss Sileo. **Do not replace stable Native12 HUD8; do not copy compiled proprietary manager/licensing.**
