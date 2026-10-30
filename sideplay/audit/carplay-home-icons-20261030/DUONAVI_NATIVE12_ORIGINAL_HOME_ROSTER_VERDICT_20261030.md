# DuoNavi 1.0.4 vs Native12-derived — ORIGINAL CarPlay Home native roster evidence (2026-10-30)

## User question and evidence boundary
The user asks **how original DuoNavi and Native12 place enabled iPhone applications as icons on the genuine Apple CarPlay Home**, rather than merely listing them within the split-pane application picker. This document is read-only ORIGINAL binary forensics. No vendor binary/code/license imported into independent DuoFace runtime, no package was built or published in this audit.

## Inputs, SHA identity and real CI
1. **Original DuoNavi 1.0.4**, `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb`, exact SHA256 **`f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`**, `DuoNaviDashboard.dylib` exact SHA256 **`44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`**. Exactly **4 Mach-O payload files**.
2. **Native12-derived technical reference** (NOT an untouched third-party stock Native12 package), immutable `1286a3ef868cf7e29804bcddf7e20b2eae707ce1:dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb`, SHA256 **`2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`**, `DuoFaceDashboard.dylib` SHA256 **`9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`**. Exactly **8 Mach-O payload files**.
3. Real workflow [`41086108428`](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41086108428) **COMPLETED SUCCESS**, runner checked three central skill ZIP SHA/contents, both DEB SHA hashes, extracted all payloads, checked exact original dylib SHAs, searched **each actual Mach-O** read-only, and archived the first-party marker report `sideplay/audit/carplay-home-icons-20261030/original-deb-evidence/ORIGINAL_HOME_MARKERS.json` (Git blob `0f5d8ff15802b4de9bc75e205556d37d12e55021`). Rerun [`41086550926`](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41086550926) likewise SUCCESS.
4. Separate targeted ARM64 decoder and CI [`41087301322`](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41087301322) executed Capstone over exact SHA-checked original Dashboard dylibs and wrote `original-deb-evidence/HOME_ROSTER_XREF.json` commit **`94a026cb`**; xref report read back from GitHub. Original image hashes verified, *machine address crossrefs*, not just free-floating strings. CI job had completed all substantive steps including evidence archiving, final run result should be checked separately. Source decoder `decode_original_home_roster_callsites.py` commit `4ed54ee1955c354141201f6b65d06ce73fe81e60`.

## Major new discovery: both actual original CarPlay Dashboard dylibs know the SYSTEM app-library hook
The original DuoNavi Dashboard Mach-O *itself* includes these precise readable markers:
- **`CARApplication`**, **`_newApplicationLibrary`**, **`CARApplicationInfo`**, **`DBApplicationInfo`**, **`setLaunchAsCarApplication:`**, `bridgedApps`.
- Native-original debug formats (redacted to mechanism): `CARApplication +_newApplicationLibrary:`, `CARApplication -_newApplicationLibrary:`, `CARApplication init called`, `CARApplication received settings updated notification`.
- Native12-derived Dashboard includes the **corresponding exact same structural markers**, under its own debug prefix, including `CARApplication`, `_newApplicationLibrary`, `DBApplicationInfo`, `CARApplicationInfo`, `setLaunchAsCarApplication:` and `bridgedApps`.

**This is much stronger than the previous vague assertion that the system Home selector was unknown.** The exact *named Apple class + app-library selector* that these original binaries target is now identified as **`CARApplication` `_newApplicationLibrary`**. It must be interpreted as **Dashboard app-library/roster integration**, not the native12 `homeButtonUp:` callback (which is only exiting the bridge), and not the `CBMultitaskingOverlayView.showAppPickerForSlot:` per-pane list. Do not claim that the precise original hook registration ABI/return-object lifecycle or a physical icon click has been proved solely by a string.

