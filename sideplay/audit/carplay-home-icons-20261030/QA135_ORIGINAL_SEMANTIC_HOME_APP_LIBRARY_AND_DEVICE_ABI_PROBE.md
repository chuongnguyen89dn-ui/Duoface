# QA135: original DuoNavi / Native12 native Home application-library semantics and first-party ABI instrument

Date: 2026-10-30. Repository `chuongnguyen89dn-ui/Duoface`. Branch `feature/duoface-qa135-home-library-20261030`. User priority: **selected installed iPhone applications appear as real tappable icons in system CarPlay Home** (not merely the DuoFace pane picker).

## Grounded machine-code finding, stronger than class-name searches
Two SHA-pinned reference Dashboard dylibs extracted from real DEBs with source-independent read-only scanners:
- Original DuoNavi 1.0.4: DEB SHA256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`; Dashboard SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`.
- Native12-derived independent reference, **not pristine vendor stock**: DEB SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`; Dashboard SHA256 `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`.

CI [41088406250](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41088406250) **SUCCESS** bounded eight original ARM64 function bodies with LC_FUNCTION_STARTS; read-back evidence `original-deb-evidence/ORIGINAL_HOME_HOOK_ABI.json`:
- DuoNavi original library-hook registration `0x3106f4..0x310a50` (215 instructions), catalog merge `0x2f16bc..0x2f2130` (669), FBS policy/app info hook setup `0x2f2130..0x2f22a0` (92), launch policy replacement `0x2f2bdc..0x2f2ed0` (189).
- Native12-derived corresponding `0x2e9d48..0x2ea0a4` (215), `0x2ca974..0x2cb5c0` (787), `0x2cb5c0..0x2cb730` (92), `0x2cc0b0..0x2cc3a4` (189).

CI [41088923434](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41088923434) **SUCCESS** archived `original-deb-evidence/ORIGINAL_HOME_SEMANTIC_SELECTORS.json` (original PC-relative selector & CFString data-flow). Critically BOTH original binaries invoke distinct application-library and launch-policy concepts:
- **Home library registration:** `CARApplication` class + instance `_newApplicationLibrary`, Dashboard icon-manager `launchIcon:` overloads, Home view controller setup. Not the internal `CBMultitaskingOverlayView` picker.
- **Actual library update logic:** reads `bridgedApps`, `allInstalledApplications`; references `LSApplicationProxy` / `applicationProxyForIdentifier:`, `applicationInfoForBundleIdentifier:`, `addApplicationProxy:`, `addApplicationProxy:withOverrideURL:`, `removeApplicationProxy:`, plus `_notifyDidAddApplications:` / `_notifyDidRemoveApplications:`. Also references a `portalAppEnabled` feature and `carPlayDeclaration` metadata. These are *original ARM64 method references*, not guessed modern API names.
- **Native app info hooks:** `DBApplicationInfo _loadFromProxy:`, `CARApplicationInfo`, `FBSApplicationLibrary.allInstalledApplications`, `CRCarPlayAppPolicyEvaluator.effectivePolicyForAppDeclaration:`, `CRCarPlayAppDeclaration.declarationForAppProxy:`.
- **Launch policy:** `setLaunchUsingTemplateUI:`, `setCarPlaySupported:`, `setCanDisplayOnCarScreen:`, `setCanShowWhileLocked:`, `setLaunchAsCarApplication:` and native-vs-bridged guards. Do not copy any original implementation or vendor license; user requests an independent project.

**Interpretation:** Original integration is more than adding strings into a menu. It involves a genuine in-memory **FBS/CarPlay application library proxy + AppInfo + policy + icon tap**. The earlier report wrongly implied finding `CARApplication._newApplicationLibrary` alone would suffice. iOS16-specific availability of `CRCarPlayAppPolicyEvaluator` and precise selector type encodings remain unmeasured on user's 16.7.16 device, therefore **cannot safely rewrite its Home catalog before runtime ABI validation**.

## Actual QA135 first-party source changes
- `sideplay/duoface-native-scene-host/DFCarPlayHomeCatalogPolicy.h`: independent deterministic native-roster-preserving input policy `DFHomeBridgeBundleIDs` (only **installed ∩ explicitly enabled** and not already native), `DFHomeExpectedBundleIDs`. Does not rewrite native icons or pretend names are real CARApplicationInfo objects.
- `tests/carplay_home_catalog_policy_135.m`: 15 Objective-C/Foundation behavior cases including disabled, missing preference, native preservation, duplicate IDs, uninstalled/invalid app exclusion.
- `tests/test_carplay_home_abi_135.py`: source gates against accidental `method_setImplementation`, `MSHookMessageEx`, CarPlay icon layout updates, unsafe Home or SpringBoard modification in ABI measurement.
- `DFCarPlayHomeABIProbe.m`: bounded read-only three-sample runtime metadata logger for real SpringBoard and CarPlay processes; records actual class/instance method encodings, types, availability and selected-app count to `/var/mobile/Library/Logs/DuoFaceHomeCatalogABI.log`. Explicitly does **not** install hooks, add app proxies or start a CarPlay scene. No background upload; manual export via iPhone app `DFNativeDiagnostics.m`.
- `build.sh` compiles probe into the existing **SpringBoard input** and **CarPlay native Dock** receiver dylibs without altering QA134 owner, QA132 display BKS, QA128 GOFA geometry, QA90 orientation or QA92 divider source.
- Package proposal `com.duoface.jb.embedded 0.0.135~homeabi1` / native host `0.1.135~homeabi1` distinct from QA134. QA134 remains available as public Sileo rollback until separately published.

## Actually executed tests
- [CI 41088642869](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41088642869) **COMPLETED SUCCESS** on `macos-15`: real Foundation test executable 15 cases and real iOS16 ARM64 SDK syntax-only compile of Home catalog policy, plus forbidden-mutation source checks.
- New signed integrated QA135 workflow `.github/workflows/duoface-135-home-abi-signed-staging.yml`: use this run's real conclusion, not an assumed result. Initial source draft accidentally inherited QA134's branch-name change; corrected commit `2882e5b5139305af4fc003ece5a8576c980156fb`, triggering [signed build 41089867414](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41089867414). Signing/artifact/archival/Sileo/hardware must be verified independently.

## Blockers and exact next iteration
1. Install the exact newly signed integrated QA135 via Sileo once actually published; parked iPhone X iOS16.7.16 run with 1 selected non-native app, 1 real CarPlay native app; capture `DuoFaceHomeCatalogABI.log` from manual diagnostics. Check `CARApplication +/_newApplicationLibrary` actual type and `FBSApplicationLibrary` selectors; record absence too.
2. Implement the **first-party reversible real publisher**, scoped to existing validated `EnabledBundleIDs`, without changing native library data for other apps, with kill switch and original-first forwarding, and real library-object/launch-policy provenance. Native CarPlay apps remain Apple-managed.
3. Confirm icon appears on actual **system CarPlay Home**; tapping opens same selected installed app's live CarPlay scene, Home/Back native, no crash, Zoom/YouTube/GOFA/Dock/lock/reconnect no regression. A source test or signed DEB alone is NOT acceptance.

**Status: Original mechanism materially clarified and first-party policy/probe implemented; selected third-party Home icons not yet implemented or physically verified. This is a diagnostic incremental signed package, not a completed app-admission fix.**
