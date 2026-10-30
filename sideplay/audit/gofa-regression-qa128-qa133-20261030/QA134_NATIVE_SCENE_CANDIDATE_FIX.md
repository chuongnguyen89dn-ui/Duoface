# 2026-10-30 — QA134 bounded native CarPlay owner candidate correction

## User issue and verified historical starting point
User reports GOFA still boxed; historical physical GOFA PASS occurred at QA128 `0.0.128~manualowner1`; last public QA133 source `c12c97966e0ed149edf1aee3cbae1fe6f6c0ce37` is NOT verified to fix it. Source compare report: `TRACE.md` in this folder. QA128 manual observer remains byte-identical in QA133, QA129 introduced strict native Home scene owner attestation.

## Concrete source error corrected, without claiming hardware causal proof
The old `DFOwnerObserveNative()` enumerated **all visible** `DBApplicationSceneViewController` entries across the CarPlay process's UIKit windows and used:
```objc
NSDictionary *candidate=found.count==1?found.firstObject:nil;
```
This rejects a valid one-and-only-one DuoFace native host if an **unrelated** official CarPlay app (for example native GOFA navigation scene or another system app) is simultaneously visible. The code then emits `native-owner-state ... active=0`, writes `Active=NO` attestation, and downstream background lease may be rejected, even with DuoFace's own scene unchanged. This is an independently reproducible **software predicate bug**; whether the user's specific GOFA failure enters that branch remains **unproven** without a loaded version/session trace.

## Independent scoped repair
- Added `sideplay/duoface-native-scene-host/DFCarPlayOwnerSelection.h` with `DFOwnerUniqueDuoFaceCandidate(visibleControllers)`. It ignores foreign CarPlay scene candidates, selects **exactly one** visible `Bundle=com.duoface.native.scenehost` entry with a nonempty SceneID and controller, rejects malformed or two+ own candidates. This **does not** force any GOFA scene into the system, change app entitlements, or change GOFA viewport scalars.
- `DFCarPlayOwnerObserver.h` uses the helper and adds source-owned log `visible-candidates=N unique-duoface=0/1`. All original session, native scene identity, homeButtonUp: hook readiness, Home revocation, foreground-only acquisition, native owner freshness, multi-DuoFace ambiguity fail-close and external display requirements remain.
- Mac Foundation executable `tests/carplay_owner_selection_134.m` covers 14 actual selection cases, including GOFA+own, foreign-only, two own and malformed own. Existing `test_native_owner_contract.py` updated its old overly strong `found.count==1` assertion; the background-acquisition and original Home behaviour checks still run.
- QA128 geometry `DFHostedMapRenderSize.h` and `DFNative12Chrome.m` remain byte-identical. QA132 SpringBoard BKS dim+touch `DFTouchOwnerProbe.m` remains byte-identical. QA90 rotation/QA92 divider/QA120 Apple Dock not edited.

## Actual verification and artifacts
- Isolated work branch: `fix/duoface-qa134-gofa-owner-candidate-20261030`, forked `858abaf7a5614c5a3e89a93efb6436b2f43e0a95`.
- Source change commits: `c4afece5881ce5c1adf15dafa78eff89b4acbd9f`, `094163c067fd441f86f937dbc123fa8736156c54`, runtime test `59b3f3f91ffc879f82c7c73d2616213844d60a33`, adjusted old test `580e79265562ff45eb30be7bd8ed6e03952193cf`.
- First independent CI source run `41082216040` **FAILED** only at old static test hardcoding `found.count==1`; Foundation runtime selection and iOS16 arm64 source compile steps ran successfully. Updated assertion to check scoped exactly-one-own-application semantics and independently run multi-scene tests.
- Corrected source CI **`41082528060` COMPLETED SUCCESS**: executed real Foundation owner selection + lease records, real arm64 iOS16 native Dock receiver syntax, QA128 geometry and QA132 BKS file compares, native-owner/Home and QA130 background tests. Device GOFA not tested by runner.
- Unique signed rootless QA134 candidate version staged: integrated `com.duoface.jb.embedded 0.0.134~gofaowner1`, host `0.1.134~gofaowner1`, same app/tweak identities; build.sh/control/Info.plist/package_integrated.py and test pin updated, no overwriting QA133.
- Native signed staging workflow `.github/workflows/duoface-134-gofa-owner-signed-staging.yml`; workflow fix commit `3582fb00fc241ef422e218470ffc6ed112282997` corrected own-path trigger; signed run **`41082747114` STARTED**, status **IN PROGRESS at last check**, final result/DEB/Sileo/physical QA NOT YET VERIFIED. Build candidate provenance and signed package, if success, will be archived under `sideplay/jb-embedded-appbridge/evidence/runs/41082747114/`, not automatically published to Sileo.

## Next exact work after signed CI result
1. Check GitHub Actions run `41082747114` job ID `124155854328`, final result, tests/signatures/UUID, stored package SHA256 and archive readback. If FAILED, inspect exact failing step log, fix only proven error and rerun with new source SHA; don't claim success.
2. If SUCCESS, release only **exact** signed QA134 SHA through existing `carplaydsp` APT publisher; verify public single selected package version and downloaded DEB SHA, preserve rollback QA133 and QA128. No unsupported Sileo success assertion before publisher verifier.
3. Parked-device physical user acceptance: confirm QA134 installed/loaded SpringBoard and CarPlay dylib UUID, open GOFA with a second native CarPlay app present, check GOFA full pane split→drag→zoom; confirm iPhone X dim+touch, YouTube Play/orientation, Apple Dock, Home/disconnect. Export actual `native-owner-state visible-candidates` trace and remote GOFA frame after write if still boxed. If `unique-duoface=1` and GOFA still boxed, this candidate didn't fix the cause; investigate per-scene frame and native GOFA compositing, NOT random changes to 0.5/2x.
