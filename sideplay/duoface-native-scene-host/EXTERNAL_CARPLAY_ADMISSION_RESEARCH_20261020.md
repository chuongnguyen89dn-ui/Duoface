# External-source verification: native Dock & independent DuoFace CarPlay admission (iOS 16)

Checked on 2026-10-20 after user asked explicitly whether outside-source research had been performed. **Research and verified user log**, not a claim that native admission or two touchable app slots now work.

## 1. Ground truth from the user's iPhone X (rootless iOS16)

Sileo package `com.duoface.carplay.nativejoinprobe 0.0.3~rosterabi1`; **MyTweak OFF, Bridge OFF, 45sec Dock trial OFF**.

```
native-admission-abi CARApplication=no allInstalled=class-unavailable byBundleID=class-unavailable
LSBundleProxy=yes typed3=@40@0:8@16#24#32 typed2=@32@0:8@16#24
bulk=@24@0:8@16 infoDictionary=selector-unavailable
FBSApplicationInfo=yes fbBulk=selector-unavailable DBApplicationInfo=yes
workspaceInitOwner=@24@0:8@16
native-workspace-abi workspace=yes requestStateChange=v24@0:8@16
controller=no request=yes activateApplication=v24@0:8@16 owner=yes
nativeChrome=1 native-bar-frame={{0,0},{45,240}}
full={{0,0},{507.3333333,240}} usable={{45,0},{462.3333333,240}}
```

This PROVES native Dock geometry and method **type encodings in the CarPlay process**. It does not prove `CARApplication` or `DBApplicationController` absent in SpringBoard/CarPlaySupport when it loads later, and does not reveal return *values/classes* for `FBSApplicationInfo` in SpringBoard. `infoDictionary=selector-unavailable` was checking `infoDictionary`, whereas CarSurf's actual iOS16 targeted metadata path includes `objectForInfoDictionaryKey:ofClass:`; do not mistake one accessor for the other.

## 2. External primary-source audit

### A. CarSurf, iOS15–17 runtime admission — MOST relevant

Repo: https://github.com/pavunato/carsurf (public source, **no LICENSE** visible as of this audit; study behavior, DO NOT copy unlicensed code).

- `sbtweak/CSSceneManifestSpoof.m` direct GitHub blob `c5c94ebc286a1286c1e5e0535be1194f4fcb6653`; near source lines 13–27 identifies **DashBoard `+[DashBoard _newApplicationLibrary]_block_invoke` → FrontBoardServices `_proxyPassesInclusionFilter` → CoreServices `-[LSBundleProxy entitlementValueForKey:ofClass:valuesOfClass:]`** as its iOS16 admission chain.
- The **typed 3-arg and 2-arg getters** queried in user's log are *exactly* CarSurf's iOS16 target selector names. It wraps the real method and distinguishes boolean NSNumber entitlement values expected by the caller. Knowing method ABI is not enough to safely change its result. No vendor license framework is required in our first-party *architecture*, but actual implementation must be independent.
- Near lines 195–205 and 283 onwards: **SpringBoard different pipeline**, `FBSApplicationInfo.entitlementValuesForKeys:` can return private **`LSBundleInfoCachedValues`** and callers invoke `boolForKey:`. Returning `NSDictionary` to that call is documented as causing *SpringBoard Safe Mode*. This is a concrete hard failure, **not** just a theoretical warning.
- `sbtweak/CSSystem.m` direct blob `9fd5418009495498f340b8fbb334cc13263aa4e8`: separates iOS16/17 LaunchServices admission and iOS18+ CarKit declaration policy; lazily loaded `CarPlaySupport` means class visibility at one instant may not capture every process/method. It installs CarPlay-related hooks in the responsible app and UI processes, avoids `carkitd` to prevent reconnection loop. Off-switch **before hooks** is necessary.
- `sbtweak/CSAppList.m` blob `9de45f39a292fb776be969d3db195b8f9803f79b` filters allowed app roster while **preserving genuine native CarPlay apps**. The two `CARApplication` class selectors are NOT observed in user's CarPlay process yet: don't transplant code and expect them to resolve.
- `sbtweak/CSCarLaunch.m` blob `b441933ba2e9a2f6886eca5cfa1686619a95097f`: tests native `DBWorkspace.requestStateChange:` and click-activation route, not "show Dock" command. In user's process `DBApplicationController=no`: no blind sharedInstance calls.
- `apptweak/CSSceneBridge.m` blob `e727b34484af37f5fa68121e96479b04b6396294`: converts incoming scene role BEFORE UIKit constructs it; changes after construction can crash. A real `UIWindowScene` is app-specific. This architecture does not solve simultaneous **two arbitrary app sessions** within one DuoFace parent.

