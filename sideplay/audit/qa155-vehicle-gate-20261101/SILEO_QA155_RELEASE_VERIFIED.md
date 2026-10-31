# QA155 Sileo beta distribution verified — NOT device-tested

**2026-11-01. This is an isolated testing channel, not an official DuoFace release.**

## Exact signed source
- Repository: `chuongnguyen89dn-ui/Duoface`, branch `feature/duoface-qa146-native-home-exit-20261031`.
- GitHub Actions signed private integrated build [41236376760](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41236376760), job `124640928821`, completed SUCCESS; immutable source `6e4dba0a03b20d787ed70760b7b1d5bbbcbc71ee`.
- DEB path `sideplay/jb-embedded-appbridge/evidence/runs/41236376760/com.duoface.jb.embedded_0.0.155~appack1_iphoneos-arm64.deb`; package `com.duoface.jb.embedded`, version `0.0.155~appack1`, `iphoneos-arm64`, **1,187,556 bytes**, Git blob `4debf916fdc8a8c81cfead1a9f379f0dfc828639`; SHA256 `24143b1893f464a1d56b57bf60956bc4503bcafe57f8d8e4675bd64bbda3ff74`.
- `CI_RESULT.txt`, `SHA256SUMS.txt`, and `PACKAGING_PROVENANCE.json` in the same folder: signed & packaged app receiver with exact Safari/VLC filter. Device acceptance remains false.

## Isolated Sileo source
- Publisher `chuongnguyen89dn-ui/carplaydsp` workflow [41236703248](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/41236703248), source commit [810890a0f0961ecd279c3cb53d4a7e7eb0290668](https://github.com/chuongnguyen89dn-ui/carplaydsp/commit/810890a0f0961ecd279c3cb53d4a7e7eb0290668). `build` and `deploy` completed SUCCESS.
- **QA ONLY Sileo source:** `https://chuongnguyen89dn-ui.github.io/carplaydsp/qa155/`
- **Live QA binary:** `https://chuongnguyen89dn-ui.github.io/carplaydsp/qa155/debs/com.duoface.jb.embedded_0.0.155~appack1_iphoneos-arm64.deb`
- **Live proof:** verification job `verify-qa155-pages`, ID `124642631741` completed SUCCESS, verified online `Packages` one exact package/version, `Release` SHA256 index, downloaded **actual Pages binary**, SHA256 check `/home/runner/work/_temp/qa155-public.deb: OK`, and `dpkg-deb -f Version`. Log marker: `QA155_ISOLATED_SILEO_LIVE_SHA_VERIFIED_NO_DEVICE_CARPLAY_PROOF`. Workflow YAML validator [41236703239](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/41236703239) SUCCESS.
- Publisher wrote new QA pages **only** under `repo/qa155/` and asserted no `Version: 0.0.155~appack1` in main `repo/Packages`. Independent `verify-duoface-integrated-pages` job succeeded; normal repository stayed at prior package. Public main QA147 and its version not changed by this stage. Do not call this official release.

## Physical go / no-go
The signed DEB and LIVE APT validation **do not establish installation or real CarPlay success**. Only actual device iPhone X 16.7.16, jailbreak rootless, in a **parked** car can provide the required result. Sileo: add beta URL above; choose exactly `DuoFace Independent (Integrated CarPlay Beta)` version `0.0.155~appack1`; review conflicts/respring and preserve rollback. Enable VLC bundle `org.videolan.vlc-ios` in DuoFace enabled apps and standalone Home opt-in. Do not use Filza. Perform one test described in `VEHICLE_QA.md` and manually export `Xuất log / lỗi CarPlay`; `DuoFaceStandalone144.log` must show same-RequestID `qa155-app-side-ack` phase(s), including scene match or explicit unmatched. Verify native Home/active Dock, orientation, top/middle/bottom touch after 30 seconds, screen lock, GOFA+YouTube, reconnect. **Device test has not been performed by assistant.** If failure, capture one complete log before any further build.

**Latest source handoff:** `sideplay/tiep tuc du an.md`.
