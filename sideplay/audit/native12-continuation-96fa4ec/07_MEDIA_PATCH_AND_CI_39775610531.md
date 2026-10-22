# Native12 media viewport — original 0xacc6c evidence, new independent source, CI verification

Original immutable Native12 DEB SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`, Dashboard Mach-O SHA256 `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`.
Methods traced from `sideplay/audit/native12-continuation-4888299/original-video-layout-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json` `CBBridgedUIAppView.updateLayout` IMP0xacc6c (376 instructions); separate `updateSceneSettingsFrame` IMP0xad5bc preserves **Portrait=1**.

CI [39775342730](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39775342730) SUCCESS exact original DEB SHA, Mach-O SHA, decoder script `sideplay/audit/native12-continuation-96fa4ec/decode_media_layout_literals.py`, immutable output `MEDIA_LAYOUT_LITERALS.json` Git blob `cfa29114bef80ba643d9157c30e55381ee836f7a`. Original:
- ad03c/ad040 uses min(slotWidth/nativeWidth,slotHeight/nativeHeight);
- ad04c VM0x310c60 double **0.05**; if min ratio > .05 uses min, else 0.5;
- ad068 `CGAffineTransformMakeScale(uniform,uniform)`, view centered at slot midpoint ad09c-ad0c8.
- ad0e0 VM0x311910 double **600**, cornerRadius=(slotWidth<600)?10/scale:0 at ad0ec-ad124.
- original native reference size = `roundf(2*slot.width),roundf(2*slot.height)`; original orientation is **portrait**, no forced landscape.

Independent changes:
1. `DFNative12MediaGeometry.h` source commit `bf942b9dc5a3e48db59878e5ab585c7ad3717329` implements original numerics (finite/input guards and fallback).
2. `DFSceneHost.m` commit `bb86c2d7c25f91aec89b7a5e2b955f22d7f12a8f` now resets transform, uses verified uniform original scale, centers view, applies corner radius and continues native Portrait=1 size setter & 0.30s debounce, real hosted scene, touch and cleanup.
3. `tests/test_preview_geometry.py` commit `e3a0227fb3f22a4114f4f13b603d42bc8fed25ff` 3 additional executable C cases, including fractional/resize, width600 corner policy, invalid fail-closed.
4. `.github/workflows/duoface-native12-source-only-validation.yml` commit `f6f984860e16e91451caaffd960946317a495bce` includes **DFSceneHost.m** in real iOS16 arm64 Apple SDK syntax check, still no packaging, no public release.

CI [39775610531](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39775610531) job **119813752703** completed SUCCESS at 2026-10-22T12:06:37Z: 46 Python source contracts PASS, **9 compiled C geometry tests PASS**, Objective-C iOS16 arm64 syntax checks DFAppPickerVC.m, DFNative12Chrome.m, DFNative12PresetPreview.m, DFSceneHost.m PASS, markers `NATIVE12_UI_REAL_SCENE_AND_RASTER_SOURCE_CONTRACTS_PASS` and `NATIVE12_SOURCE_ONLY_ARM64_SDK_SYNTAX_PASS_NO_SIGNED_DEB`. NO signed DEB, Sileo publish, iPhone physical test or YouTube app video orientation verification. Source numerics becoming exact does NOT prove the reported rotated player is solved; require real `/var/mobile/Library/Logs/DuoFaceSceneHost.log`, CarPlay capture, safe mode traces.

Separate original Close OS-process termination discrepancy evidence `06_CLOSE_RUNTIME_GAP.md` commit `c26e803e20414ec6c4290858f086ec1e41decf49`: original methods invoke CBBridgeManager terminateApplicationWithBundleID / restartApplicationWithBundleID / terminateAllBridgedApplications, independent currently only scene-release/rehost. No speculative kill. Seven user device acceptance gates and strict original parity still OPEN. ONE FINAL integrated installer only, no partial Sileo test build per user policy.
