# DuoFace independent QA — original104 scene geometry root comparison and v5

## Problem / user evidence
On iPhone X rootless iOS 16.7.x, QA `com.duoface.visual12 1.0.3-12~ui8native3` user-reported: two apps can display, but app UI is visibly cramped, real Native12 UI remains missing, and exitMode occurs more often while picking a replacement app. UI8NATIVE3 **FAILED device acceptance**. User ordered focus on scene hosting, actual render geometry, native method wiring, not more cosmetic controls.

## Source of truth (original version, not assumption)
Pinned original DuoNavi `1.0.4` DEB SHA256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`; Dashboard SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`. Dynamic addresses below are **file-local IMP offsets from original 1.0.4**, not offsets for Native12. No original binaries copied to QA.

Static disassembly `audit/duonavi-original104-ui/ORIGINAL104_UI_CALLCHAINS.json`, reverified original104 read-only Actions [39093558897](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39093558897) and [39094150899](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39094150899), both success. Extractor `scripts/audit_original104_ui_callchains.py` retains full bounded assembly for `CBBridgedUIAppView.updateLayout` (IMP `0xac7cc`) and `updateSceneSettingsFrame` (IMP `0xad368`).

### Facts established by original ARM64 instructions
1. `calculateNativeSizeForSlotRect:` at `0xac788` checks width/height positive and returns `FRINTA(2*width),FRINTA(2*height)` (else `CGSizeZero`). **2x itself is the original algorithm**, so don't blindly turn it off.
2. `updateLayout` at `0xac8b4-0xac8e4` resets **outer host view** transform to identity then `setFrame:` to native logical dimensions, not just `setBounds:`.
3. `updateLayout` at `0xac904-0xac954` also resets/frames the **inner `SBAppViewController.view`** and applies `setAutoresizingMask:0x12` (`FlexibleWidth | FlexibleHeight`). The previous QA only adjusted the outer view and left the nested hosted view's frame/constraints to UIKit.
4. `updateLayout` at `0xacb40-0xacb8c` calls `setContentReferenceSize:withInterfaceOrientation:` with `w2=#1` and `setContentReferenceSize:withContentOrientation:andContainerOrientation:` with `w2=#1,w3=#1` (portrait=1 regardless of slot aspect). `updateSceneSettingsFrame` repeats this original orientation=1 at `0xad45c,0xad490,0xad494`. **Previous QA instead calculated landscape when width>=height**.
5. Original `updateLayout` at `0xacbc4-0xacbf0` uses a **single uniform scale** (min of width/nativeWidth and height/nativeHeight, with a lower clamp depending on a literal), then `setCenter:` at `0xacc4c`. Previous QA independently scaled x/y and did not configure inner device view.
6. Original `updateSceneSettingsFrame` at `0xad3cc-0xad3e0` uses `CBWindow.carPlayUsableBounds` as fallback when its own bounds are empty; it updates frame and foreground scene policy, but its selector trace does **not** show `setInterfaceOrientation:` on `FBScene`. The previous QA applied aspect-chosen orientation to scene settings and its `FBScene updateSettings` hook.

**Interpretation, not a proven runtime diagnosis:** Items 2-6 are substantial verified layout-path differences and credible contributors to cramped/app interaction. They do not prove which one alone caused the device screenshot. First respring exitMode has no contemporaneous crash/IPS in this conversation.

## Applied independent scene corrections

- `replacement/visual12/engine/runtime/DFIRuntime.m` (commit `c022a2dad2935f36195e7e9b354f9e9511825eec`): preserve original 2x calculation, set host transform identity + `frame=(0,0,native)`; prepare nested device controller view identity + same frame + `UIViewAutoresizingFlexibleWidth|FlexibleHeight`; uniform scale; center in pane; use portrait orientation only for device content reference APIs. Do not overwrite FBScene interface orientation from aspect. `DFIUpdate` guards an optional explicit orientation before applying.
- From previous v4, keep safe launch sequencing, deferred saved app restore and serialized app replacement; retain standalone6invalidate `setRequestedMode:0`/invalidate close. No vendor `CBBridgeManager` / licensing classes/watches or original postinst included.
- `replacement/visual12/tests/test_scene_contract.py` (commit `707e04114fdd1b9336c6c2dd1116d745762da941`) verifies native arithmetic and event ordering plus nested frame/portrait reference and scene-frame orientation guard. Static test not a CarPlay simulation.

## Build, packaging, release checkpoints

- QA package: `com.duoface.visual12`, version `1.0.3-12~ui8native5`, source commit `3df3e2d81ae67b35b50d227a73da1ed268ef948e`.
- GitHub Actions [39094352328](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39094352328): completed/success including static contract test and Mach-O/signature/package verification. Artifacts saved under `dist/visual12-original104-geometry5-qa/`. DEB `com.duoface.visual12_1.0.3-12~ui8native5_iphoneos-arm64.deb` (1,068,976 bytes), SHA256 `c90048d87d9ee323b4087a9044218a655700b385fabf75833bdc06ee038d1b74`. Artifact commit `77d9f80e0f6c0d2f5425638c961196cfa68b0483`; `BAO_CAO.json` + `SHA256SUMS` on GitHub.
- Sileo publisher `chuongnguyen89dn-ui/carplaydsp`, `main`, workflow `.github/workflows/build.yml` SHA pin updated at commit `acff973351f8838e12f51ebe775257937879ae31` to QA version v5, triggered [39094409601](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/39094409601); **check build + GitHub Pages deploy conclusion before claiming v5 public**. Stable Native12 HUD8 `com.duoface.independent 0.1.0~native12+speed8compact` Sileo source entry remains unchanged.

## Required device proof / known gaps

After verified Sileo deployment, iPhone X Sileo refresh and install **QA only** (not Native12), in parked CarPlay: compare same Waze/GMaps/other app pane composition as prior UI8NATIVE3 photo, select a different app in same pane, drag ratio with two live apps, close/reopen and first respring. Send `/var/mobile/Library/Logs/DuoFaceVisual12-runtime.log` and SpringBoard `.ips` matching any exitMode, with time. New stage markers `QA geometry`, `QA scene mode request`, `QA scene frame applied`, `QA scene ready`, `QA replace close`, `QA replace start`. This is necessary to prove causal fix. Full original UI/N12 per-pane picker/zoom, iPhone Settings, speed telemetry are **not** part of geometry v5 and remain unaccepted.
