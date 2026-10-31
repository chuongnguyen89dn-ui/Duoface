# QA143 signed rootless Home-to-DuoFace scene beta: verified source, build, and Sileo status

Project: chuongnguyen89dn-ui/Duoface, branch feature/duoface-qa142-home-abi-20261031.
Source exact SHA: 7e9cb8df5c02903557f53f47447d977ba7a84aef.
Signed macOS Actions run: https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41177472190; job 124467956220, completed SUCCESS, all source tests, Theos three components, iOS arm64 compiler and ldid signatures, exact combined rootless DEB and archive.
Signed immutable archive commit: e475878b2fe93dde2e62f66f5f8c2d1217798618.
Integrated DEB: sideplay/jb-embedded-appbridge/evidence/runs/41177472190/com.duoface.jb.embedded_0.0.143~homebridge1_iphoneos-arm64.deb.
SHA256: db9019a708c4905602d00ed500878c01f208b26655e42ee079dacf30d925c39c.
Archived receipt: sideplay/jb-embedded-appbridge/evidence/runs/41177472190/CI_RESULT.txt; manifest SHA256SUMS.txt, provenance PACKAGING_PROVENANCE.json and QA143_UUIDS.txt.
QA142 public rollback version 0.0.142~homeabi1 and exact historical artifact preserved.

Scope implemented:
- DFHomeLaunch143.m: CarPlay process, exact Log21 real ABI method DBDashboardHomeViewController iconManager:launchIconForIconView: v32@0:8@16@24; read selected app icon's live bundle identifier; on explicitly enabled/consented ordinary app, look up existing real DuoFace Home icon among currently rendered UIKit windows and forward original CarPlay Home launch once with that system icon. One-shot plist with uuid+timestamp+bundleID, not a fabricated DBApplication or URL. Unknown/unselected or missing current-page DuoFace icon forwards native original untouched. New launch143 diagnostic file includes class, bundle, success/forwarded.
- DFHomeSceneBridge143.h/.m category + DFHomeRequestReceiver143.m in SpringBoard: only after real CPTemplate foreground lease and Chrome visible, 15s one-time intent accepted, uses real DFNative12Chrome appPicker:didSelectBundleID: and existing DFSceneHost scene lifecycle, not a second host. No entitlement patch, does not force app foreground. ACK means scene requested, not scene ready.
- DFTouchOwnerProbe.m now calls receiver only after valid sChrome start; existing GOFA resize141, YouTube, Apple Dock/BKS logic preserved.
- First source test run 41177231350 failed on a compiler warning for category method declared in primary class; exact fix declared method in category header only. Final QA143 41177472190 PASS.
- Run only safe physical test when parked and with genuine DuoFace native icon visible on SAME Home page as approved app icon. Without the actual rendered icon, intentionally fail open; scope limitations are explicit. Successful phone click->DuoFace CPTemplate foreground->SpringBoard sceneReady and real touch/HOME/Back/GOFA/Dock have NOT been tested on user's hardware.

Publisher (other repo metadata only):
- chuongnguyen89dn-ui/carplaydsp main .github/workflows/build.yml changed via authorized GitHub connector commit 1a91d54ab1c790eb970cf32e36696e5249668f6c. SHA-pinned exact immutable QA143 archive and verified component files; QA142 retained as frozen rollback; new expected 97 historic integrated DEB artifacts and exactly one latest version 0.0.143~homebridge1.
- Sileo workflow syntax/actionlint validation run 41177913539 SUCCESS.
- Active build/deploy run https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/41177913481. As of last read, still in progress (initial steps). DO NOT claim public QA143 before its build/deploy/verification jobs and real CDN+APT checks pass.
- Preliminary promotion automation 41177830836 did verify the immutable SHA/controls and patch size, but failed to push workflow file via built-in Actions token lacking workflows permission. The GitHub connector made the identical patch directly successfully; no source build failure.

Next:
1. Check 41177913481 until real workflow completion. Inspect job logs on any failure. Verify public https://chuongnguyen89dn-ui.github.io/carplaydsp/Packages single integrated package version 0.0.143~homebridge1 with exact db9019a... hash and public .deb binary exact SHA; record citation/commit.
2. User installs QA143 from Sileo on iPhone X iOS16.7.16, respring, places DuoFace native icon and selected ordinary app icon on same CarPlay Home page, taps approved app while parked, exports new diagnostics. Look for [DFHome143] home-callback, selected-tap-redirect-to-existing-duoface-icon, [DFHome143SB] request-consumed, [DuoFaceScene] real sceneReady with exact bundleID, and physical video/touch/Home/GOFA outcome. Unknown results remain UNKNOWN; absence of logs pinpoints whether first callback wasn't invoked.
3. If host icon not visible, never claim universal activation; discover actual Dashboard live DBApplication object / workspace instead of guessing APIs. Preserve QA142 rollback, no global entitlement hooks (old QA138 caused FrontBoard stack recursion crashes).

Skill source: Gpt-training- SKILL_INDEX.md and verified ZIP 01/02/05 via Actions 41174290359. No application code/build/records stored there.
