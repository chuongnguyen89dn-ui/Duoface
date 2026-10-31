## 2026-10-31 — QA154 generic app-side lease and restoration source staged

**New request:** "Tiếp tục". Stay on `chuongnguyen89dn-ui/Duoface`, branch `feature/duoface-qa146-native-home-exit-20261031`. Baseline QA153 private signed build `41214955481` stays unchanged/preserved. Original user-rejected Log23 unchanged.

**Concrete source progress:** `sideplay/duoface-native-scene-host/DF154AppStateProtocol.h` commit `8c7717042a60d8f5c3998df56e722e65fabfe066`: a new independent short-lived 3s owner/bundle/request/scene state carried by `NSDistributedNotificationCenter`. `DF154GeneralAppStateRelay.m` commit `3d19e28f1d3760f89a76721263c5e41b6219e7e2`: separate **unpackaged** UIKit scene listener, only accepts matching real UIKit scene ID; saves frames/bounds and restores on app owner terminal, replacement or lease expiration. `DFHomeStandalone144.m` commit `24e5126a38c7f9f23bb161d9971cebec73453b0c`: SpringBoard sends/renews state only after real owned live hosted scene, and revokes on stop, excluding existing dedicated YT/GOFA paths. Frozen `DFSceneHost.m` blob `ec2924c145be4edaaa27b7320bb869b18de12c6b` unchanged.

**Critical status:** app-side generic receiver is source-only **NOT built into DEB and NOT installed/injected into third-party apps**. There is no new Substrate app filter. This is a source-level continuation toward the original per-app state+restore boundary, NOT functional multi-app UI acceptance. No public Sileo release.

**Tests/CI:** new `tests/test_qa154_staged_app_state.py` commit `0cc66369297e2d20c8c718f391d25569ff870c62` guards live owner/scene, 3s lease, restore and absence from shipping build. Fast workflow `9706752b159f8398fd2d0b6c6a19f5a585ba3d1c` run `41216470683` **SUCCESS**. Private macOS workflow `ecba74effb7848cfe7deae86a57b87d12f2588fe` added isolated iOS source syntax-only compile: run `41216478996` **FAILED** because syntax-only clang rejects unused `-framework` link flags, **NOT Objective-C compile failure**; corrected step at `c7844358ca28845877f39525825a01ca190a92e8`. Its new private build run `41216554297` had passed QA154 source syntax check and was compiling baseline when last observed; **recheck completion/archive SHA before claiming signed success**. Static 31-check original+QA154 source audit `sideplay/audit/qa147-full-route-evidence-20261031/verify_full_route_evidence.py` updated `2b9d5454f7638e3371c0bd3ea0b096eb864d02ab`; CI marker `d1b950790695d48f03a22a3cb646003572435bd9`, run `41216635707` **SUCCESS**. Prior audit `41216616845` failed stale 29 count.

**Next:** check macOS signed private build `41216554297` and repository evidence archive; retain receiver unshipped pending precise eligible-app process/packaging review and physical app-side scene ownership, touch/rotation and restore proof. Do not expand injection silently, alter Native12/GOFA/YouTube geometry or assert final Home/Dock fix. Detailed report: `sideplay/audit/qa154-app-state-continuation-20261031/STATUS.md`. Central skill ZIP 02/05 found on `Gpt-training-` but binary fetch errors `UnicodeDecodeError`; relevant Markdown skills read, ZIP not extracted.


# tiep tuc du an — DuoFace / SidePlay active checkpoint

**Updated:** 2026-10-31, QA153. **Canonical repo** `chuongnguyen89dn-ui/Duoface`. **Branch** `feature/duoface-qa146-native-home-exit-20261031`. **Current source under test:** `ba6c8b786f36266ef45b84894750525c711125f8`. Keep implementation first-party, no vendor license/code and do not disturb Native12 split/GOFA/YouTube baseline.

