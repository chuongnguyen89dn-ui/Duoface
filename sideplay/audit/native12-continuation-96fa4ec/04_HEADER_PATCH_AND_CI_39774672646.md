# Native12 item2 source CI and partial geometry gate

Original SHA pin: DEB 2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad / Dashboard 9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea.

Fix commit 2f4fe9b61caadf53d3d157b9db3faa4d2d915abf restores original INNER 3 mode labels Apps/Layout/Recent (not outer 4 action App/Zoom/Style/Close), original mode1 SF icon 18x18, 32/38pt responsive header, tab zone 190/210, tabs tripartite widths derived from ARM64, native xmark 24/26pt separate from Close and header separator y=32/38, Style scroll start y=32.5/38.5. Commit 4c49ff06bdc0c031af745c3575b8c61821251e80 also restores original xmark responsive bounds in outer user action menu. Native independent source; does not embed original code/license.

Source-only CI: https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39774672646 job 119810511013 concluded SUCCESS, both Python source contracts and real arm64 iOS16 SDK clang syntax; original reference literal audit https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39773723186 success. Source-only regression test SHA expectation typo at cbb9e5c produced failure run39774508505, fixed test-only in 5d5f16e; subsequent run PASS.

**LIMITS:** Original tab tint/background and translated localized strings not pixel/device verified; UI may still have CarPlay touch/event routing problems, no physical iPhone test. No new signed DEB, Sileo change, or package version. Full seven-gate Native12 parity not proven. Previous 0/25 parity figure belongs older isolated build, not rerun. Next: compare exact original App/Recent gallery, Close OS process termination API and YouTube orientation using prior SHA-pinned callchain and logs; implement only proven paths. User wants one final integrated installer, keep manual release.

## CI relevant captured lines

```
2026-10-22T11:58:58.8062490Z [36;1mecho NATIVE12_UI_REAL_SCENE_AND_RASTER_SOURCE_CONTRACTS_PASS[0m
2026-10-22T11:58:59.2880910Z test_SHA_original_inner_modal_three_modes_vs_outer_four_actions (test_scenehost_safety.NativeCarPlayHost.test_SHA_original_inner_modal_three_modes_vs_outer_four_actions) ... ok
2026-10-22T11:58:59.3141130Z Ran 46 tests in 0.027s
2026-10-22T11:58:59.3141620Z OK
2026-10-22T11:59:01.6104750Z test_invalid_card_bounds_fail_closed (test_preview_geometry.OriginalCardHeaderGeometry.test_invalid_card_bounds_fail_closed) ... ok
2026-10-22T11:59:01.6107280Z test_short_original_width_210_and_content32point5 (test_preview_geometry.OriginalCardHeaderGeometry.test_short_original_width_210_and_content32point5) ... ok
2026-10-22T11:59:01.6108580Z test_tall_original_width_190_and_content38point5 (test_preview_geometry.OriginalCardHeaderGeometry.test_tall_original_width_190_and_content38point5) ... ok
2026-10-22T11:59:01.7012680Z Ran 6 tests in 2.286s
2026-10-22T11:59:01.7013550Z OK
2026-10-22T11:59:01.7116370Z NATIVE12_UI_REAL_SCENE_AND_RASTER_SOURCE_CONTRACTS_PASS
2026-10-22T11:59:01.7212870Z [36;1m  echo "COMPILING_SOURCE_ONLY $FILE"[0m
2026-10-22T11:59:01.7216460Z [36;1mecho NATIVE12_SOURCE_ONLY_ARM64_SDK_SYNTAX_PASS_NO_SIGNED_DEB[0m
2026-10-22T11:59:02.8610540Z COMPILING_SOURCE_ONLY DFAppPickerVC.m
2026-10-22T11:59:04.6641760Z COMPILING_SOURCE_ONLY DFNative12Chrome.m
2026-10-22T11:59:04.9876690Z COMPILING_SOURCE_ONLY DFNative12PresetPreview.m
2026-10-22T11:59:05.3086950Z NATIVE12_SOURCE_ONLY_ARM64_SDK_SYNTAX_PASS_NO_SIGNED_DEB
```
