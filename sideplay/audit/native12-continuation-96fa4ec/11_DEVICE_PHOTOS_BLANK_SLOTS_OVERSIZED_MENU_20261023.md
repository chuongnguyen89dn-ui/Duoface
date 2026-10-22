# 2026-10-23: real CarPlay screenshots of independently published .38 — UI parity regression

## Grounded device observations
User supplied TWO phone-camera photographs immediately after installing the newly published `com.duoface.jb.embedded 0.0.38~native12sourcehost49` test candidate (installation version is inferred from conversation, **no package screenshot or dpkg proof**). Both photos show the real CarPlay system dock (orientation of phone photos is vertical, but logical external UI rotates to landscape), two mostly black empty bordered split panes and a central circular DuoFace logo; the menu control pills appear near the outer edge of each pane. A second photograph, rotated to understand orientation, shows a very large semi-opaque rectangular GRAY action sheet across almost all split-pane area: horizontal DuoFace logo at top left, four bright App/Zoom/Style/Close action areas across header, X at top right, and **no visible body controls/actual app content below**. It obstructs both pane surfaces. These are REAL image observations, **not** a proven crash or host readiness failure.

## Verified cause in the exact shipped source, not conjecture
- Current `sideplay/duoface-native-scene-host/DFNative12Chrome.m` creates the outer four-action menu with `pw=MIN(470,MAX(180,cr.size.width-16))` and **`ph=MIN(280,MAX(140,cr.size.height-16))`**, then fills full sheet with blur/material and ONLY a single horizontal toolbar row y=7/h30 plus dismiss X; `menuContext.text=@"";hidden=YES`; there is no body view. `layoutContextMenuForPane:` repeats the same giant height. At measured device content `~462x240`, this means a **446x224pt blank modal** over actual CarPlay panes, precisely matching the photo. That size is a **locally invented** panel, not backed by the immutable original Native12 method.
- The real original Native12 `CBMultitaskingOverlayView.setupCardContent` @0xa2a58 has 32pt **SHORT header** when H<260 and 38pt tall otherwise, and distinct **3 inner modes Apps/Layout/Recent** with content under the header. `DFNative12CardHeaderGeometry.h` is SHA-audited against original `DuoFaceDashboard.dylib` SHA256 9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea, backed by `03_ORIGINAL_HEADER_TABS_AUDIT.md`. Four OUTER actions are NOT a justification for drawing an empty 224pt sheet. Remove ONLY the blank body from outer action toolbar, preserve separate real App/Style/Recent sheets, and keep real system Dock.
- Both empty panes are clearly visible; source `DFNative12Chrome.m` initializes `hostedScenes` and `pendingScenes` to NSNull; starts with **no assigned app bundle IDs**, intentionally displays actual empty containers and outline, and does not attempt to attach any remote app until user selects one through `DFAppPickerVC` via App. **Do not claim video/scene host failed yet** without an actual app selection and logs.
- Entire physical device screen includes system CarPlay icons/dock, so don't claim CarPlay Dock absent. Photos alone do NOT verify interactions, remote media orientation or SafeMode.

## Immediate scope
1. Prevent the proven invented full-area empty gray outer four-action menu: use audited original short/tall header sizing, keep functional four actions and X, keep separate existing **nonempty** App/Style/Recent picker windows; preserve real running scene windows.
2. Add source-level regression assertions for no 280pt/140pt menu cap and for single header row not blank full modal.
3. Trigger source CI, build one incremented rootless signed candidate only after tests pass, pin SHA and publish to existing `chuongnguyen89dn-ui/carplaydsp` source, verify public Pages/index/hash, never silently replace original historical Speed8.
4. If panes still black after **user selecting two actual applications**, obtain `/var/mobile/Library/Logs/DuoFaceSceneHost.log` and `DuoFaceTouchOwner.log` before touching app admission or inventing media layout.
5. Native12 + independently ported Speed8 still NOT equal to original and 8-speed HUD intentionally unlinked. No claim all functions work.

## Pre-change evidence
- Signed build: DuoFace Actions 39871335334 SUCCESS, sha256 2055200d75d48495d0e4d55abd0b8caabb976498e19442e2fb5ab8c76eed5e7e.
- Sileo Pages: CarPlayDSP Actions 39871787459 SUCCESS; user photos prove external interface visible, NOT correctness.
- Branch prior HEAD d39f06b286f19f40f05285f9cd0a8f5c34e027fa.

