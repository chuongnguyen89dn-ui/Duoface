# QA157 SOLO three-dot bridge and first-party Home chooser — signed & existing Sileo verification (2026-11-01)

## User request and causal evidence
User says original DuoNavi 1.0.4 shows its own **three-dot menu** over non-CarPlay iPhone apps, suggesting an integrated one-pane bridge rather than standalone bare window. Actual SHA-locked original DuoNavi ARM64 has `CBBridgedSplitApp.initWithBundleIdentifier:frame:showSplash:` @0x109bc8 with `multitaskingPill`, `setOnPillTapped:`, and `splitPreset`, plus `CBBridgeManager.showAppPickerForSlot:` @0x2a2630; original callback trace shows synchronous stopBridging/requestDismiss inside native Home. Exact original preset value not measured. Existing DuoFace 0.0.156~nativebridge4 was **physically rejected**: unsupported-app Home returned to generic CarPlay Home rather than the app chooser.

## Actual first-party source work
Branch `feature/duoface-qa146-native-home-exit-20261031`; release source commit **`3ce6b5f1b2e45426ed07a95a72208ae644029dbc`**. Only own code; original proprietary implementation/license not copied.

- New `sideplay/duoface-native-scene-host/DFSoloPill157.h`: actual 3-dot pill and installed `DFAppPickerVC` mounted as children in the existing `DF144Solo` root/window; no duplicate SBAppViewController or global split preset changes.
- New `DFSoloPickerCarPlay157.h`: unique SelectionID, exact active request+bundle+CarDisplay session or newly renewed standalone chooser owner lease; resolves real native Dock; calls existing `DF144BeginSelectedBridge` to switch apps via native Dashboard prep/ACK.
- Updated `DFHomeStandalone144.m`: native Home retains source-owned picker after releasing current app scene; guards duplicate viewDidAppear teardown, exports a properly link-visible Home/Dock function across .m files. Normal native Music/Calendar are untouched by the SOLO owner gate.
- Updated `DFCarPlayOwnerObserver.h` and `DFNativeDockSync147.h`: original Apple Home callback forwarded; synchronously revoke own Dock manager and remove chooser when a real Apple native app takes Dock.
- New regression `tests/test_qa157_solo_owned_pill.py`, updated QA153 phone eviction and build workflow; all old YouTube/GOFA/native Maps modules retained. Build/control/Info/package tests all versioned distinctly `0.0.157~solopicker1`.

## ACTUAL automated verification

- GitHub DuoFace QA157 scope/guard run **41276477056 = SUCCESS** (source commit `7f41333a901865163903cdddaddeee89663f2fc1`).
- QA157 signed rootless native source+merged DEB build run **41276681110 = SUCCESS** (verified source SHA `3ce6b5f1b2e45426ed07a95a72208ae644029dbc`). First attempt 41276477033 FAILED solely because workflow still checked plist CFBundleVersion156, corrected grep to157 in commit 3ce6; rerun green. No claim first attempt passed.
- Signed artifact archived in **DuoFace repo** at `sideplay/jb-embedded-appbridge/evidence/runs/41276681110/com.duoface.jb.embedded_0.0.157~solopicker1_iphoneos-arm64.deb`, immutable archive commit `c16270c70a44321a90a2356664e832f5d5c0854a`, SHA256 **`3ae35449e1449733fbd81c8b873e4f670e0faba126041462572cd6ed7c5f966b`**, with `CI_RESULT.txt`, `PACKAGING_PROVENANCE.json`, `SHA256SUMS.txt`. dpkg package `com.duoface.jb.embedded`; iOS16 rootless architecture `iphoneos-arm64`. CI identifies SILEO_PUBLISHED=false at build checkpoint, intentionally prior to distributor publication.
- **ONLY original Sileo publisher** `chuongnguyen89dn-ui/carplaydsp` updated `main:.github/workflows/build.yml` commit **`0ac854a76f44dc01d0cff2b89d18cc56d8275e21`**; no new Sileo repository, original 0.0.156 binary and all earlier versions preserved for rollback.
- Publisher YAML actionlint run **41276997073 = SUCCESS**. Existing Pages Sileo build/deploy/verify run **41276997173 = SUCCESS**; `build`, `deploy`, `verify-duoface-integrated-pages`, `verify-duonavi-observer-pages` all green. Specifically verified **one** public `com.duoface.jb.embedded` APT record version `0.0.157~solopicker1`, its SHA256 `3ae35449...`, public DEB download and SHA256, and previous QA156/QA147/QA155/.90/.92 immutable rollback public downloads.
- Public Sileo source `https://chuongnguyen89dn-ui.github.io/carplaydsp/`; public signed QA157 package path `https://chuongnguyen89dn-ui.github.io/carplaydsp/debs/com.duoface.jb.embedded_0.0.157~solopicker1_iphoneos-arm64.deb`.

## Critical remaining acceptance tests

**NO new device CarPlay test performed**, no physical UI or Safari/Home acceptance claimed. The user must install exactly **0.0.157~solopicker1** from existing Sileo source when safe, on parked car, verify: (1) selecting Safari from native CarPlay Home opens it with usable 3-dot pill; (2) tapping 3-dot presents actual app picker; (3) selecting another allowed app changes owned scene and Dock correctly; (4) pressing Home from bridged Safari returns chooser not generic CarPlay Home; (5) normal Music/Calendar/Home/Dock/YouTube/GOFA/touch/locked screen and split layout unaffected; (6) native reentry no stale orphaned overlay. Preserve QA156 and .90 rollback. Any fail: pull new logs and compare user physical observation to exact source events, not assume static-pass means runtime-pass.

Last live verification: 2026-11-01 at Sileo Pages job `124761814678` success, public SHA256 readback event `DUOFACE_PUBLIC_SILEO_DEB_DOWNLOAD_AND_CHECKSUM_VERIFIED`, unchanged rollback evidence.
