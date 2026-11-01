# Safari Home exclusion fixed in nativebridge3; release verified 2026-11-01

## User failure and source cause
User reports second time: Safari selected but no CarPlay Home icon. No newly uploaded device trace was available; latest main sideplay/log Audit24 blob1f21a2095bdcd735e3c24fa7df0ef122d58cb629 unchanged. Installed device version/settings not independently read. Do not invent current iPhone log findings.
Published nativebridge2 source0851274 allowed Safari in standalone click handler, but DFHomeAdmission141.DF141Selected required DFIsRecommendedAppID, which excludes Apple bundles; DFHomePublisher136Core additionally skipped all com.apple.*. These deterministic source exclusions prevented the intended selected Safari inclusion/declaration/add/notify path. Prior instructions to launch Safari overlooked icon publication.

## Exact change and safeguards
Production b44836618d9d82f8864d97abec4b391e12cfa508: DFSelectedHomeAdmission.h accepts only picker-enabled recommended third-party apps OR exact Safari com.apple.mobilesafari. Used in actual LS admission and FBS reconciler. No blanket Apple enable, default/recommended selection change, new scene/geometry/IPC rewrite, new APT source or vendor/license code. Existing native declarations and Maps remain untouched. Standalone launch's existing identical Safari exception preserved.

Actual source tests:
- home_admission_141_forwarding_runtime.m extends getter2->getter3 + declaration assertions to selected Safari, disabled Safari and unrelated Apple negatives.
- safari_home_roster_runtime.m imports actual production admission+reconciler+picker, with controlled process/library doubles. Verifies old filters reject input, new LS -> FBS record -> declaration -> notify1, no duplicates, no system/uninstalled/disabled additions, native Maps identity preserved.
- First new harness compilation run41263076453 failed: mock processInfo returned id, properties untyped. Corrected to instancetype at9a02572494bfdd1b4d1ef26ca95d6442fc7a2e54. Second run41263145324 failed runtime due fake LSApplicationProxy/Workspace colliding with real macOS LaunchServices. Corrected test-only unique class names + scoped resolver atf7e75cce0ae1bb32da3348c118f1b4dfa30a39d3. Production logic unchanged through these harness corrections. Do not call those failures iPhone defects.
- Actual final signed run41263222402 job124720563114 SUCCESS. Real marker SAFARI_SELECTED_ADMISSION_REAL_FBS_RECORD_DECLARATION_NOTIFY_NATIVE_PRESERVATION_PASS and reconcile1/additions1. Existing forwarding + full regressions, actual iOS compile/sign/package checks PASS. Scoped regression41263076403 SUCCESS. macOS mock boundaries do not establish physical icon presence.

## Signed archive and independent inspection
Sourcef7e75cce0ae1bb32da3348c118f1b4dfa30a39d3; archive9e14e54b65ef126a39b5c6f1a1096ad135202f32.
DEB sideplay/jb-embedded-appbridge/evidence/runs/41263222402/com.duoface.jb.embedded_0.0.156~nativebridge3_iphoneos-arm64.deb,1192308bytes, SHA256 b3a89cfa4b6afd53ec555c16474023de1ce4e97e4e69e62e640d3d917b0355ef.
CI_RESULT/SHA256SUMS/PACKAGING_PROVENANCE independently re-fetched and agree; private CI_RESULT SILEO_PUBLISHED=false describes private build stage, later public release separately verified.
Downloaded actual archive with git show <archive>:<DEB path> > /tmp/df156-safari/candidate.deb; sha256sum, dpkg-deb -f Package Version Architecture, full dpkg-deb -c and -x PASS. Executed actual publisher Python filter/binary assertions with QA156_ROOT=/tmp/df156-safari/extracted/var/jb PASS. All3 relevant dylibs thin ARM64 with embedded Mach-O signature blobs, exact14 app relay filter. Runtime binary ldid readback is CI evidence, not a device load assertion.

## Public original Sileo verified
Source https://chuongnguyen89dn-ui.github.io/carplaydsp/ .
Public package com.duoface.jb.embedded 0.0.156~nativebridge3 iphoneos-arm64.
Public DEB https://chuongnguyen89dn-ui.github.io/carplaydsp/debs/com.duoface.jb.embedded_0.0.156~nativebridge3_iphoneos-arm64.deb .
Publisher carplaydsp/main .github/workflows/build.yml commitd823d1c78a33c5904eb22a528540f819e54b9e31, exact readback blob508168987c1447a68d7e9a8efaa6d9835939b534.
Local YAML/bash30steps/exact102 archive versions/version3>2 PASS; GitHub YAML+actionlint41263504872 SUCCESS.
Publication https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/41263505018 COMPLETED SUCCESS 2026-11-01T02:05:45Z (09:05:45 ICT), all5 jobs: build124721382055, deploy124722006729, public integrated verifier124722063914, observer124722063959, QA11/stable124722064040.
Actual public verifier read Packages/Release and downloaded DEB: exactly1 live entry, version3 filename/hash match signed archive. Prior nativebridge2 SHA b64d78e9678cd36f05ab9a5a4512559254b044de61d2bd5f5e22e2da8225eb17, nativebridge1 SHA9af1868794948317f1c9f1ebd15bb33b091c9132d99c815614287656b806e193, QA155 and QA147 all re-downloaded unchanged. No same-version overwrite/new source. 102 archived integrated version files; only latest APT record. Actual markers SAFARI_HOME_FIX_VERIFICATION.log.

## Next / still unverified
User refresh existing Sileo source, update exact0.0.156~nativebridge3 and respring; retain selected Safari and existing Home settings rather than resetting them. First acceptance is Safari visible on native CarPlay Home; only then direct launch, full touch after30s, native Home/Dock, app-side same request/scene ACK and restore. If still absent, collect current export and correlate Safari inclusion/declaration/notify with real settings/library ABI before another change. Do not claim physical success or full bridge completion. No current iPhone/vehicle access in this session.
