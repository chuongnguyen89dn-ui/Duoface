# DuoFace #3/#4: strict CarPlay app allowlist, configurable picker and Add More

Date: 2026-10-29. Repository: `chuongnguyen89dn-ui/Duoface`.
Active branch: `feature/duoface-jb-embedded-appbridge-20261020`.

## User request and source audit before changes

1. In-car app listing must show **only installed apps the user allows from the iPhone**, with categories and sorting. Existing app picker was too broad.
2. App picker must support **4/5/6 columns**, **number of rows**, **hide app names**, and an **Add More** action. The previous picker was fixed 4×2 and always displayed titles.
3. No reverting to iPhone fixed "left/right/slot 1–4" assignment. Preset layouts and actual selected scenes are separate from preferences. Default/pinned/usage preference #2 stays intact.
4. Do NOT release Sileo until user explicitly asks.

### Verified existing implementation / root cause

- `DFEnabledAppsPolicy.h` previously returned `nil` for unconfigured preferences and `DFPickerAllowsApp` interpreted `nil` as **all eligible apps**, which explained the unexpectedly broad CarPlay list. iPhone `DFNativeHostRootController.m` also interpreted `nil` as all selected. This was a deliberately permissive .92/.94 migration; **the new user requirement supersedes it**.
- `DFAppPickerVC.m` enumerates real installed apps via `DFAppLibrary` and filters through `DFPickerAllowsApp` but used a fixed `4 x 2` layout, always visible labels, and lacked a true add-more tile.
- `DFNative12Chrome.m` is the existing scene and slot owner. This task does not assign slots, rebind Maps, modify YouTube orientation or change the native Dock.
- Read-only DEB evidence already in `docs/duoface-vs-duodash-app-selection-iphone-carplay-20261016.md`, `docs/duoface-v12-picker-focus-audit-20261015.md`: original native12 `CBMultitaskingOverlayView.addMoreAppsTapped:` and `OVERLAY_ADD_APP` were found at selector/callsite level, and original binary configuration referenced `gridCols/gridRows` 4/5/6 columns and 2/3 rows. **A selector and visual tile alone do not prove proprietary add-more persistence or runtime callbacks.** This independent feature is not claimed to use an extracted original implementation.

### Own changes committed

- `DFEnabledAppsPolicy.h`: an absent allowlist remains distinguishable from explicitly empty at storage layer but the runtime picker now treats BOTH as **no approved apps**; only explicit valid enabled IDs appear. `DFNativeHostRootController.m` phone switches and groups use the same strict behavior, and first toggled-on app initializes a single-app allowlist rather than silently enabling everything. Users can still choose "Bật đề xuất", "Bật tất cả", "Tắt tất cả" on the phone. Existing settings already written remain preserved.
- `DFAppPickerDisplayPolicy.h`: independent versioned prefs `com.duoface.nativehost.picker-display.v1.plist`: grid columns in 4–6, rows 2–3 and show/hide app names; defaults 4×2, names visible. Atomic write+readback and Darwin notification.
- `DFNativeHostRootController.m`: adds **Ứng dụng → Giao diện chọn App** configuration sheet on iPhone. This changes only in-car app list UI, not the nine pane layouts.
- `DFAppPickerVC.m`: real per-page capacity, dynamic 4/5/6 columns and 2/3 rows, app-name visibility, and live reload on settings notification. Existing **Đang mở** page retains independent 4×1 live-scene cards and controls. A footer category menu filters already permitted app IDs into **Tất cả / Ưa dùng / Người dùng / Hệ thống**; ranking within group retains explicit default, favorites and confirmed usage.
- `DFAppPickerVC.m`: **Thêm App** tile opens a separate inventory of actual installed **not-yet-approved** eligible apps. A deliberate tap persists that specific app into the SAME iPhone allowlist, readback and notify before returning; no automatic app launch or scene replacement. The primary app grid continues to show **only permitted apps**. This is an independently designed functional extension, not a claim original native12 could add directly from CarPlay.
- Changed source does not copy vendor binaries, license or proprietary source.

