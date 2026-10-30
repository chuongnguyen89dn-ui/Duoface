# QA130 — public Sileo release verified by live GitHub Pages runner

## Requested action and final state
User agreed: "Làm đi" to publish the already-signed QA130 for physical test. On independent verification this turn, publisher **was already committed and fully deployed by a concurrent project session**. To avoid redundant deploy, verified its exact state instead of launching a duplicate. No change to software/copyright/license or phone display brightness.

- DuoFace signed rootless package ID: `com.duoface.jb.embedded`, version `0.0.130~sceneowner1`
- Signed file: `com.duoface.jb.embedded_0.0.130~sceneowner1_iphoneos-arm64.deb`
- Immutable source repository archival path: `sideplay/jb-embedded-appbridge/evidence/runs/41052662293/`; signed source commit `0ba4f0c01ff7db7dfc20b55df059348b5cd85ca9`, signed CI [41052662293](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41052662293) SUCCESS
- Size: **1,125,864 bytes**, SHA256: `d0573ac14e402dfca450e4b01fd57f898ed03852b354361b0a8acf54a432e24b`
- Publisher repository: `chuongnguyen89dn-ui/carplaydsp`, main source commit [992572f38b424645d1eba938bffef5dc5e77d2d7](https://github.com/chuongnguyen89dn-ui/carplaydsp/commit/992572f38b424645d1eba938bffef5dc5e77d2d7), message: `publish: add immutable QA130 scene-owner signed DEB, select one Sileo APT record, retain QA129/QA128 rollback`; latest main HEAD at verification `24ab62cfe54662d0df1c08696dc6cb446ca447be` (different additional docs commit).
- Publisher workflow: `.github/workflows/build.yml`; [run 41053438550](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/41053438550) **SUCCESS**. Jobs **124054914824** (build), deployment **124056001404**, **124056200033** observer verify, **124056200088** QA130 public verify, **124056200102** QA11 parity all SUCCESS. `github-pages` artifact 12976440628.
- Actual public proof in **job 124056200088 logs**: runner read `https://chuongnguyen89dn-ui.github.io/carplaydsp/Packages`; verified exactly one APT entry `com.duoface.jb.embedded`, `Version: 0.0.130~sceneowner1`, expected Filename, SHA, arch and Name; logged **`DUOFACE_ONE_PACKAGE_PUBLIC_SILEO_INDEX_VERIFIED`** at 2026-10-30T12:14:16Z. It then downloaded the **actual public** file from Pages, checked SHA256 and printed:
```
/home/runner/work/_temp/duoface-public.deb: OK
DUOFACE_PUBLIC_SILEO_DEB_DOWNLOAD_AND_CHECKSUM_VERIFIED
```
All five publisher jobs concluded SUCCESS.
- Publisher build job 124054914824 validated source SHA of signed QA127/128/129/130, each source version/Info.plist and found **one selected QA130 APT record**. Older QA128 and QA129 exact files still downloaded and carried by repo as rollback resources; index does not present multiple competing selected versions. QA92 public rollback SHA additionally verified by public job.
- Public Sileo source: `https://chuongnguyen89dn-ui.github.io/carplaydsp/`
- Public direct DEB, externally verified: `https://chuongnguyen89dn-ui.github.io/carplaydsp/debs/com.duoface.jb.embedded_0.0.130~sceneowner1_iphoneos-arm64.deb`

## What is NOT a proven result
- Public successful publication does NOT prove installed phone package, loaded dylib UUID or any in-car behavior. The actual signed package's `CI_RESULT.txt` explicitly records `DEVICE_QA=false` and `REAL_PLAY_NOT_VERIFIED=true`.
- **No remote access to user's iPhone was available**. Cannot automatically refresh Sileo on the device, install or respring.
- The real system CarPlay Home **third-party selected app icon bridge is STILL ABSENT**; QA130 only corrects two source-level per-scene lifecycle/owner issues. GOFA layout regression, YouTube remote Play/touch while locked and Zoom crashes require device tests and logs before “fixed” is claimed.
- No mode of keeping iPhone screen dim or awake was implemented in this QA.

## Physical device next action (parked, controlled, QA130 selected)
1. iPhone X jailbreak rootless: open Sileo → Sources → refresh `https://chuongnguyen89dn-ui.github.io/carplaydsp/`, open **DuoFace Independent (Integrated CarPlay Beta)**, verify **0.0.130~sceneowner1**, Upgrade. Perform **Respring manually** so SpringBoard & CarPlay dylibs reload. This package itself does **not** run auto-respring.
2. Connect to parked CarPlay, verify two apps in panes, Apple Dock, YouTube QA90 rotation, QA92 drag, GOFA layout. With YouTube open, test one scroll and one Play with phone awake and one with phone locked; perform Zoom once while parked, Home and reconnect. Distinguish failure if another hook/OmniCar is installed; do not assume the device is equivalent to the QA device.
3. Export **QA130 same-session** DuoFace logs + SpringBoard IPS to `Duoface/main:sideplay/log/`. Verify running `DFTouchOwnerProbe.dylib` UUID **`3343768B-ED53-30B7-815B-56A0DF9D6CBB`** if obtainable (not mandatory for the user's simple try). On failure, report exact symptom/button/time, compare stale owner/scene-destroy trace in same session. Do not relabel the older Audit13 QA90 as QA130.
4. If severe regression, exact QA129/QA128 immutable DEBs remain archived for rollback; no Filza/manual DEB installation recommended.

## Durable evidence
- Existing `sideplay/audit/qa130-scene-destroy-owner-20261030/REPORT.md` and code/tests/workflows on project branch.
- Independent GitHub Actions publisher logs and exact QA130 published checksum as above.
- This file is saved in DuoFace project repository, not the central skill repository and not the publisher's handoff.
