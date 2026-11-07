# Gate0 audit2 v2, Audit13, and OFF-first branch gate — verified 2026-11-07

## Update from user after Audit13 review — no further OFF retest
The user directly confirms the most recent physical session already included Google Maps being OFF/hidden in the stock paired-car Customize menu. Despite OFF, Google Maps was visible and touch-responsive inside DuoFace, with the same persistent wrong layout. This is an operator-observed physical outcome, **not** a verified programmatic OFF field on any Gate0 record; all those records still have UNKNOWN/UNVERIFIED. Do not send the user to repeat the same test. The next code target is native Dashboard presentation/pane geometry, a positive Maps owner attestation consumed by the existing SpringBoard watchdog lease, and transactional rollback of the second pane and Home.
Static reviewed source: feature/duoface-qa182-b1nativemaps1-20261107, DFCarPlayOwnerLease.h lines 17-43 hard-require com.duoface.native.scenehost in background; DFCarPlayOwnerObserver.h lines 73-127 only writes nativehost identity; DF182NativeMaps.m lines 170-174 can validate Maps actual owner but does not feed the lease; DFTouchOwnerProbe.m lines 521-533 watchdog stops the session; DFNative12Chrome.m lines 1981-2013 starts replacing prior content before verification, and DF182NativeMaps.m lines 325-344 places scene content into Dashboard. Audit13 17/17 assignments revoked. The exact cause of the user-visible wrong rendering is not proven by a viewport receipt alone; inspect native view containment, scene surface and geometry when repairing.
Only documentation changes occurred in this response; no new source, CI, DEB, installed package, or physical test. The rest of this report remains historical evidence.

## Source and identity
Repository: `chuongnguyen89dn-ui/Duoface`. Documentation branch: `spec-main`. User-uploaded real test logs are on `main` at commit `ccaaa2bc378c8790d03e0db9d798815fe1015478` (2026-11-07 03:02:12 UTC). No new implementation was written in this documentation pass.

| Source on main / sideplay/log | Git blob SHA | Evidence |
| --- | --- | --- |
| `DuoFaceMapsGate0-CarPlay.jsonl` | `0704c2d9ccb32fff30e0595a27402bcd97f5cc41` | 1270 JSON lines, 167 v2, v2 02:56:05–03:01:31 UTC |
| `DuoFaceMapsGate0-Preferences.jsonl` | `853b1c810c81639e258a506b8352e0071aacce2e` | 11 JSON lines, 7 v2 |
| `DuoFaceAudit 13.txt` | `29f53fd91a82f8d8edc7de1d4634b8a0aa896288` | 32,053 text lines, manual-export header 2026-11-07 03:00:32 UTC |

## Gate0 v2 facts read directly from the JSONL
- `version=2` CarPlay events: 167 total, including `presentBase.original-returned` 7 and `native.scene.snapshot` 125; 167/167 `auditMirrorWrite=complete`.
- The 7 presenter callbacks have target `com.google.Maps`, `DBApplicationSceneViewController`, attached native CarPlay window (`UIWindowSceneSessionRoleCarPlay`, `carplayRoleVerified=true`) and scene IDs beginning `Car[2-3]` or `Car[2-5]`.
- 54/125 v2 scene-tree snapshots: `sceneCount=1`, `nativeMapsScenePresent=1`. A positive scene-tree sample is a read-only observation, not stable physical pane ownership or pixels/touch/navigating acceptance. Prior v1 empty-snapshot result was inadequate evidence of no scene.
- v2 CarPlay: `stockSettings=UNKNOWN` 167/167, `stockSourceStatus=UNVERIFIED` 167/167; per-vehicle profile match false. Same values UNKNOWN/UNVERIFIED in all 1270 CarPlay and 11 Preferences records. Many candidate plists contain Maps strings, but no vehicle/source binding. Never label this OS state ON or OFF.
- The manual-exported Audit13 contains 149 `area=gate0` lines (`Preferences` 7, `CarPlay` 142), proving DeepTrace LF mirror/export visibility for at least this subset. It is not a one-to-one full dump of the separate JSONL.

## QA182 reconciliation
Audit13 has 17 distinct `b1-assignment-created` IDs, each with scene-seen, frame-placed, assignment-revoked, and lifecycle-restored (17/17 for each). Revocation reasons: 16 `Chrome-Home-or-disconnect`, 1 `app-replaced-in-native-slot`. All five newest diagnostic-era DuoFace assignments revoke near SpringBoard watchdog-detach following native-owner becoming 0; none demonstrates a sustained DuoFace native Maps tile. Previous Audit12 12/12 native frame placement/tear-down is a historical subset, not 12 additional failures to add.

Do not assert that each historical frame placement is individually confirmed to have a verified `UIWindowSceneSessionRoleCarPlay` readback; the seven audit2 v2 presenter calls provide those direct role checks. Also do not equate native Dashboard scene existence to native **DuoFace pane** ownership.

## User-ordered decision gate (strict precedence)
**1. ON/OFF before ownership**. For one physically parked car, record actual `Settings > General > CarPlay > [paired car] > Customize` state, switch *only* Google Maps visibility **ON→OFF→ON**, timestamp and screenshot each change, reconnect each phase. When OFF, stock Home icon must be absent. Trigger exactly one Maps selection *from DuoFace picker* (never the hidden stock icon); photograph actual 2-pane screen and wait ≥10s. In restore ON phase, restore the car to its original state. Export fresh CarPlay+Preferences v2 JSONL and DuoFaceAudit at end.

**2. Correlate with a genuine OS state source**. Ground the per-car Customize source and paired-car ID, record state, age, timestamp and verification status per event. UI screenshot+clock establishes deliberate action but does not magically make probe's `stockSettings=UNKNOWN` a verified programmatic source. If no authenticated per-car reader can be calibrated, keep result `MEASUREMENT_BLOCKED` and do not advance on ownership assumptions.

**3. Branch only after OFF scene creation is clear.** If OFF permits Maps CarPlay scene with verified role, next work is presentation-owner + watchdog lease and 10s/touch/tiles/second-pane/Home tests. If OFF prevents the scene from being created, next work is iOS app eligibility/launch filtering, *not* scene reparenting. If OS source or scene observation stays ambiguous, do not pick either path.

## Provenance and safety
Existing independent read-only package `com.duoface.carplay.gate0probe 0.0.2~gate0audit2` source `a4be9544e528e5374e1ed0665d1a4a44b233a853`, private CI `42330321209` SUCCESS and signed artifact `13557600454`. This evidence indicates the v2 probe was on-device by the new log; no new installation was performed by this reporting session. No fresh code patch, CI build, Sileo promotion or new vehicle test performed by this session. Preserve QA182/QA180/H1/keyboard, SpringBoard watchdog, CarPlay Home, and independent clean-room DuoFace licensing.

## Exact next check
Look for a later-than-2026-11-07 03:02 UTC main log commit containing fresh gate0 JSONL+new manual photo/time notes with a *deliberately witnessed OFF phase*. Then align run/session IDs and timestamp windows, validate actual OS per-car source and reason why the scene is or is not created. Success at this gate requires verified OFF state + conclusive native scene/no-scene outcome; the final product gate separately needs 10s visible/touchable split and Home safe return.