## Independent machine-code xref corroboration
`HOME_ROSTER_XREF.json` records actual original ARM64 PC/function cross-references to selector/class strings. Recorded examples:
- **DuoNavi**: `_newApplicationLibrary` selector reference around PC `0x12322c` within recorded enclosing original function boundary `0x113c98`; `CARApplication` C-string at PC `0x310780` / enclosing function `0x3106f4`; `DBApplicationInfo` and `CARApplicationInfo` together at PCs `0x2f2140` and `0x2f21b8` / enclosing `0x2f2130`; `setLaunchAsCarApplication:` at `0x2f2e18`/`0x2f2e38` / enclosing `0x2f2bdc`; `bridgedApps` called from several genuinely parsed original methods including `0x289a7c` and `0x2a64cc`.
- **Native12-derived**: `CARApplication` at PC `0x2e9dd4` / enclosing `0x2e9d48`; `DBApplicationInfo` and `CARApplicationInfo` at PCs `0x2cb5d0` and `0x2cb648` / enclosing `0x2cb5c0`; `setLaunchAsCarApplication:` at `0x2cc2ec` / `0x2cc30c` / enclosing `0x2cc0b0`; iPhone enable/CarPlay picker sources use `bridgedApps`, as established by the earlier real selector/IMP audit.
- The ARM64 decoder classified 19 DuoNavi and 11 Native12 functions with at least one target xref. **These are scan totals, not a claim that exactly 19 vs 11 Home hooks were installed**. Note the registered function boundaries may include large gaps; xref grouping is a forensic hint, not a complete dynamic call graph.

## What the original code arrangement implies, and what remains missing
The validated partial architecture is now:
```
iPhone CBAppsManagerViewController.appSwitchToggled:
    → CBAppManager.setApp:enabled: / enableAllApps
    → shared CBDashboardSettings.bridgedApps
    → CarPlay process uses CARApplication app-library reconstruction
       (the two originals explicitly reference _newApplicationLibrary)
    → actual CarPlay Dashboard native icon membership
    → car-app identity via CARApplicationInfo / DBApplicationInfo
       and setLaunchAsCarApplication: candidates
    → Home icon tap must activate real app scene (not yet mapped)
```
**Evidence grades**:
- Original iPhone toggle and bridged-app catalog: **high**, original machine-code audit (Native12 `CBAppsManagerViewController.appSwitchToggled:` at `0x100013ab4`; `CBAppManager.setApp:enabled:` at `0x10000960c`, and original `CBMultitaskingOverlayView.loadInstalledApps` at `0xa0c48`).
- `CARApplication` / `_newApplicationLibrary` native CarPlay roster hook integration: **high confidence named class+selector+debug formats with independent ARM64 xrefs**; exact hook replacement, collection insertion, filtering, observer notification and live Home icon display are **not yet decompiled/verified**.
- Launch as real `CARApplicationInfo` or `DBApplicationInfo`: **candidate**, because original has class and `setLaunchAsCarApplication:` references; how every object is constructed/selected and exactly which CarPlay process uses it is **not yet verified**.
- Actual CarPlay Home icon of chosen YouTube/GOFA + tap launch on iPhone X iOS16.7.16: **unverified**.

Do not confuse original Native12-derived test package with pristine vendor Native12. Do not directly port proprietary object constructors/logic or licensing mechanisms. DuoFace must implement its own scoped, runtime-verified integration, preserving Apple's native app roster, vehicle icon state, original Home/cleanup, Dock, QA90 rotation and QA132 dim/touch.

## Precise next evidence needed before source patch
1. At SHA-pinned original `DuoNaviDashboard.dylib` / `DuoFaceDashboard.dylib`, resolve where `CARApplication` class, `_newApplicationLibrary` (class and instance), `CARApplicationInfo`/`DBApplicationInfo` and `setLaunchAsCarApplication:` are referenced in the exact **hook installation+replacement+notification** call graph. These markers now provide a sharply bounded, source-proven target.
2. On parked iOS16.7.16 inspect exact `CARApplication` method type encodings and actual `_newApplicationLibrary` library object model, app membership, icon tap route and scene activation. Only enable any live hook with a kill-switch and verified current app list; no fake Home tiles or broad entitlement spoof.
3. Independently integrate `DFEnabledAppsPolicy.EnabledBundleIDs` → real native Home roster, not just `DFAppPickerVC`. Preserve installed/native apps; genuine Home icon must open the chosen scene, update after app toggles/reconnect.
4. Separate signed QA build and Sileo release must follow source tests and actual safe gating; **none was built/published for this Home feature in this audit**.

## Verification & result
Original DEB SHA authentication, all-MachO inspection, original ARM64 xref and archival are real CI operations; this report does **not** state the original binary was executed on the device or that DuoFace's missing Home publisher was installed or repaired.
