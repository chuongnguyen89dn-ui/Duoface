# DuoFace independent native CarPlay scene — stage A source

- Branch `feature/duoface-native-scene-join-v1-20261020`.
- This is **executable code** for a read-only scene/geometry contract on the actual CarPlay host process. It does NOT make DuoFace an admitted native CarPlay app and does NOT attach two iPhone app scenes yet.
- No vendor executable or CarSurf code is copied. CarSurf informed the independent two-owner design; its repository is publicly readable but lacks a verified redistribution license.
- Runs only in `CarPlay` / `CarPlayApp` (not SpringBoard), starts after ten seconds, then checks active external `UIWindowScene` for the system-owned `DBDashboardRootViewController` and `DBDockWindow`/ `DBStatusBarWindow`.
- It reads `coordinateSpace.bounds` and `safeAreaInsets` without modifying any window or system Dock, writes session-bound short-lived geometry to `/var/mobile/Library/Preferences/com.duoface.native-scene-owner.v1.plist`, logs to `/var/mobile/Library/Logs/DuoFaceNativeSceneJoin.log`.
- The record is `native-dash-readonly`, **not** proof DuoFace's OWN app scene is admitted. If the native safe area is zero, the record retains original bounds, not a fake 45pt Dock crop. A production consumer must check both scene identity and true Chrome before allowing UI.
- Tested by `python3 -m unittest discover -s sideplay/native-carplay-scene-v1/tests -p 'test_*.py' -v` and Apple Foundation native `DFNativeSceneContractTests.m` in the isolated CI workflow.
- Rollback: uninstall ONLY `com.duoface.carplay.nativejoinprobe` (it has no maintainer scripts, no SpringBoard process injection, no independent window, no hooks). No dependency on or replacement of existing QA6, QA11, Native12/HUD8 packages.

## Stage B follow-up (NOT DONE)
1. Establish safe iOS16 rootless app admission for the independent DuoFace host: only after checking symbols on CarPlay device, with disable-on-mismatch; let Dashboard open a genuine CarPlay-associated application `UIWindowScene`. Never toggle actual native Dock or add a fake one.
2. Build versioned connection from that scene to existing SpringBoard-owned `MTSceneHost`; one live iPhone app with real tap/swipe/cancel via verified scene input routing. Do not reuse QA5 image stream or pretend a layer ContextID enables touch.
3. Reuse `MTSplitContainerViewController` / two `MTAppSlotViewController` instances, route ratio/swap/zoom and teardown. Only then device QA and isolated Sileo distribution.

## Stage B iOS16 app roster introspection (added in 0.0.3)

The passive CarPlay process probe records `native-admission-abi` (CARApplication class and installed-app query selectors; LSBundleProxy typed entitlement getter selectors, FBSApplicationInfo bulk getter, DBWorkspace initWithOwner:). Method signatures are observed via Objective-C runtime only, without calling/swizzling any private method or changing eligibility. CarPlay/CarPlayApp may dynamically load these classes after startup, so the ABI snapshot repeats every 30s. No new SpringBoard injection.

The independent real UIWindowScene host is in `sideplay/duoface-native-scene-host` and not publicly installed until native admission compatibility is verified.

## V6 live native Maps owner snapshot (2026-10-28; read-only)

This revision adds `DFCarPlayLiveOwnerSnapshot.m` to the existing **isolated** CarPlay/CarPlayApp-only diagnostic. It never creates a native scene, changes a Dock, launches Maps, alters a zoom ratio, calls a foreground/background lifecycle method, or replaces the working DuoFace 0.0.83 player. Package `com.duoface.carplay.nativejoinprobe` version `0.0.4~mapowner1`. Source branch: `feature/duoface-jb-embedded-appbridge-20261020`.

Capture path on the jailbroken CarPlay iPhone: `/var/mobile/Library/Logs/DuoFaceCarPlayOwnerSnapshot.log`. The existing DuoFace QA app's **Export Diagnostics** appends this log (if readable) to its manually shared `DuoFaceAudit.txt`. No telemetry or automatic upload is performed. No Filza installation is required: distribute as a distinct DEB through Sileo after package and publisher verification; GitHub Actions compilation alone is **not** an installed probe.

To collect useful live evidence, while parked and plugged into actual CarPlay: (1) leave the existing 0.0.83 functional DuoFace build untouched; (2) install the standalone diagnostic using Sileo only; (3) open Apple Maps from the CarPlay system interface and start a normal route, do not exit Maps, then leave it visible for at least 35 seconds; (4) switch to the split interface while keeping navigation ongoing, leave it visible at least 35 seconds; (5) export DuoFace QA diagnostics manually. Compare `process`, `processPID`, `probeSession`, `sceneClass`, `sceneRole`, `sceneIdentifier`, `rootController`, `controllerClass`, `viewSceneIdentifier`, `sceneHostViewStatus`, host view bounds and host scene identity across the two states. A `sceneHostViewStatus=nil` for any controller is NOT a native Maps scene host. Absence of a matching controller means *unresolved*, not a successful native map owner join.

The `mapsNativeOwnerProven=false` field is deliberately constant until independent analysis of **live** maps controller↔scene↔host evidence. Running a source/CI build only verifies compilation and bounded static safety, never the device's Maps scene identity or attachment. Read-only snapshot records only UIKit-connected UIWindowScene trees reachable from the CarPlayApp/CarPlay process. A Maps scene isolated to another process might not be reachable; that is an explicit limit to record, not something to work around by forging an owner or by scaling a phone MainDisplay scene.

CI workflow: `.github/workflows/duoface-live-map-owner-probe-v6.yml`, compiled DEB and manifest persist to `sideplay/test-artifacts/native-map-owner-v6/` only after a successful workflow; it does not publish to Sileo. Uninstall standalone package to roll back without touching the DuoFace runtime. Existing original OmniCar DEB remains reference-only and no vendor binary/license is copied.

## V7 guarded native app-scene owner capture (2026-10-28)

Uploaded actual V6 iPhone X data: `main/sideplay/log/DuoFaceCarPlayOwner-D48F4C0E-A72B-4621-ABA3-36DF83CFF037.jsonl`, commit `78bccd3c85be5a13c644b1360ab208296ad15514`. Three CarPlayApp snapshots proved a real `DBApplicationSceneViewController.sceneHostView` of 427×240 and a new controller/host instance at each snapshot, but did not link any host to the native Maps app. Dashboard map widgets must never be confused with the native Maps application scene.

Same isolated diagnostic package `com.duoface.carplay.nativejoinprobe` upgraded to `0.0.5~mapowner2`, no third tweak or additional app. For *only* `DBApplicationSceneViewController` instances, V7 checks zero-argument Objective-C object-return ABI and observes `scene`, `applicationInfo`, and a bounded app bundle ID / scene ID when available. It records nil/missing statuses rather than assuming native Maps. It does not reparent sceneHostView, activate/background any app, change app permissions, change UI, or alter native Dock. `mapsNativeOwnerProven=false` remains intentionally false until the actual new JSONL confirms ownership.

Use the already-published standalone `DuoFace Map Log` iPhone exporter `0.0.1~jsonl1` to share the entire JSONL after running Apple Maps native navigation 35 s and DuoFace split 35 s while parked. The existing functional DuoFace `.83` player remains unchanged. CI build is not equivalent to a device runtime pass; the Sileo publisher must separately pin and verify this new DEB before instructing installation.
