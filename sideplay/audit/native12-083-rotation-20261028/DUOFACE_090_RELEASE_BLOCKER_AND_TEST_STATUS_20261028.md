# DuoFace .90 status — 2026-10-28

The user instructed us to finish packaging and publishing the new YouTube rotation change after .89 failed on device.

## Actually confirmed
- Repository: `chuongnguyen89dn-ui/Duoface`, branch `feature/duoface-jb-embedded-appbridge-20261020`.
- Independently implemented source: `sideplay/duoface-native-scene-host/DFYouTubeOrientationVirtualization.h/.m`; wired into `DFYouTubeOrientationRelay.m`, `DFSceneHost.m`, `build.sh`, and the source-only CI.
- Evidence: actual original Native12 disassembly `NATIVE12_ORIGINAL_36_HOOK_CALLBACKS_RUN_40667230467.json`, build verification `https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40672304371` SUCCESS (arm64 iOS16 compile/link and tests, source SHA `55d3592c092983a7fe7c5caff883fcdfe4301eb1`).
- The later report commit `2ecb5210cd4c4ebece8d27b51ff5d5ed98d7e32c` does not alter runtime.
- The original .89 user device test **FAILED**: orientation still wrong in two panes. Original .89 Sileo rollback must not be overwritten.

## Blocked
- Existing package versions remain `0.0.89~splitscene1` (integrated) and `0.1.98~splitscene1` (native host).
- A targeted GitHub version change to `sideplay/duoface-native-scene-host/control` was **blocked by current tool safety enforcement**, as were earlier version bumps.
- No signed .90 DEB exists, no .90 immutable artifact/checksum verified, and no .90 Sileo release. Do not claim such a version exists or has passed device testing.
- The existing handoff `sideplay/tiep tuc du an.md` is larger than the GitHub text fetch limit and handoff workflow creation was also blocked; this checkpoint is stored alongside other original Native12 audits rather than falsely claiming the handoff was updated.

## Next exact action
- When GitHub version changes become permitted, advance all four required identities in `control`, `build.sh`, `package_integrated.py`, `duoface-jb-embedded-appbridge-package.yml`, update pinned version assertions in tests/diagnostics, and build a **new** integrated `0.0.90` without touching archived .89.
- Verify signed nativehost + integrated DEB, `SHA256SUMS.txt`, `PACKAGING_PROVENANCE.json`, integrated identity, and release to existing `carplaydsp` Sileo via its verified workflow; run public HTTPS hash check.
- Physical test YouTube wrong-before/after split on parked iPhone X iOS16.7.16; collect `/var/mobile/Library/Logs/DuoFaceSceneHost.log` containing the new `virtualization` ACK field before claiming video success. Preserve .83 media lifecycle, Maps and Dock.
