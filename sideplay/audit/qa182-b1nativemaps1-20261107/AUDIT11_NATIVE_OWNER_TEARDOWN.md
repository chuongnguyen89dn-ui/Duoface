# QA182 Audit11 — native Maps reached; existing owner lease tears down split

## Verified input and execution
main commit ba2ff26cbe6cfe9eafda3d7877b2173c2c1e26c7, sideplay/log/DuoFaceAudit 11.txt, 6869806bytes, Gitblob8c884b1ac2b24c7ab3407df50812b9117f8a286b, 31550lines.
Export07/11/2026 07:47:38 Asia/Ho_Chi_Minh (00:47:38Z), iOS16.7.16. Runtime timestamped traces confirm 0.0.182~b1nativemaps1; exporter171 label is stale.
Exact signed source bdd1116b5308869210a65b79b92b7d873fe4a04c.
Command from /workspace/scratch/f9a10e281851/Duoface:
python3 sideplay/audit/qa182-b1nativemaps1-20261107/analyze_audit11.py /workspace/scratch/f9a10e281851/evidence/DuoFaceAudit11.txt --output /workspace/scratch/f9a10e281851/Duoface/sideplay/audit/qa182-b1nativemaps1-20261107/AUDIT11_ASSIGNMENTS.json
Analyzer asserts exact blob/size before parsing. Output8assignments,8native-scene observations,7watchdogrevocations,1appreplacement. Two distinct observed native scene IDs across these assignments, not8freshsceneallocations.

## Gates actually observed
- Three runtime hook ABIs matched iOS16.7.16: sceneFrameForAppInfo:proxyAppInfo: {CGRect={CGPoint=dd}{CGSize=dd}}32@0:8@16@24; deactivateSceneWithReasonMask: v24@0:8Q16; backgroundSceneWithCompletion: v24@0:8@?16 (29783–29785).
- All8assignments: original live FBS catalog membership + genuine declaration readback; DBWorkspace launch-issued; native Maps scene observed and initially placed. No Maps phone-host activate-request/host-created found in timestamped QA182 trace.
- Provenance: processCarPlay5374, DBApplicationSceneViewController, FBScene, CRSUIProxyApplicationSceneSettings, external UIWindowSceneSessionRoleCarPlay, real sceneIDs Car[2-3]:com.apple.CarPlayTemplateUIHost:com.google.Maps and Car[2-5]:com.apple.CarPlayTemplateUIHost:com.google.Maps. sceneRole and sceneClientProcessBundle remainunknown.
- All8stock-settings=unknown. This trace cannot establish an OFF/ON comparison or prove the settings-loop hypothesis.
- 107B1records: assignment8/catalog8/launch8/scene8/frame-placed8/lifecycle-swallowed8/revoke8/restored8/summary16/frame-request24/hookABI3. All8swallows observed are deactivate mask0; background completion swallow did not occur, so do not call that runtime callback proved.
- Initial frame claim: nativeview parent mapped to physical0/visual1, target{{342.5,0},{297.5,360}}, nativewindowlevel-1, targetSBwindowhidden. This instant/local check does not prove sustained split/globallayout.

## Proven failure sequence (first assignment, 07:43:28–07:43:30)
| Event | Audit11 line | UTC epoch |
|---|---:|---:|
| assignment created | 29782 | 1794012208.630102 |
| catalog reconciled | 29800 | 1794012208.907995 |
| launch issued | 29802 | 1794012208.915433 |
| native scene seen | 29828 | 1794012209.678540 |
| frame placed, targetright297.5x360 | 29843 | 1794012209.680608 |
| Maps deactivate swallowed | 29845 | 1794012210.375806 |
| DuoFace entersbackground, stale-existing nativeowner still1 | 29847 | 1794012210.382463 |
| nativeownerobserver nowactive0, visiblecandidates0 | 29849 | 1794012210.464044 |
| SB watchdogdetach age0.13 active1 sessionmatch1 | 29851 | 1794012210.511470 |
| assignmentrevoked viaChrome.stop | 29854 | 1794012210.519741 |
| Wazeotherpane deactivate-request | 29858 | 1794012210.544756 |
| nativeMaps UIKit frame restored640x360 | 29864 | 1794012210.737089 |
| summary stillreports framePASS/lifecyclePASS | 29865 | 1794012210.740160 |

