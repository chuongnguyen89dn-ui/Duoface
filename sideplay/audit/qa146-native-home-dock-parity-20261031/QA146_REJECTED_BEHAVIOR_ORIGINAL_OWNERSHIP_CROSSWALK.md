# QA146 rejected as an interaction architecture — user physical feedback 2026-10-31

## Fresh original ARM64 crosswalk after user rejected QA146 (CONFIRMED STATIC EVIDENCE)

Independent GitHub Actions read-only [run 41186440398](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41186440398), job `124494211869`, **SUCCESS**. The workflow downloaded the actual central skill ZIPs 01/02/05, unpacked and read their `SKILL.md`, SHA256-validated original DuoNavi 1.0.4 and Native12-derived reference, and DuoDash repack, then decoded the actual *methods and same-function selector xrefs* (without reproducing proprietary code). Source `scan_original_navigation_imp_crosswalk.py`; immutable output `sideplay/audit/qa146-native-home-dock-parity-20261031/runs/41186440398/ORIGINAL_NAV_DOCK_ORIENTATION_IMPS.json` and receipt `CI_RESULT.txt`, archived in this project branch at commit `abdff164fd9acd6e7ca1c37424518d442acdd476`.

**New high-confidence structural finding, beyond old generic selector strings:**

| Original method; actual IMP | **same function** selector xrefs (not just dylib-wide strings) | QA146 parity gap |
|---|---|---|
| DuoNavi `CBBridgeManagerDashboard -bridgeDidActivate:` @ `0x2c70cc` | `setActivated:` → `setAppDockActiveBundleID:` → `setHomeButtonInApp:` | QA146's `DF144Solo begin:` sets its own UIWindow but never synchronizes real app Dock active bundle or Home-in-app display state |
| DuoNavi `-bridgeDidDeactivate` @ `0x2c7140` | **same three selectors**, decoded in its own deactivation method | QA146 stops its own scene via Darwin notify but does not restore original Dock/app/Home navigation state |
| DuoNavi `-setHomeButtonInApp:` @ `0x2c73d0` | references `homeButton` and `setDisplayState:` | Native Home control state explicitly managed by original bridge, not simply `homeButtonUp:` with window delete |
| DuoNavi `-prepareHomeScreenForBridge:` @ `0x2c5f3c` | `showingApp`, `closeOfficialTopApp:` | Original has a Home-screen transition/preparation before bridge; QA146 consumes selected tap then overlays without equivalent modeled transition |
| DuoNavi `CBBridgeManager -runningBridgedApplications` @ `0x2a32b4` | `currentApp`, `appViews`, `allApplicationProcesses`, `applicationWithBundleIdentifier:` | Original tracks active/previous bridged apps; QA146 only stores one `DF144Owner.bundle` and has no native recent-app identity update |
| DuoNavi `CBBridgedUIAppView -updateSceneSettingsFrame` @ `0xad368` | `setContentReferenceSize:withInterfaceOrientation:`, `setContentReferenceSize:withContentOrientation:andContainerOrientation:`, `sceneHandle`, `sceneIfExists` | Original has scene-settings/orientation coordination, not merely a generic external UIWindow frame |
| Native12-derived `-bridgeDidActivate:` @ `0x2a4738`, `-bridgeDidDeactivate` @ `0x2a47ac` | **both repeat `setActivated:`, `setAppDockActiveBundleID:`, `setHomeButtonInApp:`** | Independent corroboration in derived reference; do not misrepresent Native12 as pristine vendor original |
| Native12-derived `-updateSceneSettingsFrame` @ `0xad5bc` | same two `setContentReferenceSize` orientation selectors | Second source supports explicit scene orientation dimension contract |

The scanned original contains **18 matched DuoNavi methods** and **17 Native12-derived methods**, including `startBridging:` / `stopBridging` and separate split managers. The fresh scanner's legacy `MachO.classes()` cannot resolve the *repacked* DuoDash's dyld-fixed class pointer (`ValueError: cannot map Mach-O address 0x100000000db0d0`), correctly recorded as **unknown/not absent**. Earlier DuoDash separately verified concrete native method IMPs `onHostRequest:` vs `onHostRequestSplit:`; no false claim of fresh decoded Dock paths from that repack.

**Consequence:** There is now concrete original-machine-code evidence that **app active status + Dock active icon + Home-button display-state are coupled to bridge activation/deactivation**. Current QA146 is a side-layer host missing those transitions. This explains the architectural mismatch, but **does not establish exact runtime branch/latency on iPhone or directly authorize reusing vendor/private license code**. Next independent implementation must represent that ownership state with measured live iOS16.7.16 APIs, not copy original IMP code and not fake a Dock icon by painting UI.

**Explicit gate:** do not publish an additional speculative Sileo QA147 for mere Home-icon or orientation toggles. Require (1) verified legitimate native Dock controller/model owner on the user's iOS build; (2) independent pending→active→deactivated state machine; (3) verifiable previous-screen/back policy; (4) app-scene orientation readback and user event responsiveness. Current QA146 remains behavior-rejected and unchanged.

