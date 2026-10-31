# QA155 — Private integrated app-side state relay, hardware acceptance pending

**Date:** 2026-11-01. **Repo:** `chuongnguyen89dn-ui/Duoface`. **Branch:** `feature/duoface-qa146-native-home-exit-20261031`.

## Problem grounded in QA154
QA154 run `41216554297` signed a private merged DEB but its `DF154GeneralAppStateRelay.m` consumer was syntax-only compiled, absent from `build.sh`, absent from the package. Publishing a host-side owner state without an app-side consumer cannot restore a target app's UIKit window. That was a packaging gap, not proof of the user's device latency/Home/Dock root cause.

## QA155 code gate
- App-side receiver `DF154GeneralAppStateRelay.m` now compiled into signed `DF155GeneralAppStateRelay.dylib`, with fixed `DF155GeneralAppStateRelay.plist` bundle filter limited to `com.apple.mobilesafari` (Safari) and `org.videolan.vlc-ios` (VLC). **Pilot only**, NOT general unlimited bridge, and not guaranteed present on user's device.
- Runtime must also pass existing user `EnabledBundleIDs` policy; missing/invalid preferences mean no application. The listener handles disable/owner-stop/replacement/3s lease timeout; only matched real UIKit scene ID permits mutation and original window frame/bounds are restored.
- No injection into YouTube `com.google.ios.youtube`, GOFA `com.lumi.GOFA`, SpringBoard, Dashboard or CarPlay Dock from this relay. Their existing modules remain intact. Frozen `DFSceneHost.m` SHA blob `ec2924c145be4edaaa27b7320bb869b18de12c6b`.
- `package_integrated.py` validates merged `.dylib` and exact `.plist` before finishing; GitHub Actions validates signed dylib, extracted filter and marker after extracting the actual merged DEB. **A green source test alone is insufficient.**
- Known remaining risk: the iOS 16 device must confirm `NSDistributedNotificationCenter` availability and the true FrontBoard/UIKit scene-ID match; missing transport is logged `[DF154AppState] ... transport-unavailable` and all UIKit changes are refused. The runtime allowlist could be unreadable inside a target sandbox; this also fails closed. No evidence yet that this pilot fixes arbitrary apps or that Safari/VLC are the desired selections.

## Exact source evidence & runs
- Source integration `dc12b0cc833e2a28bc0bf2f09c030e2a74a928c3`.
- Test NUL separator fix `1de989b1b137d978c495cc53fbee6ae97e5f7a8e`.
- Historical failed fast run `41235235213` (one Git blob hash assertion bug), corrected fast run `41235255967` **SUCCESS**.
- MacOS iOS16 rootless signed integrated private build `41235256020`, job `124637582484`: initially in progress, must recheck latest status. Its archive saver writes to `sideplay/jb-embedded-appbridge/evidence/runs/<run-id>/` and never to `Gpt-training-` or Sileo.
- No release/deployment/Sileo action or physical test conducted.

## Acceptance gate for one iPhone X CarPlay session
1. On parked vehicle verify installed QA155 private candidate's **exact SHA256**, `com.duoface.jb.embedded`, rootless iOS 16, valid installed `DF155GeneralAppStateRelay.dylib` plus Bundle filter. Verify user's enabled-app preferences explicitly admit whichever pilot app is being tested. Avoid overwriting functioning release.
2. For **one** authorized app target (Safari or VLC), collect same time window of SpringBoard `qa153-verified-phone-target-eviction`, `qa149-manager-live-scene-owned`, `qa154-general-app-restore`; app logs `[DF154AppState] bundle=... registered`, `adjusted=...`, `restore=...`, or `transport-unavailable`. A missing app-side log must not be called success.
3. Test home-selected app opens to correct CarPlay landscape UI, full touch surface after 30+ seconds, system **Home button returns to previous app-grid context**, native Dock shows current running app, other CarPlay-native apps still launch and native Dock untouched.
4. Lock iPhone screen; verify CarPlay remains usable/visible with no dark backlight regression, rotate/split/zoom without GOFA crop or YouTube misrotation/crash. Test reconnect and selection memory, then exit and confirm restored app scene bounds. Save device timestamps and exact RequestID/scene IDs if logged.
5. If any failure, preserve single same-request system/app logs, diagnose only first missing real call graph hop compared against original DuoNavi 1.0.4 static audit and rejected Log23 `c327274898d8d7285259d4bdbfc04b623a81e3cb6263ccda7ccf948d9cca267d`. Roll back to previous known good private package; no speculative second install.

**Device status:** untested; car and iPhone are not controlled by this GitHub connector. **Official release:** blocked. **Firmware/package prior provenance:** QA154 archive `41216554297`, `4bee21d0bd3976be01dac799b6a61ebb3b3f76d143f327ff2811f43d74d45c46` kept unchanged.
