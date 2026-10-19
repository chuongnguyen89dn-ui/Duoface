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

## CI result checkpoint (verified, 2026-10-19)
- [GitHub Actions 39222793011](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39222793011) **completed SUCCESS**. Source commit `64a3e66ad3ff87718dc04887b2b598e3052927ea`. Build workspace uses macos-15 and xcrun iOS 16 SDK, `clang -target arm64-apple-ios16.0` and `arm64e-apple-ios16.0` for `MTCPNativeChromeLayout.m`, `MTCPDashboardOwner.m`, `MTCPRemoteLayer.m`, `MTCPBridgeContract.m`; all syntax PASS. Executed native CoreGraphics/Foundation test `22/22` assertions PASS, including x=-45, 45pt left, right/top/bottom, no-Dock, invalid/NaN/inf and containment. Python source assertions + inherited V1BC tests PASS. GitHub Actions persisted `sideplay/test-artifacts/mytweak-native-dashboard-owner-source/{CI_RESULT.txt,RUNTIME_GEOMETRY.log,SOURCE_TESTS.log,SOURCE_SHA256SUMS.txt}` in isolated branch, head commit `436c4227b9a233253bccb5ef6b0cd68dd237e609`; files retrieved/read back.
- **Not a device result.** Current CarPlay device log offscreen x=-45 is correctly **REJECTED**, so it does not magically restore Dock; the new Dashboard owner is not installed and still lacks live independent CAContext source-publisher, full touch/gesture routing, and registered CarPlay first-party shell plus real Home activation. No tested on-device crash behavior. Sileo untouched; user previously requested working native Dock, so do NOT publish this source-only phase as a Dock fix.
