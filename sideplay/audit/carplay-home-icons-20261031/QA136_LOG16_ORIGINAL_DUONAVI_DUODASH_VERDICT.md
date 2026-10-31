# QA136 real Log16 vs original DuoNavi and DuoDash: Home icons remain absent

Checked 2026-10-31. Real user-exported Log16 source: Duoface/main commit 31166d15e3606e571bc34b023e59f76613d4953c, sideplay/log/DuoFaceAudit 16.txt, export 2026-10-31 01:41:15 UTC. Device iOS 16.7.16. Full source log is 5,167,955 bytes / 20,323 lines, SHA256 71c72597900bf324a6230d2eb522500b9442e09f39f74e6d774f2e9ab3cb549f. Parsed reproducibly in GitHub Actions run 41157418748 SUCCESS with script analyze_qa136_uploaded_log16.py. Sanitized output: QA136_LOG16_RESULT.json. This is replay of a device export, NOT a CI physical car test.

## Real log: 6 accepted by one FBS library, zero visible Home icons

- Section DuoFaceHomePublisher136.log exists, line 8651: [DFHome136] pid=88938 started no-hook no-new-library notify home=0 enabled=0. Notification setup succeeded.
- Eight logged user Home switch OFF / kill-switch no-mutation events.
- **Line 8659**: [DFHome136] pid=88938 verified-library=FBSApplicationLibrary reconcile=6 reason=user-Home-toggle.
- 29 further verified-library calls return reconcile=0; no native-FBS-library-instance-not-exposed events.
- This **disproves** the old hypothesis that no FBSApplicationLibrary instance was available in the observed CarPlay process. The switch was enabled, a real library object was found and six app-info records were looked up.
- IMPORTANT: QA136 source returns a positive count for nonnil FBSApplicationLibrary.applicationInfoForBundleIdentifier: results after addApplicationProxy:withOverrideURL:. It does NOT verify six successful Apple Home icons, CarPlay declarations/policy or tappable icon-to-scene launch. The 29 zeros mean no additional newly inserted records. User reports no new Home icons.
- Three October 30 SpringBoard IPS uploaded alongside Log16 PREDATE QA136; they must not be presented as QA136 regressions.

## Original SHA-pinned DEB comparison (static evidence, not original runtime call trace)

Original DuoNavi104 SHA256 44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15 and Native12 reference SHA256 9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea. Source: sideplay/audit/carplay-home-icons-20261030/original-deb-evidence/ORIGINAL_HOME_SEMANTIC_SELECTORS.json (8 original function groups).
- **Home lifecycle**: strings/selectors DashBoard, CARApplication._newApplicationLibrary and _CARDashboardHomeViewController._setupIconModel.
- **Library integration**: FBSApplicationLibrary.addApplicationProxy:withOverrideURL:, CRCarPlayAppDeclaration and _carPlayDeclaration, _notifyDidAddApplications: and removal.
- **Home visibility / policy**: setCanDisplayOnCarScreen:, setLaunchUsingTemplateUI:, setCarPlaySupported:, setLaunchAsCarApplication:, effectivePolicyForAppDeclaration:, native Apple app pass-through.
- **Tap-to-launch**: iconManager:launchIcon... callbacks, multiple signatures.
- Original DuoDash 1.1.3 SHA256 16ffab22b4246dea9978cae92df7ec635d833ec067b4d9f425a231b26edec601: source docs/duoface-vs-duodash-app-selection-iphone-carplay-20261016.md confirms appbridge_enabled, iPhone _enumerateApps/_readBridged/_persistAndNotify, separate CNABAppPickerController, and Home-facing App Bridge setting. Its exact native Home hook ABI has NOT been decoded. Do not invent it.

## Verified code gap between QA136 and working original architecture

- DFHomePublisher136Entry.m is restricted to processName CarPlay and searches UIApplication delegate/windows/controllers. It never hooks Home's native CARApplication._newApplicationLibrary, _CARDashboardHomeViewController._setupIconModel or Home icon launch callbacks.
- DFHomePublisher136Core.m attempts addApplicationProxy and sets only setCarPlaySupported: and optional setLaunchAsCarApplication:. It does not build/validate CRCarPlayAppDeclaration, effective CarPlay policy, canDisplayOnCarScreen, Home icon model or Home icon launch dispatch.
- The Log15 live ABI found CARApplication class **unavailable within CarPlay**. That is not evidence it is unavailable in another process, especially DashBoard. Log16 has a DuoFaceGeometry119-Dashboard.jsonl export section, but no confirmed Home owner method callback from that process in this audit.
- **Diagnostic conclusion:** QA136 solved only one intermediate proxy-registration step. The actual Home UI model/visibility-policy/launch stages are missing in QA136 code. Which OS owner/methods are live on this exact iOS16 device remains unverified. Re-registering the same six FBS records or adding more retries cannot address the missing stages.

## Immediate next engineering action

Measure actual DashBoard/CarPlay native Home factory and icon-model ABI on the user device with a read-only process-scoped probe; compare native library identity and per-app CRCarPlayAppDeclaration / effectivePolicy / canDisplayOnCarScreen before mutations. Implement a reversible independently written Home-owner lifecycle integration with runtime guards only at the verified owner. Keep QA135 GOFA, QA90 YouTube rotation, QA92 divider, dock, Maps, reconnect and Apple native icons intact. Acceptance is physical Apple CarPlay Home icon displayed AND tapped to working app scene, not FBS reconcile=6. No source QA137, DEB or Sileo publish is claimed by this audit.

## Separate publisher verification issue

Carplaydsp Pages run 41155821638 build and deploy jobs PASS; integrated public QA verify job 124403067015 FAIL because verifier expected version 0.0.136 but stale QA135 filename and SHA. The public APT stanza in its log actually reports QA136 file, version and expected 9fb08f6e4e8f8c8b9d7b1876c1d66794b44bff57427e1be8a054f46836a8c49a. This false-negative release verifier is separate from the physical Home icon failure.