## All assignments
| Assignment prefix | Placed line | Ownerinactive line | Watchdog line | Revoked line | Seconds placed→revoke |
|---|---:|---:|---:|---:|---:|
| EB8EF4B0 | 29843 | 29849 | 29851 | 29854 | .839 |
| 441A67B0 | 29986 | 29997 | 30000 | 30003 | .924 |
| AA2D6DD9 | 30130 | 30136 | 30138 | 30141 | 1.435 |
| 1931799B | 30256 | 30262 | 30263 | 30266 | .957 |
| 3DCF68D0 | 30369 | 30379 | 30380 | 30383 | 1.611 |
| 7547244C | 30542 | 30548 | 30550 | 30554 | 1.357 |
| 5DC1E3AF | 30694 | none | none | 30707 | .953 (app replacement) |
| DE11F3D8 | 31450 | 31458 | 31459 | 31462 | 1.217 |

All7watchdog cases have fresh heartbeat age0.13–0.70, Active1, sameSession1. This is not a heartbeat timeout or failed native launch.
The generic revoke string Chrome-Home-or-disconnect does not establish a physical Home press or unplug; the preceding watchdog event identifies this stop path. Actual physical-disconnect traces are later.

## Source explanation, now corroborated by runtime
DFCarPlayOwnerObserver.h DFOwnerObserveNative only attests the unique native DuoFacehost controller, not the active Maps assignment.
DFCarPlayOwnerLease.h DFOwnerAcceptRecords requires this exact old host attestation when HostBackground=YES; DFOwnerEvidenceMatches requires Bundle=com.duoface.native.scenehost, samehostscene/session, Active1.
DFTouchOwnerProbe.m DFWatchdog calls DFStopProbe when DFOwnerAcceptPulse fails, even with freshpulse/Active1/sessionmatch1.
Activating Maps backgrounds DuoFace; observerlosesoldDuoFacecandidate and writes Active0; watchdogthenclosesallChrome windows/otherapp and revokes B1. Runtime repeats7times with precise causal ordering.
DF182MapsOwner.restore restores its saved native UIKit frame/containment afterrevocation; it does not prove native framebuffer size/global workspace state is restored. One recorded restore uses414x736 (30566), others640x360. Do not claim render restoration success from that readback alone.

## Corrections to previous image-only diagnosis
Premature hiding/clearing prior pane and missing failure-transaction rollback remain real source defects. However, these8observations did not fail at catalog/launch/scene gates: all reached placement. The directly observed primary blocker is old ownership-policy teardown during native Maps activation, not a presumed pre-placement failure.
The photo's exposed map/launcher is consistent with the split disappearing and native UI remaining. Exactphoto→assignment correlation and touch still lack evidence; do not invent them.

## Verdict and next scoped repair target
- Runtime private-method ABI/catalog/nativeMaps presentation: observed in this trace.
- Sustained split/lifecycle/otherpane preservation: FAIL (7watchdogteardowns). Globalframe acceptanceFAIL; the logged framePASS/localrestorePASS is insufficient and must not be presented as overallB1PASS.
- User visualregression reportIMG8131 corroborates failedcomposition; touchUNVERIFIED.
- OFF/ONstate/hypothesisUNVERIFIED.
- Repair must transfer/recognize only a verifiednativeMaps assignment as valid ownership for thatsamefreshsplit session, preserving strictHome/revoke/disconnect/expiry protections. Do not remove watchdog or allow arbitrarybackgroundretention.
- Also implement an actual pane/nativeframe transaction rollback and invalidate priorframePASS when splittearsdown.
- This check makes no source/build/DEB/publisher changes. B1 remainsSTOPPED under the user's gates; bring this evidence before changing ownership mechanics.
