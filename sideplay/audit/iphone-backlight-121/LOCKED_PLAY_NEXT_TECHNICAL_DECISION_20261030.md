# DuoFace locked-iPhone YouTube Play — QA120 physical verdict and next evidence gate

Status: 2026-10-30 Asia/Ho_Chi_Minh. Read-only decision, **NO new signed build, no public QA121 release, no on-car fix claim**.

## Current accepted facts
- User tested signed public QA120 on the real car: **native Apple Dock/content geometry fixed**. Do not change QA120 x45 authenticated geometry, .90 orientation, .92 divider, or initial CarPlay Dock.
- YouTube scroll and ordinary controls still respond. Only video Play requires iPhone main display to be lit; screen-off Play still fails. This is not a generic disabled touch region. No session-correlated QA120 device log with new `qa120-pane-tap` and `qa120-hosted-touch-hit` has been uploaded; latest user main log remains schema119, exported around 07:41 on Oct30, before signed QA120.
- In original DuoNavi signed DEB, SHA-pinned ARM64 methods `CBBridgeManager.-acquireCarPlaySleepAssertion` @0x1c05b8 and `releaseCarPlaySleepAssertion` @0x1c0650 call `IOPMAssertionCreateWithName`/Release; signed literal `PreventUserIdleSystemSleep` corroborates type. OmniCar AppBridge original contains `SBSuspendedUnderLockManager -_shouldBeBackgroundUnderLockForScene:withSettings:` and `BKSDisplayServicesSetScreenBlanked` strings; original OmniCarSplitScreen has `setPreventsDisplaySleepDuringVideoPlayback:`. Class auth-pointer ABI prevents a proved complete call sequence.
- First-party QA121 `DFTouchOwnerProbe.m` `0f927954` adds scoped IOPM system-idle request, releases on Home/disconnect/2.5s watchdog. **Code committed only.** No compiled QA121 DEB or Sileo. Attempt to create QA121 signed workflow was blocked by tool safety. Do not use an alternate operation to evade this denial.

## New external API evidence (verified)
- Official Apple IOKitUser IOPMLib.h (apple-oss-distributions/IOKitUser, main, `pwr_mgt.subproj/IOPMLib.h`) defines `PreventUserIdleSystemSleep` as preventing **system idle sleep**, but explicitly allows the display to dim or sleep; it is not a display-brightness or per-process foreground/scene assertion.
  Source: https://github.com/apple-oss-distributions/IOKitUser/blob/main/pwr_mgt.subproj/IOPMLib.h
  Apple API: https://developer.apple.com/documentation/iokit/kiopmassertiontypepreventuseridlesystemsleep
- A separate public CarPlay hosting project explains an *under-lock remote application* pathway: `SBSuspendedUnderLockManager._shouldBeBackgroundUnderLockForScene:withSettings:` determines whether a hosted app is backgrounded when device locks; its project documentation directly associates retaining correct per-app owner status with CarPlay interactivity under lock. Reference **only**, do not transplant vendor/project source or license:
  https://github.com/EthanArbuckle/carplay-cast/blob/master/src/hooks/SpringBoard.xm
- Hence the QA121 IOPM patch **alone may not repair YouTube Play after device locks** even if it builds/acquires successfully. Moving directly to publish solely based on the power assertion would be speculative. The root may be YouTube foreground eligibility/AV playback activation, not touch coordinate mapping and not actual brightness. This is a strong new investigation direction, **not** proof of specific iOS16 device causal source.

## Next actions, ordered, with acceptance conditions
1. Keep public QA120 unchanged; it has on-device geometry PASS. No more layout/size/blank-Dock experiments.
2. In a parked vehicle with QA120, reproduce against the *same video*: (A) screen awake at minimum brightness, (B) screen off/locked, (C) turn screen back on; attempt Play each time. Export built-in `DuoFaceAudit` **while still connected**, from iPhone `Xuất log / lỗi CarPlay`. Record approximate time of lock/unlock. This is not asking for the already existing schema119 log again: the missing evidence is new QA120 runtime lock and Play trace.
3. Compare in actual new log `qa120-pane-tap` vs `qa120-hosted-touch-hit`, YouTube app process `UIApplicationState`/scene `isForeground` during lock, FBScene background transitions, Chrome physical window session heartbeat. Physical tap accepted but no remote Play with YouTube scene background means use a **per-scene, validated independent owner policy**, not a global hit-test or media-touch workaround.
4. Before shipping QA121, the stalled signing/workflow creation must be resolved through authorized normal means, not bypass safety. Even a passing QA121 package must be labeled an experimental power/scene diagnostic until a real vehicle Play test.
5. Scope the potential correction strictly to live user-selected YouTube scene and active CarPlay session; ensure legitimate iPhone lock privacy, CarPlay Home and disconnect close/release; never force full-brightness screen or perpetual no-sleep on iPhone.

## Source/QA references
- `sideplay/audit/iphone-backlight-121/REPORT.md` and `ORIGINAL_SLEEP_CALLSITES.md` are SHA-checked original reports (CI success runs 40987073215,40987452972,40987599003,40987713036).
- `sideplay/tiep tuc du an.md` is the single active handoff and should be updated with this decision; no independent project code or binary copied.
