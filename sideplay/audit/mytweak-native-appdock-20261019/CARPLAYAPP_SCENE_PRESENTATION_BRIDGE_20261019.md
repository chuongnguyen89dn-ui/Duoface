# 2026-10-19 — DuoFace native Dock/Home: safe CarPlay presentation-owner implementation gate

## Scope / branch
- Repo: `chuongnguyen89dn-ui/Duoface`
- Work branch: `feature/mytweak-carplayapp-presentation-20261019`; **branched from user-tested V1BC commit `67ba830685416a3810255c383dc9aa1b1f9033d8`**, not the `0.2.5~shell1` boot-hang candidate.
- Required behavior: Apple native AppDock/Home remains visible, operational and untouched while DuoFace shows **two independently controlled iPhone app scenes** with working touch, ratio drag, Swap, Zoom, Close, disconnect/reconnect. Standalone/independent; no vendor binary, license, UI imitation or fake Apple Dock.
- Preserve `QA11 0.1.9~native12dock11`, Native12, HUD8, Sileo recovery package `0.2.6~recovery1`; **no release from this branch until evidence gates below**.
- This document is an **engineering decision / implementation protocol**, not completed code, CI result or a claim that Dock was fixed.

## Observed source facts
1. `feature/mytweak-v1bc-combined-20261019:sideplay/mytweak-independent-v1a/MTSceneHost.m` explicitly requires SpringBoard main thread; it directly uses `SBApplicationController` and `SBDeviceApplicationSceneEntity`. Moving this file verbatim to a separate shell process is invalid.
2. `feature/mytweak-dashboard-activation-20261019:shell/MTDuoFaceShell.m` only creates an independent UIWindowScene with a **placeholder DuoFace label**; it does not host the live V1BC split engine. That branch still creates the **actual** two-app `UIRootSceneWindow` from SpringBoard `MTBridgeCoordinator.m`. It does not establish a native Dock-owning scene with the real UI.
3. That candidate's `V1ATweak.x:%ctor` installs `MTCarPlayAdmission` with LaunchServices method replacement before the `Enabled` preference; there is a device-hang report for `0.2.5~shell1`. Source confirms hazardous bootstrap behavior, not the log-proven root cause. **Do not copy this constructor into the new branch.**
4. Static DuoDash 1.1.3 audit `audit/duodash-1.1.3/DUODASH_APPBRIDGE_VISUALTEST12_CROSSWALK_20261017.json` identifies separated SpringBoard host request and CarPlay UI layout: `CNABSpringBoardObserver`/`DDz2` vs `CNABUIApp`/`DDz1`. This is crosswalk evidence, **not** direct dynamic proof of vendor transport, and no vendor class/code is to be reused.
5. DuoNavi 1.0.4 original ARM64 `audit/duonavi-original104-ui/ORIGINAL104_UI_CALLCHAINS.json` reads `carPlayWindowScene`, `carPlayContentInsets`, `carPlayUsableBounds`, and has alternate external window constructors. **Correction**: existence of an external UIWindow alone does NOT prove the Dock failure; geometry + Dashboard/Home routing and z-order ownership must be established together.
6. Official Apple CarPlay document `https://developer.apple.com/documentation/carplay/displaying-content-in-carplay`: system-managed `CPTemplateApplicationScene`, special map UIWindow only for navigation apps with entitlements; dashboard is specifically for navigation maps. Neither a custom manifest key `UIWindowSceneSessionRoleCarPlay` nor `CARCapableApp=true` is a proven substitute for entitlement or a scene offered by the CarPlay UI process.
7. Remote compositing **research candidate only**: Chromium published `https://chromium.googlesource.com/chromium/src/+/refs/tags/128.0.6613.182/ui/base/cocoa/remote_layer_api.h` describing `CAContext.remoteContextWithOptions:` and cross-process `CALayerHost.contextId` (iOS). Rendering support, authorization, lifecycle, hit-testing and touch forwarding are **not verified on this jailbroken iOS16 device**. Use API names for independent capability research; do not import Chromium or vendor sources.

## Next implementation — stages, with explicit stop gates
### Stage A: first-party capability/source prototype, branch-only
- Reuse SpringBoard V1BC scene-launch/host core unchanged; retain its exact source, tests and split gestures as baseline.
- Add a separate, **opt-in and post-launch-only** CarPlay UI-side presentation capability module, without `LSBundleProxy`, `LSBundleInfoCachedValues` hooks or any `%ctor` intervention. Identify the live CarPlay UI process dynamically by process/executable and actual connected `UIWindowScene`; never assume `CarPlay` vs `CarPlayApp` from the name alone.
- Establish an independent cross-process **presentation contract**: `session`, `layout`, `content rectangle`, `two surface tokens`, `touch/gesture routing`, `home/close`, `disconnect` with strictly enumerated actions, freshness/replay checks and an explicit fail-closed state. Preserve SpringBoard as the only creator of `SBDeviceApplicationSceneEntity`. Probe candidate `CAContext/CALayerHost` only after runtime existence/ABI check; do not assume it transmits touch events.
- Only when the destination is a **live CarPlay-owned content view** do we attempt presentation. Avoid an independent `UIRootSceneWindow` over the whole display. No fake Dock/geometry constants and never alter Apple's native Dock windows.
- A proof-of-concept that draws a **static placeholder** inside a CarPlay-owned view is **not** a feature-complete Dock fix. Require a **live two-app surface+touch round-trip** before any candidate can be called functional.

### Stage B: source/CI checks (no device yet)
- Structural tests must reject any `MTCarPlayAdmission` LaunchServices override, unguarded SpringBoard boot hooks, hardcoded Dock width, source dependencies on closed DuoNavi/DuoDash binaries, or arbitrary IPC activation.
- Unit/contract checks: disconnect invalidates tokens and hides surfaces, stale layout is rejected, touches map to the correct pane in split/swap/zoom, Home invokes Dashboard-owned transition, failures never leave a fullscreen overlay.
- Compile arm64+arm64e rootless with the existing Theos GitHub Actions workflow. Audit exact DEB filter and maintainer scripts. Keep source prototype on branch; `build success != native Dock device proof`.
- Check for existing active Actions jobs and avoid duplicate runs.

### Stage C: publish ONE release only after A+B
- Rollback path must remain `0.2.6~recovery1` (not `0.2.5~shell1`); package must have a self-disabling/safe mode gate.
- Do **not** publish a new experimental SpringBoard injection solely to retry V1BC gestures or safe-area widths.
- First one parked-car hardware acceptance: Apple Home icon/Dock visible and clickable with 70mai+ChatGPT panes, ratio/Swap/Zoom/Close, reconnect/respring stability; collect only failing-module logs. Stop and roll back on boot hang, SpringBoard crash or CarPlay crash.

## Current checkpoint: facts vs pending
- **CONFIRMED:** branching baseline `67ba830...`; original shell/v1bc process boundary; high-risk admission code and history; audit paths above.
- **UNVERIFIED:** `CALayerHost` on iPhone X iOS16; CarPlay UI process native scene ownership; touch/event forwarding; actual Dock/Home after migration.
- **NOT DONE:** IPC and remote content prototype, source/CI/package tests, public Sileo update, any real device test.
- **Immediate engineer command/step:** inspect `MTSceneHost.m`/two-pane ratio and `MTDashboardContext.m` on diagnostic branch; implement Stage A as an isolated, feature-disabled module, write source tests, run CI, and checkpoint. **Do not activate experimental hooks at SpringBoard boot.**
