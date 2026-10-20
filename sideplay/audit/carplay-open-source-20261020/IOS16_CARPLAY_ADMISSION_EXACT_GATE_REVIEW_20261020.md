# CarPlay iOS16 — exact first-party app admission path review (source research, NO device build)

Date: 2026-10-20. Project: independent `chuongnguyen89dn-ui/Duoface`; work branch `feature/duoface-firstparty-carplay-admission-20261020`. Purpose: answer user's explicit question **"Bạn đã tìm kỹ vấn đề này chưa?"** with a precise code-grounded distinction between detection, roster inclusion, layout, launch and scene. Not an implementation success claim.

## Hard device facts, do not repeat tests

- User reports the `DuoFace Native Host` icon on iPhone Home Screen, **not** physical head-unit CarPlay Home.
- QA 0.1.5 observed in-process `LSApplicationProxy applicationProxyForIdentifier:` for `com.duoface.native.scenehost`: `appProxy=present bundleMatches=1`, `lookupABI=@24@0:8@16`, `manifestABI=@32@0:8@16#24`, `CarPlayRole=declared`.
- QA 0.1.7 device full log: `pid=16381`, `run=2A45B280-D173-41E9-91C3-187B50701EF2`, `preflightAck=1 version=5 hooksReady=1 typed3ABI=@40@0:8@16#24#32 DashBoardFactoryABI=@16@0:8; no application library invoked`. **No actual eligible-bundle typed getter sample** appears in the run. Missing sample does not prove no getter call ever occurred: trace was passive and may have been enabled after the roster was built.
- Actual CarPlay Dashboard is present, native system Dock 45x240 at x=0, user content x=45 width 462.3 (total 507.3x240). This geometry says NOTHING about app admission, own icon or system-owned first-party scene.
- Older SpringBoard read-only ABI report: `LSBundleInfoCachedValues boolForKey=B24@0:8@16 objectForKey=@24@0:8@16 numberForKey=@24@0:8@16`, `FBSApplicationInfo entitlementValuesForKeys:` = **selector-unavailable in that process**, `CARApplication=class-unavailable` there. Do NOT presume comparison source's caller/selector exists in this exact firmware/process.

## Primary sources inspected and what they establish

1. Apple official: https://developer.apple.com/documentation/carplay/displaying-content-in-carplay and https://developer.apple.com/documentation/carplay/cptemplateapplicationscene and https://developer.apple.com/documentation/carplay/requesting-carplay-entitlements. Apple-managed CarPlay categories need approved entitlements, CarPlay-specific scene configuration and the **system** issues the scene when a compatible icon launches. Ordinary UIKit `UIWindowSceneSessionRoleCarPlay` declaration alone does not grant CarPlay eligibility. The `CPTemplateApplicationDashboardSceneSessionRoleApplication` is **navigation Dashboard content**, not a generic shortcut to CarPlay Home app icons. Do not confuse them.
2. iOS15–17 version-matched public CarSurf sources:
   - https://github.com/pavunato/carsurf/blob/main/sbtweak/CSSceneManifestSpoof.m
   - https://github.com/pavunato/carsurf/blob/main/sbtweak/CSSystem.m
   - https://github.com/pavunato/carsurf/blob/main/sbtweak/CSSystem.plist
   - https://github.com/pavunato/carsurf/blob/main/sbtweak/CSAppList.m
   - https://github.com/pavunato/carsurf/blob/main/docs/ios18-runtime-carplay-admission.md
   * Their own iOS16 backtrace is `DashBoard +_newApplicationLibrary` → `FrontBoardServices _proxyPassesInclusionFilter` → `LSBundleProxy entitlementValueForKey:ofClass:valuesOfClass:`. This supports the **CarPlay app-library eligibility/filter** gate, not just LS installation.
   * They use typed2, typed3, **bulk** `entitlementValuesForKeys:` and scene-manifest info accessor (while retaining original private return-object class). `CARCapableApp` and `SBStarkCapable` are the two capability flag keys in their implementation. Their typed3 boolean path checks `expected` but not `valuesExpected` against `NSNumber.class`.
   * Their installer also applies a separately guarded `LSBundleInfoCachedValues` SpringBoard path, explaining that the system's **layout** data may exclude an app despite being present in the CarPlay library.
   * Their injection filter targets `SpringBoard`, `CarPlay`, `CarPlayApp`, `CarPlayTemplateUIHost`, `CarPlaySettings` and excludes dangerous behavior in `carkitd`. This is **the comparator's claimed architecture**, not proof all those processes are active/needed on user's build.
   * Crucial safety findings: replacing the real private entitlement object with a simple NSDictionary caused SpringBoard safe mode; a global cached-values hook without tagging a receiver may affect unrelated apps; iOS18 takes **another CarKit** route. Never blindly apply iOS18 code to iOS16.
   * CarSurf reports a tested iPhone X iOS16.7.12 RootHide, not independent confirmation of this user's rootless firmware and DiPlay. Its source is reference ONLY; no proprietary/unlicensed source code was copied.
