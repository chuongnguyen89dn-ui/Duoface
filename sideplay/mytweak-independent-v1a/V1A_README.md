# MyTweak independent SceneHost — v1a read-only diagnostics
Source baseline: Project Library file \`MyTweak_Independent_SceneHost_trial_source_20261018.txt\`, SHA256 \`ea561904b62717f617706ba453e004f037feef4a3c6cdab2c00327f0dac50e16\`, 25 files. This branch retains baseline source and adds a diagnostic mode, without copying any vendor runtime.

## Default behavior (important)
\`Tweak.x\` has \`MT_V1A_PREFLIGHT_ONLY 1\` and starts \`MTPreflight\`, **not** \`MTBridgeCoordinator\` or \`MTSceneHost\`. No hosted app, root CarPlay window, dock overlay or private setter is invoked. This build is for inspection only and is **not a working replacement for SidePlay/Native12**.

At SpringBoard startup and external screen connect/disconnect, log selector availability + method type encodings, CarPlay CADisplay matching, current SpringBoard UIWindow/UIScene classes and AppDock view presence (capped traversal). Evidence goes to SpringBoard console and, when writable, \`/var/mobile/Library/Logs/MyTweakV1A.log\`; file absence is not automatically a host failure.

## Verification gates
- Static: \`cd sideplay/mytweak-independent-v1a && python3 -m unittest discover -s tests -v\` (structural only).
- Compile only: \`cd sideplay/mytweak-independent-v1a && make clean all\` with Theos, iOS 16 rootless SDK (NO \`make package\` or Sileo publication). No iPhone test is implied by a green CI job.
- Device (separate explicit test package later): **do not install alongside any existing CarPlay hook/host**; preserve rollback and obtain user consent before replacing active test package. On a parked vehicle check \`diagnostic-start\`, selector encodings, \`carplay-display matched=1\`, UIWindow/UIScene/AppDock signatures, detach no SpringBoard crash; compare with native Dock screenshots. No app launching in v1a.
- v1b after review: enable one host in an isolated experiment and verify actual pixels/touch/audio, resize and teardown; \`scene-ready\` alone never passes.
- v1c: dual host, divider ratio, fullscreen, real Apple Dock Normal, reconnect/respring no exitmode. No dock = NO-GO, not a 64pt fake overlay.

## Rollback and independence
Current QA11 \`0.1.9~native12dock11\` and Native12/HUD8 public builds must remain unchanged. Never merge/test two CarPlay hosts concurrently. Native12/Visual12/HUD8 are behavior and visual references only, **not runtime/class dependencies**. This branch does not modify licensing, SidePlay DEB, or publish Sileo.

## Isolated DEB build candidate — v1a1 (2026-10-19)
The isolated package builds only `V1ATweak.x` plus `MTPreflight.m` as `com.duoface.mytweak.v1a.preflight`. The binary is `DFV1APreflight.dylib`, not `MyTweak.dylib`, and contains no UI or app-scene host code. Original source remains for v1b/v1c. All build outputs must be saved to `sideplay/test-artifacts/mytweak-v1a/` on the same repository branch.

No automatic Sileo publication or installation. Before any manual on-device install, save a rollback path, verify SpringBoard safe mode and avoid other CarPlay host experiments; use parked vehicle only. Collect `[MyTweakV1A]` lines (and `/var/mobile/Library/Logs/MyTweakV1A.log` if writable), display/window/AppDock results, and any SpringBoard `.ips`. Removal package command: `dpkg -r com.duoface.mytweak.v1a.preflight` (follow device recovery instructions if SpringBoard cannot boot). QA11/Native12/HUD8 unchanged.

Implementation note: on iOS 16, passive lifecycle snapshots use `UISceneDidActivateNotification` and `UISceneDidDisconnectNotification`, and report `UIApplication.connectedScenes` count; they do not use deprecated `UIScreenDidConnectNotification`, `UIScreenDidDisconnectNotification` or `UIScreen.screens`. A scene may not be owned by SpringBoard, so missing external scene records do not imply no CarPlay session.
