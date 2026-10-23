# Kiểm kê MENU / APP chooser DuoFace Native12 gốc (23/10/2026)

**Yêu cầu người dùng:** kiểm kê tại đây, KHÔNG sửa giao diện/code/binary, không build hoặc phát hành. Chỉ đối chiếu chính DEB Native12/SPEED8 gốc và độc lập 0.0.41.

## Nguồn (mức xác thực)

- Repo `chuongnguyen89dn-ui/Duoface`, branch `feature/duoface-jb-embedded-appbridge-20261020`.
- DEB gốc bất biến `dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb` @ `1286a3ef868cf7e29804bcddf7e20b2eae707ce1`; SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`, Dashboard Mach-O SHA256 `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`.
- **Directly READ original SHA-pinned extracted ARM64 evidence in this turn, not freshly re-extracted .deb:** `sideplay/audit/native12-continuation-4888299/original-picker-close-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json` blob `2a8b03008c8ebb2b40d42d43a68846d08bf5c9c1`, 14 method IMPs / 6289 ARM64 instructions; `sideplay/audit/native12-continuation-96fa4ec/CARD_HEADER_LITERALS.json` blob `6e542e99ae2513523ae37f973155e0ae59f4d449`; original geometry `outer-constants/ORIGINAL_OUTER_LAYOUT_CONSTANTS.json` blob `9ef724be1ecdc4ab56ca6c2cd53c34cd74f6a9a6`; original tab visual provenance `docs/duoface-v12-picker-style-20261014.md` (earlier visual v12 DEB different SHA; do not conflate with immutable Speed8 source), `03_ORIGINAL_HEADER_TABS_AUDIT.md`, `05_ORIGINAL_APP_RECENT_CLOSE_CROSSWALK.md`, `01_STYLE_CARD_AUDIT.md`.
- Independent actual source: `sideplay/duoface-native-scene-host/DFAppPickerVC.m` blob `bf0a90d2fab6b9a634ea47d8ea825208e0279309`; `DFNative12Chrome.m` current implementation, `DFNative12CardHeaderGeometry.h` and `DFNative12OuterGeometry.h`.
- Static binary constants/callsite proven; physical PNG screenshot/pixel colors and UIKit runtime effects **NOT** independently verified on current iPhone. Gpt-training- SKILL_INDEX/DEB_IPA_SKILL read; central ZIP was not decoded during this turn.

## A. Phân biệt hai tầng menu (không gộp bừa)

1. **Outer strip/pill / contextual command menu** in current independent `DFNative12Chrome.m`: `App | Zoom | Style | Close` + separate X. Current source has 30pt high action labels, nominal widths `43/51/47/51` × scale, popup width `min(470,max(180,contentW-16))`, height currently uses header 32/38, `UIBlurEffectStyleSystemMaterialDark`, logo PNG `duoface-logo-picker-alpha-v2`. **These precise 4 button widths, outer black blur tone and 30pt height are SOURCE IMPLEMENTATION values, NOT proven SHA-bound original Native12 byte values.** Need original owner method/pixel capture before claiming parity.
2. **Original SHA-proven inner `CBMultitaskingOverlayView` chooser:** THREE tabs (not four): `TAB_APPS` = **Ứng dụng**, `TAB_LAYOUT` = **Bố cục**, `TAB_RECENT` = **Đang mở**. Original calls `setupCardContent` @`0xA2A58`, callbacks `switchToAppPickerMode`, `switchToLayoutChooserMode`, `switchToRecentMode`. Separate `xmark` only dismisses overlay, does not close any app. UI mode images `square.grid.2x2.fill`, `rectangle.split.2x1.fill`, `app.badge.fill`. Independent picker currently shows English labels `Apps/Layout/Recent`, unrelated to original Vietnamese localization.
3. **Picker uses actual installed/active app records** and a real mode callback, not invented/demo tiles; original `appSelected:` @`0xA9EA8` persists a target slot's `bundleIdentifier`, conditionally `swapSlot:withSlot:` or `replaceAppInSlot:withBundleIdentifier:`, closes picker. `showAppPickerForSlot:parentView:` @`0xAA800` loads apps and spring-animates overlay; independent direct UIWindow visibility is not this exact original animation.

## B. Exact original outer card frame (pt, points; not device pixels)

`CBMultitaskingOverlayView.layoutSubviews` @`0xA28E8`:

- Given host bounds W×H, width: `min(W - (W < 500 ? 10 : 24), 680)`; height `min(H - (H < 300 ? 8 : 18),380)`. Origin centrally rounded `roundf((W-cardW)/2)`, `roundf((H-cardH)/2)`. No arbitrary 470×220 or 480×330 cap for this **inner** original menu.
- Header `32pt` if cardH <260; otherwise `38pt`. Body starts at `headerH+.5pt`: **32.5 or 38.5pt**; separator white alpha .12 and height .5.
- Header icon **18×18pt**, x14, y=(headerH−18)/2. Title x36, y=(headerH−20)/2, height20; width=max(cardW−tabZone−74,80). Original short/tall font evidence ~**11.5/13pt**.
- Tab strip zone **190pt when cardW<440**, otherwise **210pt**; frame x=cardW−36−zone, y4/5, h24/28. 3 child tabs w=floor((zone−4)/3): 62pt at zone190, 68pt at zone210; third takes remainder. Tab font short/tall **10/11pt**. X button **24×24** @ (W−32,4) in short; **26×26** @ (W−34,6) tall, background RGBA(.18,.18,.22,.9), cornerRadius12/13. X is *not* `Close` app.
- Computed example **only if** content region W=462,H=240: original card **452×232** at x5,y4; header32, contentY32.5; blue/tab zone210 wide, tab button widths68,68,71 in their own strip; X24. This is a formula example, NOT an observed on-device screenshot.

## C. Original palette / colors (byte evidence only where marked)

| Element | Verified source state | RGBA / approximate HEX | Evidence |
|---|---|---|---|
| Inner selected Apps/Layout/Recent tab | blue background + white text | (0.08,0.52,1,1) ≈ **#1485FF** | ARM64 `setupCardContent` @a362c/a386c/a3b58; VM311720/311728 |
| Inner inactive tab | **clear background**, light gray text | white .68 → **#ADADAD** alpha1 | Original visual v12 selector callsite @a392c/a3c28, `docs/duoface-v12-picker-style-20261014.md`; exact Speed8-compact mode should still be pixel checked; do not assert current source matches |
| Header separator | white at alpha **0.12** | white/12% | original constant VM310cd0, IMP setupCardContent |
| Dismiss X background | dark charcoal, alpha .9 | (.18,.18,.22,.9) ≈ #2E2E38 | original setupCardContent (notes `02_HEADER_CONTENTY_AUDIT.md`) |
| Original app pages dots | inactive white alpha**.25**, active full white | white 25% / #FFFFFF | original setupAppPicker @a42fc..a4354 |
| Recent running CLOSE ALL | red background | (.88,.18,.22,.95) ≈ **#E02E38** | original `setupRecentAppsCards` @a6ab4..a6ad8, SHA literals 30fab8/30fac0/311730/30faf8 |
| Style selected card | dark blue bg, bright blue border 2pt | bg(.04,.20,.45,.95) ~#0A3373; border(.12,.58,1,1) ~#1F94FF | original @a5e78, audit `01_STYLE_CARD_AUDIT.md` |
| Style unselected card | dark neutral bg, white border 1pt | bg(.14,.15,.19,.95) ~#242630, border white alpha .18 | original @a5e78 |
| Style check badge | white+blue, black shadow | 17×17pt, shadow radius3 opacity .45 | exact original a6174/a666c/a6670; badge x=cardW−21, y4 |
| App card **body** background/opacity/radius | **not fully decoded/verified** in original picker implementation | **UNKNOWN**; do not copy independent app card .19/.96 as “original” | AppPicker @a3e5c has button and border selectors; requires ABI/dataflow/pixel proof |
| Entire inner modal blur/background/shadow/alpha | **not yet exactly byte-verified / device captured** | **UNKNOWN**. Existing independent black 95% and sheet white10% are NOT proof of original. | Need original `CBMultitaskingOverlayView.initWithFrame:@0xa0420` and device pixels |
| Outer 4-action menu strip exact colors/button widths | **not yet original-byte verified** | UNKNOWN original; current uses materialDark + 43/51/47/51pt. | Don't mistake current implementation for original |

## D. App picker app cards — original behavior and sizes

- Original method `CBMultitaskingOverlayView.setupAppPickerCardsInCardW:cardH:contentY:` @`0xA3E5C` uses `CBDashboardSettings.gridCols` @a40b4, `gridRows` @a40d4 and `hideIconLabels` @a40f4, a4118; `CBOverlayScrollView` horizontal paging @a41c4..a41cc; `UIPageControl`.
- **New concrete correction to old audit's “max4 columns”:** original ARM64 `a40c0–a40cc` is `sub x8,x0,#4; cmp x8,#2; mov w8,#4; csel x19,x8,x0,hi`. Therefore `gridCols=4,5,6` is preserved and other values fallback **4**; `a43dc` also has explicit 6-column gutter branch. It is **not hard-capped at four columns**. Historical default/settings may be 4 columns ×2 rows but needs settings read. Independent `DFAppPickerVC.sizeForItem` ALWAYS uses `width/4`, capacity8, thus missing original configurable 5/6 columns. `gridRows` reads settings and has default/branch2; do not assert arbitrary row value without full range proof.
- Original per-cell geometry is CALCULATED responsively using content size/row/col spacing and `hideIconLabels`; exact image size/border/style on a 427×240 or 507×240 device has NOT been fully recovered from assembly's register-liveness/pixel measurement, so **do not invent one permanent icon size**. Original body has true per-app `icon`, `displayName`, `bundleIdentifier`; `UIButton` selection and badge variants `checkmark.circle.fill` @a52e0, `arrow.left.arrow.right.circle.fill` @a542c tied to active/same-app slot conditions, not arbitrary decorative assets.
- Original zero-app screen uses `square.stack.3d.up.slash` @a45ac, `NO_APPS_TITLE/DESC`, original `plus` add-app action @a5a0c / `OVERLAY_ADD_APP` @a5b3c.
- Original `appSelected:` @a9ea8 owns slot/bundle processing and `saveSlotIndex:bid:toSettings:prefs:`, `swapSlot:withSlot:`, `onMultiSplitSelected`, `replaceAppInSlot:withBundleIdentifier:`. Independent delegates to DFSceneHost create/replace of only owned scenes; does NOT claim full original scene admission/pid handling.

