# DuoFace 0.0.28 — media scene stability patch and release verification

Date: 2026-10-22 (Asia/Ho_Chi_Minh). Status: released on public Sileo, **not a device playback PASS**.

## Source and behavior

Repo: `chuongnguyen89dn-ui/Duoface`, branch `feature/duoface-jb-embedded-appbridge-20261020`.

Changed `sideplay/duoface-native-scene-host/DFSceneHost.m`, committed `60624bfbf8b305e70b7dfa9fb159e17e90cbe53f` and corrected startup seed in `cdd454fff3ef9bd752cc05ca5fa145126d4fc681`.

- Preserve initial `setContentReferenceSize` *once* before `setRequestedMode:2` (avoid startup host regression).
- During split drag or Zoom, update local UIKit viewport/transform immediately. When scene is hosted and ready, only perform private reference-size update after 0.30s of stable viewport, not on every finger move; cancel timer on close.
- Retain scene/pane ownership, full 1/2/3/4 slot and existing Style 0..8, no vendor license or binary.
- Passive sampled `hitTest` routing evidence and geometry logs in `/var/mobile/Library/Logs/DuoFaceSceneHost.log`. Does not synthesize remote app touches.
- DOES NOT repair video landscape/orientation negotiation, audio focus, or definitively fix ExitSafeMode. 25 original Native12 gates not yet proven.

## Immutable CI/build and artifacts

- NativeHost `0.1.34~mediaseed1`: Actions `39713090970` SUCCESS, signed SHA256 `a75360b9521b5790ad0d1898146b27862f8dc8d04a876cee4beffce6be8c1114`, archived in `sideplay/duoface-native-scene-host/packages/com.duoface.carplay.nativescenehost_0.1.34~mediaseed1_iphoneos-arm64.deb`, artifact commit `40b6f9791861d4c5bebd5477d3e48b6f985832ce`. Source method crosswalk `sideplay/duoface-native-scene-host/packages/NATIVE12_1385_REPORT/SUMMARY.json`: original 43 files/8 Mach-O/1385 ObjC methods vs isolated host 22 files/2 Mach-O, 0 of 25 full parity gates proven.
- Integrated package `com.duoface.jb.embedded_0.0.28~mediascene1_iphoneos-arm64.deb`: workflow `39713315901` SUCCESS, artifact commit `375329702b1b899cd59f830e2d65b6c368a8d0eb`, path `sideplay/jb-embedded-appbridge/evidence/runs/39713315901/`, signed SHA256 `8f2088931a004ee8bfae8ef5b2f254a5f1b9cdf05dcb1020973f910fd384cc2a`. Provenance includes 4 first-party input packages, 28 files; `real_two_app_scene_tested=false`.

## Public Sileo release

Publisher repo: `chuongnguyen89dn-ui/carplaydsp`, `.github/workflows/build.yml` source commit `609e01d77f7d00c1f7b30dd97b3558c2168baebd`; publisher run `39713575175` all jobs SUCCESS, YAML validator `39713575123` SUCCESS.

Public index: https://chuongnguyen89dn-ui.github.io/carplaydsp/
Exact binary: https://chuongnguyen89dn-ui.github.io/carplaydsp/debs/com.duoface.jb.embedded_0.0.28~mediascene1_iphoneos-arm64.deb

Public verifier job `119611060757` (2026-10-22T02:53:09Z) downloaded the actual Pages DEB and checked SHA256; recorded `DUOFACE_ONE_PACKAGE_PUBLIC_SILEO_INDEX_VERIFIED` and `DUOFACE_PUBLIC_SILEO_DEB_DOWNLOAD_AND_CHECKSUM_VERIFIED`. Also verified direct Pages backups 0.0.23, 0.0.24, 0.0.25, 0.0.26, 0.0.27 were individually unchanged.

## Reproduction and next action

Source tests (workflow macOS runner): `python3 -m unittest discover -s sideplay/duoface-native-scene-host/tests -p 'test_*.py' -v`; build `bash sideplay/duoface-native-scene-host/build.sh`; strict original Native12 compare via `sideplay/duoface-native-scene-host/tests/compare_source_debs.py` and `sideplay/audit/native12-vs-new-20261021/compare_native12_new_full.py`. Packaging: `python3 sideplay/jb-embedded-appbridge/package_integrated.py --build`. See workflows for exact CI parameters, SHA pin and Mac SDK.

Need iPhone X rootless iOS16 device evidence (car stopped), YouTube or other video in a split pane, second mapping pane, play/pause/seek/touch, drag split while video runs, Zoom/focus/restore, Style 1 ô, Home/disconnect/reconnect and audio continuation. Record app versions, screenshot, `DuoFaceSceneHost.log`, `DuoFaceTouchOwner.log`, SpringBoard .ips on safe mode. Next change requires observed media orientation/callback ownership before selecting landscape or audio APIs. Do not claim definitive playback integration without device PASS.
