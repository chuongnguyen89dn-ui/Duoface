# QA137 — real iPhone X Log17: Home missing, GOFA boxed, intermittent CarPlay app start

Date: 2026-10-31, iOS 16.7.16 (iPhone X). USER PHYSICAL VERDICT: QA137 Home icon NOT DISPLAYED; GOFA still boxed until opening GOFA on iPhone and terminating the app from the iOS app switcher before retry. DuoFace sometimes cannot be entered. These user reports take precedence over source-level CI green.

## Immutable real evidence

- User's GitHub main upload commit `488a2b5f416ca7ff91bc7c0c7d04379e5ad8344b`: `sideplay/log/DuoFaceAudit 17.txt` (6,133,947 bytes, 23,885 lines, SHA256 **590fc06720366d8a6f679b14008b084235ef05404af26deabc5040e4fc8c5b47**), captured 2026-10-31 09:25:31 +0700.
- Crash IPS: `sideplay/log/Crash-0-CarPlayTemplateUIHost-2026-10-31-092358.ips` (SHA256 `77eb80eb8dba9358755dd083e4a31cade65375378cde64eb7acf99fa3d34964b`); `Crash-1-CarPlayTemplateUIHost-2026-10-31-092440.ips` (`d1232dafecefd71ef28ccc5bb12821af99387bc3aa0228d44d890c83f40340e2`); `Crash-2-CarPlayTemplateUIHost-2026-10-31-092437.ips` (`5b50ee893101f4c366c2437146fea5e131e52ba44df78643ccfb9ff65a59a6e3`).
- Reproducible parser in this folder: `analyze_log17_gofa_home_crashes.py`, workflow `.github/workflows/duoface-qa137-user-log17-forensics.yml`. Script reads exact existing user upload with `git show 488a2b5:... ` and writes sanitized `QA137_REAL_LOG17_RESULT.json` without duplicating raw user log. CI status/ID in `CI_RESULT.txt` when verified.
- Never infer hardware success from CI replay of stored logs. This report is source/log evidence, not a new on-device test.

## A. Home: now have actual system class and invalid existing setter

Real `DuoFaceHomeAdmission137.log` section:
- `process=CarPlay pid=89388`, actual main bundle `com.apple.CarPlayApp`, OS 16.7.16; **`+[DashBoard _newApplicationLibrary] type=@16@0:8 image=DashBoard`** exists. In this process `CARApplication` **class-absent**, `_CARDashboardHomeViewController` **class-absent**. This disproves the assumption that the original must bind the CARApplication factory on this actual build.
- `DBApplicationInfo` class exists and **`carPlayDeclaration` getter type=@16@0:8** exists. However `isCarPlaySupported`, `canDisplayOnCarScreen`, and `launchAsCarApplication` getters logged **method-absent** on this class.
- Six freshly created, nonnil records are **concrete `DBApplicationInfo`**, proven by before/after `fbs-info` samples. `DuoFaceHomePublisher136.log` records `reconcile=6` in current CarPlay session, no `native-FBS-library-instance-not-exposed`.
- **Verified source defect:** `sideplay/duoface-native-scene-host/DFHomePublisher136Core.m:DF136PromoteNewInfo` returns if `DBApplicationInfo.isCarPlaySupported` getter or `setCarPlaySupported:` setter missing, hence on THIS ABI no promotion happens, and `infos.count` merely counts nonnil registered objects. The source has no native Home icon-model refresh/launch path.
- **Separate policy mismatch:** `sideplay/firstparty-carplay-admission/DFFirstPartyAdmission.m` only permits `com.duoface.native.scenehost`, not the six selected installed apps, so that existing typed LSBundleProxy entitlement hook cannot by itself authorize the user's selected app icon. Its `LSBundleProxy entitlementValueForKey:ofClass:valuesOfClass:` hook is actually installed in `CarPlay` (image name `DFFirstPartyAdmission.dylib`), but it is scoped to one first-party app. DO NOT broaden it globally or assume policy hook for GOFA.
- The actual Home factory is **DashBoard**, not `CARApplication`, and policy must respect the observed iOS16 exact ABI, real `DBApplicationInfo.carPlayDeclaration`, typed `LSBundleProxy` entitlement call and App Library build timing. Implement a narrow reversible allowlist later, after checking full declaration/launch contract. Do not patch a global entitlement dictionary.

