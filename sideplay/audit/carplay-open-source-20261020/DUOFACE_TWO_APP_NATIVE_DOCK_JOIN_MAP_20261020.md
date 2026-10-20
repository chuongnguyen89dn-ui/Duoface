# DuoFace native-Dock + two real iPhone app panes: Verified function-level JOIN MAP
Date: 2026-10-20 (Asia/Bangkok)
Repo: `chuongnguyen89dn-ui/Duoface`
Purpose: answer user's direct challenge: **have the DEB dual-app functions actually been analyzed to know where they can connect to a Dashboard-owned CarPlay scene, without fake Dock, screenshot, or license?**

## 0. Hard requirements and current proof
- Default native CarPlay Dock/Home is *CarPlay/Dashboard-owned*, appears automatically in NORMAL, NOT by moving or re-showing system `DBStatusBarWindow`, not a synthetic Dock or overlay, and not by short timer/45-second lease. User wants two live touchable independent iPhone apps, Split + draggable ratio + Swap + Zoom/restore, normal controls, proper reconnect and no exitmode.
- QA6 user-device reality: sometimes *real Dock and functional app panes*; repeated full-screen regressions. Source has TWO 45-second reverts. Sileo QA6 remains a useful rollback reference, NOT the final target.
- Existing V1BC user-device proof: **two** simultaneously live app panes with true UIKit touch; native Dock missing on independent full-display window. No change to baseline until native join passes.
- Ref binary audit version Native12 in branch `feature/duoface-exact-payload-migration`:
  - `dist/payload-migration/native12/com.duoface.independent_0.1.0~native12_iphoneos-arm64.deb`, SHA256 `85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7`.
  - `DuoFaceDashboard.dylib` SHA256 `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`. Source-level machine traces and method metadata already persisted:
    * `feature/duoface-exact-payload-migration:audit/v12-split-slot-wiring-full-20261014.txt`
    * `feature/duoface-exact-payload-migration:audit/speedbubble/NATIVE12_SPEED4_SPLIT_OWNER_CHAIN_READONLY.json`, blob `ed232daf44fe6e482f49eec132572e687363f590`
    * `feature/duoface-exact-payload-migration:audit/payload-migration/NATIVE12_CONNECTION_FULL_OWNERS_READONLY.json`.
  - **These files contain disassembly and Objective-C symbol/selector signatures, not decompiled vendor source. A selector present is NOT proof of successful runtime delivery or default native Dock.**
- SidePlay 1.0.4 preserved in `main:com.sideplay_1.0.4-1_iphoneos-arm64.deb`, SHA256 `7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c`, inventoried in `sideplay/audit/deb-1.0.4-1/`. Binary strings `macho-strings/002-SidePlay.dylib.strings.txt` contain `SBAppViewController`, `SBApplicationSceneHandleRequest`, `_sceneIdentityForApplication:createPrimaryIfRequired:`, `initWithIdentifier:andApplicationSceneEntity:`, `carDockArea`, `carWindowFrame`, `initWithWindowScene:`. Static names corroborate live scene hosting and geometry, but without resolved callsite ordering cannot prove its end-to-end native Dock behavior. SidePlay plist declares CPTemplate scene role and `SPCarSceneDelegate` yet the dylib uses SpringBoard private hosting independently.

## 1. Source-proven FIVE LAYERS for the independent join

### Layer A. Get real Dashboard app/scene ownership — CarSurf reference only (NOT transplant source)
GitHub: `https://github.com/pavunato/carsurf` (NO LICENSE in tree; GitHub license=null; conceptual research only).
- `sbtweak/CSAppList.m`: Dashboard CarPlay app roster based on `CARApplication._allInstalledApplications` preserving genuine apps + allowlist.
- `sbtweak/CSSceneManifestSpoof.m`: iOS 16/17 runtime LaunchServices typed capability and scene-role admission for enabled apps; `UIWindowSceneSessionRoleCarPlay`, multi-scene flag. This is private jailbreak hook, **not** Apple's official entitlement issuance and can trigger bootloops if implemented carelessly; do not copy unlicensed code.
- `sbtweak/CSCarLaunch.m`: under **CarPlay process** uses `DBApplicationController.sharedInstance`, `DBMutableWorkspaceStateChangeRequest.activateApplication:`, and `DBWorkspace.requestStateChange:`, with `DBDashboardWorkspaceOwner`. This is the normal Dashboard icon-activation path; `carsurf-launch` is merely a diagnostic equivalent to tapping an icon, **NOT an instruction to show native Dock**.
- `apptweak/CSSceneBridge.m`: remaps incoming CarPlay role to the enabled app's *ordinary* interactive `UIWindowScene` before construction, installs activation/disconnect handling and scene-safe layout. Measures `scene.coordinateSpace.bounds` before reading `window.safeAreaInsets` (reset from unmodified bounds before every measurement) to avoid cumulative shrink.
**Desired result of independent DuoFace Layer A**: a first-party host scene participating in Dashboard workspace; CarPlay system continues to own Dock/window chrome, no manual `DBStatusBarWindow` changes.