## E. Recent & Style actual contents

- **Recent** original @`0xA678C`: `CBBridgeManager.runningBridgedApplications`, real `bundleIdentifier/displayName/icon/inActiveSlot/slotIndex/pid`, count indicator `OVERLAY_ACTIVE_COUNT`, `OVERLAY_NO_ACTIVE`, Close All `OVERLAY_CLOSE_ALL` (red), per item Restart `OVERLAY_RESTART_SINGLE`, Close `OVERLAY_CLOSE_SINGLE`, running/background/PID tags, empty symbol `checkmark.shield.fill`, title/description keys `OVERLAY_ALL_CLOSED_TITLE/DESC`. Original close/restart terminate/restart **OS bridged process** via bridge manager; new independent only releases/rehosts owned UI scenes, so functionality not the same.
- **Style/Layout** original @`0xA5E78`: **9** selection cards (not 8), row tile height **66pt**, top **22pt**, row stride **78pt**, horizontal gap10/inset14, switch **5 or 6 columns** at width560, thumbnail height**54pt** y6, continuous round corner12, original raster helper @0x9efe0. Exact 9 thumbnail pixels/region shapes still pending device diff; cannot falsely say exact. Current independent `DFNative12Chrome.m` has 9 choices and Style view but not pixel verified.

## F. Current .41 crosswalk — where exact original is already present and where it isn't

