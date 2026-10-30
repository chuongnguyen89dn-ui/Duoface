# QA125 ABI correction: signed Sileo release and device-QA gap

Date: 2026-10-30. User requested source correction based on DuoNavi original on-device Observer log.

## Original evidence and exact scoped fix
- Original iOS 16.7.16 SpringBoard SBSuspendedUnderLockManager contains _shouldBeBackgroundUnderLockForScene:withSettings: with type encoding B32@0:8@16@24 and 4 ObjC args; shouldBeUnderLockForScene: is absent. Source log: main:sideplay/log/DuoNaviObserver-69D22C75-5122-4EFC-B21F-59FAE0B60498.txt, blob 8eb93be5464e710c17a7635d22537dc999be5ab6.
- Previous QA124 installed NEITHER hook due to both-method preflight (source DFSceneLifecycle.m). QA125 only hooks existing ABI-matched background selector, owner-scoped for a live external hosted app scene with a fresh session heartbeat. Nonowned scenes forward to original Apple implementation. No passcode/activation methods or vendor code changed. Source initial commit 8663aac9363b31f451c2213b81b9197dbc6f899b.
- DFNativeHostAppDelegate.m logs qa125-background-boundary with activation/protected-data/window evidence, but retains conservative genuine Home/disconnect teardown. This is not a proven full phone-lock YouTube Play remedy; physical test is required.

## CI source/build/publisher evidence
- Version integrated com.duoface.jb.embedded 0.0.125~lockabi1; nativehost 0.1.125~lockabi1; Info CFBundleVersion 125.
- First CI 41005389876 failed due stale .124 assertion in test_native_rail_120.py. Fixed at aca3508cda8b680f40d03dad307b2235fb7d798a; workflow updates at 7bde7aab4521341321c0ad4ce99bc3c189ab7deb.
- **Signed macOS GitHub Actions CI run 41005523412 SUCCESS**, job 123899430530, source SHA 7bde7aab4521341321c0ad4ce99bc3c189ab7deb; archived package commit 272f229a61ebc126ef8aeb92e3a05bd63ae440be.
- Exact package sideplay/jb-embedded-appbridge/evidence/runs/41005523412/com.duoface.jb.embedded_0.0.125~lockabi1_iphoneos-arm64.deb.
- Exact binary SHA256 1914f4e2c6e8dce0fadb5035166c0869966759fb74eb1c89424712dcf71cbe93. CI evidence SHA256SUMS.txt, PACKAGING_PROVENANCE.json and CI_RESULT.txt at same path. Artifact id 12955501288. CI_RESULT SILEO_PUBLISHED=false is build-stage only, superseded by public Pages validation below.
- First Sileo publisher run 41005904302 failed due stale coexistence assertion requiring QA124 as current active; package SHA/DPKG checks already passed. Fixed publisher at carplaydsp/main .github/workflows/build.yml commit fd30237838a8e8586f91b603b00c96011a927710 to expect active QA125 while retaining QA124 rollback.
- Publisher workflow YAML validator run 41006218096 SUCCESS.
- **Public Sileo Pages run 41006218095 SUCCESS** (at 2026-10-30T05:07:04Z). Jobs build 123901603031, deploy 123902693552, standalone observer checker 123902751468, QA11 checker 123902751521, integrated QA125 verifier 123902751601 all SUCCESS. Verifier printed DUOFACE_ONE_PACKAGE_PUBLIC_SILEO_INDEX_VERIFIED and DUOFACE_PUBLIC_SILEO_DEB_DOWNLOAD_AND_CHECKSUM_VERIFIED, and download sha256sum returned OK.
- Repo source https://chuongnguyen89dn-ui.github.io/carplaydsp/ and direct public signed package https://chuongnguyen89dn-ui.github.io/carplaydsp/debs/com.duoface.jb.embedded_0.0.125~lockabi1_iphoneos-arm64.deb.
- Exactly one active com.duoface.jb.embedded = 0.0.125~lockabi1 in public APT; signed QA124 and QA92 stay downloadable for rollback; separate passive DuoNavi Observer retains its own public package.

## Physical status and next action
- NOT YET VERIFIED: QA125 installed, phone locked YouTube Play, CarPlay Home and actual unplug/reconnect. On iPhone X iOS16.7.16 disable/remove original DuoNavi when testing DuoFace QA125 (avoid dual hook conflicts), update using Sileo, respring normally.
- Test at parked vehicle: Dock and 4 panes; Play YouTube with iPhone lit; lock phone and try Play while preserving Dock; Home CarPlay return; unplug/replug. Export new DuoFaceAudit to Duoface/main:sideplay/log/. Logs of interest: qa125-underlock runtime-presence background=1 obsolete=0; scoped-existing-background-hook-installed; qa125-background-boundary; touchowner-stop reason=scene-background.
- Do NOT claim full screen-off playback fixed from CI alone. If fails, new error boundary is CPTemplate scene ownership/foreground, not missing underlock selector; do not disable every background teardown or alter passcode.
