# APP Native12 HUD8 — numeric color + geometry + Add button continuation

**Scope:** continue direct comparison of two immutable DEBs, original SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`, independent signed 0.0.41 SHA256 `da2275c2a9ef7efe8879a7121677d2771c809b78066b4552a2294d4b8a1715c2`. Strict read-only. No DuoNavi or license handling.

## New real binary run, code, artifacts
- New original VM-literal extractor `sideplay/audit/native12-app-2debs-20261023/decode_original_app_literals.py`, source commit `47092b58c806021d2aa4b4836864abc478e52fce`. Modified the existing **two actual DEBs, never release** GitHub workflow `.github/workflows/native12-app-2debs-20261023-readonly.yml` commit `9cfc984e07d8e71764aeb59f332bf8857afc8963`, preserving prior all-payload and 1385-method scan.
- Real macOS GitHub Actions [run 39896596511](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39896596511) COMPLETED SUCCESS: original and new SHA-pinned DEBs fetched/verified/unpacked, 43 original vs 30 independent payload files, 1385 original ObjC method inventory, six new original App IMP disassemblies, AND Mach-O VM-address actual raw float64/float32 decoding, artifacts uploaded and auto committed to same project branch.
- Machine output `sideplay/audit/native12-app-2debs-20261023/runs/39896596511/actual-original-numerics/{RAW_APP_LITERALS_AND_CALLSITES.json,ORIGINAL_APP_LITERALS_SUMMARY.md}`. Original Dashboard binary SHA256 `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea` validated. Exact new report data includes original segment VM address mapping into file offsets and the original ARM64 neighboring callsite.

## Newly VERIFIED RAW original floating point constants (not visual guesswork)
| Original VM address / method instruction | Float decoded directly from Mach-O | Meaning traced / limits |
|---|---:|---|
| 0x311738 loaded `initWithFrame:@0xa05e4` / `colorWithWhite:alpha:` @a05dc | 0.65 | Original OUTER translucent dim-underlay uses white=0 / alpha 0.65, separate from transparent top overlay. Current `.41` Picker root `colorWithWhite:0 alpha:.95` is not structurally/color equivalent. |
| 0x311828 loaded `initWithFrame:@0xa076c` / `setShadowOpacity:` @a0764 | `0.649999976` (float32) | Original main card shadow opacity **0.65**, black, shadow radius26 / offset(0,10), masksToBounds=NO. Current .41 no matching original card shadow. |
| original `UIBlurEffect.effectWithStyle:` @0xa0834 and UIVisualEffectView.initWithEffect @0xa0858 | enum **18** | Original inner App sheet uses *SystemMaterialDark* UIKit blur (raw UIKit enum18). Current .41 App sheet is opaque colorWithWhite .10 (no same native effect). |
| original `setCornerRadius:` @a089c | 20pt | Current .41 sheet also corner20: numerical match but not same material/owner. |
| original `setBorderWidth:` @a0934 | **1pt** | Current .41 sheet **0.5pt**. |
| literal 0x30fac0 @a0954 `colorWithWhite:alpha:` | **0.18** | Original card border obtains white opacity 18% (read callsite @a0954/a099c; UIColor.white component is 1 loaded via d8); current .41 sheet border white alpha25%. |
| 0x311720 & 0x311728, original `setupCardContent` / Apps card | **0.08** and **0.52** | Part of exact selected blue RGBA(.08,.52,1,1) approx #1485FF in 3-tab header and App-card palette branch. Do NOT conclude every tile is blue. |
| 0x311798, original `setupCardContent @a35c4/a3694` | **0.68** | Confirms original inactive tab title white=0.68 (#ADADAD approx), vs .41 all white. Same hashed original Native12+Speed8 Mach-O, not merely other Visual12 build. |
| 0x311700 / 0x3116c8, original `setupAppPickerCards` @a49f4/a49fc | **0.62 / 0.04** | Neighboring original UIColor call assembled RGBA(1,.62,.04,1), gold/orange branch, alongside blue RGBA(.08,.52,1,1). The exact conditional state/role of each App card color remains to be proved from CFG and actual captures. DO NOT paint arbitrary tiles orange. |
| 0x3117a8, original App card @a4938 | **0.225** | Applied multiplicatively to computed candidate tile icon dimension via `fmul d0,d11,d0`. Indicates icon geometry-dependent rounding/corner treatment; not unconditional 22.5pt radius. |
| 0x3117b0 / 0x3117b8 App grid @a4c?? | **−0.65 / −0.2** | Additional layout literals; meaningful effective owners still need dataflow. |

## Original App icon sizes: bounds/conditions found, not one invented size
- Original `CBMultitaskingOverlayView.setupAppPickerCardsInCardW:cardH:contentY:` @a48dc-a4934: conditional numerical cap values **58,48,42** (encoded mov x8 0x404d...,0x4048...,0x4045...) according to column/row and available cell extent. Ends with **fmax(...,28)** @a4930/a4934 before `.225 × dimension` computation @a4938. Exact compact geometry depends card W/H, gridCols=4/5/6 and gridRows/hideIconLabels. Therefore the published independent `DFNativeAppCard` capped **43pt** with min24 (and horizontal `card W = collectionW/4`) **is not proven equivalent**; at least its algorithm differs structurally. Do not announce a fixed original app icon size.
- Original App grid `gridCols` accepts 4/5/6 then default4 @a40c0..a40cc and `gridRows` @a40d4, optional `hideIconLabels` @a40f4. New fixed four×two, 8 per page and always name.
- Original App button content icon, displayName and selected-slot checkmark vs swap glyph remain conditional. At @a52e0 uses `checkmark.circle.fill`; @a542c uses `arrow.left.arrow.right.circle.fill`; `.41` installed-app cards omit both.

## Original Add button is a REAL native informational dialog (new details)
- `CBMultitaskingOverlayView.addMoreAppsTapped:` actual original IMP **@0xa7f20** (991 ARM64 instructions), opens an animated *custom frosted alert modal*, not a direct App Store download and not an inert button.
- Original alert title localized from **`ADD_MORE_APPS_ALERT_TITLE` @a864c**, message **`ADD_MORE_APPS_ALERT_MSG` @a89a8**, button **`ADD_MORE_APPS_ALERT_OK` @a8bc4**. Alert shows SF Symbol **`iphone.and.arrow.forward` @a87ac**, separate `dismissCustomAlert:` tap handler @a81ac, blurred background `UIBlurEffect.effectWithStyle:` **enum18** @a83dc, corner radius **16pt** @a845c, black shadow opacity **0.50** @a831c, radius **18pt** @a834c, vertical offset **6pt** @a8380, and uses spring animation `animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:` @a8d6c. New .41 lacks this original button/popup entirely.
- Same UIKit popup owner may include more colors/dimensions; inspect disassembly constants for exact title/OK layout before implementation. Do not claim that pressing + directly enrolls packages; actual control supplies localized instructional alert.

## Exact unchanged functional gaps
- Original `loadInstalledApps` gates on configured `CBDashboardSettings.bridgedApps` before querying LS workspace; sorts with `categoryRank`, real bundle/displayName/icon; new uses DFAppLibrary alphabetical LS inventory without configured rank.
- Original `appSelected:` persists bundle per slot, may swap/replace through CBBridgedSplitApp, then dismiss. New staged DFSceneHost replacement and picker closing exists but persisted layout record currently lacks bundleIDs. Full independent auxiliary prefs check remains open.
- Original scroll pagination exact color inactive white alpha.25 and active white matches current source. Original X separate from action Close remains necessary.

## Next forensic task, not yet done
Decode full control flow state-machine of original 1967 App grid ARM64 instructions with exact button CGRect, border/tint, badges, per-item icon size and label presence; decode original actual localized Add-alert strings and parent 'outside tap dismiss' animations. Then patch only proven independent App menu differences, test 427×240 and 507×240 CarPlay and real device touch. Continue keeping 3-second logo and unrelated menu modes untouched.

**Status: numeric-source proof PASS, entire APP 100% visual/function parity FAIL; no runtime source edits/build/Sileo release/device tests this continuation.**