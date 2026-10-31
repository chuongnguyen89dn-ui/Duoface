# QA148 evidence-limited continuation: real PID + exact native stop reason

Date 2026-10-31. **Independent DuoFace source changes, not a verified original native manager/CarPlay execution route.** The 10-stage original DuoNavi/DuoDash crosswalk remains in `../qa147-full-route-evidence-20261031/FULL_ROUTE_VERDICT.md`.

## Why this change is warranted

Physical QA147 Log23 (pin SHA256 `c327274898d8d7285259d4bdbfc04b623a81e3cb6263ccda7ccf948d9cca267d`) showed 26 Home selected-app requests, 16 scenes observed, zero standalone hosted ACKs, zero native Dock active. The previous QA147 source fixes post-terminal pending and retries the real PID verifier, but `DFSceneHost.verifiedPIDForHostedView:` only reads `SBApplication.pid/processIdentifier`. A public SpringBoard interface declaration also exposes `SBApplication.processState.pid` (see https://github.com/udevsharold/battsafepro/blob/master/SpringBoard-Private.h), while the exact iOS16.7.16 runtime ABI still requires live measurement. The original binary's manager activation does not require our custom PID gate at this boundary, but we are **not** bypassing that existing gate blindly.

A second proven source ambiguity: `DF147Watch` and `DF147NativeActiveChanged` posted the exact same `DF144StopNotify` as a genuine `DBRootStatusBarViewController homeButtonUp:`; SpringBoard logged them all `native-Home-exit`. Consequently Log23's ~10s stops **cannot** prove that the user pressed Home. Fix telemetry identity before interpreting destination or latency.

## Code changes

- `sideplay/duoface-native-scene-host/DFHomeStandalone144.m` now has `verifiedProcessStatePIDForView:` as a fallback after the original real-host PID getter. It requires **current live owned hosted surface**, exact `bundleIDForHostedView`, exact SBApplicationController lookup ABI, exact resolved app's `bundleIdentifier`, actual `SBApplication.processState.pid` integer ABI, positive in-range PID not the SpringBoard process, and `kill(pid,0)` survival/EPERM check. No guessed/fabricated PID, no direct kill to stop app, no unguarded arbitrary `objc_msgSend`. It passes the authenticated PID into the actual hosted ACK writer, preventing the prior result serializer from discarding a fallback-verified value.
- `sideplay/duoface-native-scene-host/DFNativeDockSync147.h` emits **distinct** native stop notifications for watchdog expiry, native switch, owner/consent revoke, instead of labeling these genuine Home. SpringBoard registers separate handlers with corresponding stop reasons. Only the physical Home and existing direct user Home path retain `DF144StopNotify`. The ten-second watchdog is still a safety stop, **not** claimed to match original manager pending behavior.
- Pure source-level regression `sideplay/duoface-native-scene-host/tests/test_qa148_real_pid_and_stop_identity.py` verifies real PID gating, ABI/owner checks, exact ACK value preservation, three non-Home notifications and the pinned frozen scene host blob. Separate `DFSceneHost.m` unchanged (Git blob `ec2924c145be4edaaa27b7320bb869b18de12c6b`), so GOFA/YouTube and QA141 geometry policy are preserved.
- Both `duoface-146-native-home-exit-private.yml` and `duoface-qa147-mount-ready-guards.yml` run the new tests. Current frozen 10-stage source checker `verify_full_route_evidence.py` pinned to both changed files and extended to 19 static checks; `duoface-qa147-full-route-evidence.yml` expects `19_STATIC_ASSERTIONS_PASS_NOT_RUNTIME_PARITY`.

## Real CI verification / failures corrected

Initial targeted run `41204660525` failed because the new test used `git show <old-commit>:path` on a shallow Ubuntu checkout (exit128). This was a **test fixture**, not an Objective-C compile failure. Replaced with exact Git blob SHA1 byte calculation, including the required NUL separator; source commits `2e973da65019f4fd66e97b2973bab7db88f63bce`, `27e6614e25875e357c8a6db2920a86ae85af6041`.

- Targeted scoped regression [run 41204767449](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41204767449): **completed SUCCESS**, after the test fix. This covers source invariants only.
- Updated 19-condition historic/static evidence run [41204704464](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41204704464): **completed SUCCESS**; the prior `41204694054` failed because the workflow still grepped the old 17-check marker. No original binary was rerun; historical audit receipts and Log23 are pinned, and all reference-vs-implementation assertions are source/static.
- iOS16 macOS private signed candidate build [run 41204767520](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41204767520): started with latest source after changing tests. **Consult live run results and SHA256SUMS before reporting success or package availability.** Workflow deliberately does not publish Sileo.

## What remains genuinely unknown

- This public processState signature does not certify real selector ABI or successful matching PID on the test iPhone. A new physical trace must distinguish `qa147-ready-pid-unavailable`, `qa148-real-processstate-pid`, `qa147-ready-verified-pid` and native result/Dock outcomes with matching RequestID and CarDisplayID.
- Native manager process preparation/phone-eviction, activation after host/window, app-side bridge state for non-YouTube/GOFA bundles, native Dock/Home state and exact Home destination are **not** implemented to original parity. No claim that extra PID support alone will solve UI rotation, slow first touch or native Home.
- An accurately labeled watchdog is not a restored native Home screen. No physical user acceptance, public Sileo publication or test/install request made by this change.

## Reproduce

```bash
python3 -m unittest discover -s sideplay/duoface-native-scene-host/tests -p 'test_qa147_mount_ack_reentrancy.py' -v
python3 -m unittest discover -s sideplay/duoface-native-scene-host/tests -p 'test_qa148_real_pid_and_stop_identity.py' -v
python3 sideplay/audit/qa147-full-route-evidence-20261031/verify_full_route_evidence.py --repo .
```


## CI result finalized and repository artifact verified

- **Targeted regression CI** [41204767449](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41204767449) SUCCESS: QA147 reentrant mount guard and new QA148 processState/stop-identity guard; old Home QA144/146 guards maintained. Static/contract checks, not on-device behavior.
- **Full static 19-check route evidence** [41204704464](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41204704464) SUCCESS. The checker pins `DFHomeStandalone144.m` blob `1952332bbdca262114f1cc0d5c23467b1d0c6fa3` and `DFNativeDockSync147.h` blob `8ee73ebc7386c2f2b3e5d5321cc7f285bc997f9f`. Its checks do not prove that the newly added SpringBoard PID branch is reached on the user's iPhone.
- **Signed full iOS/macOS private build** [41204767520](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41204767520) / job `124547508589`: completed SUCCESS, source commit `27e6614e25875e357c8a6db2920a86ae85af6041`; compile, legacy regressions, signed native bridge, integrated packaging, private artifact and GitHub archive all succeeded. QA remains unpublished.
- Verified signed DEB `sideplay/jb-embedded-appbridge/evidence/runs/41204767520/com.duoface.jb.embedded_0.0.147~native-dock-sync1_iphoneos-arm64.deb`, size **1,170,196 bytes**, SHA256 **`630e14e18c90408f783534bc7007ac9a32a16f6addf5aa9804be1124ef7aeed6`**, exact file Git blob `a077a8f4efc3f625017cef3d97d3ffeef45866fd`.
- Complete GitHub tree of source+artifact archive commit `cc876deb92668ed59c53d77eeebfb384414573bd` read back and verified `CI_RESULT.txt`, `SHA256SUMS.txt`, `PACKAGING_PROVENANCE.json`, signed DEB all exist. Actions ZIP artifact ID `13044242186`, ZIP digest `a5d072964256c24cb7111f47e454ce7212377b30f5e5ebaa4b51cef9212ccb32` (different from internal DEB digest).
- CI_RESULT.txt exact values: `BUILD=success`, `SIGNED=true`, `SILEO_PUBLISHED=false`, `DEVICE_DIRECT_HOME_TESTED=false`, `STANDALONE_OWNER_FOREGROUND_VERIFIED=false`.
- No CarPlay device capture after this new candidate, no new public Sileo package or Home/Dock parity guarantee. The DEB is an archived private diagnostic candidate, not a release.

