# Native Dashboard owner — independent DuoFace implementation candidate
Branch: feature/mytweak-native-dashboard-owner-20261019

User requirement: keep V1BC proven two-app host but make real Apple Dock/Home visible, no vendor licensing, no fake Dock, no unsafe boot/LaunchServices hooks, Sileo when functional. Source is added in prototype only, not currently compiled in Sileo build.

## New step executed
1. New `MTCPNativeChromeLayout` takes **actual ON-SCREEN DBStatusBarWindow/CARStatusBarWindow geometry** to derive a bounded content rectangle. Rejects x=-45 when width45 on x0 screen (known user log), hidden/offscreen/transient windows, full-screen notification window, nonfinite positions, malformed sizes. Accepts left/right/top/bottom and keeps full root window, like DuoFace Native12. No constant 45 or 64; not a "crop the UIWindow" workaround.
2. `MTCPDashboardOwner` attaches a separate first-party **subview only** to the EXISTING Dashboard owner `DBDashboardRootViewController.view` and external `UIWindowScene`, with authenticated opt-in pair and a live two-second CAContext session from SpringBoard. No independent `UIRootSceneWindow`, no new window, no native UI mutation, no LS/entitlement hooks. Requires an actual *visible* Apple sidebar window. At the currently logged x=-45 it refuses attachment, not falsely declaring Dock fixed.
3. `MTCPRemoteLayerReceiver` fixes the **confirmed iOS16 zero-safeArea blocker**: its previous code would reject the actual CarPlay owner probe `safeAreaInsets=0` on all windows. Zero insets are now allowed ONLY for measured-owned, appropriately sized `duoface.native.content.host` directly beneath exact `DBDashboardRootViewController`, never the native root view itself.
4. Foundation/CoreGraphics runtime test covers x=-45 rejection, visible 45pt sidebar, other Dock edges, malformed/nonDock windows. iOS16 arm64+arm64e Objective-C syntax build, source-only. No DEB until live pixel feed / interactive touch / workspace native Home exists.

## Why this remains source-only
- No SpringBoard V1BC live CAContext publisher call site yet; the existing `MTBridgeRootViewController.view.layer` is already attached and must not be detached/repurposed without correct ownership semantics.
- CarPlay's native Dock was observed at **x=-45, outside the screen**, so a hidden=false toggle is not enough. Cannot claim this code restores Apple's real Dock.
- Touch sender emits pointer packets, but no device-verified iPhone application touch injection/route or Dashboard Home state transition.
- Device root UIView and CALayerHost API compatibility require **hardware proof**. The source tests do not supply it.

Do not modify QA11, Native12/HUD8, V1BC recovery, original SidePlay, existing OwnerProbe release or carplaydsp publisher in this step.

Next engineer: integrate actual independent publisher safely, verify CAContext does not detach live app host, then authenticate GUI real pane pixels/touch; implement Dashboard workspace Home/normal interaction with an authorized first-party scene, avoid old shell1 LS bootstrap failure. Once runnable, isolated opt-in DEB/rollback and user device test, only then claim Sileo Dock candidate.
