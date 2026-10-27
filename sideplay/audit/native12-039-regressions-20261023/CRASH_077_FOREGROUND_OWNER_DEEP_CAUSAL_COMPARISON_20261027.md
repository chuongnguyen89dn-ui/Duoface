# .77 crashes: further causal isolation of Live/foreground=NO and concurrent scene owners — 2026-10-27 11:33 ICT

**Scope:** analytical follow-up requested by user; preserve independent DuoFace project, do not change vendor code/license or other repos. Existing handoff: `sideplay/README.md`. Source branch `feature/duoface-jb-embedded-appbridge-20261020`; starting HEAD `460bd6f7848893aece2b527e9e7143f7ebbc9c5e`. Current public integrated version `0.0.77~mode2frame1`, user-confirmed NOT STABLE. No new tweak/runtime/DEB/Sileo edits in this investigation.

## Actual additional work (not simply repeating previous note)

Read *complete* locally mounted `DuoFaceAudit-2.txt` (13,005 lines; SHA256 `4c469e5e6ab9e9cc1fe9abd48362f5fbadcdf1396b22082992182a04359d4fba`), confirmed `DuoFaceAudit-3.txt` same bytes, exact two new unique IPS and THREE older .74 IPS, including every `usedImages` entry. Built local stdlib parser `/mnt/data/duoface_foreground_forensic.py` to correlate epoch UTC, actual SpringBoard PID, app event, crash captureTime, and loaded modules. Input logs are potentially private and deliberately not uploaded. An additional **reproducible, read-only sanitized replay script** is now persisted at `sideplay/tools/duoface_foreground_crash_replay_20261027.py` commit `1546421ab973b7e9e0b6a9535ed548e63558f699`. Tested the same code via local Python on the new .77 YouTube/Facebook IPS and older .74 control: both .77 show 8 loaded OmniCar modules and child3=1, .74 control shows 0 OmniCar modules; replay prints only selected technical fields. Run `python sideplay/tools/duoface_foreground_crash_replay_20261027.py --audit '/mnt/data/DuoFaceAudit-2.txt' --ips /mnt/data/Crash-1-SpringBoard-2026-10-27-111008.ips /mnt/data/Crash-0-SpringBoard-2026-10-27-111115.ips /mnt/data/Crash-0-SpringBoard-2026-10-27-092032.ips`. Source logs are user uploads in the current session and are NOT durable or posted to GitHub. Read source at `sideplay/duoface-native-scene-host/DFSceneHost.m`, `Omnicar/audit/OmniCar_AppBridge_exact_scene_settings_and_layout_20261023.md`, and original DuoNavi104/DuoDash113-repack audit. Existing main forensic finding `CRASH_077_REAL_FOREGROUND_NO_ASSERT_20261027.md` remains unchanged and linked.

### 1. Hard observed exception (CONFIRMED, does not name writer)

Two distinct .77 crash incidents in iOS16.7.16:
- YouTube, SpringBoard PID `62016`, `2026-10-27 11:10:04.7297 +0700`, `C7FD7415-31CF-4D3D-A13B-DBC0526C0502`;
- Facebook, PID `62056`, `2026-10-27 11:11:05.4434 +0700`, `08CE3B3F-5C39-437F-887E-187807790970`.

The `DuoFaceFatalException.log` inside user audit records for each `NSInternalInconsistencyException`: `Something changed the scene's (...) foreground status out from underneath us (current mode: Live, diff: ... foreground = BSSettingFlagNo)`. The independent corresponding IPS lastExceptionBacktrace: `objc_exception_throw -> Foundation _userInfoForFileAndLine -> -[SBAppViewController sceneHandle:didUpdateSettingsWithDiff:previousSettings:]+440 -> SBSceneHandle -> FBSceneMonitor`. The reason says **new incoming scene settings have foreground=NO while SBAppViewController is Live**. It does **not** identify the caller that wrote the settings, whether the trigger was video START, foreground entitlement/policy, other tweak, another app focus, or SpringBoard scene manager.

The audit also has older .76 fatal exceptions for YouTube, a different `com.lumi.GOFA` app, and `com.ss.iphone.ugc.Ame`: same Live-vs-foreground=NO class. It is a **general scene-owner/lifecycle problem**, not a defect unique to YouTube's codec. Old .74 IPS use the same +440 stack but have no own captured reason; strictly avoid claiming .74 was necessarily this exact foreground invariant.

### 2. Reconstructed actual .77 runtime timing by PID (NEW direct replay)

All elapsed numbers are seconds before actual IPS `captureTime`, NOT before filename timestamp:

