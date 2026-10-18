# DuoFace QA v5 — reset interface strategy from Native12 (2026-10-18)

## User device result (authoritative)
- QA com.duoface.visual12 version 1.0.3-12~ui8native5: UI has **not** improved, apps remain cramped, original DuoFace bar is missing; user says crashes are fewer but exitMode still occurs. This **rejects v5** on UI/scene geometry. Do not call it fixed or pixel-parity. No matching .ips/runtime log supplied in this user message.
- Native12 HUD8 and original DuoNavi 1.0.4 are the functional/UI references. QA is **only** a proven independent CarPlay app scene host, NOT original interface. Freeze further cosmetic patch/DEB publishing until new native-equivalent shell is verified.

## SOURCE VERIFIED (not inferred from the user's screenshot)
1. Root: replacement/visual12/engine/runtime/DFIRuntime.m:DFIStart constructs DFV12SplitController, **not** original CBBridgedSplitApp/CBWindow/CBMultitaskingOverlayView/CBDividerView/CBSlotPillView. Its root UIRootSceneWindow uses UIWindowLevelAlert+100 with black background and a full-screen controller. This **may** obscure system CarPlay chrome; original CBWindow.createWindows and resizeWindows explicitly set their own window level, use usableBounds and different window/view stacking. Confirm with device before changing root window level.
2. QA bar: replacement/visual12/engine/runtime/DFIInterface.inc creates toolbar.hidden=YES and keeps toolbar **only in self.panel.contentView** after attachNativePickerHeader. dismissPanel and armHide hide it; when no panel exists, root only has a 40x24 ellipsis edge button. Consequently, App/Zoom/Style/Close menu row **cannot** appear at rest. If user means native system status bar instead, inspect UIWindow level/usable bounds separately. Do not conflate them.
3. Native12: runtime/fullscreen/DFPickerZoomMenu.xm **restyles** an existing CBMultitaskingOverlayView original sheet: _sheetCard blur, native X, _appSegmentBtn, _layoutSegmentBtn, _recentSegmentBtn; approved logo 120pt and native-height menu row App/Zoom/Style/Close 30pt. Native callbacks and original sheet owner preserved. QA does not instantiate this sheet; its DFV12List/panel is a separate approximation. Simply adding a bar/icon to that alpha root will NOT recreate native UI.
4. Native per-pane control: src/DuoFaceVisualHook.m preserves CBSlotPillView _dotsButton/_expandButton/_restoreButton original target; src/DFDividerLogoGrip.inc preserves CBDividerView ratio-pan, native swap and logo hold movement. QA mimics selectors with separate buttons but lacks underlying native-like shell behavior.
5. Original104 static audit/duonavi-original104-ui/ORIGINAL104_UI_CALLCHAINS.json: CBWindow.showAppPickerForSlot: routes to multitaskingOverlay.showAppPickerForSlot:parentView:, CBBridgedSplitApp manages per-slot focus/restore/splitRatio, CBBridgedUIAppView manages native reference frame and layout. V5 geometry changes did not solve device issue; do not assume compilation is device proof.

## Next implementation contract (prioritize architecture, not cosmetic patches)
- Preserve only proven independent core: DFV12SceneHost and own single CarPlay owner + prior standalone6invalidate teardown; never import CBBridgeManager vendor, licensing, vendor postinst or license-check classes.
- First reconstruct source-owned Native12-like shell/window + usable bounds/system chrome ownership, then source-owned picker overlay, native App/Zoom/Style/Close menu, per-slot pill, divider, real callbacks and iPhone settings. Use original class/view/target map and verified Native12 hook behavior; keep vendor binary out of the new app.
- Test visible bar/picker and hit regions BEFORE attaching app scenes; then test two apps live, divider drag and scene layout, opening/closing apps and exitMode. Get runtime log and SpringBoard .ips for crashes.
- Gate next release: no new QA Sileo release until a new view hierarchy is implemented, at least static/UI layout tests and iOS compile pass, then user compares screenshot with Native12 on CarPlay. Do not claim 100% parity before real device test.

## Checkpoint
- Branch feature/visual12-duodash-recovery, latest shipped ui8native5 Sileo run 39094409601, device UI REJECTED. Stable Native12 HUD8 unchanged.
- This diagnostic checkpoint updates documentation/handoff only; no runtime code, build, Sileo changes and no device-side fix verified.
