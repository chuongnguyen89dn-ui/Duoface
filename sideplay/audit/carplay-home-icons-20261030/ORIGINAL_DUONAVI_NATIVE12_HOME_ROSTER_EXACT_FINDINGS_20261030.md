# 2026-10-30 — REAL DuoNavi 1.0.4 and Native12-derived DEBs: CarPlay Home app admission, NOT merely in-app picker

## Main new finding
The original binary investigation **does identify a relevant Apple CarPlay Home app-library integration route that our earlier DuoFace gap reports overlooked**: original Dashboard tweak code references `CARApplication` and **`_newApplicationLibrary`**, has original logging for both class and instance library methods, references **`DBApplicationInfo`**, **`CARApplicationInfo`**, and `setLaunchAsCarApplication:`, plus reads the configured `bridgedApps` and `allInstalledApplications`. These distinct paths exist in BOTH examined builds. This is materially stronger evidence for an original **real CarPlay app-catalog modification mechanism** than the previously inspected `homeButtonUp:` or `CBMultitaskingOverlayView.appSelected:` handlers.

**Do not confuse those three independent paths:**
1. iPhone `CBAppManager` enabled-app settings → `CBDashboardSettings.bridgedApps`.
2. Original `CARApplication` app-library integration → true CarPlay app list **candidate**, probably marks selected app objects launchable with `setLaunchAsCarApplication:`. Current evidence confirms callsites/symbols, but complete original method-level branch/return and on-device Home result remain unverified.
3. Original `CBMultitaskingOverlayView` picker → one app assigned to one split pane; `homeButtonUp:` → end/exit active bridge. Neither by itself registers a CarPlay Home icon.

## Immutable real DEBs, without vendor code redistribution
- **DuoNavi 1.0.4 original**: `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb`, SHA256 **`f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`**. Its actual `var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.dylib` SHA256 **`44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`**. Real DEB contains 4 Mach-O images. It was NOT executed during audit.
- **Native12-derived reference**, NOT unmodified stock vendor Native12: immutable original branch source `1286a3ef868cf7e29804bcddf7e20b2eae707ce1:dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb`, SHA256 **`2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`**. Its real `DuoFaceDashboard.dylib` SHA256 **`9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`**. 8 Mach-O images.
- Historical original ARM64 UI acceptance evidence: `sideplay/audit/native12-091-fullscan-20261028/original-app-picker-single-vs-bulk-imp/ORIGINAL_PICKER_VS_SETTINGS_IMP.json`; original Home-button handler `sideplay/audit/qa128-postlock-helper-20261030/ORIGINAL_ACTIVATION_AND_HOME_ARM64.json` (DuoNavi).

## Newly executed authenticated extraction
- [**Run 41086108428**](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41086108428) **SUCCESS**: all 3 relevant central ZIPs checksum verified, `unzip -t` passed and `SKILL.md` actually read in runner. Both real DEBs SHA256 verified before `dpkg-deb -x`, all 4+8 Mach-Os inspected using `strings -a -n 5`; primary Dashboard dylibs SHA-verified. Saved `original-deb-evidence/ORIGINAL_HOME_MARKERS.json`.
- [**Run 41086550926**](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41086550926) **SUCCESS**: independently re-authenticated both packages and original dylibs; read-only Capstone 5.0.7 / LC_FUNCTION_STARTS disassembly resolved direct PC-relative selector, class-name, and constant xrefs. **DuoNavi: 1788 function starts, 24 targeted xref callsites; Native12-derived: 1526 function starts, 24**. Saved `original-deb-evidence/ORIGINAL_HOME_ARM64_XREFS.json` and CI_RESULT.txt. These are actual extracted instruction references, NOT live iPhone invocation or a complete reconstructed caller graph.

## Exact original ARM64 reference evidence

