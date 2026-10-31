# QA137 physical Log17: native Home, GOFA boxed, intermittent DuoFace entry, TemplateUIHost crashes

Date: 2026-10-31 Asia/Ho_Chi_Minh. Status: **REAL DEVICE LOG CONFIRMED; no new functional fix or device-resolved claim**.

## Immutable user inputs

- **Real iPhone X iOS16.7.16 manual export**: `Duoface/main:sideplay/log/DuoFaceAudit 17.txt`, blob `06213ed85e80a00aa0445adc9fe6290ed65446b1`, size 6,133,947 bytes, 23,886 lines, uploaded by user in commit `488a2b5f416ca7ff91bc7c0c7d04379e5ad8344b`. Export time `2026-10-31 02:25:31 UTC`. Manually read original GitHub blob directly in this conversation (no OCR, no simulated device).
- Three additional original .ips on `Duoface/main:sideplay/log/` with same upload commit:
  - `Crash-0-CarPlayTemplateUIHost-2026-10-31-092358.ips` blob `503108467427829e21c10705bfe4d83c4de9bdbc`, capture `09:23:53.6671 +0700`, pid=89307, launched `09:21:00.1616 +0700`.
  - `Crash-2-CarPlayTemplateUIHost-2026-10-31-092437.ips` blob `9e3c7124d8d8eef7633e905b70c7af748aa5f44a`, capture `09:24:30.1408 +0700`, pid=89376.
  - `Crash-1-CarPlayTemplateUIHost-2026-10-31-092440.ips` blob `095e6c706b4355e674a4de03ce1aa3db5e0bf0d6`, capture `09:24:31.1286 +0700`, pid=89377.
- User physically reports no selected icons on Home; GOFA content boxed unless user opens GOFA on iPhone then quits from app switcher and retries in DuoFace; sometimes can't enter DuoFace at all.

## Native Home actual QA137 ABI (Log17 lines 9495-10265)

- In process `CarPlay` `bundle=com.apple.CarPlayApp`, **`+[DashBoard _newApplicationLibrary]` present** with exact ABI `@16@0:8` in image `DashBoard`. `-[DBWorkspace initWithOwner:]` present, `@24@0:8@16`. In SpringBoard, these classes are absent. **DashBoard is a framework/class in the CarPlay process, not a demonstrated separate executable**. Do not start hooking guessed Dashboard process.
- Actual **`CARApplication` class absent**, `_CARDashboardHomeViewController` class absent in both probed processes; its guessed `_setupIconModel` / icon manager callbacks therefore cannot be used unchanged on this iOS16.7.16. Prior original DuoNavi/Native12 static strings are NOT sufficient proof those exact classes loaded here.
- In CarPlay `FBSApplicationLibrary` exists, `DBApplicationInfo` exists, and 12 sampled newly added infos (six before + six after promotion) are **real `DBApplicationInfo` instances**, all return `carPlayDeclaration` method encoding `@16@0:8`; **`isCarPlaySupported`, `canDisplayOnCarScreen` and `launchAsCarApplication` getters absent**.
- Key **confirmed QA136 no-op**: source `DFHomePublisher136Core.m:DF136PromoteNewInfo` requires `DBApplicationInfo.isCarPlaySupported` + `setCarPlaySupported:` and returns without setting anything when missing. On this exact device the required getter is absent, so the `reconcile=6` result counts six records **without performing the intended promotion**. Whether `carPlayDeclaration` is nonnil/effective policy approved is still unmeasured (QA137 intentionally only samples selector existence and class, no private getter value).
- CarPlay `LSBundleProxy entitlementValueForKey:ofClass:valuesOfClass:` ABI `@40@0:8@16#24#32`, method image `DFFirstPartyAdmission.dylib`; `entitlementValueForKey:ofClass:` ABI `@32@0:8@16#24`, also in `DFFirstPartyAdmission.dylib`. **An existing first-party admission shim is already hooked**. Do NOT stack another global LS hook or spoof entitlements blindly. SpringBoard's three-argument implementation image `SocialSafariSpringBoard.dylib`; CoreServices two-argument implementation native.
- Log17 Home publisher section lines 9418-9494: process pid=89388 `reconcile=6 reason=CarPlay-start`, then repeated `reconcile=0`. These are library record observations, not proof of icons.

## GOFA boxed viewport evidence (Log17)

