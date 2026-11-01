# Reaudit original DuoNavi 1.0.4 — actual device method order, cross-process broker, Home classification (2026-11-01)

## Immutable provenance and method of analysis

- Verified existing GitHub `main` HEAD `4955c852628ce115b095160e480f5f8a879b14cf` at this audit; **no newer device log in main**. The latest original export is `sideplay/log/DuoNaviObserver-16990B2B-71E6-4CC1-9AAB-8CBECBD97599.txt`, Git blob `ae3f8ec858acd225b1df7ea5a991ed3e24d7bd0a`, 5,114,692 bytes, 4,439 text lines, 4,426 parsed JSON records, 915 `home_flow_call` phase records, observer `0.0.3~homeflow1`, iOS 16.7.16.
- Fetched and parsed **the actual Git blob bytes** using the authenticated GitHub connector in this session. The exported TXT concatenates per-process files and rotated `.previous`/current segments: its source-line order is **not chronological**. Reconstructed timeline by `utc`, grouping callbacks using `process, pid, run, call, selector`. Example: Home ENTER export L4437 and its actual RETURN L3704. Never treat source file order as wall-clock order.
- Original genuine package SHA256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd` and `DuoNaviDashboard.dylib` SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`. Runtime original named method observations from this export; original static bounded ARM64 body work in `../original-execution-route-20261031/ROUTE_FINDINGS.md` and `../original-manager-window-route-20261031/MANAGER_WINDOW_FINDINGS.md`. The static side does not prove the entire runtime CFG.
- Observer source `sideplay/duonavi-observer/{HomeFlowTrace.h,HomeFlowSnapshot.h,Observer.m}` records typed exact-ABI method wrappers and snapshots, with actual callbacks forwarded once, and method-argument dictionary allowlist. Snapshots do not read `CBBridgeManager._currentApp` or the vendor's picker window. Timing includes hook/readback overhead, **not** original uninstrumented performance.
- Skill source inspected for this research: `Gpt-training-` SKILL_INDEX.md plus actually decoded `skills/{01-github-continuity,02-ios-deb-ipa-carplay,05-research-debug-testing}.zip` SKILL.md. No license/code from any proprietary original copied.

## A. Actual 3 unsupported-app launches: full two-process path, not cosmetic app icon

All launches share the SAME live CarPlay manager receiver `CBBridgeManagerDashboard:0x282b8f100`, SpringBoard receiver `CBBridgeManager:0x2834d1c80`, with logged bundle identity on both sides.

| Third-party bundle | CarPlay start / prepare / request | SB request entry + manager state updated | CarPlay first handleState + bridgeDidActivate | CarPlay second state / bridgeDidActivate |
| --- | --- | --- | --- | --- |
| `com.facebook.Facebook` | L4297 / L4298 / L4299, UTC 04:16:48.280 | L3616 +14.3 ms, L3617 +84.1 ms `receiverActivated=true` | L4303 +90.9 ms `activated=true`, L4304 +93.7 ms | L4313 +131.6 ms `activated=true,isSplit=false`, L4314 +132.8 ms |
| `com.google.ios.youtube` | L4398 / L4399 / L4400, UTC 04:17:04.564 | L3631 +24.1 ms, L3632 +99.1 ms `receiverActivated=true` | L4404 +103.0 ms `activated=true`, L4405 +113.7 ms | L4414 +147.4 ms `activated=true,isSplit=false`, L4415 +148.6 ms |
| `com.google.gemini` | L3873 / L3874 / L3875, UTC 04:17:48.864 | L3662 +15.7 ms, L3663 +148.9 ms `receiverActivated=true` | L3879 +153.8 ms `activated=true`, L3880 +156.0 ms | L3889 +194.2 ms `activated=true,isSplit=false`, L3890 +195.4 ms |

All durations are *observed offsets in this instrumented recording*, not app open/frame/touch latencies. The first and second `bridgeDidActivate:` calls are two real callback executions for each app, **not** two user selections. The second CarPlay state dictionary explicitly has `isSplit=false` for all three. This **confirms a live non-split manager-state flag** during these app launches; it does **not** establish the concrete runtime class, exact 1-pane parent topology, or that the original visible three-dot pill is part of these specific runs.

