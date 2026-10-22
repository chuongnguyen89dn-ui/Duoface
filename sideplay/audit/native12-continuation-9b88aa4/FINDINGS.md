# Native12 Style continuation from 9b88aa4 — 2026-10-22

Repository: chuongnguyen89dn-ui/Duoface. Branch: feature/duoface-jb-embedded-appbridge-20261020.
Baseline 9b88aa4654058147756924f6ff4882f67a4fbec6 was the remote branch head when resumed.
Read actual Gpt-training ZIPs 01/02/05/06 at 0180bd5b4244a93a08283806be7173dea3999675 plus project history and original disassembly.

## Confirmed defects, not new design

The previous bitmap patch is not exact Native12 rendering. This supersedes its incorrect literal interpretation, without discarding other progress.

- Caller 0xa6434/38 compares preset and current selection; 0xa6474 passes preset in x0 and 0xa6478 passes selection BOOL in x1. Helper 0x9f010 preserves x1 in x24; 0x9f130 tests that flag. Old independent code instead tested preset==0. Thus solo could never get selected blue, and every non-solo looked selected.
- Original border selected RGBA=(.2,.6,1,.9), not (.2,.6,.9,1).
- Original unselected region fill RGBA=(.87,.9,.95,1), stroke=(.48,.53,.62,1), width=.6. Previous patch incorrectly used (.87,.48,.53,1) as fill and white stroke. This came from misreading register flow, not an original palette choice.
- 0x9f1e4..0x9f224: background rect=(2,2,W-4,H-4), then uniform inset 3 for W<=100, 4 for W>100. Inter-region gap is 1.8 or 2.5, a separate value. Old implementation used live scene geometry/default ratios and an extra per-pane inset.
- 0x9f248..0x9f274 rounds half dimensions through float with ties away from zero; last region takes remaining size. Three columns at 0x9f408 similarly round first two, preserve remainder in third. Added independent C geometry for all nine cases; actual scene layout untouched.
- 0x9fa58..0x9fc40: per-pane indicator requires width>=12,height>=10; selected width=roundf(.4*w), height1.2, radius.6, white alpha.95; unselected width=roundf(.35*w), height1, radius.5, RGBA(.25,.32,.45,.9).
- 0x9fc80..0x9fd60: bottom indicator if canvas width>60; width=roundf(.22*W), y=H-4.5, height1.5,radius.75. Selected RGBA(.65,.88,1,.95), unselected white alpha.75.

Changed DFNative12PresetPreview.h/.m, new DFNative12PreviewGeometry.h, and Chrome call/selection refresh. Geometry separated from live scene ratios. Selected bitmap regenerates only when selection changes. Added compiled C numerical tests and updated existing source-only workflow. No package version, signed DEB, Sileo or process termination changed.

## Reproducible evidence

Original fetched directly from repo commit 1286a3ef868cf7e29804bcddf7e20b2eae707ce1 path dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb.
Original DEB SHA256=2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad.
Dashboard SHA256=9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea.

Commands, from repository root (temporary extracted references under /tmp):

```sh
git show '1286a3ef868cf7e29804bcddf7e20b2eae707ce1:dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb' > /tmp/native12-original.deb
python -m pip install capstone==5.0.9
python sideplay/audit/native12-continuation-9b88aa4/verify_preview_reference.py /tmp/native12-original.deb sideplay/audit/native12-continuation-9b88aa4
python -m unittest discover -s sideplay/duoface-native-scene-host/tests -p test_scenehost_safety.py -v
python -m unittest discover -s sideplay/duoface-native-scene-host/tests -p test_preview_geometry.py -v
git diff --check
```

Results: actual original SHA validation, Capstone byte disassembly and caller/callee selection assertions PASS, nine jump-table entries PASS, literals decoded directly from Mach-O segment mappings. 45 source-contract tests PASS, 3 executable C tests PASS (all nine rectangles, 86/100/101/120 widths, invalid inputs). See REFERENCE_VERIFIED.json, ORIGINAL_PREVIEW_CAPSTONE.txt, source-contract-tests.txt, geometry-tests.txt. Existing latest CI before changes 39759426027 was completed/success for 9b2e6319; this is baseline evidence, not new-source CI proof.

## Remaining

UIKit syntax validation of this new source pending remote CI. No pixel comparison on actual UIKit/CarPlay has run. Menu card container dimensions, screenshot parity, YouTube portrait/scene transform, system Dock ACK/Zoom/Home, hide/show/three-second drag, true OS process Close/CloseAll and full end-to-end parity remain unverified or incomplete per previous handoff. Do not declare all seven user gates complete. Next: inspect new source-only workflow outcome, fix concrete compile errors if any; then audit original gallery/container and app/Close geometry against current source. Keep one final integrated package policy and dispatch-only packaging workflows.
