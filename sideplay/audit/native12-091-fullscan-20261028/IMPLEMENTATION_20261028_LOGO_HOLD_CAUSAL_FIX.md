# DuoFace logo gate – first safe code correction from original UI audit (2026-10-28)

Scope: **source-only**, independently authored 3-second logo hold; no vendor licensing or runtime copied; no CarPlay Dock, native Maps ownership, SBAppViewController, YouTube scene orientation or window setup change.

Evidence basis:
- Original Native12 CBDividerView.handleMoveButtonLongPress: (0x1005f4) uses distinct onRotate / onSwap callbacks; touch down/up uses onActivity/onSwap, per verified real original ARM64 static run 40700551205.
- User specifically requires **hold the circular logo 3 seconds then move** (intentional custom behavior, NOT asserted to be original vendor's exact threshold).
- DuoFace .91 DFNative12Chrome.m previously called beginDividerDragAt: on raw logo touch-down and immediate DFDragMove on every raw move; this allowed accidental ratio change and broke 3-second hold. Source confirmed before change.
- Pure C DFDividerDrag.h and its ratio tests remain UNCHANGED; the surrounding divider track continues immediate ratio pan.
- New independent DFLogoHoldGate.h allows only a clean >3.0 second stationary grip then motion parallel to divider; early >7pt movement rejects that contact, perpendicular after-hold movement rejects; quick tap ≤0.5 sec swaps, hidden first tap wakes only; cancellation/long stationary hold never swaps. Uses monotonic NSProcessInfo.systemUptime and current UIScreen touch coordinates.
- In DFNative12Chrome.m the gate is applied strictly to raw touch on DFNativeDividerGripButton. After unlocking, it deliberately locks the existing DFDividerDrag.axis to DFDragLogo, never DFDragRatio. Existing auto-hide respects logoTouchPending while finger is down. Only successful drag persists logo position; ratio remains unchanged on logo contact. Stop/start resets gate state.
- Added executable native C policy tests tests/test_logo_hold_gate.py; source CI modified to compile and run it, plus the existing tests. The historical no-hold assertion in test_scenehost_safety.py was revised to test separate track and grip contracts rather than conflict with user override.

Commits:
- b8324faf4d7ef8220e38b33d77060b6c093e12c5 – DFLogoHoldGate.h
- 25eb74f4c9c3869a7083c0831d02636c5b2e897d – tests/test_logo_hold_gate.py
- f2bf6850cc55f8ccbcf002ec432cdf969c6cd4ca – DFNative12Chrome.m fix
- af5d1fe35d6c2074b2273b179df762a0e01d53c9 – source-only workflow gates
- ae6c5b1dc3d579704fbba85862861649dd700900 – update obsolete no-hold regression test

CI:
- run 40703459408 FAILED due **obsolete source test** test_scenehost_safety.ImmediateDividerDragContract forbidding any logoHold; **not** a compiler/device failure.
- run 40703528927 CANCELLED after newer regression-test commit, no result to claim.
- run 40703684327 started after the corrected test, status MUST be checked on GitHub; no success claimed here before verification.
- No integrated DEB, no Sileo publication, no hardware install or CarPlay validation from this correction yet.

Acceptance on parked physical car before any production claim: brief clean grip tap swaps; tap when hidden wakes only; hold still 3.0s then slide parallel moves logo without split ratio change; pre-hold swipe, perpendicular swipe and cancellation never alter ratio; physical divider track still drags ratio instantly; no old menu overlay/YouTube orientation regression; 4s idle hides controls but held finger remains active.

Next P0 independent of grip: native Maps CarPlay dashboard controller remains different UIWindow owner than SpringBoard physical slots; no proven native scene surface compositor or FBScene size push/readback. Do not turn the existing CarPlay same-process VC adoption ACK into a false map-tiles PASS, and do not scale Maps arbitrarily. Focus/native apps persistence, close/restart and iPhone enabled-list should follow original 22 method callback graph after grip acceptance.