### Layer B. Window attachment — proven Native12 MACHINE CODE, not just method names
Original Native12 `+[CBWindow carPlayWindowScene]`, IMP `0xaf690`.
Original Native12 `-[CBWindow createWindows]`, IMP `0xb1064`:
- `0xb10a4` calls `carPlayWindowScene`; `0xb10c0` calls `carPlayUIScreen`; tests whether a CarPlay `UIWindowScene` and screen are available.
- `0xb1160–0xb1284` prefers an existing scene `displayConfiguration` or its `_FBSScene.settings.displayConfiguration` when possible.
- `0xb1288–0xb12bc` is FALLBACK via `FBSDisplayConfiguration initWithCADisplay:isMainDisplay:` if no scene display configuration is available. **This matters: Native12 is NOT exclusively a native workspace app; do not claim this source proves that.**
- `0xb12cc–0xb1410`: searches `UIRootSceneWindow` / `SBFTouchPassThroughWindow` / `UIWindow`, creates or dynamically derives `CBTouchPassThroughRootSceneWindow`; hooks `hitTest:withEvent:`, `pointInside:withEvent:`, `sendEvent:` so input policy is part of the window layer rather than a static screenshot. Callsites have direct machine-code evidence in the persisted disassembly.
- `0xb1428–0xb153c` tests `initWithDisplayConfiguration:`, `initWithWindowScene:`, `initWithScreen:`, `initWithFrame:` as available and `setWindowScene:` when supported; this is a **two-path window initialization strategy** rather than our one-path `initWithDisplayConfiguration:`.
- `0xb1584` may set window level; `0xb15d0` reads `carPlayUsableBounds`; `0xb1600–0xb1618` sets window frame to full display, `0xb1758` sets root VC. There is *no proof* this method by itself grants default native Dock. App must first be correctly admitted/presented by Dashboard via Layer A. We must not copy these binary class internals or assume a custom window can inherit Dashboard ownership just because it uses an existing screen/scene configuration.
- Independent V1BC `sideplay/mytweak-independent-v1a/MTBridgeCoordinator.m:attachToCarPlayDisplay:` only creates `FBSDisplayConfiguration` + `UIRootSceneWindow` in **SpringBoard**, sets `MTBridgeRootViewController` full display and windowLevel Normal. THIS is the architectural difference to replace. Do NOT solve by blindly invoking `initWithWindowScene:` on a SpringBoard object with a CarPlay-process scene object (cross-process UIKit objects cannot be passed as Obj-C pointers).

