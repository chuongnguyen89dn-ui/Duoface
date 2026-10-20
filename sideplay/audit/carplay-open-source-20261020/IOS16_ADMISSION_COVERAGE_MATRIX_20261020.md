# iOS16 DuoFace — source-to-runtime admission coverage matrix (OFFLINE)
Date 2026-10-20. Scope: `com.duoface.native.scenehost` on the user's iPhone X / iOS16 + CarPlay/DiPlay.
Source repo: `chuongnguyen89dn-ui/Duoface`, development branch `feature/duoface-firstparty-carplay-admission-20261020`. This is a **static/source audit**. No device API reads, builds, installs, or Sileo releases are claimed here.

## Hard hardware constraints — already DONE (do not repeat)

- CarPlay-process typed getter hooks **installed** (`opt-in two typed getters armed via startup`), signal **received** (`already armed: qa-notify`).
- CarPlay-process `LSApplicationProxy applicationProxyForIdentifier:` **finds** our bundle: `appProxy=present bundleMatches=1`, lookup ABI `@24@0:8@16`.
- Its Info.plist role **declared** (`CarPlayRole=declared`), manifest accessor ABI `@32@0:8@16#24`.
- **The actual car Dashboard has no DuoFace Native Host icon.** This is a real negative result. No positive `bundle=...result=number` override was captured.
- SpringBoard earlier read-only inventory: `FBSApplicationInfo.entitlementValuesForKeys:` **unavailable** as tested, `LSBundleInfoCachedValues.boolForKey:` ABI `B24@0:8@16`; nothing about return-object identity/value has been measured.
- Last Sileo QA 0.1.5, admission 0.0.3, host 0.0.1. Do not regenerate QA variants per hypothesis.

## Matrix of calls / owners / proven coverage

| Gate & caller | Target process / phase | Actual selector or role / observed ABI | DuoFace source coverage | Evidence & remaining uncertainty |
|---|---|---|---|---|
| Host install visibility | `CarPlay`, runtime read | `+[LSApplicationProxy applicationProxyForIdentifier:]` `@24@0:8@16` | **Observed, not hacked.** One-shot `DFReadOnlyRosterProbe` | Device `appProxy=present bundleMatches=1`; **not** DashBoard inclusion |
| Host scene declaration | `CarPlay`, LS info read | `objectForInfoDictionaryKey:ofClass:` `@32@0:8@16#24` | Read-only `UIApplicationSceneManifest` | Device role `UIWindowSceneSessionRoleCarPlay` declared; **not** permission to launch |
| Entitlement gate (typed3) | CarPlay DashBoard's `_newApplicationLibrary` filtering per comparator's iOS16 backtrace; exact process/call in user device **not traced** | `-[LSBundleProxy entitlementValueForKey:ofClass:valuesOfClass:]` `@40@0:8@16#24#32` | Hook present, opt-in + own bundle only. Original returned first; synthetic `@YES` only when original nil and both expected/valuesExpected are NSNumber or nil | Hardware `armed` means hook installed; **no invocation arguments or successful override captured** |
| Entitlement gate (typed2) | `CarPlay`, potential wrapper | `-[LSBundleProxy entitlementValueForKey:ofClass:]` `@32@0:8@16#24` | Hook present, guarded | Not observed being called for this bundle |
| Bulk entitlement | Potential DashBoard/LaunchServices callers | `-[LSBundleProxy entitlementValuesForKeys:]` `@24@0:8@16` (prior SB inventory) | **No Hook** | No proof the targeted admission path uses this accessor on user's build |
| Cached app-library fields | `SpringBoard`, app-library/layout path per comparator | `-[LSBundleInfoCachedValues boolForKey:]` `B24@0:8@16`; object/number variants discovered earlier | Separate SpringBoard ABI inventory **only**, no live values or hooks | No safe evidence yet mapping a cached-value receiver to first-party host; never spoof global cache |
| Legacy FBS bulk | `SpringBoard` | `-[FBSApplicationInfo entitlementValuesForKeys:]` **selector unavailable on user's process** | Correctly not hooked | Do **not** copy older guides that assume this selector exists |
| App collection | CarPlay UI DashBoard/FBS app library (per external projects) | `DashBoard _newApplicationLibrary`, `CARApplication _allInstalledApplications`, `FBSApplicationLibraryConfiguration` | **Not implemented** in first-party candidate; only own bundle LS probe | Unknown whether this exact CarPlay process/filter instance contains the host |
| Framework arrival / startup | `CarPlay` bootstrap | `CFNotificationCenterAddObserver`; hook install enqueued via `dispatch_async(main)` | Observer runs on init, hook installation deferred until main queue & consent | **Ordering relative to library construction unmeasured** |
| Other CarPlay host processes | `CarPlayApp`, `CarPlayTemplateUIHost`, etc. | External process filters include these; iOS16 exact active host unmeasured | **Not injected** (`Filter.Executables=['CarPlay']`) | Process gap is a *candidate*, not proof it is where exclusion occurs |
| Scene broker & actual launch | OS-issued `UIWindowScene` role and `DFNativeHostCarSceneDelegate` | `native-carplay-scene-connected` in host log on success | Handler implemented to wait for native scene, no custom Dock | Cannot run before admission/icon; no user-device scene-connect evidence |
| Official Apple permission | Normal authorized app | Approved category entitlement + provisioning profile | No `com.apple.developer.carplay-*` in host entitlements | Jailbreak runtime method is separate from Apple-managed category authorization |