**Critical archival rule:** The complete pre-QA153 handoff (842 KB, all prior dated checkpoint histories) is preserved **byte-for-byte** at `sideplay/audit/handoff-history/tiep-tuc-du-an-before-qa153-20261031.md`, git blob `2584539a3ed4b2bb12d5377b79413839ba4c4a7e` (also recoverable at parent commit `f764cbeac2dd952ffe9e11b956bd17a3d60cfe2f`). This file is the **only current handoff entry point**; the archive is historical evidence, not a new handoff to edit. Read the archive only as needed for preceding QA/commits and original evidence.

## User intent and non-negotiable constraints

User asks to continue fully implementing independent CarPlay bridging within DuoFace, following verified **execution/lifecycle order** of original DuoNavi/Native12/DuoDash rather than guessing UI setters. Original genuine DuoNavi1.0.4 dylib SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`; DuoDash reference repack is not an original. User device iPhone X palera1n rootless iOS16.7.16, no actual device access via connector. Rejected QA147 Log23 SHA256 `c327274898d8d7285259d4bdbfc04b623a81e3cb6263ccda7ccf948d9cca267d`: Home wrong, slow app launch, Dock not active, mobile portrait orientation and attach errors. **Do not publish another speculative Sileo build or state device success without logs.** Native Apple Home and supported apps remain forwarded; frozen `sideplay/duoface-native-scene-host/DFSceneHost.m` Git blob `ec2924c145be4edaaa27b7320bb869b18de12c6b`.

## QA153 latest source: phone app eviction added after native Dashboard prep

- `sideplay/duoface-native-scene-host/DF153PhoneEviction.h`: commit `a2a06d786481cc97281283a65480c71bddabb347`, blob `c468102f9efef875bf349b2cd181d3530792480f`. SpringBoard-only checks the **real phone frontmost app** through ABI-checked `_accessibilityFrontMostApplication`, real `bundleIdentifier` == selected app, `processState.isForeground` true, and exact private `SBUIController.sharedInstance` and `clickedMenuButton` ABI. **Only if every gate passes** calls native phone Home (the original conditional phone eviction branch), once-only 120ms deferred continuation, request generation and cancellation. Mismatch means no native phone mutation and continuing old host path. **Does not** guess `SBMainWorkspace` transition object/selector.
- `sideplay/duoface-native-scene-host/DFHomeStandalone144.m`: commit `80a27e62cc80b1b79d2c98905306ba38740f3322`, blob `908b11a99f667ca04edec9360b7767ceb9d778ab`: receiver validates selected request and opt-in, then conditionally evicts the *matching* phone foreground app before `DF144Solo begin:`. Async continuation rechecks exact RequestID, age and consent. Physical Home, native app switch, timeout and revoke cancel pending phone stage. QA152 native Dashboard workspace prep still happens **before** cross-process receiver request.
- `sideplay/duoface-native-scene-host/tests/test_qa153_phone_foreground_eviction.py`, commit `0a050345e041f45ea9982e14cb4d35c086e78231`, checks owner/foreground/ABI/once/cancel and frozen host. Fast CI workflow `f534492cfb1ea81ec99ac7034bf4290400942f7e`; private macOS iOS16 workflow `ba6c8b786f36266ef45b84894750525c711125f8`. `verify_full_route_evidence.py` now 29 historical/static assertions commit `196eaa2c3feeb295cd92a1503b8a733d33bfa204`, CI expectation `515704451d21a0f5a6a65c72ecdd21043bceeef8`.
- Prior source components: `DF152NativeWorkspacePrepare.h` conditional native Dashboard workspace deactivate with correct owner/ABI, completion and 250ms fallback; `DF151WorkspaceOwnerCapture.h` real Dashboard workspace owner (cluster excluded); `DFManagerLifecycle149.h` scene manager state distinct from PID; `DFNativeDockSync147.h` native Dock result/history and passive native button press. Detailed historical decision trail in archived handoff.

## Actual GitHub CI/build evidence, not device parity

- Fast C/Python/source CI [`41214947768`](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41214947768): **SUCCESS**.
- 29-check static original-vs-first-party route [`41215018619`](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41215018619): **SUCCESS**. Earlier `41214998384` failed stale 27-check workflow expectation, subsequently corrected.
- macOS iOS16 rootless private integrated native DEB build [`41214955481`](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41214955481), job `124577539330`, source commit `ba6c8b786f36266ef45b84894750525c711125f8`: **COMPLETED SUCCESS**, signed and archived. Exact DEB `sideplay/jb-embedded-appbridge/evidence/runs/41214955481/com.duoface.jb.embedded_0.0.147~native-dock-sync1_iphoneos-arm64.deb`, size **1,177,256 bytes**, SHA256 `7f609a78159a506e58c82c5813b436f2b82daec9f55a8c3a3cb912ae8c88d44e`, Git blob `4112ba010a4e196ec78909a19a56557daa9be0af`. Archive tree commit `c3750831f06b265e6c0291c6818ed5ec262ba975` nontruncated verified four files: DEB, `SHA256SUMS.txt`, `PACKAGING_PROVENANCE.json`, `CI_RESULT.txt`; artifact ID `13047444666`.
- `CI_RESULT.txt` explicitly `SIGNED=true`, `SILEO_PUBLISHED=false`, `DEVICE_DIRECT_HOME_TESTED=false`, `STANDALONE_OWNER_FOREGROUND_VERIFIED=false`, default opt-in OFF. **NO physical acceptance claims.** Details: `sideplay/audit/qa153-phone-foreground-eviction-20261031/PHONE_EVICTION_CI_AND_LIMITS.md` (last update commit `f764cbeac2dd952ffe9e11b956bd17a3d60cfe2f`).

## Work still blocked / next exact operation

**Confirmed code and CI, unverified device behavior:** Need actual iPhone X 16.7.16 session tracing `qa150-native-workspace-abi`, `qa151-native-workspace-live-owner`, `qa152-native-workspace-deactivate-request`, `qa153-verified-phone-target-eviction`, `qa149-manager-live-scene-owned`, `qa147-native-dock-active` with same RequestID. Only then conclude whether ABI guards run and where it fails. Native alternate `SBMainWorkspace` phone evict path, general app-side state/restore, complete previous Home navigation, proper landscape/touch/launch speed/reconnect remain not proven. Do not ask user to install repeatedly or claim 100% fixed. No scheduled/background work.

**Reproduce from repo root:**
```sh
python3 -m unittest discover -s sideplay/duoface-native-scene-host/tests -p 'test_qa153_phone_foreground_eviction.py' -v
python3 -m unittest discover -s sideplay/duoface-native-scene-host/tests -p 'test_qa152_workspace_prepare.py' -v
python3 sideplay/audit/qa147-full-route-evidence-20261031/verify_full_route_evidence.py --repo .
```
GitHub skills: `chuongnguyen89dn-ui/Gpt-training-` `SKILL_INDEX.md`, `AGENTS.md`, `DEB_IPA_SKILL.md` read. Skill ZIPs 02 and 05 identified but **not freshly extracted** through connector. No other repo modified.

## Chronology

- QA147 rejected by physical Log23; true root execution path investigated in original reference audit.
- QA148 real SBApplication PID + honest Home/timeout/switch stop labels.
- QA149 scene manager receipt and native Dock routing observations.
- QA150 runtime method ABI inventory and terminal result preservation.
- QA151 actual Dashboard-owned workspace capture, passive.
- QA152 guarded native Dashboard workspace deactivation before SpringBoard scene request.
- **QA153 current:** guarded selected-app phone foreground eviction before SpringBoard hosts CarPlay scene. Private signed build only. Continue with exact iOS device ABI/route evidence and app-side restoration.

