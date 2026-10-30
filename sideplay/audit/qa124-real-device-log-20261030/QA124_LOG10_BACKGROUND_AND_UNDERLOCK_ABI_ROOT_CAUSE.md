# QA124 on-device new Log10: native CarPlay session torn down on BACKGROUND; under-lock hooks failed ABI guard

Date: 2026-10-30 (ICT). **Evidence read directly from user-uploaded current GitHub main**, not the QA124 feature branch. User says they ALWAYS respring after Sileo updates; previous "maybe resident older code" explanation is superseded by this log.

## Immutable source / scope of verification

- Uploaded original combined diagnostic: `chuongnguyen89dn-ui/Duoface` **main** `sideplay/log/DuoFaceAudit 10.txt` (space before 10), commit `bd0a31dac35a39cb310188eb56dbfce1d2c9c1e5` at 2026-10-30T03:57:25Z; Git blob `81b6ae1aa699ec383af85112f8eddf524c409e9f`; read through `mcp__GitHub__fetch_blob` 4,685,543 characters / 19,448 lines. `mcp__GitHub__fetch_file` gives empty text for large raw files; direct blob fetch succeeds. DO NOT confuse with older `sideplay/log/DuoFaceAudit 9.txt` commit `ce0db34d` or old `sideplay/log/DuoFaceAudit.txt` commit `1d83a9fd`.
- Export banner: 2026-10-30T03:56:37Z = **10:56:37 ICT**, iOS 16.7.16, `com.duoface.native.scenehost`, exporter build `0.0.90~nativegetters1`. **CAUTION:** `DFDeepTrace.h:19` hardcodes `build=0.0.90~nativegetters1` in its format string across subsequent QA versions, so that marker **IS NOT evidence of running old DEB**. QA124 marker appears in **current native app process** (below); user confirms respring; prior activation/restart conjecture was incorrect for this run.
- All times below UTC and ICT (+07:00). Text-derived sequence is a reproducible action trace. Exporter has no explicit user physical `lock-button-pressed` timestamp: sequence conclusively shows **what killed DuoFace** in three transitions, but which were physical phone lock vs CarPlay Home is not independently labeled.

## Evidence A — QA124 really RUNS; background teardown undoes QA124 change

`DuoFaceDeepTrace.log` lines 18599–18612:
- **03:50:16.443347Z / 10:50:16.443 ICT**, PID 82809 `DuoFaceNativeHost`: `qa124-scene-resign-retained-await-background`. This is **exact new QA124 source string** from `DFNativeHostAppDelegate.m:257–264`; it is executing, not a stale QA123 process.
- **03:50:16.448503Z**, just **5.2ms later**: `touchowner-stop reason=scene-background revoked=1 notify=0`. Code source `DFNativeHostAppDelegate.m:265–268` still unconditional `stopTouchOwnerWithReason:@"scene-background"`. This tombstones live session.
- **03:50:16.480278Z**: SpringBoard `qa121-system-idle-assertion-released status=0` (sleep assertion released as a CONSEQUENCE of revoked host, not proof display brightness/underlock is fixed).
- **03:50:16.483335–.488579Z**: SpringBoard `home-own-windows-hidden-before-scene-invalidate` twice and `home-teardown-all-external-windows-hidden-before-scene-invalidate` once; **03:50:16.494543** hosted `com.google.ios.youtube` `invalidate-done`, **03:50:16.502536** Facebook `invalidate-done`; **03:50:16.505012** `native12-chrome-stop` and **.505383** `window-detached nativehost-disconnected`. This is **confirmed actual teardown**, not vague black-screen theory.
- **03:50:17.817529Z** `touchowner-start` with a **new UUID**, **03:50:18.673474Z** `native12-chrome-start windows=13`; results in repeated restart with hosted scenes recreated, hence inconsistent Play and remembered app reentry.
- Apple CarPlay Dock owner logs `dock-reply applied=0 ... reason=no-fresh-foreground-session` at **03:50:16.490344Z**, but physical rail remains measured at 45px (next Dock logs). Preserve QA120 geometry and native Apple Dock.

**Reproduced twice more in same current QA124 PID / run:**
- **03:50:47.862763Z** QA124 retained resign -> **.866350Z** stopped reason `scene-background` -> **.915281Z** Chrome detached. Hosted `com.google.ios.youtube` and `com.lumi.GOFA` both invalidated in between; reconnect/return starts new session at **03:50:49.577040Z** and Chrome at **03:50:50.439921Z**.
- **03:51:04.168880Z** QA124 retained resign -> **.172505Z** stop `scene-background` -> **.189367Z** windows detached, with both GOFA and YouTube invalidated first.
- These are transition-driven teardown and full scene invalidations, not `Sileo didn't install` or `touch regions mysteriously locked`. The log does NOT prove GOFA causes the problem; both GOFA and YouTube are victims of the same host teardown.

