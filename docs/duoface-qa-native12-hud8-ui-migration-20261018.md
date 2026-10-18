# DuoFace QA — Native12 HUD8 UI migration audit (2026-10-18)

## User decision / execution boundary

Reopen QA work after rollback checkpoint f0122bc: use Native12 Speed8 Compact as visual/function reference and port its interface into Visual12 independent QA **before speed-data integration**. Build distinct QA DEB and test through Sileo. Never overwrite the installed Native12+HUD8 package or remove the confirmed standalone6invalidate lifecycle fix. A UI preview is not acceptance of 100% renderer parity.

## Reference evidence in this repository

- Native HUD renderer + drag/long-press/prefs: `runtime/speedbubble/DFSpeedNativeSplit8SpringBoard.mm`, class `DFSpeedNativeHUD` (pill 104x46, speed+limit, position, scale, opacity, source choice, hide target).
- Native picker original visual/customization: `runtime/fullscreen/DFPickerZoomMenu.xm` — logo 120pt, App/Zoom/Style/Close one 30pt row, close X 48pt reserved, native blur card, recent app rows.
- Other native UI customization: `src/DuoFaceBorderRunner.m`, `src/DuoFaceVisualHook.m`, `dist/visual-1.0.3-12/assets`.
- Full compiled Native renderer remains in the separate `DuoFaceDashboard.dylib` payload of `dist/payload-migration/native12-speed8compact/`. Its original source was not found; binary contains CBWindow/CBBridgeManager/scene/license coupling. It is not copied into independent QA and 1:1 runtime parity is **NOT** established.

## Source changes in QA branch

- `replacement/visual12/engine/runtime/DFIInterface.inc`: approved menu logo + four tabs now belong to the picker sheet, not the floating root toolbar; a distinct native close X; wider scrollable picker, layout controls and recent apps; original 3 panes / 8 layouts / drag / swap retained.
- `replacement/visual12/engine/runtime/DFV12NativeHUD8.inc`: copied/adapted actual Speed8 UIView implementation including geometry, drag-dismiss, saved position, long-press 8 setting actions, source selector, show-limit, scaling/opacity; isolates preferences under `com.duoface.visual12.nativehud8`. No CBWindow/S7Reconcile native scene driver and no artificial speed data. Displays “—” until a real source is independently integrated.
- `replacement/visual12/engine/runtime/DFIRuntime.m`: compile HUD view into the same independent QA module. HUD is owned only by existing DFV12SplitController. Live-scene state determines whether HUD appears when two panes are attached. No new UIWindow or independent scene owner.
- QA build/script/validator/workflow: dedicated package `com.duoface.visual12`, version `1.0.3-12~ui8native2`, output `dist/visual12-native8ui2-qa/`. Builds on macOS iOS16 SDK; Sileo publication is a separate SHA-pinned step in `carplaydsp/.github/workflows/build.yml`.

## What the first device test CAN evaluate

- QA opens under existing standalone source-owned scene host (no vendor licensing/runtime classes)
- Visual UI resemblance of picker, header logo, tabs, native-style close X, app list, recent rows, eight layout choices and 3-pane geometry
- Speed8 floating HUD visual and its drag/resize/opacity/show limit/source settings after two real app scenes are ready (speed data deliberately unavailable)
- Scene close/reopen and crash regression against `standalone6invalidate`
- Package coexistence with Native12 HUD8, no original Native DEB replacement

## Remaining gaps — do not mislabel as completed

- Native compiled `CBMultitaskingOverlayView` renderer, exact native picker hierarchy, docking and per-device geometry not proven 1:1 with the QA implementation.
- Visual controls and functionality require on-device screenshots/tests. Build/link success does not equal device UI pass.
- Speed transport/producers (GMap/Waze/VietMap/GOFA) not connected by design in this milestone; HUD shows placeholders, not real speed.
- Full native fullscreen/picker interaction parity, CarPlay reconnection, extended stability and license-independent complete product acceptance remain unverified.

## Rollback and release policy

Keep `f0122bc` and `dbea5e8` as audit baseline. New QA source can be reverted without altering Native12/Sileo stable payload. Never update Sileo QA until its matching DEB SHA and build run are verified; publish through its separate package ID. Do not use previous unfinished Native8 HUD experiment commits as a functional baseline.

## 2026-10-18 — POST-INSTALL FAILURE AUDIT / UI8NATIVE2

**USER_REPORTED / DEVICE:** independent CarPlay QA displays two real apps and a speed HUD. User rejects parity with Native12 HUD8: missing per-pane zoom/restore, wrong per-pane picker, splitter ratio dragging only works while panes are empty, app display looks squeezed, iPhone preferences differ, and first SpringBoard respring still reports exit mode. User provided conversation image `IMG_7824374B-6453-481B-8B44-55EB1AF9E308.jpeg` (not copied to repo). The previous claim that full native UI was transferred is REJECTED. UI8NATIVE2 is a failed UI-parity release, not a pass.

