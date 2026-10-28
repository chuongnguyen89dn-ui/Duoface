# GitHub log check after user reports DuoFace .88 YouTube rotation still failing
Verified on GitHub 2026-10-28, Asia/Bangkok (+07).

## Source of truth / chronology
- Project: `chuongnguyen89dn-ui/Duoface`, working branch `feature/duoface-jb-embedded-appbridge-20261020`; existing handoff `sideplay/tiep tuc du an.md`.
- Device/user symptom: **DuoFace .88 still presents YouTube video in wrong orientation in split view; solo/fullscreen or swipe-down transition makes it correct**. This is a device observation, not a .88 crash report.
- GitHub default branch `main` existing `sideplay/log` checked. Latest upload commit **`f4cc3ab3d9c519547c90da5d10bbc2cc1cd4be3a`** by user was committed **2026-10-28 08:59:17Z / 15:59:17 +07**; it added precisely **`sideplay/log/Crash-0-SpringBoard-2026-10-28-131840.ips`**, NOT `DuoFaceSceneHost.log` or a `DuoFaceAudit 8` file.
- New .88 Sileo publisher run **40656863552** originated around 2026-10-28 **08:28Z / 15:28 +07**. New upload **time** is later than .88 release, but the uploaded IPS's own **capture timestamp 2026-10-28 13:18:40 +07 (06:18:40Z)** is **before** .88 release. Therefore **THIS IPS CANNOT BE A POST-.88 INCIDENT**, notwithstanding upload time. Package version is not in this IPS; do NOT assign it to .87 either.
- Last available `DuoFaceAudit 7.txt` (Git blob `803957e787859e19c430f81c1ae2f2c50894b2d8`, 2,542,564 bytes) and older owner JSONL files were present already before this upload. No timestamp-matched .88 `youtube-app-handshake-ack` log appears among the *filenames* of `main:sideplay/log`; this does not prove none exists on the device.

## What the newly uploaded SpringBoard IPS ACTUALLY proves
File: `main:sideplay/log/Crash-0-SpringBoard-2026-10-28-131840.ips`, blob SHA `ef186155df9fbe27420d41db5f4c1dc02dca6371`.
- `app_name: SpringBoard`; iPhone model `iPhone10,6`, iOS `16.7.16 (20H392)`; capture `13:18:40 +07`; `consecutiveCrashCount: 16`.
- `exception.type = EXC_CRASH`, `signal = SIGABRT`; `asi.libsystem_c.dylib = ["abort() called"]`. `lastExceptionBacktrace` starts `__exceptionPreprocess → objc_exception_throw → _userInfoForFileAndLine → -[SBAppViewController sceneHandle:didUpdateSettingsWithDiff:previousSettings:]` **+440**, then `DFManagedSceneObserver` (+372) from `DFTouchOwnerProbe.dylib`, followed by `SBSceneHandle`, `FrontBoard` scene-monitor events. Deeper path has `DFUpdateScene` and `FBScene updateSettings...`.
- The backtrace also includes `_logos_method$ImmortalizerHooks$FBScene$updateSettings$withTransitionContext$completion$` from **`AppData.dylib`**. That means a second installed tweak is present on the scene-update stack, **not proof that it caused the abort**. Neither the `reason` nor any exception `name` is included in this IPS payload; no fabricated `NSInternalInconsistencyException` reason.
- Compared with prior IPS `Crash-0-SpringBoard-2026-10-28-083218.ips` and `Crash-1-SpringBoard-2026-10-28-083042.ips`: they triggered `EXC_BREAKPOINT/SIGTRAP` at the same `SBAppViewController sceneHandle:didUpdateSettings...` callsite, without this new IPS's explicit Objective-C exception backtrace. Recurrent **SpringBoard scene-observer/update** failure family is visible in logs; the exact invariant and trigger remain unproven.
- These IPS reports are **not evidence of YouTube's rotation values**. They contain neither `clientSettings.interfaceOrientation`, the reported `youtube-app-handshake-ack` counters, nor the before/after transition from two panes → swipe → corrected scene.

## Resolution state and next checks
- **New finding**: a historically recurring SpringBoard scene-observer assertion/abort involving DuoFace's `DFManagedSceneObserver`, while an additional `AppData.dylib` hook was active in the older incident. Do not infer .88 caused this; do not remove unrelated tweaks without controlled evidence.
- **YouTube .88 rotation** still fails per user; **the newly uploaded IPS does not diagnose it**.
- Next source of truth: installed .88 diagnostics `/var/mobile/Library/Logs/DuoFaceSceneHost.log` after reproducing wrong two-pane orientation and then swipe/solo correction, or a new export that includes `youtube-app-handshake-ack`, `normalSeen`, `internalSeen`, `layoutRefreshed`, actual scene orientation/size. Save into existing GitHub `Duoface/main/sideplay/log`; verify log capture *after* .88 installation.
- Use the actual ACK to decide whether the app-side receiver failed injection, scene ID mismatched, internal video window was not reflowed, or the client orientation remained divergent. Preserve .83 video lifecycle, Maps and Dock; no fresh .89 DEB built from this old IPS.

GitHub endpoints used (GET only): `/repos/chuongnguyen89dn-ui/Duoface/contents/sideplay/log`; `/repos/chuongnguyen89dn-ui/Duoface/commits?path=sideplay%2Flog`; `/repos/chuongnguyen89dn-ui/Duoface/contents/sideplay/log/Crash-0-SpringBoard-2026-10-28-131840.ips`; comparison with two 08:30–08:32 IPSs; `/repos/chuongnguyen89dn-ui/Duoface/actions/runs/40656863552`.
