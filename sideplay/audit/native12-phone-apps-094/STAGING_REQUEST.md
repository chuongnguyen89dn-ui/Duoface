# DuoFace .94 staged one-DEB package request, 2026-10-29

New user feature scope: iPhone Apps Manager **Bật đề xuất / Bật tất cả / Tắt tất cả**, plus per-app switches and live CarPlay catalog filter. Compared verified Native12 original iPhone selectors and DuoDash 1.1.3 AppBridge; OmniCar original phone manager remains unverified. Independent code, no vendor license.

- Source commits: `d0477263fbe19ad287d8ee84ad74c0d86fd6fce3`, `e70495a60effcb5d9043c285822c002a97a5dff2`.
- Source-only macOS Foundation runtime, Python regression, YouTube ABI, iOS16 UIKit source compilation: [run 40786223749 SUCCESS](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40786223749).
- Handoff readback+GitHub push: [run 40786223869 SUCCESS](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40786223869); source handoff commit `fa82f3d288c11a550d286248e8f697b1950a092b`.
- Staging request commit: `a1c260e15a24c2c3b3bc833ae74b89493af0e271`, exact source-pinned [build 40786398702](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40786398702) started; **NO build conclusion yet when recorded**, no Sileo publish, no device test. Target nativehost `0.1.103~phoneapps1`, integrated `0.0.94~phoneapps1`.
- Current Sileo public last verified `0.0.92~logo3s1`; leave it unchanged until package signed hash/provenance + remote index and downloaded DEB match. Preserve immutable .90 verified YouTube source and .92 logo source, Maps & Dock.
- Source changes confined to iPhone `DFNativeHostRootController.m`, shared allowlist policy `DFEnabledAppsPolicy.h`, CarPlay `DFAppPickerVC.m`, tests and packaging pins. Action sheet "Bật đề xuất" = installed eligible non-Apple user apps, not a claimed proprietary recommended algorithm.
- Next: query build 40786398702 until completion; inspect exact failing step if FAILED, otherwise verify `sideplay/jb-embedded-appbridge/evidence/runs/40786398702/` package bytes, sha256, control and source SHA, then publish via existing carplaydsp Sileo workflow and remote verify. On-device parked test switches and catalog update, Tắt tất cả/re-enable, YouTube playback orientation and no-crash. No claim of installation until actual user test.
