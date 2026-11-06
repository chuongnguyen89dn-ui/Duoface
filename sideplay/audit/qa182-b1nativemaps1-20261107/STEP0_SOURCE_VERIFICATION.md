# QA182 B1 v2 — Bước 0, source verification

Base: chuongnguyen89dn-ui/Duoface feature/duoface-qa181-b0probe1-20261106 @ b7a9b45d2c5389a1f41b547887176466a8d628fb.
New branch feature/duoface-qa182-b1nativemaps1-20261107 created from this exact tip. User instruction “Bắt tay vào làm đi” authorizes implementation, CI/archive/Sileo within v2 gates. It supersedes review-only status.
Actions API checked in_progress=0/queued=0 before starting.

| Reuse | Path at base commit | Verified behavior |
|---|---|---|
| Factory hook | sideplay/duoface-native-scene-host/DFHomeAdmission141.m | DF141Factory calls original DashBoard +_newApplicationLibrary, reconciles returned original object. Already hooks typed LS entitlements and policy. No second factory hook needed. |
| Existing reconciliation | sideplay/duoface-native-scene-host/DFHomePublisher136Core.m | DFHome136ReconcileVerifiedLibrary; real FBS library/add/lookup/notify, native nonnil declarations preserved. Normal Home consent gate must remain for ordinary apps; B1 assignment native reconcile is separately scoped Maps only. |
| Native coordinator | sideplay/native-carplay-scene-v1/DFNativeMapPaneCoordinator.m | Already Attach/Restore via DFNativeMapPaneAdapter, actual pane binding and reflow; not passive-only. |
| Choice | sideplay/duoface-native-scene-host/DFNativeMapLeasePolicy.h | Choice Version1/Slot only (0 or1). Separate lease has Version/Session/BundleID/Slot/Timestamp. Old choice must not become an assignment. |
| Geometry writer | sideplay/duoface-native-scene-host/DFNative12Chrome.m and DFTouchOwnerProbe.m | physical-panes.v1.plist from actual per-slot UIWindow readback, SpringBoard sole writer, matched heartbeat session. |
| Native workspace owner | sideplay/duoface-native-scene-host/DF151WorkspaceOwnerCapture.h | Actual initWithOwner captures DBDashboardWorkspaceOwner and DBWorkspace weak references; no fabricated workspace. |

Three hook implementation searches: rg on QA181 source; GitHub code search sceneFrameForAppInfo; branch search nativemap; commit search nativemap/sceneFrameForAppInfo/native Maps; coordinator path history. No pinned historical source for the three hooks recovered. Do not claim port. QA182 implementation will be NEW first-party code on current coordinator, with runtime ABI gating. Historical source not found does not imply runtime selector absent.
Coordinator path history includes e5e8380b5fa67532859cd09a9a9b964ae90f27ea (initial attach), 904b4a6f010b35c24dd721f42f0e78963d582358 (physical proof), 168b55ac60b48a499b95e25819a5f2230ef8dd96 (choice/lease); these do not establish the missing three hooks.
Actual Audit10 iOS16.7.16 (main2406d1f1c7df7fa7419aa2aa15eaca6076176f1c, log blob5a4718133a22401bf61e601be16bf698e38c5b1f) reports DBWorkspace requestStateChange: v24@0:8@16 and DBMutableWorkspaceStateChangeRequest activateApplication: v24@0:8@16 (e.g.14394–14400). Native owner captured in log. Other ABI/provenance MUST still be checked on-device, absence/mismatch stops assignment.
No claim settings OFF catalog/launch works yet. “Vòng kẹp” remains hypothesis. Native pixels/touch OFF/ON are UNVERIFIED until vehicle verdict.
Frozen: DFAppTouch177.h, DFH1Wake188.m and QA180 Darwin protocol. Other apps retain phone-host path. No fallback for Maps assignment.
