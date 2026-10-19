# DuoFace MyTweak — native CarPlay AppDock integration decision (2026-10-19)

## Decision
**STOP the failed approach** `dock1` (crop a SpringBoard-made external window according to a guessed/recorded `DBDockWindow` rectangle). User reports real Apple AppDock still absent after Sileo `0.2.1~dock1`. The independent MyTweak engine hosting two concurrent apps on a real car display is **user-tested working** (App/Single/Split/Swap/Zoom/Close, ratio/touch). Keep this engine unchanged while replacing the *presentation/activation/navigation bridge*, not the host. No vendor binary/assets/license; independent work. Do not manufacture a fake 48/64pt bar. No blind windowLevel changes.

## Verified DuoNavi 1.0.4 original mechanism (read-only ARM64)
Source: `feature/visual12-duodash-recovery:audit/duonavi-original104-ui/ORIGINAL104_UI_CALLCHAINS.json` and `REPORT.md`, binary `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb` SHA256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`, `DuoNaviDashboard.dylib` SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`.
- `CBWindow.createWindows` IMP **`0xb173c`**: searches `carPlayWindowScene`, `carPlayUIScreen`, `carPlayCADisplay`, scene `displayConfiguration`, `_FBSScene`; candidates `initWithDisplayConfiguration:`, `initWithWindowScene:`, `initWithScreen:`. Uses `carPlayUsableBounds` and `setFrame:`. **Correction of earlier assertion:** original DuoNavi can also create its own external UI windows; an independent UIWindow is **not by itself proof** of incorrect architecture/Dock occlusion.
- `CBWindow.carPlayContentInsets` IMP **`0xb1370`**: path reading a serialized `UIEdgeInsets` from disk and fallback through `activeCarPlayWindow.rootWindow.safeAreaInsets`; exact dynamic path priority is conditional and not established by selector list alone.
- `CBWindow.carPlayUsableBounds` IMP **`0xb15cc`**: derives content rect from `carPlayScreenBounds` plus `carPlayContentInsets`, validates dimensions.
- `CBWindow.resizeWindows` IMP **`0xb24ac`**: reads both full bounds and usable bounds and updates layers/host geometry. Thus original uses **system-related content geometry** for panes rather than treating the external display as universally usable.
- `CBWindow.show` IMP **`0xb2814`**: `resizeWindows`, visibility / key-window operations.
- Original report is static ARM64 metadata/assembly, NOT verified native AppDock appearance, entitlement bypass algorithm or complete dynamic call graph.

## Verified Native12 function inventory
Source: `feature/duoface-exact-payload-migration:audit/payload-migration/NATIVE12_CONNECTION_FULL_OWNERS_READONLY.json`, SHA256 native12 DEB `85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7`.
- `CBBridgeManagerDashboard`: `prepareHomeScreenForBridge:`, `requestActivation:`, `requestStateChange:`, `handleDockIconTap:`, `setAppDockActiveBundleID:`, `setHomeButtonInApp:`, `updateCarPlayMetrics`, `getDockDimension`, `getDockWidth`, `getDockEdge`.
- `CBBridgeManager`: `receivedDashboardReadyNotification:`, `receivedDockTapNotification:`, `sendStateToApp:shouldBridge:`, `handleCarPlayConnectionChanged:`.
- **Important distinction**: `dockSystemMonitorEnabled` is the device performance/status overlay, not Apple's CarPlay AppDock.
- Selectors prove function presence, **not** that these routes work on the license-limited device, nor the content of Apple Dock implementation. Do not reuse original compiled CB* managers/watchdog.

## Verified DuoDash 1.1.3 layering (static report)
Source: `feature/duoface-exact-payload-migration:audit/duodash-1.1.3/DUODASH_APPBRIDGE_VISUALTEST12_CROSSWALK_20261017.json`; independent DuoDash DEB SHA256 `ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465` from `chuongnguyen89dn-ui/DauDat-CarPlay`.
- SpringBoard `CNABSpringBoardObserver` handles external connect / host requests `onHostRequest:` and `onHostRequestSplit:`.
- `DDz2 cnabBuildSceneHostForBid:displaySize:` builds application hosts using `SBDeviceApplicationSceneEntity`.
- `CNABUIApp setBridgeState:width:height:orientation:` communicates app state to CarPlay layer.
- CarPlay UI `DDz1 showLayoutPanes:natives:bids:` arranges visual panes.
- Process filters include SpringBoard and **`com.apple.CarPlayApp`**; a previous MyTweak Dock probe filters *process name* `CarPlay`, which logs `event=start` but **fails to observe `DBDockWindow`**, and neither name alone proves which UI process owns the sidebar on the user's iOS16.
- This does not prove how DuoDash raises the system Dock z-order or what entitlement private framework values it actually modifies. It strongly suggests **multi-process host/layout coordination** is required.

