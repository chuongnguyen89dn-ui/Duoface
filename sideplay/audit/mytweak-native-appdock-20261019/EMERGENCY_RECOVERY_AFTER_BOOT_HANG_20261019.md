# 2026-10-19 — MyTweak 0.2.5 post-install hang: recovery checkpoint

## User report / scope
- User reported iPhone **hang immediately following installation** of public `com.duoface.mytweak.v1a.preflight 0.2.5~shell1`. User later replied "Đc rồi h sửa ntn" indicating device recovered, but **recovery route, exact hang stage and crash/panic log remain UNKNOWN**. Do not claim root-cause proved by logs.
- Device context: iPhone X iOS16 rootless, CarPlay head unit. Preserve QA11/Native12/HUD8, existing app data and previously user-tested V1B+C two-app functionality.
- User requests fixing the unstable package. Latest Sileo release 0.2.5 considered DEVICE_UNSAFE. Do not advise reinstall of 0.2.5.

## Strong source-grounded suspect
`feature/mytweak-dashboard-activation-20261019:sideplay/mytweak-independent-v1a/V1ATweak.x` invokes `[MTCarPlayAdmission installIfNeeded]` in `%ctor` **regardless of Filza `Enabled`**. `MTCarPlayAdmission.m` modifies LSBundleProxy getters `entitlementValueForKey:ofClass:`, `entitlementValuesForKeys:` and `LSBundleInfoCachedValues.boolForKey:` in SpringBoard, registers image-load callbacks, and also hooks CarPlay. `MTDashboardWorkspace.m` adds private `DBWorkspace.initWithOwner:` runtime observer. Unlike older V1BC, these interventions can execute during process bootstrap. Could be responsible for hang, but **install-time uicache / package scripts or another conflict are also plausible**. Do not assert causality without log.

## Emergency corrective action COMPLETED (source/CI)
- Exact known-working source baseline: `chuongnguyen89dn-ui/Duoface` branch `feature/mytweak-v1bc-combined-20261019`, SHA `67ba830685416a3810255c383dc9aa1b1f9033d8`; user previously passed real-device split scenes, app picker, touch, drag ratio, Swap, Zoom, Close, but Dock absent.
- New `feature/mytweak-recovery-safe-20261019` branches from that baseline and updates ONLY `control` version to **`0.2.6~recovery1`** plus matching tests and an emergency workflow. Source engine and `V1ATweak.x` match user-tested baseline, i.e. no carplay process injection, no `MTCarPlayAdmission` binary compilation, no scene-shell app or init-time LSBundleProxy swizzle, normal `SpringBoard` only injection, disabled by default/Filza opt-in.
- Tests `tests/test_recovery_safety.py` explicitly require no hot-path hooks in constructor and no CarPlay app payload; old split UI test remains. `.github/workflows/mytweak-emergency-recovery.yml` checks correct exact two-file rootless arm64/arm64e DEB and no unwanted libraries.
- First CI run `39210369830`: **source/compilation/package PASSED**, but artifact upload failed because workflow `DEST` wrote to `mytweak-v1bc` while uploader looked for `mytweak-recovery-safe1`. Workflow path fixed commit **`7d33a263c178fdef22b18b1c2b3e89bc5166a021`**.
- Verified CI [`39210563968`](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39210563968) **SUCCESS**: source contracts (read test count from run log), Theos iOS16 rootless arm64/arm64e; two payload files `DFV1APreflight.dylib` and `DFV1APreflight.plist`; DEB metadata exactly original ID, new version.
- Verified artifact branch commit **`516591f95e13e476b63fedfaba438edd60020195`**, re-fetched:
  - `sideplay/test-artifacts/mytweak-recovery-safe1/com.duoface.mytweak.v1a.preflight_0.2.6~recovery1_iphoneos-arm64.deb` **41,314 bytes** SHA256 **`1c3cbb637754878c12d4dfb81731c31b19bb99b385ea3cfbd8dde20617baca12`**.
  - `CI_RESULT.txt` `MYTWEAK_RECOVERY_SAFETY_BUILD=PASS`, `LS_HOT_PATH_HOOK_COMPILED=false`, `HOST_DEFAULT_ENABLED=false`, `NATIVE_CARPLAY_DOCK_FIXED=false`, `DEVICE_TESTED=false`.
  - `SHA256SUMS` and `FILE_LIST.txt` corroborate SHA/only two files.
