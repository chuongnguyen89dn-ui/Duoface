# Real Native12 nine preview formats, recovered from ORIGINAL Mach-O

Evidence is extracted from actual immutable Native12 `DuoFaceDashboard.dylib` (SHA256 `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`), inside original DEB (SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`). This is **not** inferred from independent rebuilt `DFIInterface.inc`.

**Actions [39727952251](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39727952251) SUCCESS** on macOS original DEB, extracting all 994 ARM64 instructions for function `0x9efe0..0x9ff68`. The actual caller at `a6484: bl 0x9efe0` receives each of 9 tags from `CBMultitaskingOverlayView.setupPresetCardsInCardW:cardH:contentY:` while that caller loops 0..8. Source: `evidence/helper/ORIGINAL_PRESET_IMAGE_RENDERER_ARM64.json` and `.txt`. The actual binary jump table at image VM address `0x310d3e` is 9 uint16 offsets relative to `0x9f290`.

| Original tag | Actual preview-renderer ARM64 case | Visible preview shape | Preview rectangles |
|---|---|---|---|
| 0 | `0x9f290` | Solo / 1 ô | 1 |
| 1 | `0x9f2fc` | Trái + phải, 2 dọc | 2 |
| 2 | `0x9f384` | Trên + dưới, 2 ngang | 2 |
| 3 | `0x9f408` | 3 cột dọc | 3 |
| 4 | `0x9f4f4` | 1 trái + 2 phải | 3 |
| 5 | `0x9f5c4` | 2 trái + 1 phải | 3 |
| 6 | `0x9f690` | 1 trên + 2 dưới | 3 |
| 7 | `0x9f760` | 2 trên + 1 dưới | 3 |
| 8 | `0x9fdd4` | 4 ô dạng lưới 2×2 | 4 |

Case-to-rectangle interpretation: inspect original `NSValue valueWithCGRect:` constructions in the disassembly. The renderer starts with a padded bounding rect and horizontal/vertical midpoint with an internal gap. Case 0 appends a single full inner rect. Cases 1 and 2 split along x/y respectively; case 3 computes a `1/3` width from remaining width after two gaps; cases 4–7 append three rectangles with a shared half-panel and the other panel split on its perpendicular dimension. **Case 8** at `0x9fdd4` explicitly creates FOUR `NSValue valueWithCGRect:` rectangles for the four quadrants and routes the fourth through shared `addObject:` at `0x9f83c`. The previous 8-option reconstruction missed this final **four-quadrant** card entirely; the earlier four-vertical-strips concept is **not the ninth original preview**.

Original card gallery: 9 cards with source-origin 5 or 6 columns per row according to layout size (`a5f4c: mov w8,#0x5`, `a5f50: mov w9,#0x6`, `a5f54: csel ...`); actual precise pixel dimensions/color do not follow merely from this note.

### Implementation and remaining boundary

New independent source extends `sideplay/duoface-native-scene-host/DFLayoutEngine.m` with real ninth `case 8` using four live scene rectangles and horizontal secondary divider, `DFNative12Chrome.m` with 9th Style card and 5-column layout, iPhone picker with 9 types, SpringBoard ACK accepting 4 occupied slots and true 4 backing containers. Source changes under feature branch, with newly isolated nativehost version 0.1.38 candidate. **The original app's exact hit testing, statusbar full Zoom, video rendering and stability are NOT verified**, even if source tests/builds later pass. Do not equate nine preview shapes to complete Native12 functional parity.

Before this source correction the released 0.0.30 signed DEB genuinely had only EIGHT Style entries and was wrong in that respect. Old binaries stay immutable; a new corrected integrated DEB must be built and verified, not mislabeled as already released.
