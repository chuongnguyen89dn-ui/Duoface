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