### Source-verified architectural causes

1. `replacement/visual12/engine/runtime/DFIRuntime.m` runs `DFV12SplitController` from `DFIInterface.inc` — an independent, custom alpha-era renderer. It does not instantiate the Native12 UI hierarchy (`CBBridgedSplitApp`, `CBSlotPillView`, `CBDividerView`, `CBMultitaskingOverlayView`). The native `DuoFaceDashboard.dylib` is compiled/CB-coupled, not provided as editable UI source. Previously copied only logo/tab styling and the separate `DFV12NativeHUD8` UIView; these do not constitute a native interface transfer.
2. `DFIInterface.inc` gives a single `toggleZoom` toolbar action; it calls `DFHostSetExpanded` and `DFIChromeSetZoom` for the external screen, NOT focus/restore one app slot. Per-pane `self.maximized` is used for layout but is not wired to the native pill's expand and restore buttons. Source `src/DuoFaceVisualHook.m` preserves the actual Native `CBSlotPillView` `_expandButton`, `_restoreButton`, and `_dotsButton` actions.
3. QA per-pane picker uses a custom 32x26 ellipsis `UIButton` plus `DFV12List`. This is not original native per-pane menu/picker. The menu in Native is a native `CBSlotPillView` with original callbacks, and `CBMultitaskingOverlayView` sheet; see `runtime/fullscreen/DFPickerZoomMenu.xm`.
4. QA divider only has two 36x44pt/44x36pt `UIButton *grips`, and the 1pt line is non-interactive. Their `UIPanGestureRecognizer` is the only route to `drag:`. Native uses `CBDividerView.handlePan:` to `CBBridgedSplitApp.handleDividerPan:isVertical:state:`. Separate native tap=swap, 0.30s hold=move logo, drag outside logo=resize are documented in `src/DFDividerLogoGrip.inc` and `audit/divider/GRIP_MOBILITY_NATIVE6.json`. Active app `SBAppViewController.view` is attached to each pane. **Device reproduces touch loss with live apps, but cause of lost hit test is NOT YET VERIFIED; inspect UIKit hit-testing and actual drag logs rather than guessing.**
5. QA `DFV12SceneHost.resizeTo` sets content reference size to 2x pane dimensions and transforms its view to 0.5x, propagating the artificial logical size via `applySize`. This is real source evidence of constrained layout, but not yet proof of the user's exact visual problem; native scene frame/scale reference must be compared.
6. iPhone Preferences: `replacement/visual12/build_qa.sh` pins `independent/engine/preferences/Entry.m` at `d5227b4`, while `replacement/visual12/engine/shared/DFISettings.m` builds a four-section generic Settings controller, hardcoding `0.1.0~alpha2`. Native uses audited `CBGeneralSettingsViewController`/`CBDashboardSettings` (see `audit/payload-migration/ORIGINAL_SETTINGS_OBJC_METHODS.json`) with non-license features: auto-launch, dock monitoring, hide app labels, screen blank, language, reset and respring. Re-implement only legitimate independent options, not vendor license/subscription.
7. User reproduces `exit mode` on the FIRST respring, separate from standalone6invalidate's user-verified ordinary scene-close fix. A contemporaneous SpringBoard crash .ips + `/var/mobile/Library/Logs/DuoFaceVisual12-runtime.log` is still missing for this event, so no exact root cause is proven. Source to examine: `DFIStart`, `DFIStop`, `DFIConnectionChanged`, `UIRootSceneWindow`, host scene lifecycle and `setRequestedMode:0` / `invalidate`. Do not repeat untested timed-retain fixes.

### Updated execution checkpoint and acceptance

- STATUS: repository/source review confirmed wrong renderer and missing features. User device test confirms behavior failures. No new UI patch, build, CI or Sileo release in this audit. Existing `ui8native2` on Sileo is unaccepted and should not be called native parity.
- NEXT: preserve `feature/visual12-duodash-recovery` and `standalone6invalidate`, implement an independent Native12-equivalent per-slot pill (app picker, focus/restore), native-divider gesture ownership and full hit area, accurate scene geometry, and independent native-style iPhone Settings. Follow source audits rather than copying the licensed/vendor runtime. Log both empty and live app divider hit tests and scene resize. Investigate first-respring exit mode from device log/ips separately.
- RELEASE GATE: no new Sileo build until UI parity features compile, static/integration tests pass and a versioned QA-only DEB with checksum is ready; subsequent user CarPlay testing must confirm active-app divider movement, per-pane controls, settings and respring. Never modify Native12 HUD8 stable payload.
