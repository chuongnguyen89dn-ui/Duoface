## 2026-10-30 — QA128 SIGNED UPDATE PUBLIC ON SILEO; DEVICE TEST PENDING
- Same existing DuoFace package com.duoface.jb.embedded **0.0.128~manualowner1**, native 0.1.128~manualowner1. User authorized update/build after clarification; no separate app/tweak. Source 2aed6d232cce7d991bcbb83d7a144da6dba212cb contains previously tested manual observer contract repair plus version/staging wiring.
- **Signed build PASS:** https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41025632714; job 123962966280; artifact 12963522465. Permanent signed package at Git commit 6f8d859a4bcde70c5c1efd56efdc99176499f197, sideplay/jb-embedded-appbridge/evidence/runs/41025632714/com.duoface.jb.embedded_0.0.128~manualowner1_iphoneos-arm64.deb. SHA256 a19b59bd8f7a52af0659336575e8889aaa483d42e3dde503c11bfa885aa3b5e8. Source checks, full compile, ldid/signing checks, dpkg package identity/version/architecture and checksum passed. UUID evidence is in QA128_MACHO_UUIDS.txt alongside provenance.
- **Sileo publication PASS:** publisher chuongnguyen89dn-ui/carplaydsp main 74ed764b90db39e44e3776320129ab09bf670a47, workflow .github/workflows/build.yml. YAML validator 41026176540 SUCCESS; actual https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/41026177229 completed SUCCESS. Build 123964712830, Pages deploy 123966051834, integrated public verifier 123966156118, QA11 123966156060 and original observer verifier 123966156123 all SUCCESS. Public verifier actual log at 2026-10-30 15:28:09 ICT printed DUOFACE_ONE_PACKAGE_PUBLIC_SILEO_INDEX_VERIFIED and DUOFACE_PUBLIC_SILEO_DEB_DOWNLOAD_AND_CHECKSUM_VERIFIED with public.deb: OK.
- Repo https://chuongnguyen89dn-ui.github.io/carplaydsp/ ; direct DEB https://chuongnguyen89dn-ui.github.io/carplaydsp/debs/com.duoface.jb.embedded_0.0.128~manualowner1_iphoneos-arm64.deb . Exactly one active QA128 integrated APT record; prior signed QA127 and QA125 remain downloadable. Publisher added only QA128/download/selection/verification changes, not another app.
- **Physical status: NOT INSTALLED/TESTED by assistant.** Cannot claim crash/touch/locked Play fixed; GOFA half-map unchanged. Actual runtime repair only decouples registered manual current-controller callback ownership from transient hidden/detached presentation; stale/destroy/global foreground/CPTemplate background gaps remain.
- Device next action: refresh Sileo, upgrade DuoFace to 0.0.128~manualowner1, normal respring. Parked single test: split -> lock iPhone -> YouTube Play -> Zoom -> CarPlay Home -> reconnect. Export via existing DuoFace iPhone "Xuất log / lỗi CarPlay" to sideplay/log on main. Confirm loaded DFTouchOwnerProbe UUID **367FB46D-9CA6-3372-915E-0D083F1BD261** before attribution (old QA125/126 mismatch already proved). Other UUIDs in permanent evidence. If any crash/touch failure, analyze matched session; no repeated blind build.
- Full build/release report and verifier evidence: sideplay/audit/manual-observer-contract-20261030/QA128_BUILD_AND_RELEASE.md and QA128_PUBLIC_SILEO_RESULT.json. Older pending/local-only statements below are historical.
---


--- Previous build-stage report (historical) ---

# QA128 integrated update — signed build verified; Sileo pending

Same package com.duoface.jb.embedded, 0.0.128~manualowner1; native host 0.1.128~manualowner1, arm64 rootless iOS16. Runtime callback repair unchanged from 4d770510; source version/staging commit 2aed6d232cce7d991bcbb83d7a144da6dba212cb.

Actual build https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41025632714 completed SUCCESS; job 123962966280; artifact 12963522465. Existing source/UI/package tests, actual compile, ldid signing checks, dpkg control/architecture and SHA validation all succeeded. Package and evidence saved in same repo branch at 6f8d859a4bcde70c5c1efd56efdc99176499f197:

sideplay/jb-embedded-appbridge/evidence/runs/41025632714/
- com.duoface.jb.embedded_0.0.128~manualowner1_iphoneos-arm64.deb
- SHA256SUMS.txt, PACKAGING_PROVENANCE.json, QA128_MACHO_UUIDS.txt, CI_RESULT.txt

SHA256 a19b59bd8f7a52af0659336575e8889aaa483d42e3dde503c11bfa885aa3b5e8
DFTouchOwnerProbe UUID 367FB46D-9CA6-3372-915E-0D083F1BD261

Publisher carplaydsp/main 74ed764b90db39e44e3776320129ab09bf670a47, workflow .github/workflows/build.yml, fetches this exact immutable signed DEB by SHA. Retains QA127 and QA125 downloads, selects exactly one QA128 APT record. Real run 41026177229 pending; YAML validator 41026176540 pending at this checkpoint. Do not claim Sileo published until Pages and public checksum verifier pass.

Original user authorization: build this correction into current DuoFace update and deliver through existing Sileo; not a separate app/tweak. No user device installation or test performed remotely. Hardware crash, locked Play/touch and GOFA NOT VERIFIED. Prior GOFA and lifecycle gaps unchanged. Next inspect publisher job, verify public single APT entry and SHA, then user Sileo upgrade/respring and one matched device test using existing iPhone Export logs. Verify loaded UUID against above before attributing results.
