# DuoFace Native Dock Owner Probe 0.0.1 (QA, Sileo)

**Goal:** identify native CarPlay window/scene owner, safe-area reservation, Dock class and remote layer capabilities on iPhone X iOS 16 **without modifying any native UI**.

This optional separately installable `com.duoface.carplay.ownerprobe` package does not modify `com.duoface.mytweak.v1a.preflight` or QA11/Native12/HUD8; it does not create a custom window or show a fake Dock.

## Actual operations
- Inject into CarPlay and CarPlayApp processes only (not SpringBoard); 8-second deferred startup, no hooks/LS capability swizzling, no postinst/preinst scripts or auto-respring.
- Read connected `UIWindowScene`, window classes, external screen, safe area, root controller class and optional DBWorkspace / DBDockWindow / CAContext / CALayerHost class presence. Read at most 16 windows per sample, up to 40 samples, stop on external display window or timeout.
- Write `/var/mobile/Library/Logs/DuoFaceNativeDockOwnerProbe.log`; mirrored via NSLog if sandbox denies file writes.
- No scene activation, window resize, third-party binary or license code. No native Dock/Home fix, no app mirroring or touch forwarding in this standalone probe. Hardware safety/availability **unverified** until user tests.
- Install from Sileo only after CI and Pages SHA verification. The package is a one-shot diagnostic to resolve the previously unknown **native owner/usable region** blocker for the CarPlay presentation bridge prototype; it is not a request to retest previously verified V1BC features.

## Hardware test (parked vehicle only)
1. Refresh Sileo and install **DuoFace Native Dock Owner Probe (QA)** (ID `com.duoface.carplay.ownerprobe`), not the old unsafe `0.2.5~shell1`.
2. Allow CarPlay process to restart normally when safe (no package postinst restart). Connect CarPlay once; no UI change is expected.
3. Check the file in Filza `/var/mobile/Library/Logs/DuoFaceNativeDockOwnerProbe.log`. Send only the native window/geometry log, NOT a repeated gesture test.
4. If stuck/crashes, Safe Mode remove this standalone probe only; do not remove QA11/Native12/HUD8.

Success for this diagnostic only: one `complete` record showing actual CarPlay UI process window/scene ownership (or a `complete` record proving no external window reached), plus file log and zero new device crashes. It does **not** imply Apple native AppDock fixed or touch working.
