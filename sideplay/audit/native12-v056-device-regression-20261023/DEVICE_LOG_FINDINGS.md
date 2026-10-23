# Supplied device logs: Zoom / logo / ratio, 2026-10-23

## Evidence
Raw logs in device-logs/ beside this report. Whole-file counts (historical sessions mixed; no per-line timestamps or build IDs):
- DuoFaceDockOwner.log: 335 lines; SHA256 cb8c1f0232ace47a6b96dbba5a26aeff6d91406fcd0cf5c2b0a6ec2a648f7dee
- DuoFaceTouchOwner.log: 4838 lines; SHA256 e78e56cb38dc7cc237762b2c6eeabc225fe783036f2d06063c6b4543be084556
The tail contains restored-v056 markers, proving this code path executed, not proving every earlier entry is .56.
Read active DFCarPlayDockOwner.m and prior-turn DFNative12Chrome.m/DFTouchOwnerProbe.m.

## Findings
1. Global Zoom receives the press. Touch log tail contains native12-card-zoom-in-request-real-dock followed by native12-whole-host-zoom-rejected expanded=1 real-dock-ack-timeout: no-verified-live-native-appdock (lines 4632, 4767, 4823, 4835). Thus do not continue claiming no target/action connection as explanation for these recorded presses.
2. Receiver runs in CarPlay (13 listener-ready records). All 107 discovery attempts have matches=0 (87 with 10 windows; 20 with 11). 107 replies reject expansion with no-verified-live-native-appdock; no applied=1. ACK ordering mitigation cannot repair absent candidate discovery. However logs lack actual window/controller class hierarchy and rejected geometry, so they do not prove whether class whitelist, window filtering, view geometry, or process ownership excludes the correct Dock. Do not guess a new class or hide arbitrary left-edge views.
3. Missing-restorable-dock-snapshot occurs 5 times during restore; consistent with no successful hide snapshot. No-fresh-foreground-session occurs 23 times; do not conflate cleanup/session expiry with initial live discovery failure.
4. Logo input works at the tracking entry: 14 logo-actual-touch-begin, 9 logo-prehold-moved-cancelled-hold, zero logo-3s-hold-began-control-tracking and zero logo-3s-moved-position. Source logoTouchChanged cancels the pending timer by incrementing logoHoldSerial after hypot(perp,parallel)>7 before recognition. Source timer silently returns on serial mismatch. This proves early-motion cancellation occurred; without elapsed time/delta records it does NOT prove device jitter, how long each finger remained down, or that raising tolerance alone fixes the requirement.
5. Ratio path runs: 7 logo-quick-ratio-drag-began-restored-v056 plus ended records; tail has Ratio dispatch and accepted state acknowledgments. Example lines 4722-4738, 4791-4799. This is command/state evidence, not independent visual pane resize validation.
6. Repeated Zoom presses while pending produce owner-or-session-not-ready. The coordinator uses this broad refusal label; do not infer session loss solely from it, especially when one pending request later returns discovery timeout.

## Decision and next implementation
No new runtime patch/build/publish in this analysis. Preserve Native12 appearance and global-vs-slot distinction.
- Compare existing original Native12/working historical Dock getter implementation with DFZLocateLiveNativeDock. Capture read-only bounded per-window/root/controller/native-dock candidate diagnostics (class, process, activation, converted rect, screen rect, rejection gate) on failed discovery. No user content or app lists; do not relax safety gates without measured owner evidence.
- Compare original touch-down/up/hold lifecycle to current UIButton tracking. Record monotonic elapsed hold time, perpendicular/parallel delta, timer cancellation reason and serial; preserve immediate cross-axis ratio and exactly 3s threshold. Change movement policy only with source/reference and measured evidence.
- Then compile using existing workflow, inspect packaged source provenance, publish scoped new candidate when meaningful repair is supported, and test on actual CarPlay.
- Physical acceptance: global Zoom hides/restores actual system Dock and both panes; 3s hold permits vertical logo motion; quick horizontal drag retains ratio; no video regressions.

## Reproduction of this analysis
Workspace /workspace/scratch/3de6c9fb51b5. Read upload/01-DuoFaceDockOwner.log and upload/02-DuoFaceTouchOwner.log. Python pathlib read_text().splitlines(), collections.Counter of Dock lines, substring counts of Touch markers, hashlib.sha256 of original bytes. No code or maintainer scripts executed on phone.
