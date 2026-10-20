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