## B. GOFA: real remote portrait scene and stale display frame, not simply Chrome width

Extracted from 2248-line `DuoFaceSceneHost.log` section:
- `com.lumi.GOFA`: **771** event lines, **52** `scene-frame-readback` pre-update observations, **52** remote frame differences, **19** with actual `{{0,0},{375,812}}` — ordinary portrait phone geometry — while host's logical target for a split/full pane can be `{{0,0},{793,685}}` (24 target mentions).
- **52** real `original-native12-scene-size-dispatch child3=1` and **52** `native12-scene-settings-live-contract-requested` calls. These prove the three-argument child setter and remote frame IPC were *requested*, **not that GOFA rendered the new map viewport**.
- `DFSceneHost.m` line 390: `commitSceneGeometry` returns early for cached `committedReferenceSize == pendingReferenceSize` (even if remote scene later silently resets to portrait within the same owner). The current `pollScene` resets cache only when the scene object itself changes. A remote-app/process reset without object identity change could therefore leave a stale viewport. This is a **concrete missing revalidation path**, not proof of exact causal chain for this user's app-switcher fix.
- `DuoFaceDockOwner.log` includes `native-owner-state active=1 visible-candidates=1 unique-duoface=1 hooks=1` in some sessions. Therefore the earlier QA134 fix for selecting the correct native DuoFace owner is not by itself proof that GOFA's remote app scene fits its pane.
- User observed opening GOFA on the phone then terminating it from multitasking restores GOFA in DuoFace on next open. This is consistent with GOFA application process / remote scene needing recreation, but no paired PID/after-write ACK was exported, so we cannot prove exact app-side trigger.
- **Next safe correction boundary:** diagnose same-session GOFA sceneHandle and GOFA PID/foreground transitions, apply post-write frame re-read and UIKit content pixel/trait readout for genuine owner; if the cache is stale while physical pane unchanged, revalidate only the live GOFA scene in bounded conditions, no global owner bypass, no arbitrary change to 0.50/2x viewport scale. Keep QA128 manual observer identity fix and QA132 lock-touch.

## C. Sometimes cannot enter DuoFace: 3 actual Apple template-host crashes, distinct process

Three user-uploaded IPS files show **`CarPlayTemplateUIHost` SIGABRT/EXC_CRASH**, at **2026-10-31 09:23:53.6671, 09:24:30.1408, 09:24:31.1286 +0700**, with identical `lastExceptionBacktrace`:
`-[CPSDashboardGuidanceViewController setShortCutButtons:]` → `+[NSArray arrayWithObjects:count:]` → `-[__NSPlaceholderArray initWithObjects:count:]` → ObjC exception → abort.
- This is **real evidence that Apple CarPlay template UI host repeatedly crashes**. It can disrupt template display and coincide with the user's intermittent failure to enter DuoFace. It is NOT a proven crash of the `DuoFaceNativeHost` app itself, because all three `procName` fields equal `CarPlayTemplateUIHost`. The precise bad shortcut source and ownership remain unknown. Do not attribute it to GOFA or DuoFace without a matched run/shortcut source.
- In `DuoFaceNativeSceneJoin.log` the app repeatedly reports `application-launched`, `CarPlay-template-role-issued-by-system`; sometimes `phone-scene-connected`. This means the iPhone app launch can succeed independently of the CarPlay template UI host crashing. No evidence of a failed iPhone app executable entry or matched crash trace is in these three IPS.
- Next identify which active CPTemplate and Dashboard guidance shortcut array call introduces an invalid object, inspect only the first-party registration/scene lifecycle around crash times; protect the stable Apple template UI host and native apps, avoid swapping arbitrary CPTemplate classes.

## Immediate implementation gates

1. Home (separate regression): no more re-registering six FBS records; target actual `+[DashBoard _newApplicationLibrary]` and typed admission for **user-selected third-party only**, preserve genuine native records and launch. Physical icon + click must pass.
2. GOFA: prevent remote cached portrait 375x812 frame persisting without post-write confirmation; do not change the physical split panel scaling or bypass Apple lifecycle.
3. DuoFace app access: reproduce `CarPlayTemplateUIHost` shortcut failure before changing native launch; distinguish template-host crash from iPhone app process and maintain rollback QA135/136/137.
4. No signed QA138 build, no Sileo change or hardware PASS in this audit.
