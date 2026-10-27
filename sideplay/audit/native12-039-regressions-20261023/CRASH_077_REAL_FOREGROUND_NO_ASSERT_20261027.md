# .77 REAL ROOT EXCEPTION REASON: SpringBoard live scene became backgrounded unexpectedly

27 October 2026, user uploaded exactly six files at /mnt/data, but DuoFaceAudit-2.txt and DuoFaceAudit-3.txt have IDENTICAL SHA256 `4c469e5e6ab9e9cc1fe9abd48362f5fbadcdf1396b22082992182a04359d4fba`; two new IPS have "-2" duplicate uploads (same incident IDs). Raw logs may include app installed list and device info. NEVER commit raw files.

## Confirmed device failure, iOS 16.7.16 (20H392), .77 installed and executed

**THIS time the .76/.77 newly uploaded `DuoFaceFatalException.log` DOES contain complete exception.name/reason, matching .77 unique IPS:**

`NSInternalInconsistencyException`
`Something changed the scene's (sceneID:com.google.ios.youtube-default) foreground status out from underneath us (current mode: Live, diff: ... { settingsClass = UIApplicationSceneSettings; changes = { foreground = BSSettingFlagNo; }; subclassChanges = (none); }, window: <UIRootSceneWindow...>)`

Same EXACT class/reason and changed settings key for Facebook `com.facebook.Facebook-default` in second .77 IPS. This is a **forefront ownership/lifecycle violation**, not a video codec exception nor the `setFrame:` equality check itself. It proves previous hypotheses were under-specified; the real fatal transition was **remote FBScene foreground=NO while SBAppViewController remained in Live mode**. Source permits frontend mode2 without scene settings foreground policy. It does not identify WHICH competing actor initiated foreground=NO. Do not blame other tweaks from loaded images alone.

| New unique .77 IPS | ID, PID | Fatal method |
| --- | --- | --- |
| `Crash-1-SpringBoard-2026-10-27-111008.ips` | `2026-10-27 11:10:04.7297 +0700`, incident `C7FD7415-31CF-4D3D-A13B-DBC0526C0502`, SpringBoard PID `62016` | `EXC_CRASH/SIGABRT`; lastExceptionBacktrace `objc_exception_throw → Foundation _userInfoForFileAndLine → -[SBAppViewController sceneHandle:didUpdateSettingsWithDiff:previousSettings:]+440`; fatal log PID 62016 .77 scene `com.google.ios.youtube-default`, `foreground=BSSettingFlagNo` |
| `Crash-0-SpringBoard-2026-10-27-111115.ips` | `2026-10-27 11:11:05.4434 +0700`, incident `08CE3B3F-5C39-437F-887E-187807790970`, SpringBoard PID `62056` | same stack +440; fatal log PID 62056 .77 scene `com.facebook.Facebook-default`, `foreground=BSSettingFlagNo` |

Copies `Crash-1-SpringBoard-2026-10-27-2.ips` / `Crash-0-SpringBoard-2026-10-27-2.ips` are identical incidents, not 4 independent crashes. Old .76 forensic fatal log additionally records PID61323 YouTube, PID61365 `com.lumi.GOFA-...`, PID61390 `com.ss.iphone.ugc.Ame-default`, ALL same `foreground=BSSettingFlagNo` / Live conflict. The older .74 IPS had identical +440 stack but no .74 reason, hence **do not certify same reason for .74**.

## .77 EXACT source+runtime timeline: interventions worked but didn't fix foreground

Epoch UTC `1793074199.790192`: in SpringBoard PID62016, YouTube `mode-2-requested`; `scene-attached` +0.0005s. +0.3122s initial native settings frame 375×812 → 783×663 (`scene-frame-readback ... same=0`, `native12-scene-settings-frame-requested`). The same SpringBoard PID aborted at 11:10:04.7297 ICT (`1793074204.7297` UTC), ~4.625 seconds after frame request. Fatal diff was **foreground=NO**, not frame.

Epoch UTC `1793074243.193323`: SpringBoard PID62056, Facebook `mode-2-requested`; +0.3592s `scene-attached`; +0.671s frame 375×812 → 783×663. 12.377s after first mode2, user `FocusRight` is ACKed and live frame changed 783×663 → 1175×663 (epoch 1793074255.570582). Fatal SpringBoard PID62056 at 11:11:05.4434 ICT (epoch `1793074265.4434` UTC), ~9.873s after the second frame request. Fatal diff again only **foreground=NO**.

`DuoFaceDeepTrace.log` proves runtime `build=0.0.77~mode2frame1` for PID62016,62056 and sender side; this is not just app-exporter banner. Host `DFSceneHost.m`: `setAutomatesLifecycle:NO`, `setIgnoresOcclusions:NO`, setRequestedMode:2, private scene updates `setFrame:` only, no `setForeground:` or `setBackgrounded:` in same transaction, no hosted media foreground reassertion on focus and shutdown `close-no-private-settings-restore`. Before reporting this bug no direct `NSException.reason` had ever been extracted despite uploaded data; the missing direct reason is now present and decisive.

### Original vendor ARM64 model: observed but don't copy binary or license

Original independent SHA-proven DuoNavi 1.0.4 `CBBridgedUIAppView.updateSceneSettingsFrame` has guards and remote `setFrame:`, **`setForeground:`**, `setIdleModeEnabled:` in its single settings update. Original OmniCar 1.0.3 `ABHost.layoutPane` block guarded `setFrame:`, `setInterfaceOrientation:`, `setBackgrounded:NO`, `setForeground:YES`. In contrast .77 only changed frame. DuoDash Fullscreen427 repack has app-process bridgeState true/false and separate host+UI owners; app helper effects not proven. All evidence for comparison archived in original DEB forensic report `sideplay/audit/duodash-duonavi-media-20261027/WHY_ORIGINAL_BRIDGES_WORK_BUT_DUOFACE_CRASHES_20261027.md`. **Those engines coordinate live foreground and video host lifecycle; they don't just resize.**

### Other actual SpringBoard injections in BOTH new .77 snapshots

Loaded `GhostBoard.dylib`, `GhostBoardXFeatures.dylib`, `OhMyRotate.dylib`, `OmniCarYouTubeHandleIdle.dylib`, `AppData.dylib`, `PullOverGH.dylib`, `SnowBoard` variants, first-party DuoFace modules. Source IPS usedImages presence is verified, but there is NO direct caller/owner attribution for the external foreground diff. Do NOT claim GhostBoard was removed on these crash snapshots; it was loaded. Do NOT automatically uninstall or edit other tweak repos.

### Next bounded source action

Source owner can add foreground=YES and backgrounded=NO to the same guarded live scene update (only if setter exists, with no new broad hooks), following exact independently verified DuoNavi/OmniCar behavior; synchronize even when geometries equal only if observed scene foreground is not YES; track foreground before/after. **This is a targeted candidate, NOT proof that a third-party/system actor will not later background it again.** Do not suppress Apple's exception, hard-off frame or create dummy video renderer. Build source CI + signed DEB and publish only if checks pass; test on parked CarPlay. If still abort, a controlled third-party-injection isolation or app-process handoff is needed. No universal workaround can be guaranteed from one static diff.

Checkpoint before writing source: two new unique .77 IPS + complete captured reason correlated against actual exact .77 trace; source and release still .77 public; no full fix proven.
