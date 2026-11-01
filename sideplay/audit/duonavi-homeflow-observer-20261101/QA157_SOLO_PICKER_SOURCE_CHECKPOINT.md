# QA157 — first-party SOLO bridge + original DuoNavi pill route (2026-11-01)

## Scope and source proof

User personally observed original DuoNavi 1.0.4 opening a non-CarPlay app with an accessible three-dot menu, consistent with an integrated bridge container. Original SHA-pinned ARM64: `CBBridgedSplitApp.initWithBundleIdentifier:frame:showSplash:` @0x109bc8 references multitaskingPill/setOnPillTapped and splitPreset; `layoutSplitViews` @0x10bad8 manages focus/compact and hosted scene; `CBBridgeManager.showAppPickerForSlot:` @0x2a2630 owns picker on manager/currentApp window. This is real static ABI evidence plus user device observation; exact gốc preset ONE remains unmeasured. See `SOLO_PILL_ORIGINAL_ROUTE_20261101.md`.

## What was ACTUALLY changed in this batch (correct DuoFace repo, not shared skill repo)

Branch: `feature/duoface-qa146-native-home-exit-20261031`. HEAD commit at report drafting: `6d657bbd4ae30a8a6f567b757358ab311d5e3656`.

1. `sideplay/duoface-native-scene-host/DFSoloPill157.h` (new). Attach a small source-owned three-dot menu and existing `DFAppPickerVC` as child views of SAME `DF144Solo` root. Original standalone `DFSceneHost.hostViewForBundleID` and `UIRootSceneWindow` remain the only scene/window owner; no second `SBAppViewController` or Native12 Chrome, no change to saved multi-split layout.
2. `DFSoloPickerCarPlay157.h` (new). Scope selection to verified current CarPlay Dock/bridge request OR a fresh, heartbeat-renewed SpringBoard SOLO Home chooser lease. Selected app request routes through existing `DF144BeginSelectedBridge` native dashboard prep + owner/ACK, not direct SB launcher. Unique `SelectionID` rejects duplicate Darwin deliveries.
3. `DFHomeStandalone144.m`. Wires above headers in appropriate compile roles; adds `homeChooser` mode. On genuine owned Home stop, releases only active remote scene but preserves source-owned picker, writes/renews exact request+display lease; does not rewrite global split preset. Normal cancellation/unsupported Home retains prior teardown. `DF144NativeHomeHandled` prevents a duplicate Home `viewDidAppear:` stop. `DF157NativeHomeCallbackObserved` is a **link-visible** C function in CarPlay TU.
4. `DFCarPlayOwnerObserver.h`. For actual CarPlay statusbar Home, invokes that linked function to synchronously revoke the exact active first-party Dock manager **before** forwarding Apple's unchanged original Home callback; posts the existing stop signal. Native Music/Calendar have no active first-party manager and are not converted to picker.
5. `DFNativeDockSync147.h`. If a real native app subsequently takes the Dock while first-party chooser remains visible, notify SpringBoard to remove chooser.
6. Regression: `tests/test_qa157_solo_owned_pill.py` new; `tests/test_qa153_phone_foreground_eviction.py` updated to keep exact phone-revoke test for either chooser or normal stop path; `.github/workflows/duoface-146-native-home-exit-private.yml` now includes new tests + file triggers.

## CI and known limitations

- Existing scope-only 41276042390 at commit `ac934d71...` SUCCESS; a later scope-only run is needed for final current HEAD.
- Two intermediate private runs at `e3ef1bee...` failed static `test_qa153_phone_foreground_eviction` because it hard-coded the old unconditional Home-stop string. Diagnostic from real GitHub job logs confirmed this, regression test was **updated to assert the new conditional owner** (not deleted).
- Current private signed build run on HEAD `6d657bbd4ae30a8a6f567b757358ab311d5e3656` = **41276138348**, in progress at last check. Scope run = **41276138222**, in progress. This is not a green-build claim.
- Integrated public 0.0.156~nativebridge4 was physically rejected for Home destination. Current build metadata still uses 0.0.156; do NOT overwrite or publish this version to existing Sileo until a new version, all tests and full archive checks pass.
- **Not physically validated**: menu visibility/touch, Safari app reselect, Home chooser page, Apple original Home interaction, external scene geometry/black screen, Music/Calendar protected. Theoretical navigation achieved in independent source is NOT a real-device PASS. No new Sileo publication.

## Next exact steps

1. Check run `41276138348` and scope run `41276138222` on final SHA. If fails: fetch offending job log, patch exact compiler/test assertion and rerun existing private CI; do not publish or ask user to test rejected .156 again.
2. Verify no second Home `viewDidAppear:` destroys the chooser, lease cannot outlive current CarPlay owner, native-app switch closes overlay, picker app selection goes through same signed Dock ACK, no double scene host/forged state.
3. If green, update **existing package** version/control/Info/plist/packaging+workflow to `0.0.157~solopicker1` (nativehost subpackage appropriately), generate signed artifact/inspect dpkg files, keep existing source publisher in `chuongnguyen89dn-ui/carplaydsp`. Publish only confirmed version to same Sileo and then request physical QA. No new Sileo repository.
4. Physical acceptance: pick Safari in CarPlay Home -> visible 3-dot; tap -> real picker; choose another enabled app -> rehost and correct Dock; Home -> shows picker rather than generic Home; native Music/Calendar original Home and Dock unaffected; no crash/black screen/locked-touch regression.
