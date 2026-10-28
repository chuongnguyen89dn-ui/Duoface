## PHYSICAL DEVICE UPDATE — USER-CONFIRMED YOUTUBE ROTATION PASS (2026-10-28)

- **User explicitly confirms the installed DuoFace .90 now rotates YouTube video in the correct direction.** This supersedes the earlier 'not physically tested / outcome unknown' status for the **YouTube orientation behavior**. Evidence is the user's direct report, not a GitHub Actions test or an independently inspected on-device log. No screenshots or newly exported .90 telemetry were supplied in this turn.
- Known working version: integrated signed Sileo `0.0.90~nativegetters1`; SHA256 `c9a6c8f624ce3224ec5cdc7aee9c3280306068c99c9842d4b4f802914c560f27`; source commit `53781cca1ca9285975394754ac9080ca35b57cda`; signed build run `40674445027`; public Sileo run `40674909879`.
- **Why earlier iterations failed / consumed time:** .87–.89 focused on host->app notifications, a one-shot UIWindow rotation/frame reflow and bounded public geometry refresh. Original Native12 app-process ARM64 was not traced at callback-body level early enough. The successful .90 adds YouTube-process-local ABI-checked hooks of orientation getters and future UIKit UIWindow rotations, activated only for the owned live scene, in addition to the existing .89 bridge. These are the actual differences and a plausible causal mechanism; the precise winning callback remains **unisolated** without runtime hook traces/ablation tests.
- **Regression gates remain unconfirmed:** extended YouTube playback and seeking, safe-mode/crash stability, switching SOLO->split repeatedly, Maps and real Apple Dock behavior across sessions. Do not equate single-feature user PASS with full DuoFace parity. Do not casually revise the functioning orientation implementation; treat .90 as known-good rotation baseline and preserve immutable .90/.89/.83 rollback artifacts.
- **Next:** only if the user requests, collect targeted device telemetry for actual hook count/lease and remaining regressions, then fix a specific reproduced issue without changing the orientation path.

---
# DuoFace .90 — Signed QA / Sileo public verified — 2026-10-28

## Verified release
- User requested retry; blocked version update retried successfully.
- Source repo chuongnguyen89dn-ui/Duoface branch feature/duoface-jb-embedded-appbridge-20261020.
- Source commit 53781cca1ca9285975394754ac9080ca35b57cda.
- Original Native12 DEB SHA256 2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad; genuine original 36 ARM64 callback forensic archive NATIVE12_ORIGINAL_36_HOOK_CALLBACKS_RUN_40667230467.json. New code is independent.
- Integrated package com.duoface.jb.embedded_0.0.90~nativegetters1_iphoneos-arm64.deb, SHA256 c9a6c8f624ce3224ec5cdc7aee9c3280306068c99c9842d4b4f802914c560f27, file size 1007564 bytes. Native host version 0.1.99~nativegetters1.
- Build run https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40674445027 SUCCESS. SHA256SUMS, CI_RESULT, BUILD_SOURCE, PACKAGING_PROVENANCE read back.
- Immutable source archive GitHub commit 352374cf9cd8671d445b2b702f14abe72b404cca: sideplay/jb-embedded-appbridge/evidence/runs/40674445027/com.duoface.jb.embedded_0.0.90~nativegetters1_iphoneos-arm64.deb.
- Publisher repo chuongnguyen89dn-ui/carplaydsp main commit 9832ce4d603d0c2cb432228608bdec5ed52101fe adds SHA-pinned .90 without deleting older .89 rollback.
- Sileo workflow https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/40674909879 build SUCCESS, Pages deployment SUCCESS, public verify-duoface-integrated-pages SUCCESS (job 122772308857), verify-qa11-pages SUCCESS. YAML validator 40674909849 SUCCESS.
- Public Sileo source https://chuongnguyen89dn-ui.github.io/carplaydsp/ and public DEB https://chuongnguyen89dn-ui.github.io/carplaydsp/debs/com.duoface.jb.embedded_0.0.90~nativegetters1_iphoneos-arm64.deb .

## Runtime scope and still untested
- .89 was DEVICE FAIL for wrong YouTube orientation in two-pane. .90 is a Native12-original-derived independent, YouTube-only orientation state/rotation-hook candidate. Only active with exact UIKit scene owner lease, restores original UIKit behavior otherwise.
- Maps, Dock and original .83 video lifecycle were not edited.
- .90 has passed source, package signing, SHA and Sileo CDN checks; NOT TESTED on actual iPhone/CarPlay, NOT proven video orientation fixed.
- Next physical test: iPhone X JB rootless iOS16.7.16, car parked, YouTube two-pane immediately (no solo/swipe); then solo -> split, fullscreen, swipe-down, playback/seek, Dock/Maps/no crash.
- Export new sideplay/log/DuoFaceSceneHost.log with youtube-app-handshake-ack virtualization phase/hooks/leaseActive/split and controllerMismatch/clientOrientation/serverOrientation to distinguish missing ElleKit symbols from a still-wrong video presentation window.
- Restore earlier .89 or .83 from saved immutable archives if crash. Do not suggest Filza or arbitrary scaling.

## Exact source and handoff
- New source: sideplay/duoface-native-scene-host/DFYouTubeOrientationVirtualization.h and .m; DFYouTubeOrientationRelay.m, DFSceneHost.m, build.sh, source tests and packaging tests.
- Existing handoff: sideplay/tiep tuc du an.md; build CI already prepended signed .90 SHA evidence (commit 352374cf); append this Sileo outcome separately and verify readback.
