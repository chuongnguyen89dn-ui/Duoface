# 2026-10-23 (Asia/Ho_Chi_Minh): Requested DuoFace signed .38 DEB and Sileo delivery — VERIFIED

## Source and unchanged baseline
- Project: `chuongnguyen89dn-ui/Duoface`; active branch `feature/duoface-jb-embedded-appbridge-20261020`.
- Historical exact baseline (NOT copied into new build): `dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb`, SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad` from commit `1286a3e`.
- User wants an actual DEB test published via existing Sileo source; no fake "all finished" claim. Speed8 HUD in independent host remains unlinked.

## Why manual Run workflow missing and how it was fixed
- Default `main` of DuoFace had NO `.github/workflows/duoface-jb-embedded-appbridge-package.yml`. The workflow existed on feature branch only, so iPhone GitHub UI did not present manual Run workflow.
- GitHub connector supports GitHub file push/write but not workflow_dispatch. Fixed without user action: commit `f750117e12fab862ed6698c441ada8dabfd25fba` added scoped `push` trigger only for `sideplay/jb-embedded-appbridge/build-request/REQUEST.md` on active feature branch, retaining manual trigger and avoiding automatic build for normal source changes.
- Explicit approved request file created at commit `ee6df7f2f7e05eac798b319ad6cb80a38b14f2b4`; source SHA of build identical.
- Reproduction trigger: modify that dedicated REQUEST.md on the named branch, DO NOT rerun stale workflow commit SHA. GitHub Actions on macos-15 runs `bash sideplay/duoface-native-scene-host/build.sh` after Theos/ldid/dpkg and uses `python3 sideplay/jb-embedded-appbridge/package_integrated.py --build --expected-nativehost-sha256 "$NATIVEHOST_SHA" --expected-source-sha "$GITHUB_SHA"` to package one rootless signed DEB.

## Build: full package, not source CI
- DuoFace Actions [run 39871335334](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39871335334), job `120146231356`: **COMPLETED SUCCESS**. Unit tests, Theos builds, NativeHost 0.1.49 sign, integration, dpkg package checks, artifact upload, immutable Git archive all completed successfully.
- Exact package `com.duoface.jb.embedded_0.0.38~native12sourcehost49_iphoneos-arm64.deb`; Package `com.duoface.jb.embedded`; Architecture `iphoneos-arm64`; **961,784 bytes**; **SHA256 `2055200d75d48495d0e4d55abd0b8caabb976498e19442e2fb5ab8c76eed5e7e`**.
- Durable archive under DuoFace commit `125b8146fd6c6c5f5f3dda3ba9f8f694ff999757`: `sideplay/jb-embedded-appbridge/evidence/runs/39871335334/` contains DEB + `SHA256SUMS.txt`, `BUILD_SOURCE.txt`, `CI_RESULT.txt`, `PACKAGING_PROVENANCE.json`.
- NativeHost source build SHA256: `359f896ab6ce9b5ed88388c21d772b0f7054b68915211b1d77b0f2bc9b686b7d`. The package is own independently built code, not original third-party vendor payload.

## Sileo published and verified (not just drafted)
- Existing Sileo repository: `chuongnguyen89dn-ui/carplaydsp`, main, workflow `.github/workflows/build.yml`. Updated only `com.duoface.jb.embedded` pinned .37 reference to above immutable .38/sha at distribution commit [`1d6a0c81becacf460ecfcc47df382e80e43ebc57`](https://github.com/chuongnguyen89dn-ui/carplaydsp/commit/1d6a0c81becacf460ecfcc47df382e80e43ebc57); preserved separate HUD8 `com.duoface.independent` and other package identities and their pinned contents.
- Sileo YAML validation run [39871787540](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/39871787540): **SUCCESS**.
- APT Build/Pages Deploy/public downloaded verification run [39871787459](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/39871787459): **COMPLETED SUCCESS**; build job `120147692470`, deploy `120148572058`, `verify-duoface-integrated-pages` job `120148646673` all **SUCCESS**. The last job actually downloaded public `Packages` and `.deb` and tested package/version/filename/public SHA256. Verified log prints `DUOFACE_ONE_PACKAGE_PUBLIC_SILEO_INDEX_VERIFIED` and `DUOFACE_PUBLIC_SILEO_DEB_DOWNLOAD_AND_CHECKSUM_VERIFIED`; earlier frozen .23–.30 direct DEBs also verified unchanged.
- Live APT source (already existing): `https://chuongnguyen89dn-ui.github.io/carplaydsp/`.
- Live exact DEB: `https://chuongnguyen89dn-ui.github.io/carplaydsp/debs/com.duoface.jb.embedded_0.0.38~native12sourcehost49_iphoneos-arm64.deb`.
- Package will appear as `DuoFace Independent (Integrated CarPlay Beta)`, version `0.0.38~native12sourcehost49`; refresh Sileo Sources first.

## Limitations and next acceptance
- CI/published DEB does NOT prove device compatibility or exact original Native12 Speed8: independent Speed8 HUD view still not linked, CarPlay scene admission, two real apps, YouTube orientation, Zoom native Dock, menu Style/Close, three-second logo move, 4-second hide and ExitSafeMode must be tested physically.
- `PACKAGING_PROVENANCE.json` warns `requires_replacing_old_qa_packages=true`: DO NOT simultaneously install conflicting old experimental DuoFace bridge/host QA packages. Archive/rollback versions are retained in Git history and some public direct package links. Avoid testing while driving.
- Next: user refreshes Sileo, installs/updates `com.duoface.jb.embedded` on a stationary CarPlay test setup, reports installed version and UI/CarPlay audit log. On failure, verify exact device logs before patching; preserve working older DEB, never invent UI or vendor license.
