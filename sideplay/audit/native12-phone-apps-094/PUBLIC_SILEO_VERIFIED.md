# DuoFace .94 iPhone Apps Manager — PUBLIC SILEO RELEASE VERIFIED 2026-10-29

USER APPROVED SCOPE: iPhone per-app toggles and action menu Bật đề xuất / Bật tất cả / Tắt tất cả first; compare original DuoDash 1.1.3, OmniCar 1.0.3, Native12; code independent, no vendor license.

## Verified implemented code and CI
- Source commit d0477263fbe19ad287d8ee84ad74c0d86fd6fce3; source/tests e70495a60effcb5d9043c285822c002a97a5dff2; source-only macOS + iOS16 UIKit and executable preference regression [40786223749](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40786223749) SUCCESS.
- Source pin a1c260e15a24c2c3b3bc833ae74b89493af0e271; signed one-DEB rootless package build+immutable archive [40786398702](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40786398702) SUCCESS.
- Archive path sideplay/jb-embedded-appbridge/evidence/runs/40786398702/com.duoface.jb.embedded_0.0.94~phoneapps1_iphoneos-arm64.deb. Size 1034444 bytes, SHA256 df3a87256e0ed0f8086df77d3eae1a78af8d2392c61286c7c79bc05c894e3be7, Package com.duoface.jb.embedded, Version 0.0.94~phoneapps1, Architecture iphoneos-arm64, embedded NativeHost 0.1.103~phoneapps1.
- First-party runtime: iPhone DFNativeHostRootController.m UISwitch + recommended/all/none action menu; DFEnabledAppsPolicy.h persisted allowlist and successful-write notify; DFAppPickerVC.m live catalog refresh and single-app/slot selection. Previous YouTube .90, logo .92, native Dock and Maps code unchanged.

## VERIFIED SILEO PUBLIC
- Publisher repo chuongnguyen89dn-ui/carplaydsp main code commit 8e43a788fda54800746161711fde9133ab04693f modified only established .github/workflows/build.yml to pin .94 source+SHA, produce one latest DuoFace APT entry and preserve all prior DEBs byte-identical.
- Publisher actionlint run [40786982012](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/40786982012) completed SUCCESS.
- **Publisher Pages [40786982028](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/40786982028) completed SUCCESS**, jobs: build SUCCESS, deploy SUCCESS, verify-duoface-integrated-pages SUCCESS, verify-qa11-pages SUCCESS. Public verifier checked newest APT record Package com.duoface.jb.embedded / Version 0.0.94~phoneapps1 / SHA256 df3a87256e0ed0f8086df77d3eae1a78af8d2392c61286c7c79bc05c894e3be7 and exact downloaded remote DEB, frozen old .92 SHA 1f4a495f8b9ba91f71bac4c7abc4e064878fb8f2edd5272df3d48fef3a95e1f0 and .90 SHA c9a6c8f624ce3224ec5cdc7aee9c3280306068c99c9842d4b4f802914c560f27.
- Sileo source: https://chuongnguyen89dn-ui.github.io/carplaydsp/ ; direct .94: https://chuongnguyen89dn-ui.github.io/carplaydsp/debs/com.duoface.jb.embedded_0.0.94~phoneapps1_iphoneos-arm64.deb . Do not install via Filza. No user device installed/tested claim.

## ORIGINAL ANALYSIS SCOPE AND NEXT
- Native12 ARM64 original runs 40699487806 and 40700551205 prove iPhone app-switch/setApp:enabled and Enable Recommended/All/Disable All, separate from one-app/slot CarPlay. DuoDash original phone _readBridged/_enumerateApps/_persistAndNotify and in-car My Apps are proven. OmniCar original audit proves ABHost/SCPCarSplit app scenes, but NO original phone bulk App Manager proof; we do NOT claim it.
- 'Bật đề xuất' independent definition: eligible user-installed non-Apple apps. Not vendor recommendation scoring. Do not claim identical Original implementation.
- NEXT PHYSICAL DEVICE gate: through Sileo update from .92 to .94 on iPhone JB, open DuoFace iPhone App > Ứng dụng, toggle YouTube OFF/ON, confirm live CarPlay App gallery filtering; test Bật đề xuất/Bật tất cả/Tắt tất cả; preserve already running scene until user changes slot; reconnect; verify video rotation in split/solo, Apple Dock, logo, SpringBoard crash-free; record logs. Physical device result still unknown.
