# DuoFace .94 — iPhone Apps Manager: cross-check DuoDash and OmniCar original

**Date:** 2026-10-29. **Repo:** chuongnguyen89dn-ui/Duoface, **branch:** feature/duoface-jb-embedded-appbridge-20261020.
**Latest user request:** implement FIRST the iPhone Apps Manager (per-app switches and Bật đề xuất/Bật tất cả/Tắt tất cả), using original OmniCar and DuoDash as references. This new request supersedes the old .93 rollback scope **only for this one feature**; do not restore unrelated .93 code. No vendor binaries/license.

## Directly verified prior binary evidence

- **Native12:** original SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`. Read-only original ARM64 extracts [run 40699487806](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40699487806), [run 40700551205](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40700551205). iPhone `CBAppsManagerViewController.appSwitchToggled:` invokes `CBAppManager.setApp:enabled:`; `showActionMenu` has Enable Recommended/All/Disable All; `enableAllUserApps` is associated with the recommended/user-installed action. CarPlay `CBMultitaskingOverlayView.appSelected:` chooses ONE app/ONE slot, not batch.
- **DuoDash 1.1.3:** DEB SHA256 `16ffab22b4246dea9978cae92df7ec635d833ec067b4d9f425a231b26edec601`, original metadata audit in `docs/duoface-vs-duodash-app-selection-iphone-carplay-20261016.md`. iPhone `DuoDashRootListController.chooseAppsToBridge:` opens `DuoDashAppPickerController`, whose `_readBridged` / `_enumerateApps` / `_persistAndNotify` manage selection. CarPlay picker displays the separate filtered `My Apps` catalog. Do NOT mistake CarPlay one-at-a-time selection for phone bulk enable.
- **OmniCar 1.0.3:** original SHA256 `d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd`. `chuongnguyen89dn-ui/Omnicar/audit/OmniCar_AppBridge_exact_scene_settings_and_layout_20261023.md` verifies ABHost scene size, owner, foreground/orientation. **No verified OmniCar iPhone app-manager toggle/bulk-enable/persist+notify handler in the existing original audit**. Thus no basis to claim OmniCar has the same settings UI. The DuoFace independent implementation follows proven Native12/DuoDash phone/settings separation instead.

## Implemented first-party source (commit d0477263fbe19ad287d8ee84ad74c0d86fd6fce3)

- `sideplay/duoface-native-scene-host/DFNativeHostRootController.m`: existing iPhone **Ứng dụng** tab now includes each eligible installed app's on/off switch, an action row with **Bật đề xuất**, **Bật tất cả**, **Tắt tất cả**, and tap-row switch handler. Action is user-triggered, not a fake UI control. Save errors alert and revert individual switches; does not close running scenes.
- `DFEnabledAppsPolicy.h`: first-party versioned plist `/var/mobile/Library/Preferences/com.duoface.nativehost.enabled-apps.v1.plist`, atomic write+readback and `notify_post` if successful. Missing prefs retain .92 legacy all-eligible behavior; explicit empty means no allowed apps; invalid existing prefs fail CLOSED. Policy still validates eligible IDs, and CarPlay only shows installed apps from `DFAppLibrary`.
- `DFAppPickerVC.m`: filters the existing **single bundle/slot** CarPlay picker, registers `notify_register_dispatch` to refresh upon iPhone changes, cancels observer on teardown. Do not modify Native12 Chrome slots, YouTube orientation, Maps, Dock or logo.
- "Bật đề xuất" is independently defined as installed eligible **non-Apple** user apps (the native original method is named `enableAllUserApps`); we are NOT claiming to have extracted an original proprietary recommender.

## Testing / acceptance gates

- `sideplay/duoface-native-scene-host/tests/enabled_apps_policy_runtime.m` macOS executable: missing vs explicit empty, malformed fail-closed, ID deduplication, system exclusions, recommended preset semantics.
- `sideplay/duoface-native-scene-host/tests/test_native12_phone_apps_manager_094.py`: source integration, UI handlers, one-app/slot, notify, ABI preservation.
- `.github/workflows/duoface-native12-source-only-validation.yml`: run above, syntax-check both UIKit owners with actual iOS16 SDK; source-only CI is not signed DEB or on-car proof.
- **DO NOT CLAIM BUILT/PUBLISHED/INSTALLED/TESTED ON CAR** without exact successful macOS package run, immutable package SHA, publisher and physical evidence.
- Next after green source tests: stage one NEW integrated rootless .94 candidate; publish through existing Sileo only after staging SHA verification. On parked vehicle test switches, all/none/recommended catalog, hot update, reconnect, running-scene preservation, Maps/YouTube, no crash.
