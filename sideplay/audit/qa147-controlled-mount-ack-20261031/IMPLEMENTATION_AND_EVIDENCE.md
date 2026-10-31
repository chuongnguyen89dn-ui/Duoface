# QA147 controlled reentrant mount + PID-readiness evidence patch

Date: 2026-10-31, branch `feature/duoface-qa146-native-home-exit-20261031`.

**Scope:** only proven pending-after-terminal source defect and unknown one-shot scene-ready/PID gate, while preserving original scene-host geometry and all YouTube/GOFA/touch/CarPlay splitting code. NOT a claim of original DuoNavi manager/workspace/Dock/Home parity. No changes in vendor binaries, licensing, tokens, user preferences or public Sileo APT.

## Source change and causal evidence

Hardware QA147 Log23 previous pin SHA256 `c327274898d8d7285259d4bdbfc04b623a81e3cb6263ccda7ccf948d9cca267d`: 26 requests / 16 observed scenes / 0 standalone-success ACK / 0 native Dock-active / 8 `Scene attach exception: bogus reference size`; the eight synchronous attach failures were followed by **eight null-ID pending responses**. In the old source `DF144Solo.begin` unconditionally emitted pending **after** `[root.view addSubview:v]`, even though UIKit mount can reenter `DFSceneSurface.start -> failed -> sceneFailed -> stop` and clear owner. Original caller then wrote an obsolete pending response. This is a source-level, log-correlated bug, independent of any assumptions about the actual throw API.

Commit `67c43d901c3e3110077cf84184fbbc731a6d0389`: `sideplay/duoface-native-scene-host/DFHomeStandalone144.m`:
- Serialize nonterminal `pending-scene` **before** reentrant mount. After mount, check exact generation, surface pointer, window pointer and request ID. If nested failure has already revoked ownership, return NO immediately and never schedule a stale timeout or overwrite the terminal result.
- Guard outer exception handler against overwriting a terminal generation from an inner failure.
- Add read-only request/bundle/surface/window geometry trace immediately around the mount. No window frame/orientation setter was changed.
- At `sceneReady`, log which owner/window/scene/bundle gate fails; when the scene is live but verified PID is absent, retry the **existing real `verifiedPIDForHostedView:` verifier** at most 14 times separated by 0.5s, checking generation+request+surface on each attempt. Log only attempts0,4,14; successful PID retains exact original `scene-hosted-render-and-touch-unverified` semantics. No fake PID, no fake media/first-touch ACK, no relaxing Dock consumption.
- Scene attach `bogus reference size` root operation is **not yet established**; no native scene lifecycle reordering or forced landscape was made.

## Regression barrier and rollback

Initial nonmutating attach-operation markers added to `DFSceneHost.m` were rejected by the legacy QA141 **byte-exact** geometry baseline test. CI [41203749310](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41203749310) FAILED at `test_qa141_map_layout.py::test_host_geometry_remains_baseline` before compilation. This was **not a Swift/Objective-C compiler failure**; no DEB was built in that run.

**The scene-host instrumentation was reverted**, commit `8a62d344b8ac9720a84f212e35c7b3a5ceefdcee`. `DFSceneHost.m` now has exactly its pre-change Git blob `ec2924c145be4edaaa27b7320bb869b18de12c6b`. Its GOFA and YouTube scene bootstrap, layout and geometry baselines are preserved. Targeted test updated to instrument only the standalone owner in commit `dc66546c18e566c2cd6134625584b1bf3746e73d`.

## Executed checks and actual limitations

- Added `sideplay/duoface-native-scene-host/tests/test_qa147_mount_ack_reentrancy.py` (4 static source-invariant tests): pending-before-mount/terminal guard, owned real PID and bounded retries, pre/post mount geometry, no fake Dock.
- CI [41203877746](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41203877746) completed **SUCCESS** after reverting frozen host: this test plus older QA144 and QA146 contracts. This verifies source text invariants, not synchronous UIKit callbacks or iPhone behavior.
- New static full-route verifier was repinned to the changed standalone source in commit `336acf5d7ce0e167e49464e53c22b70aae303b6a`; the original Log23 and binary audit receipts remain immutable. This verifier checks historical evidence; it is NOT a fresh Log24 capture.
- Signed private no-Sileo macOS workflow `duoface-146-native-home-exit-private.yml` extended to include new regression test in commit `a9f3d8fcd52cea566fad68e1ef35009e200e3294`. Actions run `41203911733` was started after regression correction. Its actual build/sign/archive status must be checked in the run before any success claim.

