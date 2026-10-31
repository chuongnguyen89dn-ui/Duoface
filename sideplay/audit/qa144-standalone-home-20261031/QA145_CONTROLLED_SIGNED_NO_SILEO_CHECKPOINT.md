# QA145 — Controlled iPhone opt-in single-app CarPlay Home: signed private staging VERIFIED

Date: **2026-10-31**. Exact workflow [41181488480](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41181488480), macOS-15 job `124479634401`: **all steps completed SUCCESS**. This document is an offline/source/build evidence record, **not real CarPlay functional proof**.

## Immutable source and signed QA145 private DEB
- GitHub project/branch: `chuongnguyen89dn-ui/Duoface` / `feature/duoface-qa144-standalone-carplay-home-20261031`.
- Actual source commit checked out and built: `0ce7b5fbb045c4e41aace251885552a5dd059bdc`.
- Merged rootless package `com.duoface.jb.embedded_0.0.145~standalone-controlled1_iphoneos-arm64.deb`.
- Exact SHA256 **`c43a84b42f8a6e7a7f064ae13b2561ea95d82588ceee104fb5bab750651e32d5`**, 1,165,176 bytes.
- The already committed full private binary, `SHA256SUMS.txt`, `PACKAGING_PROVENANCE.json`, and `CI_RESULT.txt` reside at `sideplay/jb-embedded-appbridge/evidence/runs/41181488480/` (GitHub archive commit `84988a6ea5c83a575856124ef7bb77607fec89a9`). All four paths and exact SHA/version/source/readback verified on the target branch.
- Live Sileo publication: **FALSE**, `carplaydsp` untouched. Physical CarPlay Home open/test: **FALSE**. `StandaloneHomeDirect` consent default: **OFF**. Original QA144 archive and QA143 public release unchanged.

## Executed CI and exact original causes
- Original five-DEB SHA-locked full forensic audit run `41179261436` passed, including DuoNavi six real ARM64 Home icon callsites and distinction of standalone bridge vs split; Native12 derived and DuoDash repack are not pristine vendor packages.
- QA145 run `41181488480` did: native Home + separate SpringBoard owner static contract, default-off iPhone preference control, receiver heartbeat, QA141 GOFA, QA132 BKS and native owner regressions, macOS iOS16 SDK native compile, three own Theos packages, real `ldid` verification, rootless signed merge, ZIP artifact upload, git archive push, SHA readback. All complete success.
- Previous QA145 run `41181330399` failed with `DFNativeDiagnostics.m:156:20: error: redefinition of 'leaseAge'` (previous definition line 94). Fixed to standalone-local `soloLeaseAge` by source commit `0ce7b5fb...`; next full run success. Old QA144 CI failures expecting previous QA144 filename in a changed branch are obsolete, not QA145 source failures.

## Exact current architecture
1. **iPhone owner controlled:** In iPhone DuoFace `Ứng dụng` there is an explicit separate item **`Mở trực tiếp App từ CarPlay Home`** (row 9, old section 0 rows extended from 9 to 10). Defaults OFF, requires existing `Hiện app trên CarPlay Home` and nonempty enabled app selection. Confirmation says only test when parked and no physical rendering guarantee. Toggling OFF revokes session, and disabling the parent Home roster also stops standalone.
2. **Native CarPlay source producer:** `DFHomeStandalone144.m` intercepts only observed `DBDashboardHomeViewController iconManager:launchIconForIconView:` with exact `v32@0:8@16@24` ABI; selected allowed app only, requires native real Dock/status rail/content window geometry AND a **fresh SpringBoard receiver lease** (max 2 s). Every inactive/missing-ABI/unselected native icon is passed to original system, no DuoFace icon substitution.
3. **SpringBoard sole standalone owner:** independent `DF144Solo` creates exactly one content-bounded external `UIRootSceneWindow` and a fresh independent `DFSceneHost hostViewForBundleID:error:`, `setSplitMode:NO`. App PID/scene readiness, intent TTL, home-return revoke, consent-display heartbeat watchdog, disconnect teardown; no split `DFNative12Chrome`/app-picker/slot0. The prior QA143 route was excluded from the compiled Home and CPTemplate receivers.
4. **Manual evidence:** existing `Xuất log / lỗi CarPlay` on iPhone now also collects `DuoFaceStandalone144.log` and scrubs standalone preference, receiver availability and scene-result ACK. Runtime `scene-hosted-render-and-touch-unverified` means **NOT VERIFIED rendered/touch/video**.

## Device-only acceptance that remains BLOCKED (no physical iPhone attached to tools)
- On parked car, physical iPhone X iOS16.7.16: enable two distinct switches and approve at least one app; native Home tap opens app alone **without entering DuoFace split**; watch actual pixels/touch/play, YouTube controls and GOFA map correctly sized, native Apple Dock and CarPlay Home/Back remain; reconnect/home/physical disconnect cleanup.
- Check exported runtime logs and receipt against UI observation before any promotion. Static class selectors + green compiler cannot prove CarPlay Home frontmost window acceptance or input propagation.
- Never infer success from `SBAppViewController isHostingAnApp` and PID alone; if content overlay doesn't appear, preserve logs and fix the owner handshake, rather than repeatedly installing variant DEBs.
- Because user explicitly rejects blind repeated Sileo tests and device proof is missing, **no public Sileo publish was performed**. A future intentional single bounded private-device validation is required to promote.

## Reproduction
- Workflow: `.github/workflows/duoface-145-controlled-standalone-private.yml`; built from exact source `0ce7b5fbb...`, GitHub run `41181488480`.
- Signed package: `sideplay/jb-embedded-appbridge/evidence/runs/41181488480/com.duoface.jb.embedded_0.0.145~standalone-controlled1_iphoneos-arm64.deb` (same repo).
- No third-party vendor binary/license deployed, no background device job, no Sileo public index changes.
