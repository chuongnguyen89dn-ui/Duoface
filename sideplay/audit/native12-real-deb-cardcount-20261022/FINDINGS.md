# Correction: original Native12 DEB constructs NINE Style preset cards

Verified by read-only CI: https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39724563111 (SUCCESS, job 119645412031).

- Original real DEB repo commit: 1286a3ef868cf7e29804bcddf7e20b2eae707ce1
- Path: dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb
- Original DEB SHA256: 2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad
- Extracted Dashboard Mach-O SHA256: 9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea
- Extracted files: 43; source: actual original DEB, not assistant-created reimplementation.

Original ARM64 CBMultitaskingOverlayView.setupPresetCardsInCardW:cardH:contentY: at IMP 0xa5e78:

    a5fd4: mov x26, #0x0
    a6700: add x26, x26, #0x1
    a6704: cmp x26, #0x9
    a6708: b.ne 0xa61ac

This constructs nine card previews, not eight. The previous claim of eight exact-original layouts came from the project-authored replacement/visual12/engine/runtime/DFIInterface.inc and is invalidated by the original machine code. The previous static audit erroneously compared source against this replacement instead of establishing the original card count. It should not be used as a nine-layout correctness gate.

The original CBBridgeManager.switchToMultiSplitMode:apps:ratio: has comparison against four slots in actual instructions, but the exact nine card-tag-to-geometry mapping and runtime simultaneous app count are not verified by this audit. Do not invent labels/shapes or declare parity from card count alone.

The old eight-choice 0.0.30 integrated DEB was built (DuoFace Actions 39720659962 success, job 119633099739) and published to public Sileo (carplaydsp Actions 39721005563 success), checksum dab6b7c3cd7e9b6d9b5fff703a37416f668803f360cfbf8c783d17e7926ffe35. Build/deployment were real, BUT they did not fix the incorrect eight-count. No new nine-layout DEB has yet been compiled or published in this audit.

Next actionable step: decode all nine original preset IDs and picture/scene rectangles via original IMP; modify DFLayoutEngine, DFNative12Chrome, SpringBoard/phone preset range and migration consistently; preserve 3-second logo hold and top-centered pane pills; compile new distinct version, run tests and actual DEB inspection, and only then publish as a new QA candidate. Original/N-1 binaries remain immutable.

Evidence: sideplay/audit/native12-layout-forensic-20261021/evidence/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json, new scan_original_card_loop.py, .github/workflows/duoface-real-original-cardcount.yml, artifact Native12-Real-Original-DEB-Nine-Cards-No-Release.
