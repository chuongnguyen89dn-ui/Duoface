# MyTweak 0.2.0 ZIP vs DuoFace Native12 GP/CarPlay — source-only technical assessment

**Date:** 2026-10-18. **Source attachment:** user-provided `/mnt/data/mytweak.zip` (runtime temporary mount, NOT a persisted GitHub asset). **SHA256:** `caf1557d1f9ac4828cf13cf8a5876a60c4b596b57b2951a8e9ac4d428225e015`. ZIP integrity `zipfile.testzip() == None` (**PASS**), 24 regular files, total 37,487 uncompressed bytes, nested root `mytweak/`. Test: all 10 `MyTweak_FILES` sources named by the Makefile are present, `MyTweak.plist` parses and filters `com.apple.springboard` only. No secrets were extracted. GitHub target repo: `chuongnguyen89dn-ui/Duoface`, branch `feature/visual12-duodash-recovery`, pre-audit HEAD `dfa258136c994d136b31da08539015f4f75e267b`.

## User intent and decision

User asks whether the **MyTweak architecture/schematic** can replace the existing Native12 license subsystem while preserving DuoFace native UI / CarPlay. **Answer: NOT as a drop-in replacement.** MyTweak is an early independent SpringBoard overlay / CarPlay visual shell, not a replacement for `DuoFaceUI.app/DuoFaceUI` licensing, `DuoFaceDashboard.dylib`'s mixed `CBBridgeManager`/policy ownership, or a functioning scene-host engine. It may serve as a small **independent reference** for an eventual source-owned CarPlay host if integrated into a single-owner design. **Do not install its tweak alongside stable Native12 or QA**, because both create external UIWindow owners; headunit/UI overlap and SpringBoard instability are risks, not demonstrated failures.

## Direct facts from ZIP (precise source)

| ZIP file | What it actually does | Limit / risk |
|---|---|---|
| `Tweak.x` | Logos `%hook SpringBoard` `applicationDidFinishLaunching:`, starts coordinator 2 seconds later | `MT_SHOW_LOAD_ALERT=1`: shows modal alert on every SpringBoard startup. No established iOS16/CarPlay device test. |
| `MTBridgeCoordinator.m:21-86` | Watches `UIScreenDidConnectNotification` and `UIScreenDidDisconnectNotification`. For first non-main screen, creates `MTBridgeWindow` and calls `[window makeKeyAndVisible]`. | Any external screen is treated as CarPlay; it does not verify CarPlay display identity or use the QA-approved `UIRootSceneWindow`/FBS display path. Could be a competing owner. |
| `MTSplitContainerViewController.m:17,70-98` | Starts left ratio 0.5, pan clamps .25–.75; creates two panes and 8pt divider. Double-tap toggles fullscreen. | Does not implement Native12's 8 layouts, menu Zoom-only fullscreen, divider logo 28/30pt, ratio/prefs persistence, HUD or long-press relocation. |
| `MTAppSlotViewController.m:50-72` | Self-made 44pt slot toolbar and selection button; double-tap gesture. | Native12 per-pane slot pill/placeholder, border/chrome, picker visuals and touch boundaries absent. |
| `MTAppPickerViewController.m` | `UITableView` picker from `LSApplicationWorkspace` | Native12 uses card/grid/paging + approved App/Zoom/Style/Close header, not table list. |
| `MTSceneHost.m:9-28` | `hostViewForBundleID:error:` always emits NSError domain `MyTweak` code **1001** with "Host scene chưa được implement" and returns `nil`. | **HARD BLOCKER**: cannot host any third-party app on CarPlay. `MTAppLauncher.m` returns nil whenever this host does. |
| `MyTweak.plist`, `control`, `Makefile` | Injection only into SpringBoard, package `com.nguyen.mytweak` v0.2.0, rootless Theos arm64/arm64e | Package is unrelated to and does not physically remove or replace DuoFace's two mixed binaries or remove their policies/license dependencies. |

**QA baseline already provides more scene functionality:** `replacement/visual12/engine/runtime/DFIRuntime.m` owns a real `UIRootSceneWindow` and `DFV12SceneHost` using SpringBoard private APIs; `replacement/visual12/engine/runtime/DFCarPlaySplitCoordinator.m` has actual asynchronous `openApp:inPane:completion:`, `setSplitRatio:`, focus/swap/close scene path; `DFCarPlayBridgeAPI.h` explicitly requires **one external UIWindow owner**. Existing QA nonetheless has UI fidelity/touch/exitMode issues and cannot be declared working perfectly. Swapping in MyTweak's stub would regress playback rather than solve license coupling.

## Native12 license coupling — unchanged

Two actual Native12 core Mach-O files: `/var/jb/Applications/DuoFaceUI.app/DuoFaceUI` and `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib`. `CBBridgeManager` (75 ObjC methods) includes scene/window/split functions and 7 license/watchdog methods; `CBLicenseSyncManager` contains CarPlay detection methods in both binaries; `CBBridgeManagerDashboard` has activation / policy flow. The existing audits `audit/payload-migration/LICENSE_BOUNDARY_AUDIT.json`, `NATIVE12_LICENSE_ACTIVATION_GATE_READONLY.json` say license is **NOT safely separable by file**, dynamic dispatch not fully mapped. `DFVisual12GateRepair` altering VIP validity getters did not restore iPhone X CarPlay. `MyTweak` has **no integration/callback ABI** toward those classes, and its own window is not a drop-in for their existing object graph.

## Practical feasibility / boundaries

- **NO:** copy `mytweak.zip` into Native12, remove two licensing objects/classes or simply install `com.nguyen.mytweak` in parallel and expect Native12 UI or CarPlay to work. Not supported by source.
- **YES with additional engineering, as a different project:** use the MyTweak naming/modules as conceptual architecture only; build a fully source-owned scene host (or preserve the already more complete QA host), one window owner, correct CarPlay display detection, lifecycle/teardown, touch/scene geometry, then separately restore UI. That is NOT a license-subsystem replacement while keeping original Native12 compiled UI.
- **If source/license rights exist for the original Native12 renderer:** refactor `CarPlayHost` and `LicenseService` behind separate callable interfaces and retain Native12 UI; needs original source and permitted use, not binary patch guesses. Otherwise independent UI restoration is the maintainable option.

## Executed checks and limits

Checks executed locally in container without Theos: `file /mnt/data/mytweak.zip`; `unzip -Z -1 /mnt/data/mytweak.zip`; Python `zipfile.testzip()`, SHA256, `plistlib.loads(MyTweak.plist)`, Makefile source existence, scan for `MTSceneHost` stub. These tests **do not compile, package, run SpringBoard/CarPlay, or prove safety/behavior on iPhone X or iPhone 8 Plus**. No external service/window actually started; no Native12/QA source or Sileo package changed. MyTweak ZIP not copied to GitHub; only this audit with original SHA/source references is persisted. No license bypass performed or recommended.

**Next concrete checkpoint:** do not merge zip directly; if user chooses Native12 path, continue read-only ABI/policy-window ownership tracing. If user chooses independent QA scene host path, perform a narrowly scoped design review before adapting anything from MyTweak, ensure one owner, and test stable split/exitMode regression. Keep `main`, Sileo Native12 HUD8, and user's device install unchanged.