### Layer C. TWO independent app scene hosts (per-slot)
Native12 `CBBridgedUIAppView` (verified objective-c selectors / IMP):
- `initWithBundleIdentifier:scale:` `0xac704`, `startInParentViewController:` `0xadf30`, `calculateNativeSizeForSlotRect:` `0xacc28`, `updateSceneSettingsFrame` `0xad5bc`, `updateSceneFrame` `0xade4c`, `refreshSceneLayout` `0xade58`, `dismiss` `0xaf01c`. Touch overrides `hitTest:withEvent:` `0xac940`, `touchesBegan:withEvent:` `0xaca6c`.
- `CBBridgedSplitApp.startInParentViewController:` `0x10bb1c` looks up manager `window` / `rootViewController`, calls per-slot `startInParentViewController:` at disassembly line `0x10bc4c`, calls `layoutSplitViews` `0x10bd48`. This CONFIRMS the reference separation: ONE parent/window **contains** N app views; per-pane source views are started INSIDE that parent, not N CarPlay Dock root windows.
- Independent V1BC `MTSceneHost.m:hostViewForBundleID:error:` demands MAIN-THREAD **SpringBoard** and privately instantiates `SBApplicationController` → `SBDeviceApplicationSceneEntity` → `SBAppViewController initWithIdentifier:andApplicationSceneEntity:`. The `MTSceneSurface` attaches controller as a child and sets requested mode 2; resizes scene settings via `updateSettings:withTransitionContext:completion:`, 2× logical source / 0.5× scale, polls `sceneHandle.sceneIfExists`; `stop` requests mode 0 and invalidates. It is the running two-app host and should be retained.
- **UNRESOLVED PROCESS BOUNDARY**: `MTSceneHost` refuses execution outside SpringBoard, whereas a genuine Dashboard-owned DuoFace app scene runs in its own app process. `SBAppViewController`/the UIKit child views cannot simply be `addSubview` into another process. App A and App B can't automatically coexist as two independent foreground Dashboard workspaces either; standard workspace activation has one top app. Need a designed **cross-process live scene surface/input bridge**, or prove a supported private parent/scene hosting method that runs in the SAME process as the split container. DO NOT repeat QA5/QA6 `drawViewHierarchyInRect` or pretend `CALayerHost` image transport has working multitouch.

### Layer D. Layout, ratio and input
Native12 `CBBridgedSplitApp`: `handleDividerPan:isVertical:state:` `0x103ee0` → `layoutSplitViews` `0x1044f8`; `focusSlot:animated:` `0x105890`, `restoreSplitAnimated:` `0x105e2c`, `toggleFocusForSlot:` `0x106518`; `handleDividerSwapPressed:` `0x108fc8` → `swapSlot:withSlot:` `0x10915c`, `replaceAppInSlot:withBundleIdentifier:` `0x1098c0`, `closeSlot:` `0x10ab28`, `closeAllSlots` `0x10b0b8`. App views/containers/dividers are separate properties.
V1BC `MTSplitContainerViewController.m` already does `dividerPanned:`, `dividerHeld:` (0.3s) → `swapSlots`, and `toggleFullscreenForSlot:`. Slots `MTAppSlotViewController.m` install the live `MTSceneSurface` in a content view; double-tap `cancelsTouchesInView=NO` preserves touches.
**Known V1BC DIFFERENCE**: it clamps leftRatio to [0.25,0.75]; user expects reversible *infinite drag to solo* with three-dot recovery from Omni or DuoFace reference. This must be an independent UI state-machine change after native ownership works, not connected to the primary Dock bug.
Native12 touch `CBTouchPassThroughRootSceneWindow` selector hooks and `CBSplitContainerView hitTest:withEvent:` prove original explicitly handles routing. Cross-process transport must route **begin/move/end/cancel plus gesture and orientation** to correct active pane; `sendActionsForControlEvents` to top menu alone (QA5) is insufficient.

### Layer E. Safety and teardown
Native12 `CBBridgedSplitApp stop` `0x10beec` / `CBBridgedUIAppView dismiss` `0xaf01c` / `CBWindow destroyWindows` `0xb21f8` distinguish scene stop from UI hide. Native12 `CBBridgeManager` also contains licensing and mandatory disconnect kill watchdog; **DO NOT graft proprietary `CBBridgeManager` into independent code or copy its license/watchdog**.
Independent split host `MTSceneHost.stopAllHosts` owns scene invalidation; must run from SpringBoard on car disconnect, opt-out, app selection changes and explicit Close; avoid double invalidation/race with CarPlay app-scene shutdown.
CarSurf uses `UISceneDidActivateNotification` and `UISceneDidDisconnectNotification` so Dashboard owns normal/default UI lifecycle.