## Public independent comparator
`pavunato/carsurf/sbtweak/CSCarLaunch.m` tests `processName=CarPlay` and captures `DBWorkspace` with `DBDashboardWorkspaceOwner`; uses `DBApplicationController`, `DBMutableWorkspaceStateChangeRequest activateApplication:` and `DBWorkspace requestStateChange:` for standard dashboard navigation (not two-pane owner by itself). The project reports running iOS16.7.12; **not** proof of compatibility with this device/tweak. Refer for concept only, license/source permissions require separate verification before reuse.

## Current MyTweak vs independent target
Current code: `sideplay/mytweak-independent-v1a/MTBridgeCoordinator.m` (feature branches) locates `CADisplay`, creates `UIRootSceneWindow initWithDisplayConfiguration:`, assigns `MTBridgeRootViewController`, initial frame all display, `windowLevel=UIWindowLevelNormal`; `MTDockLayout` clips the window **only** if a fresh valid native Dock geometry record appears. Device log reports `native-dock-not-measured-use-original nativeKind=none` before Zoom. `MyTweakDock.log` has only `event=start process=CarPlay`. Thus **DOCK1_FAIL user-confirmed**, owner/occlusion/scene routing mechanism unresolved; Zoom is not initial cause; user explicitly says Airaw NOT installed.

### New independent interface contract (implementation target; not deployed)
1. **`MTDashboardContext`** (CarPlay process, read-only initialization): discover actual UI process name/bundle, active `DBWorkspace` with `DBDashboardWorkspaceOwner`, native scene/window + `safeAreaInsets`/usable content bounds and Dock/Home UI state. Record source, time and failure reason without modifying Apple windows or user data. Do not rely exclusively on `DBDockWindow` class existence.
2. **`MTDashboardCoordinator`**: own a *single* activation/close/home handoff state machine (Disconnected → DashboardReady → HostActive/Normal/Split/Zoom → Home → Closed), tied to real workspace/scene lifecycle. Prefer CarPlay-owned navigation events and restore Home on Close; do NOT activate synthetic fake Home or claim workspace launch alone hosts two panes.
3. **`MTSceneHost` reuse**: preserve working independent two-app host, touches and audio/ratio/swap/zoom/close, but attach its visual presentation inside a Dashboard-accepted content region when reliably available. If no valid dashboard context, fail closed and keep known working v1bc separately, don't automatically show another full-cover layout while claiming native Dock support.
4. **`MTContentGeometry`**: derive content rect from actual CarPlay scene/safe-area insets (like the original DuoNavi evidence), measure change on Home/normal/split/zoom/rotate; do not infer Dock width solely from `DBDockWindow` or constants; avoid overlays on native system nav.
5. No vendor license checks, binaries, entitlements faked by borrowing old paid product. On iOS jailbreak using private APIs must be independently authored, conditional, ABI-checked; no claim Apple's public app entitlement supports arbitrary iPhone hosting.

## Implementation order and hard acceptance gate
A. Verify CarPlay-process owner/scene and `safeAreaInsets` on iOS16; compare actual `UIRootSceneWindow` full frame vs Dashboard usable bounds (requires a new diagnostic that reports these *directly*, not just `DBDockWindow`).
B. Write one independent Dashboard-aware controller + content bounds adapter on a separate branch; compile rootless arm64/arm64e and static tests. Do not alter QA11, Native12/HUD8, original DEB, or publish Sileo.
C. Release at most ONE candidate after source-level ownership and fallback checks pass; preserve current working package as rollback.
D. Real CarPlay device acceptance: **Apple's own AppDock/Home visible + actually navigates home and back**, two simultaneous apps and all existing gestures still work, no exitmode on Close/reconnect/respring. No fake Apple nav. User must confirm; CI alone insufficient.

## Checkpoint
At writing, **research/crosswalk only**. No functional Dock fix or new device-proof; `0.2.1~dock1` still user-reported FAIL. Source branch `feature/mytweak-dock-runtime-diagnostics-20261019` currently diagnostic changes not released. Save main handoff path `sideplay/tiep tuc du an.md`. Next engineer should start with section A, not another geometry-only Sileo release.