3. Historical CarPlayEnable (older iOS version): https://github.com/EthanArbuckle/carplay-cast/blob/master/src/hooks/CarPlay.xm . Its `+[CARApplication _newApplicationLibrary]` override instead builds an `FBSApplicationLibrary` with `FBSApplicationLibraryConfiguration` and generates extra declarations, **another older approach**. The user's actual SpringBoard reported `CARApplication` unavailable in that process; old CarPlayEnable selectors are NOT verified on this firmware. Copying its wide app-library replacement is risky and not indicated.
4. Project current source: `sideplay/firstparty-carplay-admission/DFFirstPartyAdmission.m` and `DFFirstPartyAdmission.plist` only inject into `CarPlay`, install just typed2/typed3 getters, and require `valuesExpected` to be NSNumber when nonnil. The "successful override" message logs only on an eligible own-bundle call with original nil. The 0.1.7 audit can log only calls **during its 180-second interval** and did not trigger or observe actual roster creation.
5. First-party host `sideplay/duoface-native-scene-host/Info.plist`: declares `UIWindowSceneSessionRoleCarPlay`; `entitlements.plist` lacks an Apple-approved `com.apple.developer.carplay-*` entitlement. The project intends a jailbreak-only independent admission mechanism rather than Apple official category approval.

## What is verified vs unknown

**Verified implementation gaps:** no new SpringBoard roster implementation in the candidate; no bulk entitlement/cache/manifest getter handling in `DFFirstPartyAdmission`; only CarPlay-process two getter hooks. `valuesExpected` guard differs from comparator. Trace could miss startup calls.

**Not verified:** the exact real app-library creation call stack and object/filter data on *this* phone's CarPlay process; whether those absent code paths are necessary for this specific bundle; whether `valuesExpected` mismatch ever occurs on a real target getter; whether the library was built before hook arming; whether the native-scene broker would accept the app after it has an icon. Do not promote hypothesis to root cause.

## Engineering decision — one real solution rather than serial QA

- **STOP repeating** `armed`, `appProxy=present`, scene role, Dock dimension and v5 ACK tests: already proven and not sufficient.
- **Research/implement as a coherent admission pipeline**: iOS16-specific app-library eligibility + owner/roster/layout path (SpringBoard vs CarPlay host) + system-issued scene/launch. Preserve actual original object types and only change own-bundle conditions, with fail-closed ABI guards, default-off and emergency kill switch. Distinguish CarPlay Home application icon admission from navigation Dashboard content scene.
- Before any device build, establish a version-matched runtime identity for the private getter and the actual roster owner rather than blindly hooking `FBSApplicationInfo` that was unavailable. Verify inclusion with actual filtered roster membership and proper one-time system-owned scene; don't claim success from proxy or hook installation.
- **Acceptance:** (1) Native Host icon physically appears on CarPlay Home, (2) tapping obtains `native-carplay-scene-connected` from OS, (3) correct real 45pt native Dock and reliable touch, (4) no SpringBoard safe mode/respring/exitmode, (5) then build independent two-phone-app panels and UI. A working CarPlay admission implementation is NOT currently verified.
- No source-code modifications, CI, rebuild, Sileo or device tests performed in this research checkpoint. Public versions remain QA `0.1.7~ready1`, gate `0.0.5~ready1`, native host `0.0.1~scenehost1`, springboard probe `0.0.1~readonly1`.
