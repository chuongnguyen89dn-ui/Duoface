# DuoFace v12 — focused picker text, + tile, transparency evidence (2026-10-15)

## Status / scope
- CONFIRMED: targeted READ-ONLY audits against unchanged v12 `DuoFaceDashboard.dylib`, SHA256 `bc1df854ec7a2ddfeec4cb81b080ead34b54df80143d4a8f6254bb8b618003ce`, from `dist/visual-1.0.3-12/com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb`, SHA256 `8b7dedf77b9ec05465b83fdb6e2d7127800eac232a34ecf12f2c08b3983a481a`.
- Latest user decision: make entire picker sheet background transparent so live CarPlay behind remains visible; retain controls/touch and native X. No border around picker; do not change completed red split-pane interaction border.
- No DEB build or Sileo without a **fresh explicit instruction**; before any future DEB build list all intended edits. Do not change Zoom mechanism, Close callback, picker choices, or app restart functionality.
- Central skill ZIPs `skills/01-github-continuity.zip`, `skills/02-ios-deb-ipa-carplay.zip`, `skills/05-research-debug-testing.zip` read directly from Gpt-training- via GitHub base64, decompressed, and their SKILL.md checked. Training repo not modified.

## Exact Vietnamese label evidence — file offsets, not ARM64 IMPs
Read-only `scripts/v12_picker_text_probe.py` now searches targeted labels (commit `1913b470e10bff4afde495aa4565de0e2ccb532a`). CI run `38662323074` completed success and wrote `audit/v12-picker-text-probe-20261014.txt` (existing filename retained).
- `DuoFaceDashboard.dylib` full-DEB-member UTF-16LE offsets: `Cột Trái` `0x33f40c`; `Cột Phải` `0x33f41e`; `Mở lại` `0x33f856`; `Thêm App` `0x33f864`; `Đóng tất cả` `0x33f82c`. Also `Đang hoạt động` `0x33f7b2`.
- `DuoFaceUI.app/DuoFaceUI` offsets: `Cột Trái` `0xe57d2`; `Cột Phải` `0xe57e4`; `Mở lại` `0xe5c1c`; `Thêm App` `0xe5c2a`; `Đóng tất cả` `0xe5bf2`.
- Localization class `CBLocalization` contains `+localizedStringForKey:` IMP `0x8974` and `-localizedStringForKey:` `0x89f8`; its `_viTable` ivar is offset `0x20`. Confirmed from workflow run `38662679428`. References of CFString keys in Dashboard ARM64: `OVERLAY_ADD_APP` `0x3491e8`, `OVERLAY_RESTART_SINGLE` `0x3491a8`, `OVERLAY_CLOSE_SINGLE` `0x349168`, `OVERLAY_CLOSE_ALL` `0x349128`; see `audit/v12-picker-text-probe-20261014.txt`.
- The exact key mapping for `Cột Trái/Cột Phải` is NOT yet extracted; do not invent `OVERLAY_LEFT/RIGHT` keys. Static `CBLocalization` method audit `audit/v12-picker-localization-table-20261015.txt` from run `38662750949` is available; contains no direct annotated Vietnamese strings in the traced method ranges.

## Native button renderer/action — confirmed from ARM64
`audit/v12-picker-targeted-controls-20261015.txt` and filtered `audit/v12-picker-targeted-extract-20261015.txt`, CI run `38662510504` success:
- App tile grid: `-[CBMultitaskingOverlayView setupAppPickerCardsInCardW:cardH:contentY:]` IMP `0xa3e5c`.
- `+ Thêm App`: target/action setup loads selector `addMoreAppsTapped:` at `0xa57ac`, and `UIImage systemImageNamed:withConfiguration:` with `NSString 'plus'` at `0xa5a0c`, then sends `setImage:` to an `UIImageView` at `0xa5a28`. Text via `CBLocalization.localizedStringForKey: OVERLAY_ADD_APP` at `0xa5b2c-0xa5b60`. Safe visual-only candidate: replace this `plus` glyph with SF Symbol `ellipsis` on the exact tile icon, retaining action and hit region. No runtime patch/device validation yet.
- Recent list: `-[CBMultitaskingOverlayView setupRecentAppsCardsInCardW:cardH:contentY:]` IMP `0xa678c`; action `restartSingleAppTapped:` loaded `0xa6fe0`; `OVERLAY_RESTART_SINGLE` key `0xa761c`, `OVERLAY_CLOSE_SINGLE` key `0xa7734`; `inActiveSlot`, `slotIndex` keys at `0xa70dc`, `0xa7110`. Native action selectors must remain unchanged. New labels for Mở lại / Cột Trái / Cột Phải NOT chosen by user yet; research only.

## Transparent picker sheet — owner and exact failure
`CBMultitaskingOverlayView` `initWithFrame:` IMP `0xa0420` builds:
- `_dimBackground` ivar `0x18`; background black/alpha created near `0xa05d4-0xa0610` and has dismiss gesture `dismissOverlay` attached around `0xa063c-0xa0664`. **Do not hide/remove this view** or its recognizer; set only its visual background clear when implementing transparency.
- `_cardShadowContainer` ivar `0x20` has shadow color/opacity/radius (radius 26) around `0xa06d8-0xa07a0`; clear visual shadow, preserve hierarchy.
- `_sheetCard` ivar `0x28` is `UIVisualEffectView`; blur effect built `effectWithStyle:` `0xa0830`, `initWithEffect:` `0xa0858`, corner radius 20 at `0xa0898`, **border width 1.0** at `0xa0930-0xa093c`. Clearing only `overlay.layer.borderWidth` / `contentView.layer.borderWidth` in current `runtime/fullscreen/DFPickerZoomMenu.xm` cannot remove this actual native border/blur. Exact fix needs clear effect/background and sheet layer border, preserving card's contentView and click hierarchy, plus test on device. Rounded geometry can be retained if desired while border removed.
- Other backgrounds (per-app cards, tile labels, running-app rows) are separately set within grid/recent renderer; transparent sheet alone does not guarantee every tile becomes transparent. Preserve readability before choosing alpha values. Split-pane border code is OUT OF SCOPE.

## Horizontal logo black-box verified (read only)
File `dist/visual-1.0.3-12/assets/duoface-logo.png`: 960×240 PNG RGBA, 230,400 pixels **all alpha=255** (0 fully transparent), 187,635 visually black pixels (<24 RGB) and all opaque. Four corners are `RGBA(0,0,0,255)`. Verified by decoding GitHub PNG bytes, zlib/PNG scanlines and alpha pixel counts; original in repo unchanged. This conclusively explains the black rectangular logo background shown on user's device. Needs menu-only transparent artwork preserving white/black face content and slogan; do not blindly mask all black (would erase logo's dark face), nor overwrite approved original used elsewhere.

## Verification and next action
- Read-only CI runs success: `38662323074` (Vietnamese string scan), `38662510504` (targeted control chain), `38662679428` (CBLocalization metadata), `38662750949` (localization method disassembly). Audits are static only. They **did not build DEB** and do not prove runtime behavior.
- User's installed compact picker test corresponds to earlier manually triggered build run `38659711965` SUCCESS (GitHub jobs), but installed file hash/version has NOT been independently mapped to that run. No new DEB triggered here.
- Next edits only after retaining exact owners: (1) remove native picker card border+blur+dim visual but preserve dim tap recognizer, (2) visual-only `plus`→`ellipsis`, (3) Zoom/Close visible titles and balanced spacing, (4) separate transparent menu logo asset, (5) investigate row labels and request desired replacement wording if/when needed. Source code remains unchanged in this investigation; compile-only may be run before any separately authorized DEB.
