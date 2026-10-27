# DuoFace .74 iPhone crash evidence — 2026-10-27 (sanitized)

**Input read locally**: user-supplied `DuoFaceAudit 2.txt` (~1.9 MiB) and three raw `.ips` files on 2026-10-27. These contain device/session identifiers, so **DO NOT commit/upload the raw attachments**. This is a sanitized fact summary without incident IDs, hardware keys, sessions or memory pointers. Local upload files are conversation attachments, not durable project artifacts.

## Reproduced failures (Asia/Bangkok, iOS 16.7.16)
| Timestamp +07 | SpringBoard process | Signal | lastExceptionBacktrace | Consecutive count |
| --- | --- | --- | --- | --- |
| 09:13:19 | SpringBoard | EXC_CRASH/SIGABRT | `-[SBAppViewController sceneHandle:didUpdateSettingsWithDiff:previousSettings:]+440` | 11 |
| 09:13:55 | SpringBoard | EXC_CRASH/SIGABRT | same exact offset +440 | 12 |
| 09:20:32 | SpringBoard | EXC_CRASH/SIGABRT | same exact offset +440 | 13 |

All three lastExceptionBacktrace chains include `objc_exception_throw → Foundation _userInfoForFileAndLine → SBAppViewController +440 → SBSceneHandle observer → FBSceneMonitor settings update → FBSceneWorkspace`. The actual abort is **SpringBoard**, not a proved crash in the YouTube application process. Apple exception *reason* is missing in these .ips. Do not claim a proven invalid frame assert, an app-specific problem or GhostBoard culprit.

## Correlation to the installed, running .74 code
- Archive's top-level header still says `Audit schema 2; build 0.0.67~scenediag1` (diagnostic exporter metadata); its timestamped `DuoFaceDeepTrace.log` explicitly says **`build=0.0.74~media37host1 process=SpringBoard`** for all three crash process IDs and matching times. This is verified device runtime evidence for .74, not an assumption from Sileo.
- On each cycle, DuoFace opened the real App picker, created a YouTube scene with `setRequestedMode:2` and reported `scene-attached FBScene`, immediately before SpringBoard later aborted.
- 09:13:19: last `scene-attached` at ~09:13:14.545; **no `native12-scene-settings-frame-requested` marker for that cycle before crash**. Therefore it is inaccurate to claim every occurrence was directly preceded by our `setFrame:` call.
- 09:13:55: `original-native12-scene-size-dispatch child2=0 child3=1 main2=0` then `native12-scene-settings-frame-requested {{0,0},{479,663}}` at ~09:13:46.352; abort ~8.65 seconds later.
- 09:20:32: `child2=0 child3=1 main2=0` then `native12-scene-settings-frame-requested {{0,0},{696,663}}` at ~09:20:16.494; abort ~15.5 seconds later (user's divider/logo gestures were also logged). This is **correlation**, not proof of unique cause.
- User confirmed four-pane .37 media restored in .74 and content no longer boxed. The `DFNative12Chrome.m` four `UIWindow` owners must stay untouched while triaging.

## Narrow source decision / actual modifications
- A previous unshipped source-only fix at commit `26bc899d` guarded stale scene ownership, with CI run `40438173968` SUCCESS. **This fix was NOT in the installed .74 binary that crashed.** Stale-pointer suspicion remains separate from directly observed SpringBoard scene-diff abort.
- This .75 candidate makes `FBScene.updateSettingsWithBlock:/setFrame:` **unreachable by hard-coded default OFF gate** in `DFSceneHost.m`. This A/B removes only the unverified transaction correlated with 2/3 crashes, while retaining the scene host's original .37 2-arg/3-arg content-reference selector paths, UIKit player view transform and per-pane `UIWindow` ownership. Stale-owner checks remain.
- **Risk**: the 09:13:19 cycle had no explicit frame-request marker; disabling it is not proven to stop all three incidents. Content may become boxed again; verify visually. Do not claim repaired crash or media orientation until real-device testing.
- Need a separately versioned single integrated DEB `0.0.75~framegate1`, existing macOS CI, SHA256, published Sileo after build success if authorized, then parked-device open YouTube ×3, ChatGPT, 70mai, split resize/Zoom/Dock/close and 5-minute observation. Restore previous immutable `.74` if regression. Avoid untested bulk private mutation work or silent OEM code/library inclusion.

## Evidence and reproduction commands
- Local analysis used Python stdlib `json.loads` of the first/header and remaining/body lines of each `.ips`, extracted `exception`, `lastExceptionBacktrace`, `consecutiveCrashCount`, `pid`, and matched timestamped `utc=` records inside the supplied 1.9 MiB audit to each crash PID/time. No iPhone command run, no device binaries altered.
- CI source validation: `python3 -m unittest discover -s sideplay/duoface-native-scene-host/tests -p 'test_scenehost_safety.py' -v` plus existing workflow iOS16 SDK syntax checks. CI is not a device proof.
- Follow-up verify source CI, integrated build, signed binary SHA, publisher job and **real iPhone crash evidence**, in that order.
