# DuoFace .106 Sileo release — signed one-DEB staging and publisher request

Date 2026-10-29 Asia/Ho_Chi_Minh. User explicitly requested **"Phát hành sileo"**. Project implementation in `chuongnguyen89dn-ui/Duoface`, branch `feature/duoface-jb-embedded-appbridge-20261020`. Publisher is **existing** `chuongnguyen89dn-ui/carplaydsp`, main, serving Sileo repository `https://chuongnguyen89dn-ui.github.io/carplaydsp/`. No other project is modified.

## Signed immutable integrated package verified in GitHub

- Dedicated new workflow `.github/workflows/duoface-106-integrated-sileo-stage.yml`, source checkout SHA **`98d793faf6867cb23fea6714c3d434325cb17663`**, [signed build run 40809319208](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40809319208) **SUCCESS**.
- Built three original DuoFace independent Theos modules, current NativeHost 0.1.106 rootless, merged via `sideplay/jb-embedded-appbridge/package_integrated.py` to exactly ONE installable package **`com.duoface.jb.embedded`**, version **`0.0.106~duodash-disc10s1`**, architecture **`iphoneos-arm64`**. Verified mandatory app executable, signed SpringBoard/CarPlay/YouTube/Maps dylib files, YouTube-only and native Map CarPlay-only plist filters, iOS Speech privacy keys, no vendor CarBridge dependencies, exact control and source provenance.
- Package exact **SHA256 `3ce04db501b6f657bb3dac4eb62610787008aab741112af7929b16b6cec8aa48`**, frozen file `sideplay/jb-embedded-appbridge/evidence/runs/40809319208/com.duoface.jb.embedded_0.0.106~duodash-disc10s1_iphoneos-arm64.deb`, plus adjacent `SHA256SUMS.txt`, `BUILD_SOURCE.txt`, `CI_RESULT.txt`, `PACKAGING_PROVENANCE.json`.
- Actual archive push verified: GitHub commit **`98061a8fea8888a1efc9dafecdd96289c279d310`**. Package is **persistently in the correct GitHub repo**, not solely a temporary Actions artifact.
- Temporary QA artifact ID **12869931387**. This artifact is NOT the public Sileo source.

## Authorized Sileo publisher change

- Modified ONLY established publisher workflow `.github/workflows/build.yml` in `chuongnguyen89dn-ui/carplaydsp` main, commit **`4fe98c37e5ec06a927cd1006981fb30abab892fd`**.
- Adds pinned raw GitHub archive source URL at commit `98061a8...`, checks exact package ID, version, rootless architecture, SHA and expected first-party binary/filters; retains all previous .94/.92/.90 public archives unchanged; raises prior 63-DEB archive count to 64; filters Sileo's APT `Packages` to advertise **exactly ONE latest `com.duoface.jb.embedded` .106**, and verifies public `Packages`, `Release`, remote new binary SHA, old rollback SHA.
- Publisher workflow run [40809650669](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/40809650669) and actionlint [40809650653](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/40809650653) were **IN PROGRESS when this audit entry was written**. Do NOT claim live Sileo publication before their build/deploy/verify jobs succeed and remote page is checked.
- Expected public URL **only after successful remote SHA verification**: `https://chuongnguyen89dn-ui.github.io/carplaydsp/debs/com.duoface.jb.embedded_0.0.106~duodash-disc10s1_iphoneos-arm64.deb`.

## Scope/risks and next step

- .106 carries distinct phone switch **Ứng dụng → Đóng app khi ngắt CarPlay**, default OFF, user-approved **10 seconds**, generation-cancelled on real reconnect, PID/provenance/foreground gating. RunningBoard invocation is private API, so system process exit and YouTube audio stop still require phone/CarPlay hardware log verification. Other new maps native/voice/language features also lack full device acceptance. Does not clone original DuoDash license or binary.
- Publishing only places the signed rootless QA beta in existing Sileo. **No remote installation, no phone, no respring, no Filza.** Retain .90 user-confirmed orientation rollback bytes and .92 three-second logo rollback.
- Next: wait for actual publisher action and actionlint conclusion (no background claims), fix exact failure if required. After publisher success, verify live `Packages` contains only .106 with exact hash/filename and the direct DEB downloads with matching SHA. Append final **verified publication**, publisher job IDs and checked times to this report and existing `sideplay/tiep tuc du an.md`. If no success, say explicitly **Chưa phát hành**.