## Evidence B — BOTH QA123/QA124 under-lock hooks never install on device (ABI failure)

Current SpringBoard recent-process trace, `DuoFaceDeepTrace.log`:
- **03:49:33.615746Z** PID 82777: `area=qa123-underlock os-underlock-methods-abi-incompatible`.
- **03:55:49.509737Z** PID **83173** after **fresh SpringBoard process PID**: exactly same `os-underlock-methods-abi-incompatible`.
- At the next ~0.3ms `scene-lifecycle manual-owner-observer-and-foreground-boundary-installed` exists, so SpringBoard injection/part of scene lifecycle is active, but **the underlock decision hooks have FAILED CLOSED**.
- In `sideplay/duoface-native-scene-host/DFSceneLifecycle.m:202–224`, `class_getInstanceMethod` obtains `SBSuspendedUnderLockManager` methods `_shouldBeBackgroundUnderLockForScene:withSettings:` and `shouldBeUnderLockForScene:`. It aborts if `DFLockABI(bg,4) || DFLockABI(ul,3)` fails. The helper requires method existence, exact Objective-C argument count, return type `B/c`, all explicit argument type `@`. It logs only a **combined** failure, so cannot presently distinguish **missing method**, wrong argument count, non-object args or return encoding, or which selector. Do not force-install until ABI is read and verified.
- Thus the attempted QA123 owner-only underlock fix has **NOT executed** in either trace. The latest user-confirmed respring also does not change this: new PID 83173 repeats failure. Original DuoNavi 1.0.4 and Native12 original 3 underlock hook registration forensics remain valid behavior reference, but do not copy their unsafe passcode/application activation selectors.

## Evidence C — correct dock geometry; log build-version false lead

- After fresh boot-like process start: **03:55:46.915901Z** app PID 83207 launched; **03:55:47.637316Z** SpringBoard PID 83173 Chrome `native12-chrome-start windows=14 content={{45, 0}, {595, 360}}`; CarPlay process PID 83172 publishes native rail `{{0, 0}, {45, 360}}`, appDock actual `{{0, 124.667}, {45, 111}}` consistent with QA120 measured correct geometry. **NO geometry change needed.**
- Both `DFDeepTrace.h:19` and exported header have fixed `0.0.90~nativegetters1`; QA124 in code is authenticated by **new `qa124-scene-resign-retained-await-background` marker** from live app PID 82809. Do not repeat old "you didn't respring" diagnosis; this source string is decisive.

## Engineering conclusion and next concrete step

**CONFIRMED**: The exact QA124 remedy is bypassed by the still-unconditional `sceneDidEnterBackground` call. It revokes owner then SpringBoard immediately hides all 4 Chrome windows and invalidates app scenes. **CONFIRMED**: Underlock hooks never install on actual device because `DFLockABI` rejects one/both methods. These are two separate code defects, not speculation. The export lacks explicitly labeled phone-lock vs true CarPlay Home, so cannot safely make `sceneDidEnterBackground` a no-op: that would leave overlays over CarPlay Home and break disconnect. This is sufficient to reject another heartbeat-timeout tweak.

**Next correction** (separate patch, scoped; NOT executed here): (1) add read-only `SBSuspendedUnderLockManager` precise class/SEL method encoding/arg-count diagnostic to determine exact actual iOS16 ABI, without bypassing lock or installing unsafe hooks; (2) preserve explicit **real external frontmost owner** and discriminate physical iPhone lock vs CarPlay Home before revoking the session; no global scene policy or arbitrary foreground forces; (3) ensure Home and physical detach still hide immediately, no respring/filza request, and regress measured QA120 native Dock, QA90 rotation, QA92 divider; (4) signed QA125 build and public Sileo only once safe ABI and owner invariants pass, then physical test. Logs not automatically streamed to GitHub: the latest actual user upload was specifically **main/log/DuoFaceAudit 10.txt**.

**Status this analysis only:** no source/runtime fix, no QA125 DEB, no CI, no new Sileo package. Exact-device cause of pane **teardown** is proven. Exact physical screen-lock trigger vs Home still not tagged; Play failure may also involve separate remote YouTube scene foreground.