- **No assertion of actual crash fix / Dock restored on device**. Device proof is unavailable until user tests after recovery.

## Distribution CURRENT checkpoint
Publisher repo `chuongnguyen89dn-ui/carplaydsp`, `main:.github/workflows/build.yml` commit **`a60ed9f2798718d399dbbddf928a9495d09079f1`** pins recovery artifact exact immutable `516591f...`, version `0.2.6~recovery1` and SHA `1c3cbb...`, verifies absence of old `MTDuoFaceShell.app` and two-file payload; keeps QA11 version unchanged. Publisher [run `39210807542`](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/39210807542) was **in progress** at this checkpoint. DO NOT say Sileo is live until publication success + `release-checkpoints/mytweak-recovery1-pages-verified.txt` read-back.
- Public Sileo repo `https://chuongnguyen89dn-ui.github.io/carplaydsp/` and anticipated after verification `https://chuongnguyen89dn-ui.github.io/carplaydsp/debs/com.duoface.mytweak.v1a.preflight_0.2.6~recovery1_iphoneos-arm64.deb`.
- Prior unsafe public `0.2.5~shell1` was never verified device-safe; user reports hang. **Do not have user install any version just to test Dock**.

## Next actions and acceptance
1. Verify CarPlayDSP run `39210807542` + actual public APT listing and DEB SHA; QA11 stays `0.1.9~native12dock11` exact SHA `0d20390c560452b0c68c9311ae3c58a48bc9d3e7528de1b130c6bca58c87c1b9`.
2. In chat: ask exactly how user recovered (Safe Mode / uninstalled / disabled tweak), and **avoid advising another tweak injection until stable**. If bad package still installed, remove it first in Safe Mode or update recovery cautiously. Show branch/CI/Sileo status precisely; avoid claiming Dock fixed.
3. If fresh `0.2.6` recovery actually stable, revisit native AppDock in **isolated opt-in extension** with no launch-time LS hot-path hook in SpringBoard and actual device diagnostic before release. Do not ship another shell without rigorous VM/device test.

## VERIFIED SILEO RECOVERY PUBLICATION (supersedes IN PROGRESS)
- [CarPlayDSP Actions 39210807542](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/39210807542): **completed SUCCESS**, UTC updated 2026-10-19T06:38:51Z; all `build`, `deploy`, `verify-qa11-pages` SUCCESS.
- Live public repo `https://chuongnguyen89dn-ui.github.io/carplaydsp/`; emergency MyTweak `com.duoface.mytweak.v1a.preflight 0.2.6~recovery1`; direct DEB `https://chuongnguyen89dn-ui.github.io/carplaydsp/debs/com.duoface.mytweak.v1a.preflight_0.2.6~recovery1_iphoneos-arm64.deb`; public index/file SHA256 **`1c3cbb637754878c12d4dfb81731c31b19bb99b385ea3cfbd8dde20617baca12`**.
- Read back actual `carplaydsp/main:release-checkpoints/mytweak-recovery1-pages-verified.txt` blob `17fc4a065c485009b86d6d61e9cceae0b9ceea5c`, `MYTWEAK_RECOVERY1_SILEO_PAGES_DEPLOY_VERIFIED`, `HOT_PATH_ADMISSION_HOOK_REMOVED=true`, `NATIVE_CARPLAY_SCENE_PACKAGED=false`, `NATIVE_DOCK_STILL_UNRESOLVED=true`, `DEVICE_TESTED=false`. Legacy `DASHBOARD_CONTEXT_NATIVE_WINDOW_PROBE=true` field is stale publisher label and **not** compiled feature; Makefile and 2-file payload are authoritative.
- QA11 verified unchanged from `carplaydsp/main:release-checkpoints/qa11-native12dock11-pages-verified.txt` blob `c009ae6d3067b4c5e4744f6686984d5c20dac50f`, version `0.1.9~native12dock11` SHA256 `0d20390c560452b0c68c9311ae3c58a48bc9d3e7528de1b130c6bca58c87c1b9`.
- **Do not misrepresent this as native Dock fixed or proven safe on the user's device.** User recovered before this public release. If still using the broken version, first ensure it is disabled (and machine stable); then refresh Sileo and cautiously use the recovery update, or remove the MyTweak package outright if UI functionality is not needed. Preserve QA11/Native12/HUD8. Ask how user recovered to distinguish installed vs removed package.
