## 2026-10-29 — .111 signed QA archived, public Sileo deployment gate

- User-requested three CarPlay Home/return regressions: (1) saved YouTube slot reopens blank and must manually reselect; (2) startup splash repeats after Home; (3) old DuoFace windows linger over CarPlay Home. These are physical device observations with installed .110, NOT device-tested .111 results.
- Independent original DuoNavi/Native12 comparison: `CBBridgedUIAppView.dismiss` / `CBWindow.destroyWindows` / `bridgeDidDeactivate` from archived ARM64 disassembly reports. Vendor code/license not imported. DuoFace's old teardown destroyed SBAppViewController scene and new Chrome unconditionally replayed splash.
- Source contract .111 `b95ba2a52427cc4c20a6f409a385074c08029d54`: hide SpringBoard-owned windows *before* PID / Dock / scene cleanup; distinguish true CarPlay unplug from Home and skip startup screen only on Home reentry; saved approved YouTube scene waits 13.5 seconds (old seven-second timeout was shorter than actual scene poll 12.6 seconds) and may retry once after a real failure, never synthetic ready. Preserve current one/two-pane layout, correct logo no-hold two-axis gesture, system Dock and old .90 YouTube orientation.
- Source GitHub CI at same source SHA: `40832650203` ratio/disconnect/restore SUCCESS; `40832650213` Native12 UI source regression SUCCESS; `40832650277` multi-slot workspace SUCCESS; `40832650163` strict picker SUCCESS. Separate native Maps original-only probe `40832650329` failed and MUST NOT be represented as a full-green matrix; its failure is independent of the new Home fix.
- Actual signed integrated .111 package: build run [40832650431](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40832650431) **SUCCESS**. Archive commit `7cdd1d91bec80b38d51d563a3c8fae1c104806d9`, package `sideplay/jb-embedded-appbridge/evidence/runs/40832650431/com.duoface.jb.embedded_0.0.111~home-reentry-youtube1_iphoneos-arm64.deb`, SHA256 `05519c72474b12274e3cd54a348d54a13203999bb6b710b648b0dd7868e3124c`, verified from repo `SHA256SUMS.txt` and `BUILD_SOURCE.txt`. Artifact ID `12879337506`. Package contains first-party rootless native modules; GitHub binary archive is NOT evidence of installation.
- Publisher repo `chuongnguyen89dn-ui/carplaydsp` main `f3620ba623038cb99c9750cba74efeff3dceb3c3` pins the exact archive source URL and SHA, `.111` latest one APT entry, retains earlier binaries. Actionlint [40833123520](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/40833123520) SUCCESS; [build/publish 40833123461](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/40833123461) **build SUCCESS; deploy queued at this checkpoint**. Mark public only after deploy + remote Pages download/Packages verifier both PASS.
- On-device acceptance still pending: CarPlay Home 3x with real YouTube playback before exit, immediate overlay removal, no second splash, both old app choices live on re-entry (not merely saved labels), no duplicate host / blank video; and physical cable unplug separately with opt-in 10-second shutdown, check `/var/mobile/Library/Logs/DuoFaceTouchOwner.log`, `DuoFaceSceneHost.log`, `DuoFaceDisconnectClose.log`. No Filza, no automatic phone installation.

---

# DuoFace Home/re-entry lifecycle forensic — 2026-10-29

## User-reported CURRENT device behavior (.110)

1. Exit DuoFace to Apple CarPlay Home then re-enter: physical app choices are remembered, but YouTube pane is blank until selecting YouTube manually again.
2. Every Home → re-enter shows the full DuoFace startup logo/progress anew.
3. DuoFace windows/divider remain visible briefly above CarPlay Home after leaving.
User requires direct comparison with original Native12/DuoNavi and functioning Sileo DEB for real device QA. These are DEVICE OBSERVATIONS, not claims from CI.

## Original binary evidence vs first-party source (do NOT copy vendor license/code)