- `DuoFaceSceneHost.log` section lines 205-2453 contains 771 GOFA lines, **52** `scene-frame-readback` entries with **52 `same=0`**; `scene-frame-readback actual={{0, 0}, {375, 812}} target={{0, 0}, {793, 685}} same=0` repeated on first GOFA scene attach. This **is a physical stale iPhone portrait remote frame vs requested CarPlay logical frame**.
- Later GOFA frame values alternate `{793,685}`, `{397,685}`, `{647,685}` while targets change with split / zoom: the native settings update is asynchronous and mismatched at request time. These logs do **not** establish that later frames never settled; they prove initial mismatch and repeated size transactions, not definitive root cause of the user-visible boxed pixels.
- GOFA gets `host-created` **17**, `scene-attached` **19**, `scene-foreground-observed-only` **19**, `original-native12-scene-size-dispatch` **52** with `child2=0 child3=1 main2=0`, and new `FBScene` generations after recreation. This is compatible with the user's workaround of starting/restarting native iPhone GOFA to reset its scene, but explicit before/after process-level GOFA restart correlation is not logged.
- `DFSceneHost.m:commitSceneGeometry:` uses portrait-sized `DFHostedLogicalSizeForBundle`, attempts child 3-argument setter, reads old scene frame before issuing `updateSettingsWithBlock:` and never verifies **post-transaction ACK and actual rendered viewport**. GOFA 375x812 at initial scene mount is an accurate observation, not automatic success of a setter. Next repair should be owner/scene-generation-aware acknowledgment after size changes, not global force foreground or a guessed new viewport scale.
- Existing app picker log shows repeated `workspace-restore-attaching physical=0 bundle=com.lumi.GOFA generation=1` without render confirmation; some `scene-replace-committed-render-unverified` records, so a UI app-selected checkmark alone cannot prove correct scene dimensions.

## DuoFace intermittent inability to open on CarPlay

- Same Log17 `DuoFaceNativeSceneJoin.log` has **70** `CarPlay-template-role-issued-by-system`, **70** `native-carplay-template-scene-connected UIKit-issued CPWindow, not app-host success`, **53** `native-carplay-template-scene-disconnected`, and **31** `application-launched` records in retained tail. This is real repeated scene lifecycle churn, relevant to “sometimes won't open DuoFace”; no single cause proven yet.
- Three CarPlayTemplateUIHost .ips all **SIGABRT**, same `NSException` chain: `-[__NSCFString characterAtIndex:].cold.1` → `-[__NSPlaceholderArray initWithObjects:count:]` → `-[CPSDashboardGuidanceViewController setShortCutButtons:]` → `-[CPSTemplateInstance hostSetShortcutButtons:completion:]`. All are CarPlay's **system TemplateUIHost**, not a DuoFace-process crash; crash at shortcut buttons handling. The precise invalid string/element, invoking app/bridge, and relationship to DuoFace failure are not in these IPS; **cannot assert DuoFace caused the crash**.
- New priority: inspect whether a template scene/publisher or another installed tweak sends malformed shortcut-button descriptors; compare native host role/scene event timestamps and preserve iOS UI allowed native Dock. Avoid altering guidance shortcuts without proof.

## Next engineering actions and gates

1. **Do not immediately ship QA138 LS entitlement spoof**: QA137 proved existing `DFFirstPartyAdmission` already owns that exact CarPlay selector; duplicate hook may crash GOFA or Home.
2. Instrument real `DashBoard._newApplicationLibrary` factory as read-only in CarPlay, classify exact library (not instantiate), and nonnil `DBApplicationInfo.carPlayDeclaration` / policy (typed exact ABI only). Discover actual Home icon-model owner by loaded runtime class enumeration, avoiding guessed absent classes. Do not log user app contents or secrets.
3. For GOFA, compare first-frame/after-commit and distinct process scene lifetimes with physical app launch/quit; confirm `375x812` → `793x685` ack or stale scene before changing geometry code. Preserve QA135 GOFA baseline. Investigate whether current scene host reuses an old app scene and why native restart recovers.
4. For entry failure, investigate template UI crash `setShortCutButtons:` and role reconnect churn. Treat it as independent until process-level linkage found. Validate the exact user-visible failure after a new narrow diagnostic build / logs.
5. Acceptance: actual native Home app icon visible and tappable, GOFA full correct frame without iPhone manual restart, DuoFace scene open reliably, no CarPlayTemplateUIHost crash, no regressions to GOFA/Dock/YouTube/Maps/lock. **No QA138 compiled, tested, or deployed by this analysis**.