## 2. Exact independent connector to implement, subject to evidence gates
```
CarPlay process: real DBWorkspace + DBDashboardWorkspaceOwner
    ↓ normal app roster / icon activation (CarSurf **concept**)
Independent DuoFace CarPlay application scene: UIWindowScene owned by CarPlay,
normal safe area measured from real scene, native Dock **left untouched**
    ↓ independent DFDashboardSceneOwner (has explicit scene connect/disconnect)
DFTwoPaneRootController (V1BC behavior, ratio/swap/zoom/menu)
    ↓ two slots, retains one app session per slot
DFSceneSurfaceTransport (UNRESOLVED IMPLEMENTATION BOUNDARY)
    ↔ SpringBoard MTSceneHost (existing SBAppViewController for app A + app B)
       two live FBS app scenes, per-slot layout, restore & invalidation
```
**If an app-associated CarPlay UIWindowScene cannot contain the SpringBoard scene surfaces with genuine complete touch, the above is ONLY an interface sketch; it is NOT a functional solution.** Alternative to validate: one CarPlay-host process is both host and child scene owner under private FBS APIs (requires runtime proof, not assuming class availability); or live remote layer with a true touch bridge to original app scene. Do not use a fake Dock, fake license, no direct commercial byte-for-byte code copying, and do not turn on early LS hooks in SpringBoard without bootloop rollback.

## 3. Integration plan with measurable stop/go gates
1. **A: native Dashboard-owned entry first**. On a new isolated source branch, build only a read-only/version-gated scene/app-admission prototype. Probe classes in correct processes; avoid injecting into `carkitd`; no UIApplication window creation, no native Dock writes, no entitlement edits on disk, no auto-respring. Confirm *only* independent DuoFace app gets a native Dashboard entry. Use normal CarPlay icon tap, no `showDock`.
2. **B: persistent native Dock with safe area**. Within that CarPlay-associated scene, load a harmless solid-color debug root WITH NO arbitrary iPhone app host; verify native Home icons work and persist >2min including reconnect, orientation and phone lock. This is a necessary gate before adding two apps. On unexpected class/selector mismatch, fail closed; preserve Sileo QA6 and recovery.
3. **C: prove cross-process scene surface and all touch**. Attach exactly ONE existing V1BC live SpringBoard app scene into the native CarPlay host, with actual interactive tap/swipe/scroll/video/keyboard, not raster screenshot, without stealing a private UIKit parent pointer across processes; verify scene remains alive through layout changes. If this fails, stop; don't build fake Split UI to hide failure.
4. **D: connect TWO scenes to independent split controller**. Preserve V1BC existing slot engine, call host twice for distinct bundle IDs, refresh size for each slot when divider moves, swap controllers without destroying scenes, zoom focus/restore without toggling host Fullscreen. Native Dock stays system-owned all along. Add full drag-to-solo and recovery menu after basic 2-pane gate.
5. **E: validate cleanup**. Disconnect/reconnect/respring / close one slot / swap / zoom no duplicate scenes, no SpringBoard exitmode, no automatic native chrome hide. Then isolated Theos CI + Sileo test candidate. Only replace public QA6 once all device gates pass.

### Direct acceptance contract
- NORMAL app launch from CarPlay icon: native Dock/Home visible *without* NativeSidebarTrial, window-level tricks, forced DBStatusBarWindow frame, timers or 45point constants; stays >2 minutes.
- Two DIFFERENT selected apps genuinely interactive at once, including swipe/scroll and real player graphics; ratio variable and stable, Swap doesn't relaunch; Zoom doesn't accidentally hide system Dock; user-requested intentional host Fullscreen clearly separate.
- Crash/bootloop rollback accessible; stable QA11 / Native12 / HUD8 / V1BC remain unchanged during development.

## 4. Evidence & limitations
**Completed in this analysis**: checked real original Native12 ARM64 instruction traces around `CBWindow.createWindows` from `NATIVE12_SPEED4_SPLIT_OWNER_CHAIN_READONLY.json`; confirmed class/selector ABI and trace of per-pane `startInParentViewController`; compared directly to V1BC `MTBridgeCoordinator.m`, `MTSceneHost.m`, `MTAppSlotViewController.m`, `MTSplitContainerViewController.m`, `MTBridgeRootViewController.m`; cross-checked original SidePlay 1.0.4 strings, CarSurf native dashboard workspace/scene design.
**NOT complete**: no proven CarPlay-owned DuoFace entitlement/roster implementation; no proven cross-process touch transport; no compiling/building new executable; no runtime proof for a native CarPlay app scene enclosing two independently hosted views. A simulator/CI pass cannot close those device gates.
**Avoid misunderstanding**: Native12 `CBWindow.createWindows` probes CarPlay UIWindowScene first but **still falls back to independent UIRootSceneWindow**. It is not proof that Native12 obtains natural Dock ownership by itself. The app must actually be admitted into native Dashboard workspace.