## Offline source findings ranked by actionability

**P0 / exact source gap (verified):** `DFFirstPartyAdmission.plist` only injects into executable `CarPlay`. CarSurf's broad multi-process coverage includes SpringBoard and other CarPlay UI processes, and separately handles the LS cached-values route. This is not proof SpringBoard is *the* missing link on our phone.

**P0 / instrumentation gap (verified):** Our hook only logs if it returns `@YES`, so an actual getter call with a real nonnil return, mismatched key, expected class, valuesOfClass, or bundle will not appear at all. The absence of `bundle=...` cannot distinguish no call / early call / class guard / roster exclusion.

**P1 / type policy difference (verified source, runtime effect UNKNOWN):** Our `DFEligible` rejects non-NSNumber `valuesExpected`; comparator CarSurf's boolean flag path checks expected class only. We should not loosen the gate blindly: must capture the *actual* class arguments and true return type in this build.

**P1 / timing risk (verified source, runtime effect UNKNOWN):** `DFAdmissionEntry` registers callback and enqueues `DFCheckConsentAndArm(@"startup")` on main queue. Comparable CarSurf waits for CarPlaySupport framework loading; there is no measured ordering against `_newApplicationLibrary` in the DuoFace log.

**P2 / not first priority:** The native scene's implementation and native Dock/window geometry will matter once system admits icon/scene. Doing them now repeats unrelated QA.

## Cross-source differences (architectural study only)

- **Apple official** `Requesting CarPlay Entitlements`, `Displaying Content in CarPlay`: OS-managed category entitlements and templated scenes. This cannot directly authorize arbitrary UIKit dual-app CarPlay host.
- **CarSurf**: [`CSSceneManifestSpoof.m`](https://github.com/pavunato/carsurf/blob/main/sbtweak/CSSceneManifestSpoof.m), [`CSSystem.m`](https://github.com/pavunato/carsurf/blob/main/sbtweak/CSSystem.m), [`CSAppList.m`](https://github.com/pavunato/carsurf/blob/main/sbtweak/CSAppList.m), [troubleshooting](https://github.com/pavunato/carsurf/blob/main/docs/troubleshooting-framework.md). Claims working on iPhone X 16.7.12, **not independently tested on user's DiPlay**; repository has no available reusable license in prior audit. No source copied.
- **Historical CarPlayEnable**: [`CarPlay.xm`](https://github.com/EthanArbuckle/carplay-cast/blob/master/src/hooks/CarPlay.xm) custom `_newApplicationLibrary` and FBS configuration plus SpringBoard hosted app window, rather than first-party native scene. Not demonstrated working on this iOS16 setup; native Dock not guaranteed.
- **DuoFace local audit**: `main:sideplay/audit/carplay-open-source-20261020/DUOFACE_TWO_APP_NATIVE_DOCK_JOIN_MAP_20261020.md` and `main:sideplay/audit/carplay-open-source-20261020/IOS16_FIRSTPARTY_ADMISSION_MULTI_SOURCE_REVIEW_20261020.md`.

## GO/NO-GO decision for a single consolidated device cycle

**NO-GO for another entitlement-spoofing DEB or multi-variant Sileo QA now.** This audit proves source gaps, not a winning fix. Next candidate must first be a **single read-only, one-shot bounded observability design**, not a second global SpringBoard hook:

1. Inspect whether a *non-injected* or differently named CarPlay UI host is the actual app-library owner on user's build, with process name/PID and framework presence. Capture exact call/receiver/arguments/return class (without altering returns) for **only** our bundle.
2. If SpringBoard is involved, associate any `LSBundleInfoCachedValues` receiver safely with our own bundle before retrieving one entitlement value. Earlier missing `FBSApplicationInfo.entitlementValuesForKeys:` means no assumptions about bulk return type.
3. Record monotonic order of hook installation vs first roster construction. Do not request the user to repeatedly reconnect or toggle old controls.
4. Require iOS16 + approved one-shot nonce + auto-disarm + log cap + kill switch + no global entitlement write + no auto-respring + no dependence on proprietary DuoNavi or unlicensed CarSurf code.
5. **Only after instrumentation proves the gate and callsite**, patch only the own-bundle condition and verify in a single parked-car run: physical native icon, system scene connect, native Dock and no exitmode. Keep stable QA6/QA11/native12/HUD8 unchanged.

## Reproducible offline script & limits

```sh
python3 sideplay/audit/carplay-open-source-20261020/verify_admission_coverage.py --strict --output /tmp/duoface_admission_coverage.json
python3 -m unittest discover -s sideplay/audit/carplay-open-source-20261020/tests -p 'test_*.py' -v
```

The script checks ONLY exact source invariants and snapshots a JSON coverage summary. `PASS_SOURCE_STATIC` is **NOT** a CarPlay runtime success or entitlement approval. This report alone does not run a build or touch the device.