CarSurf README: https://github.com/pavunato/carsurf/blob/main/README.md reports its own RootHide iPhone X iOS16.7.12 test and iOS18 rootless; **not** independent proof on user's rootless + DiPlay setup.

### B. CarPlayEnable / carplay-cast — historic compare, not a replacement

Repo: https://github.com/EthanArbuckle/carplay-cast (Apache-2.0 licensed according to GitHub, `LICENSE` present; do not copy code without applying actual license obligations).

- `src/hooks/SpringBoard.xm` https://github.com/EthanArbuckle/carplay-cast/blob/master/src/hooks/SpringBoard.xm: listens for CarPlay launch notification in **SpringBoard** and creates a private `CRCarPlayWindow`; has separate lock/scene lifecycle handling. This is **legacy** iOS14+ private-source-window hosting and does not by itself prove Dashboard gives the app its own CarPlay scene, or that native Dock remains natural.
- `carplayenable.plist` https://github.com/EthanArbuckle/carplay-cast/blob/master/carplayenable.plist: injection targets SpringBoard + CarPlayApp/UIKit. Its architecture is informative as a historic precedent for input/session management, not a drop-in source of iOS16 native admission.
- `TweakInspect` https://github.com/EthanArbuckle/TweakInspect provides disassembly/hook analysis tooling; documented `CARApplication` / dock selectors belong to older packages and not evidence they resolve on present iOS16 CarPlay process.

### C. Apple docs — scene lifecycle is system-owned and category-restricted

- https://developer.apple.com/documentation/CarPlay/displaying-content-in-carplay
- https://developer.apple.com/documentation/bundleresources/information-property-list/uiapplicationscenemanifest/uisceneconfigurations

Official CarPlay supports scene-based UI with system lifecycle and category-specific app entitlement/template roles; navigation category has limited direct window access. Simply listing `UIWindowSceneSessionRoleCarPlay` in `Info.plist` does **not** create a system-authorized entitlement. DuoFace is an independent jailbreak project using private APIs, not an Apple-approved generic mirroring CarPlay application.

## 3. What to implement next (explicit interfaces; stop/go gates)

```
                      CarPlay UI (native Dock, DBWorkspace)
           Dashboard app-list qualification and activation [MISSING]
                     |
     runtime iOS16 LaunchServices capability/scene manifest
        CarPlay process: LSBundleProxy (typed3/typed2) [ABI VERIFIED]
        SpringBoard: FBSApplicationInfo → cached LS values [NOT VERIFIED]
                     |
   own bundle: com.duoface.native.scenehost [BUILT, NOT ADMITTED]
             ↳ real UIKit-issued UIWindowScene required
                     |
        independent 2-pane DuoFace root/controller [FUTURE]
                 live input/session bridge [FUTURE]
                     |
           SpringBoard V1BC app A / app B live hosts [EXIST]
```

Implementation gate 1: inspect read-only `SpringBoard` ABI `FBSApplicationInfo`, `LSBundleInfoCachedValues` getter/accessors, and inspect actual owner process of CARApplication/roster. Use a self-disabling, low-risk process filter and QA log capture; no broad LS result substitution, no SpringBoard bootloop, no future background job. A **single** native app-admission debug gate is enough — avoid endless rounds of Dock measurement tests.

Implementation gate 2: a version/ABI-checked and OFF-by-default admission mechanism for ONLY `com.duoface.native.scenehost`, with fail-closed for other bundles or unknown return classes, kill switch/recovery before injection. Preserve all Apple genuine app records. Do not re-sign third-party apps or rewrite App Store bundle, no forked vendor license code.

Implementation gate 3: release isolated Sileo demo ONLY when local CI safety/build and rollback verified; parked-car test: native DuoFace icon becomes visible; tap it; actual log `native-carplay-scene-connected`; native Dock/Home works naturally for >2min, pause/exit/reconnect without reboot/exitmode.

Implementation gate 4: merge existing independent V1BC `MTSceneHost` (two real active `SBAppViewController` scenes) with native owner through actual remote live layer and full multitouch bridge; **DO NOT assume CarSurf can display two phone apps simultaneously on its own**. Use split/ratio/swap/Zoom from V1BC only after one full app's video and touch passes.

## 4. Evidence/state

**Verified:** external source code paths and source SHA for CarSurf; older carplay-cast code; Apple official docs; actual user ABI log. **NOT executed this audit:** no iOS source code modified, no CI build/release, no new device action. Stage-B scene host build run #39382552551 previously PASS; public Sileo ABI probe 0.0.3 run #39382915334 PASS. QA6, QA11, Native12, HUD8, V1BC and recovery untouched. This report is the next project's checkpoint and does not make up a functional host-admission result.
