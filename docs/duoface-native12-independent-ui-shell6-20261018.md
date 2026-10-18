# DuoFace Native12 UI shell reconstruction — QA visual preview 6 (2026-10-18)

## Purpose and acceptance boundary

The user rejected QA v2–v5 because they were not actually DuoFace Native12 HUD8: no original CarPlay bar, incorrect split/picker/pane visuals, apps cramped, and intermittent exitMode. This milestone **replaces the QA alpha visual view tree with independently authored native-class-analogue views**, while preserving the scene hosting owner already demonstrated to open real CarPlay apps. It is **NOT full Native12 visual parity** and has not been evaluated on an iPhone or headunit. Do not port or link the original proprietary/licensed `CBBridgeManager` or any licensing/remote checks.

Stable Native12 HUD8 Sileo package `com.duoface.independent` remains untouched; visual-only candidate is `com.duoface.visual12` `1.0.3-12~ui8native6`.

## Confirmed original DuoNavi 1.0.4 evidence: CarPlay Dock and usable content

Original pinned binary source: `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb` sha256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`, original `DuoNaviDashboard.dylib` sha256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`. New read-only macOS disassembly report `audit/duonavi-original104-ui/ORIGINAL104_UI_CALLCHAINS.json`, [Actions 39095994271](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39095994271) success, 27 methods (script `scripts/audit_original104_ui_callchains.py`, workflow `.github/workflows/duoface-original104-ui-callchains-readonly.yml`).

Original `CBWindow.carPlayContentInsets` IMP `0xb1370`:
- checks configured `UIEdgeInsetsFromString`, then `rootWindow.safeAreaInsets`;
- if all insets zero, at `0xb1544–0xb1550` assigns `d9=64.0`, `d8=d10=d11=0`, and `0xb1564–0xb1570` returns `d0=d8,d1=d9,d2=d10,d3=d11`, i.e. **top 0, left 64, bottom 0, right 0**. This is a Dock reserve **on the left**, not a top bar.
Original `CBWindow.carPlayUsableBounds` IMP `0xb15cc` obtains full screen and insets, subtracts left+right and top+bottom, and checks minimum 100x100 before fallback. Original `CBWindow.createWindows` IMP `0xb173c` initializes an external window, sets its window level, creates its root content frame from `carPlayUsableBounds`, and sets a transparent background.
This is **static original104 evidence**; Native12 and target receiver geometry may differ. Current QA implementation first honors actual window/view safeAreaInsets and uses the original 64pt-left fallback only when unavailable; frame viable guard is an independently authored approximation. It does **not** assert the original binary callback order or exact UIKit window level on the user's receiver.

## Actual QA-owned source hierarchy implemented

| Original Native12 concept | Independent source/UI owner | Linkage |
|---|---|---|
| `CBWindow` external content | `DFINativeWindowSurface` | `DFV12SplitController.loadView` creates it; real CarPlay `UIRootSceneWindow` retained |
| Usable split content | `DFINativeSplitSurface` | Only this child has black app backgrounds; root and window outside it are transparent so underlying CarPlay Dock can show |
| `CBSlotPillView` per-app | `DFINativeSlotPillView` | Own dots, expand, restore buttons with approved `duoface-picker.png` and `duoface-fullscreen.png`; callbacks `choose:` and `zoomPane:` |
| `CBDividerView` | `DFINativeDividerTrack`, `DFINativeDividerLogo` | Track/independent gesture hit and approved swap logo; pan in native usable coordinates |
| `CBMultitaskingOverlayView` sheet | `DFINativePickerCard`, `DFINativePickerMenuBar` | Dim backdrop + blur card with the same 120pt approved logo and compact 30pt App/Zoom/Style/Close row inside picker |
| Native scene | Existing `DFV12SceneHost` | Scene owner/controller unchanged, v4/v5 geometry and validated `setRequestedMode:0` + `invalidate` on close |

