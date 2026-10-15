# DuoFace picker UI changes — compile-only checkpoint (2026-10-15)

## Owner constraints / task lock
- Repository: `chuongnguyen89dn-ui/Duoface`, branch `main`. Only menu/picker visual changes authorized; original native Zoom callback, mode callbacks, picker X and split-screen red activity border must remain intact.
- **DO NOT BUILD A DEB OR DEPLOY TO SILEO** until the owner separately asks and has first been shown a complete change list.
- Approved menu row height: 30pt. Horizontal DuoFace logo is inline. Accent from approved asset: #E3020F.
- Live menu must have *transparent sheet and backdrop*, showing the active CarPlay content behind; hide picker outline and separator, NOT split-pane activity border.
- Rename visible titles Zoom In/Zoom Out -> Zoom; Close App -> Close. SF arrow direction still tracks existing expanded state. Change Add App tile glyph `plus` -> `ellipsis` ONLY, retain native `addMoreAppsTapped:` action.
- Two Mở lại buttons and Cột Trái/Phải labels: user requested origin tracing but has NOT supplied replacement words. Do not invent labels or alter native restart actions.

## Evidence confirmed from unchanged v12 DEB
- Source: `dist/visual-1.0.3-12/com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb`, SHA256 `8b7dedf77b9ec05465b83fdb6e2d7127800eac232a34ecf12f2c08b3983a481a`.
- `DuoFaceDashboard.dylib` SHA256 `bc1df854ec7a2ddfeec4cb81b080ead34b54df80143d4a8f6254bb8b618003ce`.
- Native picker class: `CBMultitaskingOverlayView`. Visual owners: `_dimBackground` at ivar 0x18; `_cardShadowContainer` 0x20; `_sheetCard` UIVisualEffectView 0x28, created via effectWithStyle at 0xA0830 / initWithEffect at 0xA0858, sheet layer border width 1 at 0xA0930. `_dimBackground` owns dismiss tap recognizer; never hide or set alpha zero.
- `setupAppPickerCardsInCardW:cardH:contentY:` 0xA3E5C, type `v40@0:8d16d24d32`: SF Symbol `plus` at 0xA5A0C and target `addMoreAppsTapped:` around 0xA57AC. `OVERLAY_ADD_APP` key at 0xA5B3C.
- `setupRecentAppsCardsInCardW:cardH:contentY:` 0xA678C, type `v40@0:8d16d24d32`; `OVERLAY_RESTART_SINGLE` 0xA761C; `restartSingleAppTapped:` type `v24@0:8@16`. Helper `0x85D58` called at `0xA7548` returns position label; `SLOT_LEFT_COL` at `0x85FAC`, `SLOT_RIGHT_COL` at `0x85E20`. No need to binary-patch UTF16 bytes.
- Verified UTF-16LE source offsets in full Dashboard file: `Cột Trái` 0x33F40C; `Cột Phải` 0x33F41E; `Mở lại` 0x33F856; `Thêm App` 0x33F864. Evidence: `audit/v12-picker-text-probe-20261014.txt`, `audit/v12-picker-targeted-controls-20261015.txt`, runs 38662323074, 38662510504, 38663850600.

## Source edits — NOT installed on device
- `runtime/fullscreen/DFPickerZoomMenu.xm`:
  - commit `78e66574c0f15e326f80ae1cc96fcf405e6bfebe`: method `DFClearNativePickerChrome` clears visual backgrounds/blur/card shadow/1pt border without removing dim tap recognizer, shortened tab titles.
  - commit `72bf44a81f8d0dd0bca4c2ec5a1879d14f54d662`: responsive spacing based on sheet width; 120pt logo slot, 30pt row, 48pt native X reserved; intrinsic tab widths [43,51,47,51]pt.
  - commit `734ab1cf34c69b5cfc20dd5db4e78e7617fc58ce`: `DFBuildingNativeAddTile` guard around native `setupAppPickerCardsInCardW:cardH:contentY:`; replace only SF `plus` with `ellipsis` during original card creation. Callback unmodified.
  - `785c4a55469733fe1a7df2d6c8aa18e37266429c` and `36a9d73eb44c034a485e28ea13ab82b5764bb719`: MENU-only transparent logo path, prefers `/var/jb/Library/Application Support/DuoFace/duoface-logo-picker-alpha-v2.png`, falls back to original if absent. Original logo/splash asset never overwritten.
- `src/DuoFaceBorderRunner.m` and native split focus/ratio are deliberately UNCHANGED.

