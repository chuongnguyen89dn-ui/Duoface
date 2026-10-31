# DuoFace QA136 — deeper original-DEB CarPlay Home investigation (2026-10-31)

## Verified execution, sources, and boundaries

- Current branch: `feature/duoface-qa136-ios16-native-home-publisher-20261031`; baseline signed QA136, Sileo public but user reports no new Home icons. Preserve GOFA functioning in QA135, native CarPlay applications, Dock, YouTube rotation, splitter and iPhone lock.
- Real user's iOS16.7.16 Log16: `main:sideplay/log/DuoFaceAudit 16.txt`, upload commit `31166d15e3606e571bc34b023e59f76613d4953c`. Earlier verified [Log16 parser run 41157418748](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41157418748): `FBSApplicationLibrary reconcile=6`, no native icon seen.
- New reproducible *actual original-DEB* audit script: `sideplay/audit/carplay-home-icons-20261031/inspect_original_duonavi_duodash_home_scope.py`; workflow `.github/workflows/duoface-qa136-original-home-scope-audit.yml`; [run 41157922214](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41157922214) **SUCCESS**. Actual inputs SHA checked, original package payload plists opened, dylib string markers inspected, raw Log16 section sampled. Durable machine results `sideplay/audit/carplay-home-icons-20261031/HOME_PROCESS_SCOPE_RESULT.json` and `HOME_PROCESS_SCOPE_CI_RESULT.txt` (CI run ID 41157922214).
- DuoNavi ORIGINAL 1.0.4 exact DEB `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb`, SHA256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`. DuoDash file analyzed is **REPACKED Fullscreen427** 1.1.3, `chuongnguyen89dn-ui/DauDat-CarPlay/main:DuoDash_1.1.3_Fullscreen427_iphoneos-arm64.deb`, SHA256 `ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465`. It is NOT independently verified to be pristine stock DuoDash: label all conclusions accordingly.

## Decisive original packaging/ABI evidence

**DuoNaviDashboard.plist** actually specifies bundle targets `com.apple.CarPlayApp`, `com.apple.CarPlay`, **`com.apple.dashboard`**, `com.apple.springboard` and 18 additional host/app bundle IDs. Dashboard dylib contains real `CARApplication`, `_newApplicationLibrary`, `FBSApplicationLibrary`, `addApplicationProxy:withOverrideURL:`, `_notifyDidAddApplications:`, `DBApplicationInfo`, `CRCarPlayAppDeclaration`, `_CARDashboardHomeViewController`, `_setupIconModel` and `iconManager:launchIcon:` markers. SHA-verified independent prior ARM64 audit `ORIGINAL_HOME_SEMANTIC_SELECTORS.json` places these in related installer, catalog, policy, icon-model and launch paths.

**DuoDash 1.1.3 repack** has `DuoDash.plist` bundle filters `com.apple.springboard`, `com.apple.Preferences`, `com.apple.CarPlayApp`, `com.apple.UIKit` and executable `mediaserverd`; separate `DuoDashUnifiedFullscreen.plist` targets `com.apple.CarPlay`. Its `DuoDash.dylib` contains `CARApplication`, `_newApplicationLibrary`, `FBSApplicationLibrary`, `addApplicationProxy:withOverrideURL:`, `_notifyDidAddApplications:`, `DBApplicationInfo`, `CRCarPlayAppDeclaration`, `effectivePolicyForAppDeclaration:`, `_CARDashboardHomeViewController`, typed `entitlementValueForKey:ofClass:`, `appbridge_enabled` and `CNABAppPickerController`. Strings are **presence evidence, not executed callbacks or established exact DuoDash Home hook**.

**DuoFace QA136 package already has the relevant receiving FILTER but the implementation does not use it.** `sideplay/duoface-native-scene-host/DFCarPlayDockOwner.plist` targets `com.apple.CarPlay`, `com.apple.CarPlayApp`, `com.apple.dashboard` plus executable `CarPlay`, `CarPlayApp`, `dashboard`, `Dashboard`. Yet `DFHomePublisher136Entry.m` constructor expressly aborts unless `processName == CarPlay`; `DFHomePublisher136Core.m` similarly requires CarPlay, thus no integration can occur via the OTHER injected Home host paths even when the library is accessible there. `DFTouchOwnerProbe.plist` correctly targets SpringBoard but only includes QA135 read-only Home ABI probe, not QA136 admission policy. It is insufficient to merely edit a plist: the process guard and policy routing remain missing.

## Stronger independent public iOS16 source corroboration (not copied)

GitHub source [pavunato/carsurf](https://github.com/pavunato/carsurf) reports on real iPhone X iOS **16.7.12** (RootHide), distinct from user's palera1n **16.7.16**:
- `sbtweak/CSSceneManifestSpoof.m` documents a measured iOS16 backtrace **DashBoard +[DashBoard _newApplicationLibrary] -> FrontBoardServices _proxyPassesInclusionFilter -> LSBundleProxy entitlementValueForKey:ofClass:valuesOfClass:**. Hence an ordinary user-selected app may be screened *before* a FBS entry is added or before Dashboard recognizes it.
- `sbtweak/CSAppList.m` describes real `CARApplication` roster class APIs `_allInstalledApplications` and `_allInstalledApplicationsByBundleIdentifier`, preserving genuine Apple Home apps and merging enabled third-party.
- `sbtweak/CSCarLaunch.m` identifies the genuine Dashboard tap/launch path involving `DBApplicationController`, `DBMutableWorkspaceStateChangeRequest`, `DBWorkspace`. It explicitly restricts its successful owner to CarPlay and Dashboard workspace, showing **DashBoard can be a CLASS inside the CarPlay process**, not necessarily a separate running executable.
- `sbtweak/CSSystem.m` delays hook registration until CarPlaySupport/related image loads. Without this the constructor may fire too early and a Home selector not yet loaded is not proof it never exists.
- The same source warns that broad/global entitlement-hook/dictionary replacements crashed CarPlay/SpringBoard. Do **not** copy their code/implementation, or assume iOS16.7.12 RootHide equals 16.7.16 palera1n.

## Real Log16 negative measurement and corrected interpretation

The exported `DuoFaceGeometry119-Dashboard.jsonl` section contains only **three** lines, no parsed JSON entries with process fields. This establishes **insufficient direct Dashboard runtime evidence**, NOT that the Dashboard app or class is absent. In contrast QA136 Home publisher log has `reconcile=6` and 29 zero subsequent increments. The six represent nonnull lookups **regardless** of whether info objects were genuine DBApplicationInfo, CarPlay declaration nonnil or policy allowed, because QA136 source increments count unconditionally after `if(info)`; its `DF136PromoteNewInfo` returns immediately on class mismatch without reporting an error.

### Resolved diagnosis / next minimal patch boundary

QA136 is a **partial FBS library registration** and lacks:
1. Evidence of iOS16 **LaunchServices entitlement inclusion gate** passing in the true Home owner's execution context. Existing QA135 measured `LSBundleProxy` ABI within SpringBoard but not these hooks actually running in CarPlay's Home loader.
2. Evidence of actual Home-ready `DBApplicationInfo`, required `CRCarPlayAppDeclaration` and `canDisplayOnCarScreen` fields, plus `CARApplication` roster membership.
3. A Home icon-model refresh and **real click-to-launch** path; no related callback is installed by QA136.

**First next implementation step:** a bounded, **read-only** diagnostic in already-filtered CarPlay/CarPlayApp/dashboard and SpringBoard contexts, capturing actual process/bundle, loaded `DashBoard`, `CARApplication`, `FBSApplicationLibrary`, `DBApplicationController` and `LSBundleProxy` method encodings, actual `DBApplicationInfo` class/flags for one explicitly enabled third-party and native reference, the actual Dashboard Home icon model and a real launch callback. Record method *existence before* choosing narrow original-first owner hook; fail closed, default off, no copied vendor code. Build an isolated next QA only once such instrumentation can prove host process/ABI; preserve signed QA135/136 rollback. A physical vehicle icon AND tap-to-scene is the acceptance test.

## Not completed

No new functional Home admission patch, signed QA137 DEB, Sileo publication, device execution or claim of resolved Home icon visibility. All findings distinguish raw original DEB evidence, binary markers, independent public references and real Log16. Do not mistake original presence of hooks for proof they ran on user's device.
