# Item 2 — header/contentY mismatch, analysis checkpoint

Original setupCardContent @0xa2a58 is 1281 ARM64 instructions in ../native12-continuation-4888299/original-picker-close-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json.

Verified register chain:
- a2bf8 d9=card bounds height (fallback380 at a2c04).
- a2c0c loads threshold260 from VM0x311768, verified directly in SHA-pinned Dashboard bytes.
- a2c14/a2c1c constants38 and32; a2c24 selects32 when height<260, otherwise38.
- a2e00 saves headerHeight to [sp+0x38].
- a3c18/a3cf0 reload d9 from same stack slot for both branches.
- a3d40..a3d50 creates separator (0,headerHeight,cardWidth,.5).
- a3dd8 passes contentY=headerHeight+.5 through d2 to selected page builder at a3dec.
- setupPresetCards a5ef8..a5f1c creates scroll frame (0,contentY,cardWidth,cardHeight-contentY-4).

Current Chrome hardcodes gallery y46,height=styleH-46-4. Thus at typical card height232, original y32.5 differs by13.5pt; at height>=260 original y38.5 differs by7.5pt. Not an inferred cosmetic preference.

Other coupled discrepancy: original dismiss button is square24x24 at x=W-32,y4 for short cards; square26x26 at x=W-34,y6 for tall cards (a2fcc..a3010), corner radius half width at a3070/a30a4. Current dismiss is (W-42,9,32,26), text glyph ×. Original background literal RGBA(.18,.18,.22,.9). Full icon/title/tab reconstruction must be completed before moving gallery; otherwise current 30pt controls at y7 extend below original small-card contentY.

Status: ANALYZED, NOT IMPLEMENTED. Keep existing UI untouched until tab/logo/title frame and selector paths are traced. Next immediate read: setupCardContent a2c28..a2f94 (icon/title), a3100..a3cf4 (tabs), decode exact literal thresholds/widths and image assignment. Preserve original assets and callback contracts; no guessed header.
