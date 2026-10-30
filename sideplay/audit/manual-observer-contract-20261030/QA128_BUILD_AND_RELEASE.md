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
