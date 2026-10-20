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