---


**Project** `chuongnguyen89dn-ui/Duoface`, branch `feature/duoface-qa146-native-home-exit-20261031`. **Current public QA146 remains a real signed, SHA-verified Sileo package, but the user's physical test rejects its semantics.** Do not mark "fixed" from compilation, signed package, Pages verifier, or successful rendering of one selected app. **No new Sileo package, source fix, or physical verification is claimed by this audit.**

## Latest user acceptance criteria — supersede former simplifying assumptions

The user confirms direct selected Home app can render but identifies **four independent failures**:
1. App navigation/launch reaction is slow relative to original DuoNavi/Native12/DuoDash-type DEBs.
2. Pressing Home loses the *current navigational screen/context* and jumps straight to CarPlay Home; this is not the behavior the user is asking to reproduce. **Do not assume "always jump to Apple's CarPlay icon grid" is an accepted Back/Home semantics.** Need actual vendor state-machine and physical transition evidence, including Apple Home vs Dashboard/recent-app/current context.
3. Currently opened external app is **not present as a recent/active app in the real native Dock**.
4. Several apps have **wrong interface orientation**.
Overall: displaying an externally hosted app atop CarPlay is not sufficient; must integrate actual navigation, active scene/app ownership, Dock bookkeeping and per-app scene orientation. **Stop using more standalone UIWindow/notification/forced Home patches as the presumed solution without verified original behavior.**

## Verified current QA145/QA146 architecture (source, not inference)

- `DFHomeStandalone144.m`, compiled into CarPlay Dock and SpringBoard modules: selected native `DBDashboardHomeViewController iconManager:launchIconForIconView:` is intercepted; writes `standalone144-request.plist` and `notify_post(...standalone144.request)` **without invoking native original Home selected-app activation** for approved apps.
- SpringBoard `DF144Solo begin:`: allocates **separate** `UIRootSceneWindow` via `FBSDisplayConfiguration`, sets `w.windowLevel=UIWindowLevelNormal+1`, creates a transparent root and attaches `[[DFSceneHost sharedHost] hostViewForBundleID:]` with `setSplitMode:NO`. This is **external overlay scene hosting**, not code that updates `DBWorkspace`, CarPlay active application identity or native Dock recent-app model. A drawn app view can coexist with a native workspace that thinks a different app is active.
- The native CarPlay Dock owner `DFCarPlayOwnerObserver.h` uses native `DBRootStatusBarViewController homeButtonUp:`; QA146 added `notify_post(standalone144.stop)` **before** the older DuoFace-only session gate; the SpringBoard receiver calls `[DF144Owner stop:@"native-Home-exit"]`, hides the overlay and releases its hosted view. It does **not** transition a correctly registered workspace/previous-scene stack; original native Home continues. User reports this loses the expected current page.
- `DFHomeStandalone144.m` optional `DBDashboardHomeViewController viewDidAppear:` hook did not install on real iPhone Log22: **`native-home-hook-installed tap=1 home=0`**. The QA146 button interception addresses window persistence but not original navigation semantics.
- `DFSceneHost.m` owns app scene orientation/resize policy separately; YouTube-only app-side `DFYouTubeOrientationRelay.m` and `DFSceneOrientationPolicy.m` exist. None proves a general-app standalone orientation contract. Do not infer multi-app orientation parity from a YouTube-specific or split-owned handshake.
- The cross-process protocol is write-plist + Darwin notify + asynchronous SpringBoard scene host. Physical Log22 shows only **two app requests** accepted (`Facebook`, `YouTube`), their `pending-scene` recorded ~0.120s and ~0.225s after selected tap, respectively, **no scene-ready/verified-PID ACK or Home stop**; no exact *visual responsive latency* measured. A possible asynchronous architecture delay is a hypothesis, NOT a measured explanation for subjective slowness.

## What the verified original/ref binaries actually establish

All five package checksums, 449 extracted files / 31 Mach-O and six DuoNavi Home ARM64 functions are available in
`sideplay/audit/qa144-standalone-home-20261031/runs/41179261436/` (job 124473114983 SUCCESS). References: DuoNavi **original 1.0.4** SHA256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`, Native12 **derived** SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`, DuoDash **repacked not pristine** SHA256 `ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465`, original OmniCar SHA256 `d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd`, SidePlay original SHA256 `7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c`.