The native CarPlay snapshot at each first bridge start is `activeBundle=com.apple.CarPlay.dashboard`, `showingApp=false`; that remains true during first activation. An active vendor bridge can coexist with native Dashboard state; `showingApp=false` is not bridge failure. On each first activation, original manager updates `setAppDockActiveBundleID:` and `setHomeButtonInApp:YES` (e.g. Facebook L4305/4307); these are part of the manager notification lifecycle. Original app Home unsupported taps are **not directly instrumented as `iconManager:` calls here**: the only two observed `iconManager:launchIconForIconView:` callbacks are native Music/Calendar (L3757, L3815). Do **not** claim the three starts were all triggered by that exact native icon callback on this phone.

## B. Corrected count: 9 Home callbacks ≠ 8 Home stop/dismiss calls

Earlier narrative `8/9 Home stop/dismiss` is **incorrect when describing Home-nested invocation count**. Actual total `stopBridging` entries = 8; **6 are nested between an observed native Home ENTER and RETURN**, while 2 occur outside any Home callback. The other **3 Home callbacks use native workspace `deactivateApplication:`**. Pairing used absolute UTC and `run/pid/call`; do not classify by export line order.

| Home no. chronological | Home enter→return export lines | Native active on ENTER | Executed during this Home, before RETURN | Home duration, observed |
| --- | --- | --- | --- | --- |
| 1 | L4224→4237 | Music, showingApp=true | stop L4225, dismiss L4226 | 105.4 ms |
| 2 | L4272→4279 | Music, showingApp=true | native deactivate L4273, workspace request L4275 | 33.9 ms |
| 3 | L4337→4350 | Dashboard, showingApp=false (following Facebook) | stop L4338, dismiss L4339 | 48.1 ms |
| 4 | **L4437→3704** | Dashboard, showingApp=false (following YouTube) | stop L3692, dismiss L3693 | 76.7 ms |
| 5 | L3768→3781 | Music, showingApp=true | stop L3769, dismiss L3770 | 59.8 ms |
| 6 | L3788→3795 | Music, showingApp=true | native deactivate L3789, workspace request L3791 | 32.4 ms |
| 7 | L3827→3840 | Calendar, showingApp=true | stop L3828, dismiss L3829 | 47.8 ms |
| 8 | L3849→3856 | Calendar, showingApp=true | native deactivate L3850, workspace request L3852 | 33.0 ms |
| 9 | L3912→3925 | Dashboard, showingApp=false (following Gemini) | stop L3913, dismiss L3914 | 44.3 ms |

- Off-Home `stopBridging → requestDismiss` #7th/#8th: **L3745→3746** at 04:17:22.902 UTC followed **39.2 ms later** by native `iconManager:launchIconForIconView:` L3757 for Music; **L3803→3804** at 04:17:30.646 UTC followed **35.9 ms later** by native icon launch L3815 for Calendar. Same process, but the observer does NOT capture the caller relationship: only temporal adjacency is proven.
- This proves the original may invoke bridge stop/dismiss when handling surrounding native app transitions too. Therefore `stopBridging` invocation alone is **not** evidence that the bridge instance was active at that instant; need actual current-app/activated state.

## C. Critical timing nuance: local synchronous dismiss vs asynchronous SB teardown

For **Facebook bridged Home** at L4337, 04:16:59.323 UTC: CarPlay `stopBridging` +2.4 ms (L4338) → `requestDismiss` +4.8 ms (L4339) → **local** `bridgeDidDeactivate` +7.7 ms (L4340) → local Dock clearing +9.8 ms (L4341), Home-in-app false +13.9 ms (L4343). `requestDismiss` returns +33.4 ms, `stopBridging` returns +35.5 ms, Apple `homeButtonUp:` returns +48.1 ms (L4350). **SpringBoard** `CBBridgeManager.requestStateChangeWithDictionary:` has actual entry +28.5 ms (L3624), **notifyStateUpdated** +63.3 ms (L3625), CarPlay receives subsequent `handleStateDict:` at +99.4 ms (L4354) and another `activated=false,isSplit=false` state at +140.8 ms (L4364). Thus **synchronous local manager/UI state and later asynchronous remote state both exist in the original**; it is false to assert that the original waits for all SB teardown before native Home returns.
- For Gemini Home L3912 at 04:17:55.569 UTC, local stop/dismiss +2.4/+5.0 ms, local bridgeDidDeactivate +7.1 ms, Home return +44.3 ms; SB request +25.8 ms, SB notify +55.4 ms, CarPlay later handles manager state +78.0 and +123.8 ms. Same observed order.
- For YouTube Home L4437 at 04:17:18.447 UTC, local stop/dismiss +1.9/+4.9 ms, native Home returns +76.7 ms; SB request +35.1 ms (L3638); the export's segment rollover/trace loss means later state callbacks cannot be exhaustively enumerated for this case. Do not invent them.
- Original static evidence `ROUTE_FINDINGS.md` independently observes **file + notification IPC**, SB manager and state notifications. Hence use of plist/Darwin notifications in DuoFace is **not inherently the defect**. The verified difference is **which manager owns and publishes state at Home dispatch and which host/window is being dismissed**, not a proven transport-speed cause.