| Component | DuoNavi 1.0.4 | Native12-derived |
|---|---|---|
| `CARApplication` class name reference in hook-registration region | PC `0x310780` in function `0x3106f4` | PC `0x2e9dd4` in function `0x2e9d48` |
| `_newApplicationLibrary` selector reference, **same function as CARApplication** | PC **`0x310744`**, function **`0x3106f4`** | PC **`0x2e9d98`**, function **`0x2e9d48`** |
| `bridgedApps` and `allInstalledApplications` references **in the same function** | `0x2f16bc`: PCs `0x2f1730`, `0x2f18f4` | `0x2ca974`: PCs `0x2ca9e8`, `0x2caca8` |
| `DBApplicationInfo` and `CARApplicationInfo` in same function | function **`0x2f2130`**, PCs `0x2f2140` and `0x2f21b8` | function **`0x2cb5c0`**, PCs `0x2cb5d0` and `0x2cb648` |
| `setLaunchAsCarApplication:` references | function **`0x2f2bdc`**, PCs `0x2f2e18`, `0x2f2e38` | function **`0x2cc0b0`**, PCs `0x2cc2ec`, `0x2cc30c` |
| Actual separate in-car one-app-per-pane `appSelected:` | `0xa35cc`, PC `0xa42a4` | `0xa3e5c`, PC `0xa4b34` |
| Home button exit `homeButtonUp:` reference | PC `0x30f23c` in `0x30f1ac`; separately decoded original Home callback invokes `stopBridging` | PC `0x2e8a08` in `0x2e8978` |

Additionally, the actual original Dashboard images contain these informative text markers:
- `[DuoNaviDB] CARApplication +_newApplicationLibrary: %@`
- `[DuoNaviDB] CARApplication -_newApplicationLibrary: %@`
- `[DuoNaviDB] CARApplication init called`
- `[DuoNaviDB] CARApplication received settings updated notification`
- Corresponding `[DuoFaceDB]` markers in Native12-derived reference.

This corroborates both **system CarPlay app-library intervention** and **settings-change handling** as deliberate original components. It does NOT prove what was returned, which selected bundle was admitted, whether SpringBoard's separate gate passed, or when an icon became visible. The output does not contain the entire caller graph or actual connected-screen UI trace.

### What the original more likely does vs what DuoFace currently does
The original appears to combine `allInstalledApplications` with `bridgedApps` under a `CARApplication._newApplicationLibrary` interception and a launch-as-CarApplication policy. DuoFace QA134 has only `DFCarPlaySelectedAppCatalog.h` (iPhone-enabled ∩ installed) and `DFAppPickerVC.m` in the hosted **DuoFace popup**; **no first-party `CARApplication._newApplicationLibrary` publisher/launch identity in the signed build**. Simply writing `EnabledBundleIDs` and calling Darwin notify cannot make native Home icons appear.

## Exact next engineering tasks
1. Decode branch+call graph of the **four source-derived original ARM64 function groups** per image above (install `_newApplicationLibrary` hook, resolve native entries / append based on whitelist, `setLaunchAsCarApplication:` handling, settings change notification). Confirm original IMP forwarding, class-vs-instance selector, return types, catalog object identity and refresh semantics. The strings and xrefs are strong but don't yet prove the full algorithm.
2. Independently implement **typed and version-scoped** iOS16 CarPlay app-library path, plus any required SpringBoard/FBS app admission, for installed and explicitly allowed IDs only. The proven reference from CarSurf iOS16 separately describes typed `LSBundleProxy` and `LSBundleInfoCachedValues` gates; avoid wholesale spoof or CarKit iOS18 code.
3. Real CarPlay Home icons must be **true app objects**, tappable and launchable on the head unit, preserving the Apple native catalog, Home/exit semantics, Dock, QA90 orientation, QA92 divider, QA132 iPhone dim+touch, QA134 GOFA, plus a kill switch. Confirm on actual iPhone X iOS16.7.16. No new runtime / signed QA135 / Sileo feature completed in these read-only original scans.

## Repro commands
From root on GitHub Actions ubuntu:
```sh
python3 sideplay/audit/carplay-home-icons-20261030/scan_verified_original_home_markers.py \
  --duonavi dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb \
  --native12 /tmp/native12-derived.deb \
  --out /tmp/ORIGINAL_HOME_MARKERS.json

PYTHONPATH=/tmp/verified-parser python3 sideplay/audit/carplay-home-icons-20261030/trace_original_home_catalog_arm64.py \
  --duonavi-image /tmp/unpack-duonavi/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.dylib \
  --native12-image /tmp/unpack-native12/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib \
  --out /tmp/ORIGINAL_HOME_ARM64_XREFS.json
```
All paths above include the required setup from `.github/workflows/duoface-original-native12-duonavi-home-roster-audit.yml`, which pins DEB hashes and installs Capstone. Exact workflow run & job timestamps can be read from GitHub; log output `ORIGINAL_IOS16_HOME_CATALOG_ARM64_REFERENCE_SCAN_PASS` confirms actual scan. No vendor license code or dylibs were committed in the audit result.
