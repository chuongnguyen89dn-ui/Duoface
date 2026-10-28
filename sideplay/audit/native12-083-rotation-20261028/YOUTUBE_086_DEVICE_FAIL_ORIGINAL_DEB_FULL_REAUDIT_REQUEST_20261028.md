# 2026-10-28 13:27 ICT — YouTube .86 DEVICE FAIL; freeze Google Maps; full original-DEB orientation audit

## Latest user requirement (supersedes .86 rollout assumptions)
- User tested installed .86: **YouTube orientation unchanged**, hence .86 is DEVICE-FAIL for the requested rotation fix, regardless of CI/Sileo PASS.
- **Freeze Google Maps**: not yet validated; do not alter native map, scene owner, Dock, zoom ratio, or map code. All further work exclusively investigates YouTube orientation from original DEBs.
- Do **not** issue another guessed orientation patch or publish another DEB until exact original code paths and live owner/runtime discrepancy have been established.
- Keep working .83 player and crash mitigation `DFSceneLifecycle.m` unchanged. .86 is not a rotation fix.

## Direct evidence re-read from actual archived original-binary audits
1. `sideplay/audit/native12-083-rotation-20261028/BINARY_DIRECT_083_VS_ORIGINAL.json`, original-binary SHA-pinned run 40621241302: Native12 `SBDeviceApplicationSceneHandle._mainSceneSupportsInterfaceOrientation:` @0x2c8b4c–0x2c8ca4 checks bridge owner and only allows requested portrait=1; independent 2-arg and 3-arg `setContentReferenceSize` hooks replace logical size via `renderSizeForBundleID:` while preserving orientation args. Native12 DEB SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`. This is verified static binary behavior, **not a proven YouTube runtime solution**.
2. OmniCar original DEB SHA256 `d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd`: `ABHost.layoutPane` @0xec80 uses live scene handle `sceneIfExists` then `updateSettingsWithBlock:` @0xf048; block @0xf210 invokes `setFrame:` @0xf248 and `setInterfaceOrientation:` @0xf280. The orientation argument originates from captured state; **not verified to equal portrait or a fixed landscape**. `OMNICAR_ORIGINAL_NATIVE_MAP_BRANCHES_V2_RUN_40627902229.json` contains ARM64/CFString traces, not live-device replay.
3. SidePlay original 1.0.4-1 SHA256 `7f8520b9...` has `SPPane.layoutInFrame:scaleMode:` @0x2f6e0 and `setSceneFrame:orientation:` @0x31500. DuoNavi original 1.0.4 SHA256 `f3f911de...` uses separate scene frame and content reference paths. DuoDash 1.1.3 Fullscreen427 is a **repack**, not verified stock DEB, so do not conflate with original.
4. User's three-image transition: DuoFace Zoom of one pane = sideways YouTube; **YouTube's own video fullscreen = correct**, then return to two panes stays correct. Evidence `PHOTO_3_STEP_SCENE_ORIENTATION_20261028.md`. This strongly indicates a **state-transition / app-owned player presentation** problem; not merely scene frame aspect ratio.

## Why the .86 experiment cannot be called a fix
- `DFSceneHost.m` in .86 only attempts orientation repair when observed `FBScene.settings.interfaceOrientation` is 2, 3 or 4 **and** mutable setter ABI is recognized and owned scene/generation still matches. If remote orientation is already portrait=1, unavailable, or YouTube player's internal `UIWindowScene` / `AVPlayerViewController` state is wrong, **no effective correction occurs**. Even if a scene-settings write succeeds, that is not an ACK from YouTube's video presenter.
- Current device report establishes **no visible change**, but not which guard skipped or whether UIKit accepted a remote update. Without actual .86 `DuoFaceSceneHost.log` and app-side orientation events, claiming a specific cause would be speculation.
- Historical .70 YouTube-only external orientation setter did not achieve a verified device PASS. OmniCar QA14 fixed 3/4 landscape lock was DEVICE-FAIL. Do not repeat either.

## Next concrete original-DEB audit, read-only first
1. Enumerate **every extracted original** Native12, DuoNavi 1.0.4, OmniCar 1.0.3, SidePlay 1.0.4, and DuoDash repack ARM64 image with exact SHA256, slice/architecture, class/method, IMP offset, caller/callee, data-flow for orientation and scene geometry. Distinguish CarPlayApp native and SpringBoard app bridge paths. Audit both sides of all `updateSettingsWithBlock:` blocks; track where orientation is *computed* (not just selector existence), where/when the scene capability hook is installed, how fullscreen/player mode changes trigger layout, and any app-side message/ack. Never copy vendor binaries or licensing.
2. Build a method-level comparison matrix: original input event → scene owner → orientation source → setter/callback → timing → readback; compare exact .83/.84/.86 paths. Flag unverified disassembly explicitly.
3. If existing GitHub artifacts do not contain these method bodies/data-flow, use **one read-only GitHub Actions original-binary analysis** with SHA-pinned DEBs, store disassembly and machine-readable report in this repo. No UI patch, no new Sileo package.
4. Correlate physical YouTube states `before Zoom → wrong after Zoom → correct after YouTube fullscreen → restored correct` with owner/generation, observed FBScene orientation, and app/player orientation. User may upload latest log if already available; never invent missing data.
5. Only after confirmed cause design an independent, scoped change. Preserve working .83 video, system Dock, and frozen Google Maps.

## Status
**Verified:** user-reported .86 rotation failure; existing original binary SHA-pinned static findings re-read. **Not done:** complete re-disassembly of all original DEB methods in this turn; no new runtime fix, DEB or device test. No job started by this checkpoint. Repo branch `feature/duoface-jb-embedded-appbridge-20261020`.