## Still required before approving a release

1. **Compile/package check** from the newest private Actions run, then check the exact source SHA and package SHA. A green static test alone does not qualify.
2. Hardware session trace must show `qa147-ready-pid-unavailable` or `qa147-ready-verified-pid`, `before-standalone-mount`, `after-standalone-mount` or `mount-reentrancy-terminal`, with matching request/generation. Verify that **no null-ID pending occurs after synchronous failure** and the exact guard that blocked Log23 ACK is identified; log-only code cannot retroactively produce these measurements.
3. Separate native workspace/phone eviction/manager-active state + Dock/Home transaction remains unimplemented. Native Home wrong destination and universal per-app mobile orientation remain **unsolved**; do not conflate first corrected failure with full DuoFace parity.
4. Don't publish or ask for another Sileo install from static evidence alone. No external Apple Home interception/portrait forcing; no vendor licensing code.

Repro:
```bash
python3 -m unittest discover -s sideplay/duoface-native-scene-host/tests -p 'test_qa147_mount_ack_reentrancy.py' -v
python3 -m unittest discover -s sideplay/duoface-native-scene-host/tests -p 'test_qa141_map_layout.py' -v
python3 sideplay/audit/qa147-full-route-evidence-20261031/verify_full_route_evidence.py --repo .
```

Scope remains ONLY: slow/wrong native app entry, attach reference size, standalone ACK, native Dock activation and Home exit. No full original native host execution parity is claimed.


## Signed private build: confirmed, NOT promoted to Sileo

Verified after the draft report above: [Actions 41203911733](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41203911733), job `124545016681`, **completed SUCCESS** on source commit `a9f3d8fcd52cea566fad68e1ef35009e200e3294`. Its existing QA144/145/146 and new QA147 guard tests, macOS iOS16 toolchain, native Objective-C compile, signed integrated DEB assembly, artifact upload and GitHub archive all completed successfully. Standalone source patch and reverted scene host are included in that source commit. Runtime baseline `DFSceneHost.m` remains exact blob `ec2924c145be4edaaa27b7320bb869b18de12c6b`.

**Archive verified in actual DuoFace feature branch via nontruncated Git tree at `594c61d85f83b3e45b8b0585d747ad1f671be37a`:**
- `sideplay/jb-embedded-appbridge/evidence/runs/41203911733/com.duoface.jb.embedded_0.0.147~native-dock-sync1_iphoneos-arm64.deb` — 1,169,216 bytes; SHA256 from runner-checked `SHA256SUMS.txt`: `ae76a8d5a9cbccc9800de22fc30135d789bc82a809bbb96ad70e72e91cdb0225`; Git blob `daf2161022bcf813933bd9bfa176f6baebd40ab4`.
- `sideplay/jb-embedded-appbridge/evidence/runs/41203911733/SHA256SUMS.txt` plus `CI_RESULT.txt` and `PACKAGING_PROVENANCE.json`, all read back. `CI_RESULT.txt`: `SILEO_PUBLISHED=false`, `DEVICE_DIRECT_HOME_TESTED=false` and `STANDALONE_OWNER_FOREGROUND_VERIFIED=false`.
- Actions artifact `QA147-private-standalone-signed-UNPUBLISHED` ID `13044111154`. Artifact ZIP digest is different from the *internal DEB* checksum; do not confuse them.

Original-route 17-check current-source verifier repin [Actions 41204013065](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41204013065) also completed SUCCESS. These are authentic static/compile/sign/archive proofs, **not** Home/Dock/rotation/use-on-iPhone proof. No new public Sileo update was made; QA147 user hardware rejection is not overturned.

