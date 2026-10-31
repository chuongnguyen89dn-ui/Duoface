# QA135 real device Log15: GOFA user-confirmed OK, CarPlay Home publisher is absent

Checked: 2026-10-31 (Asia/Ho_Chi_Minh). Feature branch: `feature/duoface-qa135-home-library-20261030`. Raw original log and three IPS were uploaded into `Duoface/main` **commit `12ef117f469ed6cd1dd11c0096621953329793ee`** (not attached to chat; no reupload requested).

## Input/verification
- Source `sideplay/log/DuoFaceAudit 15.txt`: 4,683,740 bytes, **17,843 lines**, includes `DuoFaceHomeCatalogABI.log`; generated `2026-10-31 00:48:25` printed in header (timezone in that field not established).
- Read-only GitHub Actions [run 41152508547](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41152508547), **COMPLETED SUCCESS**. Actual `git show 12ef117f:sideplay/log/... ` checked out full uploaded log and three individual crash reports. Project output `sideplay/audit/carplay-home-icons-20261031/QA135_LOG15_RESULT.json`, bot archive commit `1a6eb52221ffe2f2e5322bffaab74b4525a268f5`. This is real **user phone** log analysis, NOT CI device simulator log; no phone action executed by CI.
- User expressly reports QA135 physical test: **GOFA no longer has the previous problem**; **selected applications still do NOT appear on genuine Apple CarPlay Home**. User-confirmed GOFA is valuable evidence, preserve QA134/135 native scene/geometry/touch code; neither a code change nor an automated test authorizes marking the original failure absent for every app.
- Phone DuoFace diagnostics ending of Log15: `Remembered app slot 0: com.lumi.GOFA`, `slot 1: com.google.ios.youtube`, slots 2,3 empty. Home ABI log reports **`configured=6 preference=present`** in both SpringBoard PID 88408 and CarPlay PID 88433. Therefore the selected allowlist is visible to the running processes; failure is *downstream of iPhone selection persistence*, not because the user selected zero apps. 6 configured does not certify any of those six can be admitted to Apple Home.

## Exact observed iPhone X iOS 16.7.16 runtime ABI (actual QA135 log)
Within **CarPlay** process PID 88433:
- `CARApplication` class **unloaded**. Both `+[CARApplication _newApplicationLibrary]` and `-[CARApplication _newApplicationLibrary]` **unavailable**. **Do NOT hook original Native12's `CARApplication._newApplicationLibrary` in this currently observed `CarPlay` process**: the named class isn't loaded here; original vendor image's reference was from a potentially different OS/build and may target Dashboard instead.
- `DBApplicationController applicationWithBundleIdentifier:` **unavailable** and `CARApplicationInfo _loadFromProxy:` **unavailable** in that process. Do not blindly invoke.
- `FBSApplicationLibrary -addApplicationProxy:`: class loaded, exact method **absent**.
- `FBSApplicationLibrary -addApplicationProxy:withOverrideURL:`: **PRESENT**; `v32@0:8@16@24` (void return; 2 object arguments; 4 including self,cmd).
- `FBSApplicationLibrary -applicationInfoForBundleIdentifier:`: **PRESENT**, `@24@0:8@16`.
- `FBSApplicationLibrary -_notifyDidAddApplications:` / `-_notifyDidRemoveApplications:`: **PRESENT**, both `v24@0:8@16`.
- `DBApplicationInfo -_loadFromProxy:`: **PRESENT**, `v24@0:8@16`.
- `CRCarPlayAppPolicyEvaluator -effectivePolicyForAppDeclaration:`: **PRESENT**, `@24@0:8@16`.
- `DBApplicationController` and `CARApplication` not loaded here do not mean they cannot load in another process or at another time; logger sampled multiple times from the same real device and should be extended to log actual process/module ownership rather than speculate.

Within **SpringBoard** PID 88408:
- `FBSApplicationInfo -entitlementValuesForKeys:` class loaded but method **absent**. Reject the earlier first-party `DFFirstPartySpringBoard` path targeting this method as a universal iOS16 hook.
- `LSBundleInfoCachedValues -boolForKey:`: `B24@0:8@16` (BOOL).
- `LSBundleInfoCachedValues -objectForKey:`: `@24@0:8@16`.
- `LSBundleProxy -entitlementValueForKey:ofClass:valuesOfClass:`: `@40@0:8@16#24#32` (object, 2 Class parameters).
- `LSBundleProxy -entitlementValueForKey:ofClass:`: `@32@0:8@16#24`.
These are exact ABI values, not guesses.

## Why Home still fails
QA135 was explicitly compiled as a **read-only probe**. Its source `DFCarPlayHomeABIProbe.m` checks metadata and writes `DuoFaceHomeCatalogABI.log`; it **never** calls `FBSApplicationLibrary.addApplicationProxy:withOverrideURL:`, never publishes `_notifyDidAddApplications:`, never creates a native Home `DBApplicationInfo`, and never authorizes launch/tap via `CRCarPlayAppPolicyEvaluator`. The iPhone setting writes `EnabledBundleIDs` and the DuoFace **internal pane picker** consumes them; system CarPlay Home does not. This is a **confirmed missing implementation**, not a failed ABI logger, and not an app-list persistence bug.

**New decisive insight:** On actual user phone, the original **`CARApplication._newApplicationLibrary` hook target is unavailable in observed CarPlay process**; the real active bridge lies in `FBSApplicationLibrary`, `DBApplicationInfo` and `CRCarPlayAppPolicyEvaluator` with precise type encodings as above. Do not port hooks that reference absent methods, spoof entitlement dictionaries globally, mutate vehicle icon layout, or convert a genuine CarPlay app to a fake CPTemplate role.

## SpringBoard crash provenance and GOFA preservation
Three `.ips` in same uploaded main commit have **incident timestamps 2026-10-30 14:25:55, 17:31:09 and 17:32:11 +07:00**, all **before QA135's 2026-10-30 ~23:40 ICT publication**. Two are `SIGABRT` with `-[SBAppViewController sceneHandle:didUpdateSettingsWithDiff:previousSettings:]` and a `FBScene` modified call stack with third-party `ImmortalizerHooks`; the earlier one is `SIGTRAP` with `DFManagedSceneObserver`. They prove historical scene-update crashes; **they are NOT proof QA135 currently crashes**. Preserve working GOFA path, don't remove optional third-party tweaks without user's authorization.

## Next implementation constrained by verified facts
1. Implement an **independent, opt-in, reversible iOS16 native Home admission** using only runtime-present and correctly typed methods. Locate the **actual live `FBSApplicationLibrary` instance/authoritative native roster** first; use native `LSApplicationProxy` identity and selected `EnabledBundleIDs`, preserve original native CarPlay app declarations and icon state.
2. Add only installed/eligible/explicitly enabled third-party app proxies; original-first API with narrow change notification and fail-closed guards for unknown `DBApplicationInfo`/policy behavior. Validate system Home's actual icon and tap/scene in a parked vehicle before claiming PASS; preserve Apple Maps and native apps, lock/GOFA/YouTube/Dock.
3. Separate new signed DEB QA136, Sileo release and physical log-based QA. **No QA136 publisher or physical Home icons were implemented by this report.** QA135 is on Sileo and user has tested it. The policy module `DFCarPlayHomeCatalogPolicy.h` already enforces installed ∩ enabled without replacing native icons.

This report distinguishes direct original machine-code evidence, actual device ABI log, user-observed GOFA result and future code work. No release/publish claim beyond previous QA135 verified Sileo.