| Observable moment | YouTube PID62016 | Facebook PID62056 |
| --- | --- | --- |
| SpringBoard scene host created | T-4.999 | T-22.302 |
| `setRequestedMode:2` requested | T-4.940 | T-22.250 |
| FBScene attached | T-4.939 | T-21.891 |
| Child content-reference size setter result | `child2=0 child3=1 main2=0`, T-4.629 | same, T-21.584 and T-9.876 |
| Actual scene frame readback | `375×812 → 783×663`, T-4.627 | `375×812 → 783×663`, T-21.582 |
| `updateSettingsWithBlock: setFrame:` request logged | T-4.626 | T-21.579 |
| Other first-party focus action | **No subsequent focus or Stop or mode0 event in SpringBoard trace** | `FocusRight` command T-10.203, ACK T-10.170, frame changed to `1175×663` at T-9.873 |
| Fatal background diff | T=0; foreground=NO; Live host | T=0; foreground=NO; Live host |

**Inference boundary:** .77's mode2-first step succeeded (child3=1 on both) and the remote frame was actually `375×812` on first read, then a settings update was *requested*. Trace's `media-reference-committed` is a local dispatch marker, NOT a UIKit media ACK. Neither crash is immediately synchronous with update: gap ~4.626s YouTube, ~9.873s since LAST Facebook frame request. YouTube has **no logged post-frame manual Focus/Close action** before abort, hence explicit divider/focus touch **cannot** explain every instance. Facebook focus could be a contributor for that one, not a general explanation. We cannot pin a PLAY timestamp from audit, so video trigger still only user observation.

### 3. CRITICAL NEW discovery: exact co-loaded ORIGINAL OMNICAR host modules during .77

Compared the **`usedImages` arrays directly**, not broad notes. In BOTH NEW .77 SpringBoard fatal snapshots the process includes all these OmniCar-named dynamic libraries:
`OmniCarAppBridge.dylib`, `OmniCarCore.dylib`, `OmniCarSplitScreen.dylib`, `OmniCarDoubleTapFullscreen.dylib`, `OmniCarNativeSoloTimer.dylib`, `OmniCarSpeedBubble.dylib`, `OmniCarStartupScreen.dylib`, `OmniCarYouTubeHandleIdle.dylib`.

Together with **DuoFace SpringBoard** `DFTouchOwnerProbe`, `DFNativeDashboardBridgeQA`, `DFFirstPartyAdmission`, `DFV1APreflight`, `DFCarPlayDockOwner`. Also loaded are `GhostBoard`, `GhostBoardXFeatures`, `OhMyRotate`, `AppData`, `PullOverGH`, `SnowBoard` components.

The archived original OmniCar 1.0.3 `ABHost.layoutPane:` static disassembly **contains guarded remote `sceneHandle -> sceneIfExists -> updateSettingsWithBlock:` and an update block with `setFrame:`, `setInterfaceOrientation:`, `setBackgrounded:NO`, `setForeground:YES`** (see `Omnicar/audit/OmniCar_AppBridge_exact_scene_settings_and_layout_20261023.md` CI 39929982072). Thus **if** its corresponding installed module actively operates on the same target scene while DuoFace holds Live mode, there is potential for competing scene ownership; however current installed binary versions, hooks actually triggered, and the writer of `foreground=NO` are **NOT established**. Merely loaded .dylib does NOT prove it even runs its host.

**Important counterevidence against falsely declaring OmniCar the sole root:** All THREE older .74 IPS at 09:13 and 09:20 **DO NOT list any OmniCar-prefixed dylibs in `usedImages`**, yet also abort at the same +440 method. The earlier .74 NSException.reason was unavailable, so exact failure equality cannot be proven; at minimum OmniCar co-injection is **NOT NECESSARY** to reach that generic +440 stack. Both old .74 and new .77 DO have `GhostBoardXFeatures`, `OhMyRotate`, core DuoFace modules loaded; these too are only co-occurrences, not proof of causality.

**Diagnostic priority change:** The current 11:10/11:11 environment is NOT an isolated DuoFace host; any claim `.77 failed in absence of another app host` is disproved. Before releasing a source patch with more foreground setters, A/B **one owner** during a safe parked-phone test: preserve/restorable OmniCar installation, temporarily prevent its SpringBoard injection **without uninstalling its data or code** using a known reversible enabled-tweak control if available, then separately compare with DuoFace-only. DO NOT modify the OmniCar repository or do uncontrolled mass uninstall. Capture actual loaded modules, timestamp and same video/app. If still crashes when isolated, owner-conflict is not sufficient explanation; use new scene state reason to fix independent lifecycle contract.

### 4. Source-level causal gaps, observed not guessed