Source: `replacement/visual12/engine/runtime/DFINativeShell.inc` added commit `15716ecb59ceb4f492054118929336c406c69efa`; integrated by `DFIInterface.inc` commits `be8d604aae57a336f39b2e6b12e42137dbc58ea1`, `eae916277ebf9e04c400705b57ae4303c8ff90a9`. Native left 64pt geometry and touch-safe pass-through added in `095c99f3ba2534d33b2e1a798063ff65fe89b648` and `8f9bb95b16e09cb3f3d67bed1f924b555a06a078`; window outside split switched to clear/opaque=NO `8a65d0a2eb25f3d0489bb7861242c7ed0740cad9`. Source-owned root still uses original existing scene controller and does **not** copy or embed the vendor UI renderer.

Existing `DFIChrome.inc` specifically hides `DBStatusBarWindow`, `CARStatusBarWindow` or `DBDockWindow` if persisted `zoomEnabled` is true. Commit `860f4ae4e52c479f6c9f6a27be0ea78d19ff30c6` restores normal chrome at fresh QA start, keeping hide action **only in Zoom menu**. This is a source-verifiable second possible reason for the missing bar. It does not prove chrome is visible on the user's actual unit.

## Build, release and verification states

- Native view class/source regression: `replacement/visual12/tests/test_native_shell_structure.py` includes view-tree creation, ownership, original64 fallback, safeArea, clear frame/pass-through, approved assets, callback targets and explicit absence of vendor license linkage; wired into `.github/workflows/duoface-visual12-engine-bind-ci.yml`.
- Arm64 link-only test [39096289167](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39096289167) success, [39096408855](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39096408855) success. First iteration static test failed on a now-obsolete full-bounds check; `78a2a3be005526d1801e2c2533331e2f6e72e79a` corrected it, no device result.
- Isolated QA DEB `com.duoface.visual12_1.0.3-12~ui8native6_iphoneos-arm64.deb`; compiled/verified in [Actions 39096491111](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39096491111), SUCCESS. Exact path `dist/visual12-native-shell6-visual-qa/`, **SHA256 `f02ab3a2de25185b008c4213e64b208a314c2eb93a376dfe08ca49cf3f2caa7b`**, 1,071,888 bytes. Artifact persist commit `03930f9f981e87a2d6fe6c827737023f76aef1f9`. Source commit `47072ca17e2647b21f78b9e806b3920514983e52`.
- Original `ui8native5` artifact not overwritten. Automatic production QA packaging paused outside this one deliberate preview workflow, Sileo updated only via separate package ID and exact SHA.
- Sileo publisher `chuongnguyen89dn-ui/carplaydsp` main commit `ae69b9ea0b5487c75b134a3b6fb01e879d32a84c`, [run 39096576504](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/39096576504). **Publisher outcome must be rechecked and added to handoff**; do NOT claim success from only the workflow trigger.

## Real-device acceptance gate (not passed)

Compare with approved **Native12 HUD8**, with the car stationary:
1. At launch (Zoom off): original CarPlay left status/Dock bar is visible and tappable; two panes align to *usable* bounds without black overlay covering the left 64pt.
2. Open picker: original-like blur card, horizontal DuoFace logo, App/Zoom/Style/Close row, close X in non-overlap hit region; verify layout and bar are actually visible.
3. Per-slot pill artwork and placements, divider/central swap logo; take side-by-side screen captures with Native12 at the same receiver size.
4. Then only once visuals are accepted, test scene sizing, live-app drag, exitMode and other behaviors. Collect `/var/mobile/Library/Logs/DuoFaceVisual12-runtime.log` and SpringBoard .ips for any first-respring/app-select failure.

**Known remaining risk:** root `UIRootSceneWindow.windowLevel` still `UIWindowLevelAlert+100`, inherited from alpha; transparent content and hitTest pass-through might still not expose cross-process bar depending on actual CarPlay window stack. That cannot be marked solved without device evidence; a verified window-level/receiver stack trace would be next. The sheet is a custom native-equivalent UI, **not byte-identical original `CBMultitaskingOverlayView`**; exact pixel parity awaits screenshot/user acceptance. No original Native12 binary included and no user/device test in this build.