- Six actual same-method original DuoNavi Home callback references follow `setIcon:` → `shouldInterceptLaunchForApp:` → `startBridging:` → `pending` → `activated` → `stopBridging` (e.g. `iconview` function `0x311094`, references at `0x3110f4`/ `0x311144`/ `0x311164`/ `0x31119c`/ `0x3111d8`). This is **static method-local selection/lifecycle structure**, not proof of a specific runtime branch.
- Original `CBBridgeManagerDashboard` declares **`prepareHomeScreenForBridge:`**, **`bridgeDidActivate:`**, **`bridgeDidDeactivate`**, **`setHomeButtonInApp:`**, **`startBridging:`**, **`stopBridging`**. `CBBridgeManager` declares **`trackBridgedBundleID:`**, **`runningBridgedApplications`**, **`requestStateChange:`**, **`loadNewAppFromCurrentRequest:`**; the method separation is directly seen in the decoded ObjC metadata. Thus original has explicit state/navigation/active-app API surfaces missing from a simple window overlay, though their actual call ordering/coupling still requires deeper disassembly or original runtime logs.
- Original `CBBridgedUIAppView` declares **`hostedScene`**, **`refreshSceneLayout`**, **`updateSceneFrame`**, **`updateSceneSettingsFrame`**. DuoNavi tweaks inject in **CarPlay/CarPlayApp/Dashboard, SpringBoard and app-side YouTube/VLC/Maps** (verified original package filter); this is consistent with explicit per-app lifecycle/orientation support but is **not physical execution proof**.
- DuoDash REPACK has separate **`CNABSpringBoardObserver -onHostRequest:`** versus **`-onHostRequestSplit:`**, and `CNABUIApp -setBridgeState:width:height:orientation:`. These are separate native binary IMPs and show an intentional app-side orientation/bridge-state path; do not claim full stock DuoDash native Home/Dock callback parity yet.
- OmniCar original `OmniCarAppBridge.plist` targets UIKit while `OmniCarSplitScreen.plist` targets CarPlayApp/SpringBoard; different modules for app-side scene and CarPlay ownership. No exact native Dock selection/active-app method was decoded by prior bounded scanner; unknown.
- Apple official documentation: CarPlay uses system-managed **scene lifecycle**; the real Dock's edge displays recent-app icons and launches those apps, and Home/Dashboard navigation are separate controls. Official references `https://developer.apple.com/documentation/carplay/cptemplateapplicationscene`, `https://support.apple.com/en-gb/guide/iphone/iph5f6b2beb5/27/ios/27`. This does NOT imply unsupported third-party UIKit apps natively receive Apple CarPlay entitlements.

## Crosswalk / blocking missing evidence

| User-visible symptom | QA146 actual path | Necessary original-like behavior / evidence |
|---|---|---|
| Reaction slow | plist request + Darwin notification + SpringBoard async remote host; `pending-scene` only | Measure tap→owned scene activation→first-frame→input and original DEB on same iPhone; no numerical latency claim absent timestamps |
| Home goes to wrong screen | system `homeButtonUp:` + forced standalone stop, no previous view workspace state | Decode original `setHomeButtonInApp:`, `prepareHomeScreenForBridge:`, bridge activation/deactivation and prior-app Home/Back policy; real screen transition before change |
| App absent from Dock | separate `UIRootSceneWindow` not a native workspace change or recent app state | Trace native Dashboard/DBWorkspace selected/active app, actual Dock recent app model and/or original bridge integration. Do not counterfeit Dock icon by adding overlay fake buttons |
| Wrong app orientation | host size and YouTube-specific app relay; no universal standalone handshake | Examine original `updateSceneSettingsFrame` and `setBridgeState:width:height:orientation:` with per-app scene/client orientation/geometry and physical cases |
| Incomplete app ownership | Log22 reports `pending-scene` after accepted calls, not `ready` | One app owner authoritative state machine (pending→active→previous/paused→deactivated), verified CarPlay scene/host PID and app side ACK, no split UI |

## Engineering decision (this checkpoint)

**QA146 is physically behavior-rejected**, even if its signed DEB/Pages and native selected app click work. Stop making QA147 "Home shortcut", Dock fake-recents or blanket portrait fixes. Preserve QA146 byte-for-byte, leave deployed package unchanged until a verified replacement or explicit rollback decision; **no new app code/build/Sileo in this audit**. Next work is **read-only original binary method/IMP crosswalk** for `setHomeButtonInApp:`, `prepareHomeScreenForBridge:`, `bridgeDidActivate/deactivate`, `trackBridgedBundleID:`, Dock model ownership and app-side scene/orientation, then controlled physical original-vs-QA146 transition timings. Build an independent equivalent state machine only once original critical transitions have verifiable evidence; no vendor code/license copied.

## Reproducible source status

- QA146 signed source SHA `1159f7119d515a5eefe0959ce9aa6701d92a62bb`, [signed build 41185002153](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41185002153) SUCCESS; public [Sileo run 41185275192](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/41185275192) SUCCESS. These only attest package and hosting, not correct behavior.
- QA145 real user Log22 source main commit `ce436ddb04e62d1762531a97ad74e21d3354a34d` / `sideplay/log/DuoFaceAudit 22.txt`, SHA256 `21dc19c52406ae3f1b8ac8a3b39bf48457ac694dddcf2b3591e32ed12a9edc54`, parsed via [41184755646](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41184755646), report `sideplay/audit/qa145-log22-home-exit-20261031/LOG22_STANDALONE_EXIT_FINDINGS.json`.
- **No newly uploaded Log23** in current `main` at review (HEAD `ce436dd`). User's new QA146 experience is direct statement only; do not invent QA146 device logs.
