# DuoFace first-party admission — CarPlay-only developer candidate

This is **not** a working DuoFace native app and **not published to Sileo**. Candidate isolated from the public SpringBoard readonly probe and QA app. No native UI or two-phone-app integration is asserted.

## Evidence

User's iPhone X iOS16 SpringBoard QA image 2026-10-20: one-shot status `complete`, `LSBundleProxy` typed3 `@40@0:8@16#24#32`, typed2 `@32@0:8@16#24`, `LSBundleInfoCachedValues` bool `B24@0:8@16`, `FBSApplicationInfo.entitlementValuesForKeys:` unavailable, `CARApplication` and `DBWorkspace` unavailable in SpringBoard. Previous CarPlay-process log had matching LSBundleProxy typed methods, Dashboard geometry 507.3x240 and system Dock 45pt, yet **no DuoFace scene admission**. These are signatures, not evidence of any getter return value or end-to-end launch.

## Candidate implementation

- New module injected **only** into process `CarPlay`, never SpringBoard. Version-gated iOS16. No maintainer scripts, process restart, Dock/window mutation, device activation, LaunchServices database changes or foreign-app admission.
- Constructor checks explicit `Enabled=true`, `RiskAcknowledged=true`, and `HostBundleID=com.duoface.native.scenehost` in `/var/mobile/Library/Preferences/com.duoface.firstparty-admission.plist`. Missing/invalid is OFF.
- Kill switch file `/var/mobile/Library/Preferences/.duoface-firstparty-admission-disable` wins over preferences; checked at startup AND at each eligible call. Since hook installation happens only once on process start, enabling later needs a naturally restarted CarPlay process; never force a respring on iPhone X.
- Requires **both** exact observed typed selector encodings before installing hooks. Each hook invokes the original first. Only when original returns nil, bundle identifier is the one first-party host, exact `CARCapableApp` or `SBStarkCapable` key, and expected return is `NSNumber` or unspecified, may it answer `@YES`. All other lookups untouched. The template entitlement getters, bulk getter and cached-values object are NOT hooked.
- Logs to `/var/mobile/Library/Logs/DuoFaceFirstPartyAdmission.log`.

## Unresolved

SpringBoard app library admission has an additional gate: its FBS bulk method was absent in this user's runtime, so there is **no evidence this CarPlay-only hook can make the app appear in the Dashboard**. The native host `com.duoface.native.scenehost` is a separately compiled but not installed/published development candidate. This package alone is insufficient for an end-to-end CarPlay test. Build results are independent of device validation.

Do not publish or enable this candidate automatically. After CI, inspect class-return behavior, build a reversible first-party SpringBoard roster strategy only after isolating the correct caller and verifying its ABI; prepare an interactive QA consent and rollback path before any device trial. Keep QA6, QA11, native12/HUD8 and published QA 0.1.2 unchanged.

References: external CarSurf iOS16 admission explanation (concept only; unlicensed files NOT copied), Apple CarPlay entitlements documentation. Original implementation independent and minimal.

## iOS16 device screenshot fix — version 0.0.2~signal1 / QA 0.1.4

User-supplied QA 0.1.3 screenshot showed config Enabled and an old constructor line
`[DFAdmission/CarPlay] idle: disabled or unsupported iOS`. The old module
returned early when consent was OFF at process load, so subsequent QA button
presses could not install hooks until process restart. This is a verified source
design flaw; it does not prove that any CarPlay native app was accepted.

This revision **registers only a Darwin notification listener at CarPlay load**.
After the user explicitly accepts QA consent, the iPhone QA app writes preferences
and posts `com.duoface.firstparty-admission.refresh`. The CarPlay module receives
the notification, queues validation on the main queue, rechecks current consent,
OS major version 16 and exact typed API encodings, and arms the two getter hooks
only when every gate passes. Repeating consent does not reinstall already-armed
hooks. The emergency OFF button creates the kill file and posts the same signal:
already-installed hooks become inert because all eligible lookups consult consent
at call time. Nothing restarts SpringBoard or CarPlay. If the module was never
loaded, no callback is expected; QA must not claim a successful registration.

Do not confuse the `opt-in two typed getters armed via qa-notify` diagnostic with
a real Dashboard icon or a UIKit-owned CarPlay scene: SpringBoard roster inclusion
is still unimplemented. Required on-device evidence: new log after clicking
Enable, actual first-party Dashboard entry and native scene lifecycle separately.

## Native Host absent from physical CarPlay Dashboard — iOS16 read-only roster check v0.0.3

Observed 2026-10-20: user confirmed native host icon exists **only on the iPhone**, not the head unit, while QA showed both getter hooks ARMED and consent signal received. This is a **negative device result for actual Dashboard inclusion**, not evidence of getter failure.

A separate user-initiated QA button sends a nonce + 30-second request to the existing CarPlay-only process. It reads `LSApplicationProxy applicationProxyForIdentifier:` for **only** `com.duoface.native.scenehost` after checking the exact method encoding, optionally reads this app's `UIApplicationSceneManifest` via a separately guarded read-only method, and logs whether it can find the bundle and scene role. It does not read other apps, enumerate SpringBoard state, insert records, hook new methods, mutate the Dashboard, or restart processes. It disarms the request on first handling. This is **not** a full Dashboard-roster enumeration: presence in LaunchServices is necessary but not sufficient.

Expected diagnostic log: `roster-readonly appProxy=present ... CarPlayRole=declared (NOT Dashboard admission)` or an explicit absence/ABI/exception. If present but still no icon, investigate CarPlay Dashboard inclusion policy and SpringBoard roster as a separate next gate with independent evidence and rollback. All historical QA/Native12/HUD8 behavior preserved.
