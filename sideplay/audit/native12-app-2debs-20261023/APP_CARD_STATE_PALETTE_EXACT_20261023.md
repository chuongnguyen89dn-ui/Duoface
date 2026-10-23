# APP tiles Native12: transparent cells, exact badge palette, selected font and outline

2026-10-23 ICT · Repo `chuongnguyen89dn-ui/Duoface` · Branch `feature/duoface-jb-embedded-appbridge-20261020` · **READ-ONLY, no UI patch or Sileo**.

## Sources and successful verification
- Exact original DEB `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`, extracted original Dashboard Mach-O `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`; independently signed new 0.0.41 DEB `da2275c2a9ef7efe8879a7121677d2771c809b78066b4552a2294d4b8a1715c2`. Exact original `.deb` and signed `.41` were both SHA-checked/extracted by CI.
- Pre-existing full binary runs [39895316677](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39895316677), [39896596511](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39896596511) SUCCESS. This new byte-anchored original tile-status regression executed in **[39897816882](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39897816882) SUCCESS**, source commit `cc12ff3b49b6a48beba6b20f62e8ffd838e8bba1`: reads same direct SHA-locked two DEBs, native original App owner 1967 ARM64 instructions, and raw original VM-mapped float constants. All steps, including uploading evidence and committing it back to same branch, passed.
- New script `sideplay/audit/native12-app-2debs-20261023/check_app_tile_palette_20261023.py` commit `b7e3927d29f162e60570fb0a585c5a7563ece0c8`. Result **`sideplay/audit/native12-app-2debs-20261023/runs/39897816882/tile-state/APP_TILE_STATE_CROSSWALK.json`** blob `97c50c944a6ec8153a4bfbc6b359bf2b667ff919`, read back verified PASS.

## New original App tile pixel-state facts, from actual ARM64 and numeric literal bytes

| Surface / state | Actual original Native12 verified callsite and effective design | Independent signed 0.0.41 first-party source | Verdict |
|---|---|---|---|
| Underlying **App item UIButton**, not the outer modal itself | Background **UIColor.clearColor**: clearColor sel loaded `a4b00` to x27, carried x20 `a4cfc`, called on UIColor `a4e68–a4e6c`, passed to `setBackgroundColor:` `a4e80–a4e88` | `DFNativeAppCard.contentView` fills entire card with `colorWithWhite:.19 alpha:.96` and radius14, clips YES | **Definite App-card visual mismatch**. Original transparent button is not a gray rectangular tile; separate image and selection borders exist. |
| Selected/current App icon's border | **Width 2 pt**, blue RGB **(.15,.62,1)** (roughly #269EFF), determined by app equality `w23` and branch `a4ff0`, borderWidth2 `a4ffc–a5000`, `colorWithRed:...` `a5014..a5028`, CGColor and setBorderColor `a503c..a5068` | No icon border conditional on active app | **Definite state UI mismatch**; not same as tab-selected blue .08/.52/1. |
| Nonselected App icon outline | Border width **0**, branch `a5084–a5090` | No conditional state | Inactive is equivalent in absence of icon border only, but content/card differs. |
| **Selected App name** | RGB **(.55,.80,1)**, alpha1 (≈ #8CCFFf), direct `a5184` branch and literal loads `0x3117c0=.55`, `0x30fac8=.8`, setTextColor `a51d0..a51d8` | White title on all cards, 11 pt Medium | **Definite selected-color mismatch**. |
| Nonselected App name | **UIColor colorWithWhite:.95 alpha:1** ≈ #F2F2F2, `a51ac..a51bc` | Pure white | **Definite nonselected-color mismatch**. |
| Current-slot **check badge** | SF Symbol `checkmark.circle.fill`, using palette colors **blue (.08,.52,1)** and **white**. First color creation `a49bc..a49e8`, passed as `sp#e0` to palette `a5278` then glyph `a52e0`. | App cells have no current-slot check badge | Missing UI condition and glyph. |
| Other-slot **swap badge** | SF Symbol `arrow.left.arrow.right.circle.fill`, palette **orange (1,.62,.04)** and **white**. Orange created `a49f4..a4a20` and passed as `sp#68` to `a53c4`, glyph @`a542c`. | App cells have no other-slot swap badge | Missing. Orange is **not** the background of every App card (correction vs earlier uncertainty). |
| Badge icon shadow | Black shadow opacity **.5**, radius **2.5 pt**, offset (0,1): `a54fc`, `a5528`, `a5550–a555c` | No matching check/swap badge | Missing original icon detail. |
| Badge candidate dimension | Conditional **16 pt in 6-column mode**, **18 pt otherwise**, candidate `a4a80..a4a8c`; may still be limited by frame geometry | Not implemented | Algorithm/screenshot parity pending. |
| App icon adaptive shape | Candidate icon size with 28pt minimum, conditional caps 42/48/58, and icon-view **cornerRadius = .225 × adaptive iconSide**, multiplier VM `0x3117a8` loaded at `a493c–a4940`, applied to icon @`a4f70..a4f74` | Icon 24..43pt; **14pt corner on whole card**, iconView without same radius | **Definite algorithm mismatch**. Exact physical icon frame per cell still requires remainder of CFG calculation. |
| Hide app labels | Original conditional skip `tbnz w8, #0, a522c` @`a50dc` from `CBDashboardSettings.hideIconLabels` | Always visible | Missing setting. |

## Original App tile design needs separation from other surfaces
- OUTER 4-action menu strip (App/Zoom/Style/Close), INNER 3-tab header (Apps/Layout/Recent), INNER backdrop/blur, App tile UIButton, App icon imageView, and App active/swap badge have **different colors and distinct layers**. Do not paint all App tiles solid selected-blue/orange or reuse Style/Running card colors.
- Original INNER tab selected blue (.08,.52,1), inactive text white=.68, per-app icon selected BORDER blue (.15,.62,1), per-app name selected pale-blue (.55,.8,1), check badge blue (.08,.52,1), swap badge orange (1,.62,.04). They are separate properties and distinct ARM64 calls.
- Original App modal: dim alpha=.65, inner blur `UIBlurEffectStyle` raw18, shadow alpha=.65 radius26 offset y10, continuous corner20, border white alpha .18 width1; `DFAppPickerVC` old gray opaque sheet and black dim alpha.95 visibly diverge.

## Unresolved blockers before declaring exact 100%
1. Finish the original per-cell CGRect math from `a3e5c–a5cc8`, varying 4/5/6 columns, gridRows and screen widths; derive app icon CGPoint and exact text frame from branch assignments rather than name of UIFont constant; capture reference screen for 427x240, 507x240.
2. Decode App selected/other-slot boolean input and badge visual conditions for selected slot, currently running, standby, swapped, label hide, and single-page empty; original check/swap badge palette/glyphs now established but all predicates not fully proven.
3. Original `addMoreAppsTapped:` custom informational modal with `iphone.and.arrow.forward`, localized TITLE/MSG/OK must be transcribed from actual original locale lookup/assets or original screenshot; previous report has shadow and geometry.
4. Then implement **only** provably equivalent independent App mode surfaces/events, preserve SpringBoard scene safety, system Dock, 3-second logo hold and 4s hide behavior. New screenshot+CarPlay interaction test is still necessary; no off-device static analysis proves 100% rendered equality.

Status: original APP styling and state mismatch are proven via binary assertions. **NO runtime code edit, no new DEB build, no Sileo release, no iPhone hardware test in this turn.**