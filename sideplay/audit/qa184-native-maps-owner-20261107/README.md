# QA184 — Maps presenter membership / shared owner lease (SOURCE-ONLY)

## Goal and user constraints (2026-11-07)
Repair native Google Maps inside the actual DuoFace two-pane CarPlay UI; do not force Google Maps into stock Apple Home, replace it with iPhone Maps, turn off the watchdog, disable Home safety, or use vendor source, binary, activation or license logic. User confirmed a physical OFF trial had Maps visible and touchable with UI wrong. The newer user decision is to repair the already observed native presentation/ownership path first, while **preserving OFF as a deferred hard release requirement, not cancelling it**. Existing logs still have `stockSettings=UNKNOWN`, so do not claim every historical record was instrumented as ON.

Baseline: repo `chuongnguyen89dn-ui/Duoface`, branch `feature/duoface-qa182-b1nativemaps1-20261107`, head `dad12dba608e7ce5561c7452497d133b38174277`. Patch branch `feature/duoface-qa184-native-map-owner-sourceonly-20261107`. QA182 Audit13 cumulative 17/17 native assignments revoked (16 `Chrome-Home-or-disconnect`, 1 `app-replaced-in-native-slot`); 7 Gate0 v2 post-presentation callbacks have true CarPlay-role native scene; 54/125 v2 scene samples positive. Existing `native-owner-state active=0` precedes watchdog detach.

## Specific code changes — implementation hypotheses, not device acceptance
1. `sideplay/native-carplay-scene-v1/DF182NativeMaps.m`: hook the **actual Apple** `DBDashboardRootViewController presentBaseViewController:animated:launchSource:completion:` only if the checked iOS 16 ABI matches; invoke original once; synchronously observe the genuine `DBApplicationSceneViewController`, `FBScene`, native CarPlay window, live assignment and physical pane geometry. Only this post-original gate writes `PRESENTED` with a maximum **0.85-second** transitional receipt. Recheck verified UIKit containment, frame, hit target and native scene periodically before writing `COMMITTED` (fresh every 0.25s). On loss, `REVOKED` precedes restore; never assume pixels/touch are accepted from static source checks.
2. `sideplay/duoface-native-scene-host/DF184NativeMapMembership.h`: separate, versioned, atomic shared membership. CarPlay is the evidence writer; SpringBoard and DuoFaceNativeHost validate exact session + assignment + physical slot + Maps bundle + native scene + window role + Home-ready and <=1.25s freshness. Unknown, revoked or stale fail closed. The original nativehost owner remains available.
3. `DFCarPlayOwnerLease.h` and `DFNativeHostAppDelegate.m`: both ordinary SpringBoard watchdog and nativehost *background heartbeat* use the same new native Maps receipt. Do not skip or broaden watchdog checks. NativeHost evaluates the live foreground-to-background transition against a receipt without editing its persisted pulse.
4. `DFNative12Chrome.m` / `DFTouchOwnerProbe.m`: a Maps assignment no longer destroys the previous target app before scene commit, nor the other physical pane. Hide only target window pending handoff; on revocation, restore visibility of preserved app. Keep the existing `app-replaced-in-native-slot`, Home and disconnect paths.

## Source-only testing (no DEB)
Workflow `.github/workflows/duoface-qa184-native-owner-sourceonly.yml` runs on this patch branch: QA184 source contracts, frozen QA182/H1 tests, Foundation receipt acceptance/rejection matrix, original owner-lease tests, and iOS16 arm64 syntax-only compile of changed modules. It does **not** run a packaging script or publish to Sileo. CI success, if achieved, means only source/compile verified. No device installation or road/CarPlay test has been performed for this patch.

## Physical acceptance criteria (not yet passed)
- Verify with real on-car screenshots and gestures, not a `PASS` string alone.
- Actual map pixels correctly filling its *DuoFace* pane for **multiple minutes** with touch and map interaction, while the other app remains alive and usable.
- Genuine native Apple CarPlay Home **app icon grid** return, with correct exit/re-entry behavior; not merely Dashboard or a substituted picker.
- Clean disconnect, reconnect and rollback with no stale scene/lease, no orphaned windows.
- Revisit stock per-car Customize **OFF** as the unchanged hard final-product requirement once owner/pane is stable. A genuine programmatic OS reader remains unverified.

## Execution limitations
No dedicated macOS/iOS16 SDK or physical CarPlay is accessible in this current runtime, and the source-only CI must be inspected before reporting any pass. Do not claim a build, signed package or vehicle acceptance without its corresponding evidence.