### QA and release policy

Test sources `tests/picker_display_runtime.m` (Foundation executable), `tests/test_picker_display_097.py` (source regression), amended `tests/enabled_apps_policy_runtime.m`, and `.github/workflows/duoface-native12-source-only-validation.yml`; dedicated real macOS/iOS16 workflow `.github/workflows/duoface-097-picker-smoke.yml` writes immutable run result and appends checkpoint to existing `sideplay/tiep tuc du an.md`. Check workflow and file readback; **do not claim PASS before jobs succeed**.

Physical regression still REQUIRED: iPhone X rootless / CarPlay, missing vs explicitly empty vs selected allowlist, 4×2 to 6×3 paging, hiding names and accessible app labels, Add More success/failure, pinned/default/habit ordering, no changes to .90 YouTube orientation, .92 logo 3-second move, Apple system Dock, experimental native Maps. No new signed DEB and no Sileo publication in this source-only stage.

## Verified regression corrections and source QA results (2026-10-29)

1. First independent CI `40797121734` failed because historical `test_logo_092_exact_regression.py` found a .96 usage-counter change in `DFNative12Chrome.m`, altering its immutable .92 source hash. Restored exact .92 Chrome (blob `367689325f6ff84d8d258ff9891ec85338a7d647`) at `7ba2f5e5`; moved usage count into `DFSceneHost.m` **after the actual scene ready gate** at `6ce7a3c`; updated tests. This prevents breaking the user's 3-second logo implementation.
2. Runs `40797367518` and `40797487125` exposed two old regression assertions hardcoded to a fixed 4x2 grid, which contradicted the NEW user request for variable sizes. Updated only those obsolete assertions to check the original default is still 4x2, permitted sizes are 4x2 to 6x3, and running-app controls remain 4x1; commits `0f5eb1c` and `fea77c4`. Historical failed runs remain archived.
3. **Verified PASS** dedicated GitHub Actions [run 40797583585](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40797583585), source `fea77c40bbfbc1a41d2d2151fec9e4ebdcb57800`, job `123197691206`. Python source tests and regressions: **5 + 4 + 4 + 4 + 3 + 74 = 94 tests PASSED**; actual macOS Foundation executables `DF_PICKER_DISPLAY_RUNTIME_PASS`, `ENABLED_APPS_POLICY_RUNTIME_PASS`, `APP_HABITS_RUNTIME_PASS`, `DUOFACE_CATALOG_RUNTIME_PASS`; iOS16 arm64 SDK syntax check of phone root, CarPlay picker, original .92 Chrome, app library and scene host: PASS.
4. CI archived the run result and updated the existing handoff via GitHub commit `413a6c9043bf8c6158addb84b74c2c48e7efad1d`. Exact paths: `sideplay/audit/duoface-picker-097/ci/runs/40797583585.txt`, `sideplay/audit/duoface-picker-097/ci/LATEST_RESULT.txt`, `sideplay/tiep tuc du an.md`. Readback and push were logged `DF097_HANDOFF_READBACK_VERIFIED` / `DF097_GITHUB_HANDOFF_ARCHIVE_PASS`.
5. No new integrated DEB was signed, no Sileo publishing or live phone/CarPlay acceptance tests were run. This is **source-level + actual macOS compiler/runtime proof only**. Manual QA still needed for UIKit presentation of the Add More subview on CarPlay and touch/paging at 6×3 on the actual display. The existing nine pane layout presets, .90 YouTube orientation, .92 logo and native system Dock must be retested after any release.

Important nuance: "Đang mở" continues showing actually running SceneHost-owned apps even if a user subsequently disabled their visibility, so a user can explicitly close a live app. That is a lifecycle management list, **not** the approved-app launch picker. The launch picker is strictly filtered by iPhone approval.
