# iOS 16 DuoFace Native Host CarPlay admission — multi-source research BEFORE any next device QA
Date: 2026-10-20. Work repo: `chuongnguyen89dn-ui/Duoface`. Current native admission source branch: `feature/duoface-firstparty-carplay-admission-20261020`, source checkpoint `dc2f310d95d2f1b88f50626dc92afc75b94d19c8` (device-evidence append); main handoff is `sideplay/tiep tuc du an.md`.

## Scope and confirmed device facts
- iPhone X, rootless iOS16, external DiPlay CarPlay. The user has **not** seen the white DuoFace Native Host icon on the physical head-unit CarPlay Dashboard; it exists only on iPhone.
- Real iPhone QA 0.1.4: `opt-in two typed getters armed via startup`, `consent signal received`, `already armed: qa-notify`. This only proves hooks installed in `CarPlay`, not that they were exercised for the bundle.
- Real iPhone QA 0.1.5: `roster-readonly appProxy=present bundleMatches=1 lookupABI=@24@0:8@16 manifestABI=@32@0:8@16#24 CarPlayRole=declared (NOT Dashboard admission)`. This proves **in-process** `LSApplicationProxy` lookup and manifest scene-role declaration, **not** membership in `DashBoard` filtered app library, Apple entitlement, or launch.
- No screenshot contains `bundle=com.duoface.native.scenehost ... original=nil result=number`, so no positive entitlement override has been observed. The hook only logs a narrow successful override; absence does not prove no getter was called.
- Last public packages: QA `0.1.5~roster1`, candidate `0.0.3~roster1`, Native Host `0.0.1~scenehost1`, Sileo publisher run `39400536022` verified. DO NOT repeat previously successful consent / proxy / scene-role probes.

## Sources compared — exact evidence and limitations

### 1. Apple official CarPlay integration
- https://developer.apple.com/documentation/carplay/requesting-carplay-entitlements
- https://developer.apple.com/documentation/carplay/displaying-content-in-carplay
- Apple requires an approved category entitlement and corresponding provisioning for normal CarPlay apps; the OS manages authorized scene creation. Adding a `UIApplicationSceneManifest` role is **insufficient** by itself.
- Apple's regular `CPTemplateApplicationScene` and navigation-specific scene instructions are **not** a general permission to show any arbitrary UIKit screen on a vehicle. DuoFace's jailbreak admission path is independent and relies on private iOS behavior; cannot pretend the official API grants it.

### 2. CarSurf (strongest VERSION-MATCHED independent public source)
- https://github.com/pavunato/carsurf , README claims working iPhone X iOS16.7.12, but our team **has not tested it** on the user's rootless/DiPlay setup.
- `sbtweak/CSSystem.plist` targets **SpringBoard, CarPlay, CarPlayApp, CarPlayTemplateUIHost, CarPlaySettings** (and `carkitd` with protective behavior); compared to our `DFFirstPartyAdmission.plist` which filters only `CarPlay`.
- `sbtweak/CSSystem.m` chooses LS typed getter path for iOS15–17, CarKit for iOS18+, and can install at dynamically loaded CarPlaySupport image; warns incorrect hooks can crash SpringBoard/car hosts and carkitd may loop.
- `sbtweak/CSSceneManifestSpoof.m` reports iOS16 `DashBoard +[DashBoard _newApplicationLibrary]` → `FrontBoardServices _proxyPassesInclusionFilter` → `LSBundleProxy entitlementValueForKey:ofClass:valuesOfClass:`. It also handles a distinct SpringBoard app-library cached-values path, but substitution must respect the original object types. A selector existing does not prove its gate fires in the user's real process.
- `sbtweak/CSAppList.m` queries genuinely CarPlay-capable apps vs user-enabled apps and builds an allowlist rather than blindly displaying the whole LS roster.
- `docs/troubleshooting-framework.md` stresses recording exact failure, original object class, process/pid and freshness **before** patching, with emergency recovery.
- **License:** prior repo audit found no LICENSE / license metadata. Public code may be read for architectural understanding only. Do not copy source/derivatives into independently authored DuoFace.

### 3. CarPlayEnable / carplay-cast (historical architecture, NOT demonstrated iOS16)
- https://github.com/EthanArbuckle/carplay-cast , `src/hooks/CarPlay.xm`, `src/hooks/SpringBoard.xm`, `src/CRCarplayWindow.mm`.
- Uses `+[CARApplication _newApplicationLibrary]`, custom `FBSApplicationLibraryConfiguration`, and generated CarPlay declarations to make app icons; SpringBoard receives a launch notification and hosts a bridged view. Includes a **custom Dock/window** approach, not proof of native Apple-owned Dock.
- Public crash report https://github.com/EthanArbuckle/carplay-cast/issues/58 describes SpringBoard safe-mode failures on older iOS14 after tweak update.
- Repo uses Apache-2.0 (verify license obligations before derivative work). Its old iOS14-era private selectors are not a drop-in for this iOS16 rootless target. No automatic code transplant.

### 4. CarPlay entitlement re-sign method — separate hypothesis only
- https://github.com/danielyc/carplay-enabler describes TrollStore resigning with an audio CarPlay entitlement.
- Different from our runtime first-party scene-host path. Re-signing an unrelated feature category does **not** establish the correct CarPlay scene role, authorization, or two live panes. No user-device proof for this option.

