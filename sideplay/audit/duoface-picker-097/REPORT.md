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
