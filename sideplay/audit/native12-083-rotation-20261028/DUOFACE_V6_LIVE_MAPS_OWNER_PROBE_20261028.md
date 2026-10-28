# DuoFace V6 — live CarPlayApp native Maps controller/scene/host observation

Date: 2026-10-28 (Asia/Bangkok). Source repo `chuongnguyen89dn-ui/Duoface`, branch `feature/duoface-jb-embedded-appbridge-20261020`; prior checkpoint `427b196737f80fecbc9060befe6488c3b369756e`.

## Proven prior facts (original OmniCar is reference only)
- V4 original package filter and process ownership: `OMNICAR_ORIGINAL_PROCESS_OWNER_V4_RUN_40629909847.json` from run `40629909847` **SUCCESS**.
- V5 original `SCPHostedAppVC.sceneHostView` getter returns nil (`mov x0,#0; ret`), and native pane holder `SCPCarPane` has distinct `vc/host/handle/hostHandle/hostFrame/sceneSize`. Report: `OMNICAR_ORIGINAL_HOSTED_VC_V5_RUN_40630009621.json`, run `40630009621` **SUCCESS**.
- These are static ARM64 observations in a vendor DEB; do not claim they prove a live Maps scene controller.
- DuoFace 0.0.83 was reported video-playing/no-crash by user. Do not regress, do not reintroduce the rejected 80% Maps phone-view zoom, do not force-close Maps, do not copy vendor license or binary.

## Implemented independent observation, not native attachment
- Existing isolated `sideplay/native-carplay-scene-v1/DFNativeSceneProbe.m` (injected only into CarPlay / CarPlayApp) now invokes `DFCarPlayCaptureLiveOwnerSnapshot` at 1st tick and every 20th tick (~30s).
- New `sideplay/native-carplay-scene-v1/DFCarPlayLiveOwnerSnapshot.m` reads connected `UIWindowScene` and session role/identifier; screen, window class/identity/frame, root and bounded VC children/presented VC; `viewIfLoaded.window.windowScene`; checks `sceneHandle/scene/applicationInfo` selector existence, then only type-checks and invokes an object-returning no-arg `sceneHostView` getter. Nil getter **is explicitly labeled nil**, no fake host. Captures real UIView bounds/frame/window/scene when present.
- Source guard: no `setFrame`, no `foregroundSceneWithSettings`, no `backgroundSceneWithCompletion`, no launching/closing Maps, no fake CarPlay app entitlement, no `%hook` or native Dock replacement. Bound: <=12 scenes, <=48 windows, <=72 controllers per snapshot, log limit 4 MiB with rollover.
- iPhone live evidence destination: `/var/mobile/Library/Logs/DuoFaceCarPlayOwnerSnapshot.log`. `DFNativeDiagnostics.m` includes this path in existing manual DuoFace QA export. No automatic upload.
- Diagnostic package version: `com.duoface.carplay.nativejoinprobe 0.0.4~mapowner1` (standalone, rootless), `Makefile` includes new source, Python safety test updated.
- CI workflow `.github/workflows/duoface-live-map-owner-probe-v6.yml` run `40630617316` was triggered (source SHA `9ab33976042ed3d89de0282494bbde70197148f0` at the trigger); it compiles/persists package and hashes in the same DuoFace repo on **success only**. Do not assume success before examining run steps.
- Source of central skill instructions: `chuongnguyen89dn-ui/Gpt-training-` `SKILL_INDEX.md`, `PROJECT_INSTRUCTIONS.md`, `AGENTS.md`, `DEB_IPA_SKILL.md`. The suitable ZIPs `skills/02-ios-deb-ipa-carplay.zip` and `skills/05-research-debug-testing.zip` were enumerated; current GitHub text interface cannot decode ZIP blobs. Earlier V3 CI job `122620428372` is recorded as having SHA-verified and extracted these exact ZIPs; no current-turn ZIP extraction is claimed.

## Actual verification boundary
**NOT VERIFIED LIVE YET:** real native Maps controller class; Maps process/scene owner and active navigation; CP window or scene host identity; role/identifier continuity after showing DuoFace split; whether a native Maps scene can be safely reparented; on-device probe installation or output; Sileo publication; YouTube orientation fix. The log field `mapsNativeOwnerProven=false` is intentionally hardcoded: a source build cannot prove Maps scene ownership.

## On-device capture and acceptance gate
1. Only after a verified successful CI build, deliver the standalone diagnostic through the approved Sileo publisher; do not use Filza or replace 0.0.83. Confirm package identifier/version and actual Sileo index/DEB before claiming publication.
2. Park car, connect JB iPhone X iOS 16.7.16; launch Maps natively from CarPlay and start a route. Without closing Maps, leave its native view visible for >=35s; then display DuoFace's split without ending guidance for >=35s.
3. Export diagnostics manually via DuoFace QA. Retrieve log `DuoFaceCarPlayOwnerSnapshot.log` and correlate `process/pid/session`, scene role/identifier and native VC→view.window.windowScene, plus `sceneHostViewStatus` / actual host dimensions. Compare before/after maps and split. A nil placeholder is not a map host; absence of window/VC is **insufficient evidence**, not success.
4. Only after verifiable native owner and lifecycle identity, design an independent scene-owner-aware adapter that does not teardown foreign/active Maps navigation scenes. Explicitly guard host and controller identities before touching layout. Test video .83, one-pane YouTube first zoom orientation, Dock/logo/SOLO/touches as regressions.

## Current blocking dependency
CI compilation can be verified remotely. **Actual on-device CarPlayApp contents cannot be observed remotely using the available GitHub tools**; only a future installed, opt-in on-device snapshot and exported log establishes real controller/scene/sceneHostView. No unsupported extrapolation from original DEB is an acceptable substitute.