### 5. Historical CarPlayActivator safety reference
- https://github.com/pigigaldi/CarPlayActivator targets running CarPlay UI over SpringBoard rather than adding our independent app; author explicitly warns it is buggy and can brick SpringBoard. Not appropriate as an admission implementation. Supports conservative rollback discipline.

### 6. Local version-proven DuoFace/SidePlay/Native12 audit
- `main:sideplay/audit/carplay-open-source-20261020/OPEN_SOURCE_CARPLAY_SURVEY_AND_QA6_ROOT_CAUSE.md` already studied multiple sources for the **Dock**, but that study did not validate first-party app **admission**.
- `main:sideplay/audit/carplay-open-source-20261020/DUOFACE_TWO_APP_NATIVE_DOCK_JOIN_MAP_20261020.md` distinguishes app-library admission → Dashboard workspace/scene ownership → UIKit window → TWO live bridged app slots. V1BC demonstrated two user apps on a SpringBoard-owned external window but without stable native Dock; this cannot be fixed by treating a foreign window as Dashboard-owned.
- `main:docs/duoface-vs-duodash-app-selection-iphone-carplay-20261016.md` confirms choosing bridged apps on iPhone vs those icons becoming eligible on car are two separate layers.
- Original `main:dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb` and Native12 disassembly/reference assets should be consulted for scene/wiring concepts only. Do not copy proprietary binaries/license code into independent DuoFace.
- In our own `sideplay/duoface-native-scene-host/entitlements.plist` the declared keys are platform/no-container, not Apple CarPlay entitlements; its `Info.plist` scene role was confirmed by user QA but is not authorization.
- Our `sideplay/firstparty-carplay-admission/DFFirstPartyAdmission.m` filters ONLY the `CarPlay` process and hooks two `LSBundleProxy` typed getters. It requires BOTH `expected` and `valuesExpected` to equal `NSNumber.class` for synthetic return. Public comparator checks only expected class. This MAY suppress a real iOS16 admission query; record actual arguments before changing (not proven cause).
- Our hook gets armed asynchronously on the main queue during startup, raising a **timing hypothesis** that an app library may already be built before arming. Again unproven until a timeline or callsite is established.
- We have **not yet** verified which process, invocation timing and return *object type* determines system-owned Dashboard inclusion on this particular device.

## Ranked hypotheses (NOT declared root causes)
1. **H1 — process/roster gate incomplete:** SpringBoard and/or another CarPlay host builds a cached app library not affected by a filter limited to `CarPlay`. Supported by direct source scope gap and independent comparable source, but unproven on this exact iOS build.
2. **H2 — wrong getter/type/ABI policy:** current gate never produces a positive override due to key/argument/class/return constraints, despite being 'armed'. Photo only establishes installation, no positive return. Requires an observational method-call trace, not new spoofing.
3. **H3 — initialization timing:** CarPlay library initialized before the hook installation. Current QA logs lack startup timestamps/PID and calls; cannot exclude.
4. **H4 — post-roster native scene/launch:** even if admitted to an app library, an incompatible scene broker/entitlement policy can prevent a `UIWindowScene` being issued. Validate *after* physical icon is observed; do not work on Dock before then.

## GO / NO-GO engineering plan to eliminate redundant hardware QA

**NO-GO for new public Sileo or unsafe SpringBoard hook today.** Static source research cannot by itself establish exact runtime return values or prove native Dashboard admission.

A. **Offline-only next:** create a single source-level coverage table for classes, process, ABI, hook installation time, caller/callee, original return type, allowlist, and effect on app roster. Compare `DFFirstPartyAdmission`, earlier `DFSpringBoardAdmissionProbe` and two independent public approaches. Find which evidence is missing. Confirm no rootless/RootHide assumption leak and decide which of H1–H3 a single observation could differentiate. No new DEB per individual hypothesis.

B. **Instrumentation decision:** if still required, design ONE read-only and *strictly reversible* consolidated diagnostic gathering only the host's eligibility state across the actual relevant processes (not global entitlement overrides), a bounded log, exact OS/selector/object type, process PID + timestamp, and absence of side effects. Safety review source, static checks, rollback and if feasible isolated CI before offering it for an iPhone test. If correct object cannot safely be read, **stop** rather than guessing.

C. **Only one hardware acceptance cycle per validated implementation:** pass/fail conditions: physical CarPlay Dashboard icon appears; user presses once while parked; `DFNativeHostCarSceneDelegate` logs system-issued `native-carplay-scene-connected`; native Dock remains system-managed, no exitmode, no arbitrary foreground app hijack; rollback/off works. Then move to two independent iPhone app panes and split UI. A green CI / two getter hooks ARMED / `appProxy=present` / role declared is **not sufficient**.

D. **Preserve baseline:** QA `0.1.5` and gate `0.0.3` are the last publicly verified packages. Do not alter QA6/QA11/Native12/HUD8, original vendor references, active MyTweak recovery, Dock geometry or system app entitlements while doing this research.

## Execution record

This is **research only**. Investigated public webpages and public repository source plus existing private DuoFace report. Did NOT build, change injection code, test a phone, access live CarPlay process, or publish Sileo on this step.