| Feature | Original status | Current independent source | Mismatch remaining |
|---|---|---|---|
| Two menu layers | Original inner Apps/Layout/Recent SHA-proven; outer per-pane control different owner | per-pane App/Zoom/Style/Close + separate Apps/Layout/Recent | Don't claim current outer widths/material equals original |
| Blue selected tab | original .08/.52/1 | .08/.52/1 in DFAppPickerVC | Source parity only |
| **Inactive tab color** | original visual v12 .68 white, clear BG | **always white** titleColor in `updateNativeModeButtons` | **Explicit color regression:** needs original exact-current DEB check before applying |
| Header icon/title/tab/X geometry | original 18, 32/38, 190/210, 24/26 | `DFOriginalCardHeader` used | Static formula present, runtime window content region unknown |
| App tiles | original gridCols settings support4/5/6, gridRows, hideIconLabels | hardcoded 4cols×2rows, title always displayed | Major verified behavior gap; default may look similar but options differ |
| App tile badges | original active/swap markers at a52e0/a542c | current `DFNativeAppCard` icon+title, no badges | Missing original conditional glyph states |
| Installed apps icon/name | original real records | independent real `DFAppLibrary.installedUserApps`, original-icon attempt via private UIImage method | Source semantics similar, exact filtering/order/icon size not proven |
| Paging dots | original white alpha.25 / white | matches .25/white | Static source parity |
| Empty-app plus CTA | original plus and OVERLAY_ADD_APP | no explicit add-app card in current UICollectionView | Missing original distinct CTA |
| Running/recent data | original bridge PID and running slot status | independent owned ready scene bundleIDs only | Does not show PID/background or all original bridged processes |
| Running Close/Restart | OS terminate/restart | release/re-host scene | Functional difference |
| Outer button/row | original bytes not yet verified | 30pt high; button widths43/51/47/51 and materialDark | **Do not call identical** |
| Actual full modal background | original pixel/blur color unknown | `self.view=black alpha.95`, `self.sheet=white.10`, radius20, white stroke .25 | Not original-verified |
| Independent installed app tile styling | original not fully decoded | BG white.19 alpha.96; corner14; max icon43pt; label11pt; current card may vary | **CURRENT ONLY**, never label as original visual |

## To close remaining original byte-proof and device gates

1. Read-only decode of original `CBMultitaskingOverlayView.initWithFrame:` IMP @`0xA0420` to establish actual modal opacity/blur/shadow and card backing colors; main repo already has SHA-locked DEB and prior CI scripts, reuse them. Do not invent static app tile RGB if not traced.
2. More precise original `setupAppPickerCards @0xA43DC..0xA5D18` dataflow into tile width/height/icon/badge offsets; test with 4,5,6 cols and both hideIconLabels modes. Compare with current UIKit implementation.
3. Obtain pixel-grounded original screenshots for at least 427×240 and 507×240 (or actual CarPlay viewport) so active app badge, app card icon size, alpha and outer 4-action strip can be tested.
4. Only AFTER verification and explicit further user request should change menu code, then source tests / signed one rootless DEB / on-device visual comparison / Sileo separate publication.

**Actual work this turn:** GitHub source/handoff/index/archived disassembly READ; source-level audit/inventory and new corrected interpretation of 4–6 original gridCols. **No source code edits, no compile, no DEB or Sileo changes.**