## D. Side-by-side boundary with QA157's actual source

- DuoNavi original recorded: same `CBBridgeManagerDashboard` owner across start/prepare/request and native-state receipt; SB `CBBridgeManager` request/notify; local manager `bridgeDidActivate/Deactivate` drives native Dock/Home; native Home callback calls stop+requestDismiss locally before return (when bridged). `isSplit=false` states on 3 real third-party launches.
- DuoFace QA157 source verified: `sideplay/duoface-native-scene-host/DFHomeStandalone144.m:182-242` CarPlay own `DF144BeginSelectedBridge`, request plist/Darwin; `:259-263` selected icon hook; SpringBoard `:510-620` `DF144Solo.begin` owns `UIRootSceneWindow` + `DFSceneHost.hostViewForBundleID`, and `:817-822` async stop handler tries `df157ReturnHomeToPicker`. CarPlay `DFCarPlayOwnerObserver.h:127-164` calls `DF157NativeHomeCallbackObserved` and emits async stop before forwarding Apple Home; `DFHomeStandalone144.m:246-257` synchronously resets **only first-party Dock lifecycle**, not a corresponding locally-owned bridge manager with original-style `requestDismiss` state semantics. Native Dock update itself is not enough to certify route.
- QA157 is signed and Sileo public but **not** tested on iPhone X. Latest actual DuoFace hardware log is Log26 from QA156, user-rejected Home, source `main:sideplay/log/DuoFaceAudit 26.txt`. Do not mix QA156 device trace with QA157 source and claim a new physical failure/pass.

## E. Remaining specific unknowns / evidence requirements before any new production QA

1. Original runtime bridge object class and identity at each activation/stop: actual `CBBridgeManager._currentApp`, `_window`, `appViews` and preset/solo/focused flags. Original binary shows `CBBridgedSplitApp` is capable of a multitasking pill; existing runtime observer did **not** record this object/class or `CBBridgeManagerDashboard` actual app window. So a three-dot user observation is not sufficient to prove `CBBridgedSplitApp` was the active object for the three traced launches.
2. Exact page outcome after Home: **zero** `RESULT_APP_CHOOSER` or `RESULT_CARPLAY_HOME` manual markers in original export. Visible `DBDashboardHomeViewController` tree only confirms framework controller ownership, not pixels; no original app-picker visibility proof.
3. No measured original app-side scene-start geometry, touch-ready and orientation handshake for the same three device sessions; no full vendor CFG or exact caller edges for the two off-Home stops.
4. Next evidence-only observer extension (not yet implemented): read-only ABI-validated manager current-app class/window/activated with safe runtime class/selector metadata, record `isSplit` and real picker owner/visibility at manager callbacks, owner/selected bundle + generation and current native scene before and after Home; add explicit user-visible chooser/Home manual result marker. Do not guess private ivar layout, modify license, or change vendor bridge lifecycle. Reconcile with actual QA157 runtime logs only when new device log exists.

## Execution status

**Performed:** latest Github HEAD/log inventory; fetched and parsed complete genuine original 5.1 MB export; sorted rotated multi-process records by timestamp/call; verified 3 two-process app launches, exact 9 Home classification, 2 non-Home stop/dismiss calls, false 8/9 narrative correction, local-vs-remote dismissal sequence; cross-read original observer source/static original binary notes and current first-party source. **Not performed:** new device recording, new observer patch/build, DuoFace runtime change/DEB build/Sileo release/hardware test. Nothing in this report labels an unobserved behavior a fix.
