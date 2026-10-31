# QA144 private signed candidate — SOURCE/CI verified, CarPlay standalone NOT physical verified

**2026-10-31 — evidence-only, NO Sileo public update and no iPhone install.**

## Exact GitHub Actions build / bytes
- Project: `chuongnguyen89dn-ui/Duoface` branch `feature/duoface-qa144-standalone-carplay-home-20261031`.
- [Mac/iOS16 native QA144 compile and ldid check](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41180229988) run `41180229988`, job `124475939475`: **ALL STEPS PASS** (actual `clang -target arm64-apple-ios16.0`, SDK and rootless `ldid`, plus safety and regressions).
- [Private integrated rootless QA144 build](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41180378546) run `41180378546`, job `124476375294`: **ALL NINE RUN STEPS PASS** including source/regressions, Theos 3 unchanged modules, new iOS16 native host, signed rootless merged DEB, stage upload, archive push and readback.
- Exact source SHA built **`10bc5b4e3a124b0ff849caa8a579620f6da887d0`**; later handoff/audit commits do not alter binary.
- Exact merged candidate **`com.duoface.jb.embedded_0.0.144~standalone-probe1_iphoneos-arm64.deb`**, version `0.0.144~standalone-probe1`, size **1,161,512 bytes**, SHA256 **`34f1fbe357ebb8dffc4599d001308be4a804f97a83a8944119ef37088ab89c39`**.
- Binary and SHA archive: `sideplay/jb-embedded-appbridge/evidence/runs/41180378546/`; contents: `com.duoface.jb.embedded_0.0.144~standalone-probe1_iphoneos-arm64.deb`, `SHA256SUMS.txt`, `PACKAGING_PROVENANCE.json`, `CI_RESULT.txt`. Actual GitHub archive commit **`3cef17ab44f684ec0eba911b4131bd2717a94a24`**, fetched and read back SHA/version/provenance. Expected packaging `SILEO_PUBLISHED=false`, `DEVICE_DIRECT_HOME_TESTED=false`, `STANDALONE_OWNER_FOREGROUND_VERIFIED=false`.
- Publisher `chuongnguyen89dn-ui/carplaydsp` **NOT CHANGED**. QA143 remains the publicly indexed Sileo version, does not acquire this fix. QA142 rollback historical binary untouched. Do **not** claim QA144 available in Sileo.

## Source implementation and negative routing assurance
- Source `sideplay/duoface-native-scene-host/DFHomeStandalone144.m` compiles into CarPlay-only and SpringBoard-only modules, via exact `DF144_CARPLAY`/`DF144_SPRINGBOARD` build macros. Native iOS16 Dashboard Home button callback `v32@0:8@16@24` is the actual physical Log21 contract, selected allowed only and native system Dock + content area must be matched; otherwise exact original forwarded.
- For selected app, **does not substitute `com.duoface.native.scenehost` icon**, does not request `DFNative12Chrome`/split/app picker/slot0. One-shot atomic intent and Darwin notification gives separate first-party `DF144Solo` SpringBoard one-app owner a chance to attach `DFSceneHost` in a single CarPlay content-only external window. Fresh 2-second UUID intent and app allowlist required; explicit separate opt-in `com.duoface.nativehost.standalone144-optin.plist` (Version 1, StandaloneHomeDirect true), default **OFF**. Native + SpringBoard owners have original first Home-return watcher and physical disconnect teardown. One hosted app pending/ready/fail and verified SB PID, but ACK deliberately **`scene-hosted-render-and-touch-unverified`**.
- QA143 wrong icon redirection and `DFHome143ConsumeRequest(sChrome,sSession)` **removed from new runtime build**. Original independent DuoFace 1–4 split Chrome, GOFA resize .141, YouTube relay, native Apple Dock controls and native Maps remain compiled. Preserves old behavior for actual DuoFace icon.
- First-party release tests `tests/test_qa144_no_split_home_redirect.py` and `sideplay/jb-embedded-appbridge/tests/test_integrated_package_144.py` PASS in CI, existing QA141 map geometry, QA132 BKS, native owner, C GOFA and Objective-C Home pass-through baseline PASS.

## What is NOT proven / why Sileo is deliberately blocked
1. A source-compiled `UIRootSceneWindow` in SpringBoard may **not** be display-owned / foreground above native CarPlay Home when DuoFace CPTemplate isn't active. Actual iPhone X iOS16.7.16 proof of standalone viewport required. DO NOT infer original vendor's bridge acquisition from same method names.
2. Native CarPlay `DBStatusBarWindow` and `DBNotificationWindow` may not be simultaneously visible/unique at exact external app tap; if absent callback forwards Apple. Original `viewDidAppear:` stop ABI is guarded, runtime presence unverified.
3. Scene ready + PID does NOT prove user can touch Play or that GOFA is correct; exact native layer/input and GOFA needs real visual+touch evidence.
4. Feature is intentionally **not activated by default**, no on-phone user toggle yet; installing current private build without further instrumentation would not establish feature success. An explicit controlled test release/enablement is a *separate future gate*, not a green-light to promote blindly.
5. No explicit active background task; GitHub Actions run is completed/success and file bytes persisted. No live device is attached to this ChatGPT tool.

**Decision:** preserve user requirement: avoid repeated unverified Sileo updates. Implemented the separate source and signed **unpublished** artifact; next evaluate how to obtain actual scene-owner/display acceptance evidence without shipping an unproven public build. Then create one explicit bounded opt-in/on-phone test, with Home/Back, selected apps, GOFA, YouTube Play and Dock acceptance, only when user can validate safely on parked CarPlay. Avoid vendor code/license and global entitlement swizzles.

## Reproducibility
- Native `bash sideplay/duoface-native-scene-host/build.sh` in repo root expects Apple macOS iOS16 SDK, ldid, dpkg-deb, original own assets.
- Build three original Theos module packages exactly as `.github/workflows/duoface-144-integrated-private-staging.yml`.
- From exact source SHA `10bc5b4e...`, run `python3 sideplay/jb-embedded-appbridge/package_integrated.py --build --expected-nativehost-sha256 <SHA from signed current native module> --expected-source-sha 10bc5b4e3a124b0ff849caa8a579620f6da887d0`; do NOT paste secrets, and do not treat changes to HEAD as same binary.
- For actual evidence, use `/var/mobile/Library/Logs/DuoFaceStandalone144.log`, `...DuoFaceSceneHost.log` (diagnostic path exists in source, no physical logs yet).