`sideplay/duoface-native-scene-host/DFSceneHost.m` current `.77`:
- `start` adds child `SBAppViewController`, `setIgnoresOcclusions:NO`, **`setAutomatesLifecycle:NO`**, uses mode2; this makes it especially important that *some owner* keeps remote scene foreground coherent. The code currently has no state machine ensuring Live and remote foreground agree.
- `pollScene` treats `isHostingAnApp` + current sceneHandle + appView.window as ready. That is not the same as remote app remaining foreground when video/fullscreen state changes.
- `commitSceneGeometry` calls guarded child3 reference setter with `UIInterfaceOrientationPortrait`, then one scene settings update that **only sets `setFrame:`**, skipping remote foreground/backgrounded policy. It sets `committedReferenceSize` merely after calling a selector, not after actual remote scene/app ACK.
- `stop` mode0 + invalidate, intentionally `close-no-private-settings-restore` despite snapshot `sceneSettingsBefore`. This might produce stale settings across rehosts but did **not** happen immediately before either failing scene in the trace; cannot claim it triggered either abort.
- Original DuoNavi 1.0.4 scene code exposes `setForeground:` plus sizing/idle policy, calls `refreshSceneLayout` after its own lifecycle, and has `setHosting:` before mode switch on dismissal; original OmniCar similarly writes foreground/background along with frame. DuoDash Fullscreen427 repack separates app-side bridge-state control (stock original not proven). **These are structural differences**; do not cargo-cult copy private setters, which may provoke a tug-of-war with other scene owners.

### 5. Hypotheses ordered by strength and discriminating evidence

A — **Verified violated invariant, unverified origin:** Apple SpringBoard host remains mode Live while FBScene reports foreground NO. Must determine which scene process or manager initiated NO. A targeted independently managed per-scene foreground lifecycle is candidate, not complete proven repair.

B — **New test-worthy co-owner contention:** Original-format OmniCar host libraries plus DuoFace were *simultaneously resident* in both new .77 SpringBoards. Original OmniCar is itself a scene settings mutator. Yet .74 +440 exists without OmniCar; use reversible single-owner A/B, not assertions against OmniCar vendor or user-installed tweaks.

C — **UIKit video/background transition or phone scene focus:** Starting playback may lead to UIKit/system activating a different presentation/scene and demoting original scene. Audit has NO direct `PLAY` event or scene-settings author trace; cannot claim YouTube/FB app caused the background diff.

D — **Less supported for these two:** a lone `setFrame:` incorrect size or duplicate frame. Fatal diff specifically says `foreground`, and both crashes are seconds after a frame request. v75 frame-off boxed and STILL crashed, v77 mode2-first/frame equality still crashes. Do not repeat these failed partial fixes.

### 6. Exact next steps (no unproven .78, never modify another repo silently)

1. Keep `.77` known-bad and disable its tweak on the phone when not running controlled parked tests.
2. Test **isolation in SpringBoard**, preserving installed packages: one change at a time, first OmniCar scene-owning injection off vs on with DuoFace, then potentially rotation/visual tweak interference if needed. Record loaded module names and exact scene fatal reason/PID/time. Cannot establish cause without A/B; prioritize not breaking OmniCar independent project.
3. If crashes also in isolated DuoFace, implement ONE scene ownership state machine that reconciles mode2/live vs actual foreground (with documented method guards and generation semantics). Instrument read-only foreground diff (including source context if obtainable) to prove before changing scene state. Avoid repeated unconditional setForeground:YES writes or suppressing fatal exception.
4. Source iOS16 compile & tests; signed rootless DEB CI; immutable SHA; Sileo one-entry verifier; **real** YouTube AND Facebook PLAY and Map split + fullscreen + close/return, parked iPhone. Fail if a SpringBoard SIGABRT occurs, or if media becomes boxed, Dock cropped, logo/zoom/menu regression.
5. Current device trace and first-party source **do not reveal the exact actor** sending foreground NO; that question remains **CHƯA XÁC MINH**. No .78 build/source modification was executed this turn; previous tool blocked direct runtime private setter edit (see prior checkpoint).

## Reproduction / evidence reading

Current container paths (mounted for this turn, not permanent): `/mnt/data/DuoFaceAudit-2.txt`, `/mnt/data/DuoFaceAudit-3.txt`, `/mnt/data/Crash-1-SpringBoard-2026-10-27-111008.ips`, `/mnt/data/Crash-0-SpringBoard-2026-10-27-111115.ips` and older three `*-09*.ips`. Local executed `python /mnt/data/duoface_foreground_forensic.py` using stdlib `json`, `re`, `datetime`, `hashlib`, and also validated the stable counterpart `sideplay/tools/duoface_foreground_crash_replay_20261027.py` via `python /mnt/data/duoface_forensic_replay_20261027.py --audit /mnt/data/DuoFaceAudit-2.txt --ips /mnt/data/Crash-1-SpringBoard-2026-10-27-111008.ips /mnt/data/Crash-0-SpringBoard-2026-10-27-111115.ips /mnt/data/Crash-0-SpringBoard-2026-10-27-092032.ips` followed by Python syntax compilation `python -m py_compile`. The code is saved in DuoFace source as above; the raw user's .ips/audit files are NOT committed.

Safety: do not store raw IPS/device identifiers/tokens, unredacted dumps, or user data in GitHub. This report is curated selectors/technical status only.
