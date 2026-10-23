# APP tile UI states from both actual DEB evidence — 2026-10-23

## Verified scope
Comparison **Native12+Speed8 original DEB** SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad` vs **DuoFace 0.0.41 staged signed DEB** SHA256 `da2275c2a9ef7efe8879a7121677d2771c809b78066b4552a2294d4b8a1715c2`. Actual original Dashboard binary SHA256 `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`. Verified by SHA-pinned complete-DEB GitHub workflow [39897816882](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39897816882), status **completed/success** (all stages including App tile ARM64 source constants test). This is a **static binary/code crosswalk**, NOT an on-device render or interaction test.

Actual immutable JSON produced by passing CI: `sideplay/audit/native12-app-2debs-20261023/runs/39897816882/tile-state/APP_TILE_STATE_CROSSWALK.json` (Git blob `97c50c944a6ec8153a4bfbc6b359bf2b667ff919`). Matching scripts `sideplay/audit/native12-app-2debs-20261023/check_app_tile_palette_20261023.py` and SHA-locked disassembly `sideplay/audit/native12-continuation-4888299/original-picker-close-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json`. Source at `sideplay/duoface-native-scene-host/DFAppPickerVC.m`.

## Newly found *original APP item* visual logic

| Element | Original Native12 proven source at SHA-verified ARM64 | New first-party 0.0.41 difference |
|---|---|---|
| App item **UIButton background** | `UIColor.clearColor`: selector @`0xa4b00`, register forwarding @`0xa4cfc` / `0xa4e68` and `setBackgroundColor` @`0xa4e88`; other layers may carry styling | Single `DFNativeAppCard.contentView` painted solid gray-white=0.19 alpha=0.96 and rounded 14 pt. **Different**, don't replace every independent card until distinguishing Running cards |
| Icon border when selected | width **2 pt**, color RGB **(0.15,0.62,1)** from original @`0xa4ff0/0xa4ffc/0xa5000/0xa5028` | no original selected-app icon outline |
| Icon border otherwise | width **0 pt**, @`0xa5084` | no matching state-dependent border |
| Selected app name | RGB **(0.55,0.80,1)** (approx `#8CCFFF`), original branch @`0xa5184–0xa51d8` | always white regardless active state |
| Unselected app name | `colorWithWhite:0.95 alpha:1` (approx #F2F2F2), original @`0xa51ac/0xa51b0` | white=1 |
| Current-slot badge | `checkmark.circle.fill`, blue RGB **(0.08,0.52,1)** + white, original @`0xa5278/0xa52e0` | no App tile state badge |
| Other-slot badge | `arrow.left.arrow.right.circle.fill`, orange RGB **(1,0.62,0.04)** + white, @`0xa53c4/0xa542c` | no App tile state badge. Important: Orange color is **badge palette**, NOT a proven App-card backdrop |
| Badge decoration | shadow opacity **0.50**, radius **2.5 pt**, y offset **1 pt**, `0xa54fc/0xa5528`; size candidate **16 pt in six-column grid**, otherwise **18 pt** | missing corresponding badges/decorations |
| Icon corner rounding | **0.225 × computed adaptive icon side** `0xa4934/0xa4940`; icon candidate min 28 / caps 42,48,58 subject to content size and settings | icon min24/max43, entire cell radius14 |
| Hide name setting | original conditional branch `0xa50dc` skips UILabel; depends on `CBDashboardSettings.hideIconLabels` | App names always shown |

All values above were checked by exact ARM64 instruction/address assertions plus original Mach-O virtual-address raw float reads. Some conditional state ownership is inferred from adjacent original branches and must be corroborated with actual screen captures; **do not claim every pixel 100% verified**.

## Other original APP UI already verified in prior audit
- Modal separate translucent black dim opacity 0.65, SystemMaterialDark UIBlurEffect raw enum18, card shadow black opacity0.65 radius26 y10, round20 border1 white alpha0.18. New independent black root alpha0.95 gray opaque sheet border0.5 white alpha0.25 no equal blur.
- Current tab selected bright blue RGB(.08,.52,1), inactive gray white0.68; new inactive white (wrong).
- Original multi-page grid allows 4/5/6 configured columns and hide icon captions; new hardcoded4×2 with all captions.
- Original installed app gate `CBDashboardSettings.bridgedApps` + `LSApplicationWorkspace` sorted `categoryRank`, active-slot badges, `appSelected:` stores chosen bundle into slot. Current generic app inventory sorted by name and scene state.
- Original +Add button opens separate dark frosted native instruction modal `addMoreAppsTapped:` with real title/message/OK, `iphone.and.arrow.forward` icon, shadow and dismiss; new lacks it.

## Remaining verification
Source/asset ABI full binary inventory PASS, UI pixel/CarPlay touch parity FAIL/not completed; no code edits to runtime, no new signed DEB, no Sileo publish. Next decode original App tile CGRect/layout formulas and detailed selection transitions for 4/5/6 columns, exact setting persistence and dynamic localization. When implementing, distinguish installed-App tile from Running tile and protect original 3-second round-logo gesture, Zoom/Style/Close, 4-second auto-hide and YouTube scene integrity.
