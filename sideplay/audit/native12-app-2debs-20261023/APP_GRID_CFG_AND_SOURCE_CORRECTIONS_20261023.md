# Native12 APP continuation: original grid arithmetic and safe source corrections

2026-10-23 ICT · feature/duoface-jb-embedded-appbridge-20261020 · based on original 2-DEB audited run 39897816882.

## Original ARM64 grid arithmetic at exact PCs (READ-ONLY)
- Method `CBMultitaskingOverlayView.setupAppPickerCardsInCardW:cardH:contentY:` original IMP `0xa3e5c..0xa5d18`, 1,967 instructions in `runs/39896596511/extra-original-app-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json`. Original DEB SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`.
- `gridCols` return `x0` transformed at `0xa40c0 sub x8,x0,#4; 0xa40c4 cmp x8,#2; 0xa40cc csel x19,x8,x0,hi`. Thus **exact 4,5,6 accepted; everything else defaults to 4**. This is not a universal 4-column cap.
- `gridRows` at `0xa40e0 and x8,x0,#...fe; 0xa40e4 cmp x8,#2; 0xa40ec csel x22,x0,x8,eq` means **2 or 3 rows accepted; other values default to 2**.
- Grid capacity computed by `0xa4108 mul x19,x22,x19`. Per-column width numerator at `0xa4414–0xa4434` subtracts **2 horizontal margins** and **(cols−1) inter-column gaps**, divides by columns, rounds downward at `0xa4438–0xa4440`. Row height counterpart `0xa4444–0xa447c` subtracts **2 vertical margins** and **(rows−1) gaps**, divides by rows, rounds down and clamps **minimum 40 pt**. This proves current zero-spacing four-by-two UICollectionView is not generally pixel equivalent. Exact adaptive margin inputs remain conditional on card dimensions and require CFG/physical verification before porting.
- Original page-item coordinate logic: `0xa4dbc–0xa4dd0` computes logical page, column and row via `sdiv/msub`; `0xa4dd4–0xa4dfc` sums configured margin + page/column offset for x and margin + row offset for y; `0xa4e20–0xa4e48` rounds button origin. Current independent UICollectionView uses a different paging renderer.
- Icon size `0xa48dc–0xa4938` has conditional caps (42/48/58) and floor **28 pt**; icon corner multiplier `0x3117a8=.225` at `0xa493c–0xa4940`. Original `hideIconLabels` gates label creation `0xa50dc`. Badge coordinates (check/swap) need more original CFG and actual snapshot proof.

## Current first-party source update (NOT a copied vendor implementation)
- Restored proven localized original inner mode names (Ứng dụng / Bố cục / Đang mở), active white/inactive .68 tab text.
- Installed App tile now clear (not running gray card); running-card styling and actions preserved. App icon rounded by .225 × its current adaptive icon side; current icon-side *size algorithm still differs* and needs separate fix.
- App selected title RGB(.55,.80,1), other title white=.95, active-icon border 2 pt RGB(.15,.62,1), inactive border0. Selection is read from confirmed DFSceneHost scene-ready current-slot bundle ID, not guessed app inventory. No other-slot badge drawn yet because exact position/state predicates are not fully verified. No custom grid settings added based on assumptions.
- Original slide/media/3s logo, Zoom, Style, Close, four-second hide and Dock code unchanged by patch.

## Acceptance status / next
- Source static unit and iOS16 clang CI still **PENDING** at commit authoring; no signed DEB, Sileo or device claim.
- Next audit: original badge frame/other-slot branch and exact grid margins/pagination for columns 4/5/6, rows2/3, labels hidden; then independent implementation and only after CI build. Device images for 427×240 / 507×240 remain mandatory for pixel claim.