Verified original pinned Native12/DuoNavi ARM64 SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`. Previously saved original reverse engineering:
- `sideplay/audit/native12-continuation-4888299/dismiss-selref/ORIGINAL_DISMISS_SHARED_SELECTOR.json`: original `CBBridgedUIAppView.dismiss` @`0xaf01c`, first `removeFromSuperview` receiver = appController.view; `CBWindow.destroyWindows`/`bridgeDidDeactivate` handle outer Home chrome.
- `sideplay/audit/native12-039-regressions-20261023/END_TO_END_ORIGINAL_APPBRIDGE_081_GAP_MATRIX_20261027.md`: Native12 `setRequestedMode:0` and invalidate/child removal are distinct from app-process termination; `CBBridgeManager` owns foreground lifecycle and `refreshSceneLayout`/app state reflow.
- `sideplay/audit/native12-091-fullscan-20261028/COMPREHENSIVE_UI_FUNCTION_PARITY_VERDICT_20261028.md`, rows 02,19,20: splash and Home cleanup exist in original; old DuoFace parity NOT device-proven. **No original hardware call trace** proves original's exact Home retention strategy; do not claim it keeps the exact YouTube FBScene alive.

## Verified independent-source causal chain and changes

- `DFNativeHostAppDelegate.m`: on `sceneWillResignActive`, `stopTouchOwnerWithReason:@"scene-resigned-carplay-home"` writes `Active:NO` and Darwin stop; entering again creates a fresh UUID.
- `DFTouchOwnerProbe.m`: `DFStopProbe` always invalidates/tears Chrome and `DFSceneHost.stopAllHosts`; original code captured PIDs / detached Dock before hiding external DuoFace windows. Fixed to call `[sChrome hideAllExternalWindowsImmediately]` BEFORE Dock detach, PID collection and app-scene invalidation; native Dock/CPWindow are untouched. Home and physical unplug separated by verified `AVExternalDevice.screenIDs/CADisplay`.
- `DFNative12Chrome.start`: old unconditional `self.startupActive=YES` + 1.3s launch `splashWindow` on **every** CPTemplate scene entry. Implemented `sShownFirstSplashForPhysicalConnection` in SpringBoard: Home same physical CarPlay display skips splash, first cable connect shows native logo, genuine physical unplug resets flag. `beginSavedWorkspaceRestore` starts without false full startup on Home.
- `DFSceneHost.stop` invalidates prior SBAppViewController with mode 0; immediate automatic YouTube rehost may race old scene teardown (user selecting it later succeeds). `DFNative12Chrome.restoreNextSavedWorkspaceApp` previously abandoned pending at **7s**, while `DFSceneSurface.pollScene` permits **36×0.35s = 12.6s** before its own timeout. Fixed to 13.5s plus exactly ONE bounded retry after actual host failure/timeout, generation-cancelled; still requires approved+installed persisted bundle and actual ready scene; log every skipped allowlist/install and retry. This is a grounded *possible* causal mechanism, NOT proof of original Youtube-specific on-car failure.
- Existing 4-slot saving, native Maps lease, ten-second opt-in disconnect close, original .90 YouTube rotation, independent vertical logo drag, four-second auto-hide and Apple Dock remain untouched.
- Source files: `sideplay/duoface-native-scene-host/DFTouchOwnerProbe.m`, `DFNative12Chrome.m/.h`; test `sideplay/duoface-native-scene-host/tests/test_carplay_home_reentry_111.py`; `.github/workflows/duoface-ratio-disconnect-restore-source-qa.yml`.
- Relevant source commits `335e04ba87532112d3463f90d7c57b403ba004fc`, `8d355c1184660c2b04c0fef9ebc2f85d31897932`, `0c4ff4109e80d0abe2a0a9c1490165cc1abd4d2a`, `7d8102814cd37057b2a22837226ddb83dabe71bb`, `2c02c0b5ed9972552abfef6fb2cbf8a0a2cfd846`. Follow-up source QA PASS `40832259218` (real iOS16 Objective-C syntax + macOS executable policy), `40832259165` Native12 regression, `40832259143` saved workspace; current final-source QA `40832650203`, `40832650213`, `40832650277` also PASS.
- QA package .111 source `b95ba2a52427cc4c20a6f409a385074c08029d54` workflow [40832650431](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40832650431) **started**. DO NOT CLAIM Sileo/publication until signed DEB archived, SHA-pinned carplaydsp Pages publisher build/deploy/remote Packages+DEB hash PASS. Public .110 is old source and does NOT contain this Home fix.

## Device confirmation gates (parked car only)

1. With actual CarPlay physically connected: open DuoFace and show YouTube + another iPhone-approved app; press physical CarPlay Home then re-enter. **No startup screen on re-entry**, YouTube comes back WITHOUT a manual app picker action; current physical split/logo and Apple Dock correct.
2. Exit to Home: verify zero remaining DuoFace divider/window overlays after OS transition. Note any perceptible lag; export `/var/mobile/Library/Logs/DuoFaceTouchOwner.log` with events `home-own-windows-hidden-before-scene-invalidate`, `home-reentry-splash-skipped`, `workspace-restore-pending`, `workspace-restore-skipped-allowlist-or-install`, `workspace-restore-requeued-after-host-failure`.
3. Then REAL cable unplug/replug: first cable connect splash allowed once; rehost only allowed saved app IDs. With opt-in disconnect close ON test Maps process/voice and ACK `VerifiedExited`; default switch OFF legitimately closes nothing. Do not interpret mere scene disappearance as PID exit.
4. Inspect SpringBoard scene-host log `/var/mobile/Library/Logs/DuoFaceSceneHost.log` for `scene-host-timeout`/`scene-attached`/`scene-handle-observed-render-unverified`. Ready/CI is not proof of YouTube pixels; user screenshot/video required.

## Latest verified state

Source CI PASS only and signed .111 workflow in progress at last observed. Device tests NOT RUN. Previous .110 Sileo publisher [40830957635](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/40830957635) SUCCESS; not sufficient for new fix.