## Logo audit, lossless source
- Original `dist/visual-1.0.3-12/assets/duoface-logo.png` approved RGBA 960x240, SHA256 `78450d8ee4759353bdc21f27a06016c03fab61038ae60109ba21515c087b0089`. Every original pixel opaque; its black box is part of source, not UIView background.
- First flood-fill alpha preview was REJECTED after checkerboard visual inspection: it damaged the dark face and metallic text; `scripts/duoface_picker_logo_alpha.py` retained only for diagnostic/history. Do not package `duoface-logo-picker-alpha.png` (v1).
- `scripts/duoface_picker_logo_grabcut.py` derives menu-only image from exact approved RGB pixels, protecting dark face. Latest candidate `dist/visual-1.0.3-12/assets/duoface-logo-picker-alpha-v2.png`. Visual inspection of `audit/duoface-picker-logo-grabcut-checkerboard.png` shows both faces and wordmark present with the outside background removed. It is still only an **alpha preview**, NOT physical-device verified.
- Source has no changes to approved original PNG. Future packaging MUST explicitly copy and hash-check `duoface-logo-picker-alpha-v2.png` to rootless support path; currently installed menu-compact1 DEB does not include this new asset.

## Verification (distinguish source vs build)
- Compile-only gate `38663820786` SUCCESS on `bdac48d123613e256a364df8cace9ecc7c75e43f`, report `audit/duoface-next-compile-bdac48d12361.json`: bridge and border hook compiled; `deb_built=false`, `sileo_published=false`.
- Compile-only gate `38664197991` SUCCESS on `785c4a55469733fe1a7df2d6c8aa18e37266429c` (after menu-only asset loader); `DuoFace fullscreen adapter compile check` `38664197995` SUCCESS.
- Static geometry report `audit/duoface-picker-layout-sanity-20261015.json`: menu/X spacing safe by formulas on 360–720pt; 350pt falls back to native. This is NOT touch validation on CarPlay.
- Static v12 picker audit `38664702825` SUCCESS and generated menu-only alpha-v2 PNG, report `audit/duoface-picker-logo-grabcut-report.json`.
- Latest compile on source `36a9d73e...`: workflow run `38664724807` was queued/in progress at checkpoint; MUST refresh before claiming PASS.
- CI conflict encountered in old compile job `38663625399`: source compilation and markers passed, but Git rebase conflicted on single shared report JSON. Fixed at `bdac48d...` to save per-commit report `audit/duoface-next-compile-<sha12>.json`. Do not call old run a compiler failure.
- No new DEB, no Sileo publish and no physical device pass in this work.

## Before any authorized DEB build
1. Recap EVERY UI/source change above and ask owner to confirm build.
2. Update manual-only `.github/workflows/duoface-approved-border-deb.yml` to **new, collision-free** candidate version/path (existing `menu-compact1` output already exists). Update outdated mandatory literal `Close App` binary marker to correct `Close`; verify `Zoom`.
3. Copy/hash-verify menu-only `duoface-logo-picker-alpha-v2.png` into `$ROOT/var/jb/Library/Application Support/DuoFace/`; preserve original PNG and native Dashboard.
4. Keep existing rootless package identity and functions; do not modify the red activity border, split ratio, Zoom action, restart or add-app callback.
5. When explicitly approved, run ONE packaging workflow, inspect full Actions logs, package contents/metadata/checksum and GitHub-persisted artifact; then separate optional Sileo release approval.
6. User must device-test transparent sheet visibility, white/dark logo faces, evenly spaced tabs, native X dismiss, ellipsis Add App, both Mở lại and native red border before claiming UI success.

## Execution checkpoint
- Active repo: `chuongnguyen89dn-ui/Duoface`, `main`; no local working tree used.
- Exact code outputs: source and script commits above, CI reports and alpha-v2 candidate paths.
- Next action: verify latest compile gate `38664724807`, re-read current script/image SHA, checkpoint `tiep tuc du an.md`; ask for desired replacement *words* for Mở lại / Cột Trái / Cột Phải only if the user wants them renamed. No DEB now.


## Final compile-only readback (after the checkpoint was drafted)
- GitHub Actions run **38664724807** `https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38664724807` completed **SUCCESS**, including source compile, visual hook compile and persist evidence. Source commit: `36a9d73eb44c034a485e28ea13ab82b5764bb719`.
- Exact report `audit/duoface-next-compile-36a9d73eb44c.json`: `status=COMPILE_ONLY_SUCCESS_NOT_DEVICE_PASS`, bridge SHA256 `b58a3a6e6c3829d0e6642410158d95ccf389c11f8d4c9c70484a3ac1c76f051a`, visual SHA256 `692d1ecfe9e2753cfd9a5a13b4382653fd121525da3752e058def990c18c8d0d`, `deb_built=false`, `sileo_published=false`.
- Supporting fullscreen adapter compile run `38664724740` also completed SUCCESS. This closes the previously pending compile verification. It does NOT establish on-device CarPlay UI correctness.
