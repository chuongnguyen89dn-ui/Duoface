# Original DuoNavi live Observer 0.0.1: device ABI and CarPlay lock vs disconnect — verified report

Date: 2026-10-30 ICT. User asks: **“Check log đi”**. This report is based on the **actual newly uploaded live file**, not the previous source-only audit and not on guesses.

## Evidence provenance

- Exact user upload: `chuongnguyen89dn-ui/Duoface` **main** commit `962290dd877d6a6fd3622ef8b0f82fcf1cc11c0a`, `sideplay/log/DuoNaviObserver-69D22C75-5122-4EFC-B21F-59FAE0B60498.txt`.
- Blob SHA `8eb93be5464e710c17a7635d22537dc999be5ab6`, 20,592 UTF-8 bytes; exported `2026-10-30T04:44:45Z` **11:44:45 ICT**, iOS **16.7.16**.
- Contains **79 JSONL records**: 38 from SpringBoard PID 4989, 34 from CarPlay PID 5020, 7 explicit manual time markers. No `CarPlayApp` separate process section or original DuoNavi class/method invocation events. All interpreted times below are Asia/Ho_Chi_Minh UTC+07.
- The `DuoNaviObserver` first-party tweak is *passive*, logging UIKit state/ABI only. This file establishes the OS event timeline during the user's claimed original test, but it **does not independently prove that DuoNavi app was foreground, hosted YouTube actually played, or an original proprietary method executed**. The 3 Home markers do not correspond to a direct log of frontmost application identity.

## Confirmed root-cause discovery: actual iOS16 under-lock Objective-C ABI

SpringBoard PID **4989** recorded at 11:39:37.286 ICT:

| Runtime class/selector | Actual instance method type encoding | Number args | Result |
|---|---|---:|---|
| `SBSuspendedUnderLockManager interceptUpdateForScene:withNewSettings:` | `v32@0:8@16@24` | 4 including self/_cmd | Exists, returns void |
| `SBSuspendedUnderLockManager _shouldBeBackgroundUnderLockForScene:withSettings:` | `B32@0:8@16@24` | 4 including self/_cmd | Exists, boolean result |
| `SBSuspendedUnderLockManager shouldBeUnderLockForScene:` | `missing` | 0 | **NOT PRESENT** on runtime class, neither instance nor class method |

Class itself **exists**. Crucially, source `sideplay/duoface-native-scene-host/DFSceneLifecycle.m:200–224` does:

```objc
Method bg=class_getInstanceMethod(cls,background);
Method ul=class_getInstanceMethod(cls,underlock);
if(!DFLockABI(bg,4) || !DFLockABI(ul,3)) {
    DFDeepTrace(@"qa123-underlock",@"os-underlock-methods-abi-incompatible");
    return;
}
```

Now the earlier QA124 SpringBoard `os-underlock-methods-abi-incompatible` in `main:sideplay/log/DuoFaceAudit 10.txt` is **fully explained**: **`ul` is NULL** because the selector does not exist on this iOS16.7.16 class; `bg` matches the 4-argument boolean/object signature. The combined preflight rejects both hooks before installing any. The original static ARM64 audit did show a vendor registration *attempt* for the third selector; **absence on this live device means this runtime alone does not prove that vendor registration succeeded**. Do not infer vendor underlock behavior from a missing original selector or forcibly hook/create a nonexistent selector.

**Engineering decision, not yet implemented:** independent first-party owner-scoped logic should never require absent `shouldBeUnderLockForScene:` to install the ABI-confirmed available method. If a new version hooks `_shouldBeBackgroundUnderLockForScene:withSettings:` at all, preserve Apple original IMP for all unowned scenes, use live CarPlay+scene+owner checks, fail closed on unknown states and no phone passcode or device lock policy bypass. Original `interceptUpdateForScene:withNewSettings:` is a void-return method and cannot be treated as a boolean method. Separately fix the native host `sceneDidEnterBackground:` unconditional tear-down only when an independently verified CarPlay frontmost scene remains active; true CarPlay Home and disconnect must still release promptly. **No new code or DEB build in this log-verdict task.**

## Real-time physical timeline

| ICT timestamp | What the log directly shows | Interpretation limits |
|---|---|---|
| **11:41:58.671–11:41:59.495** | CarPlay external display connects, **640 × 331.333 pt**, scale 3; **two** CarPlay-process UIScenes become foreground-active | System CarPlay scenes, not proof of hosted YouTube |
| **11:42:20.432–11:43:15.532** | CarPlay process gets `ProtectedDataWillBecomeUnavailable` then `DidBecomeAvailable`; samples 11:42:31–11:43:13 show **protected_data=false**, **2 foreground-active** scenes, 1 external screen | Strong evidence system CarPlay stays active through an iPhone protected-data unavailable interval, without entering Background |
| **11:43:37.924** | Manual marker `VIDEO_AWAKE` | Button was tapped; no direct YouTube Play event captured |
| **11:43:44.238** | Manual `BEFORE_PHONE_LOCK` | Later corresponding OS protected-data transition is **22.027 sec after marker**; do not assign exact physical button instant from marker |
| **11:44:06.265–11:44:10.983** | Another CarPlay process protected-data unavailable/available interval (~4.72 sec); 2 CarPlay scenes remain active, 1 external display. SpringBoard also emits 11:44:06.406→11:44:11.054 | **Physical phone lock ≠ automatic global CarPlay scene background** in this session |
| **11:44:13.527** | Marker `AFTER_PHONE_UNLOCK` | Consistent with protected-data restoration by 11:44:11 |
| **11:44:18.359 / 11:44:21.078 / 11:44:21.443** | `BEFORE_CARPLAY_HOME` marker recorded three times | No frontmost-app snapshot or event proving Home action actually occurred. CarPlay process scenes remain active through 11:44:28 |
| **11:44:31.463** | Marker `BEFORE_UNPLUG` | Real detach happens ~10.88sec later |
| **11:44:42.347–11:44:42.467** | CarPlay gets two scene deactivation/background transitions, application background, then `UIScreenDidDisconnect`; SpringBoard `UIScreenDidDisconnect` at 11:44:42.348 | Confirms **true physical disconnect teardown** and normal iOS scene background in this interval |

**Critical differentiation**:
- Under phone protected-data unavailability during *connected* CarPlay: `CarPlay` PID 5020 stayed alive, two `UISceneActivationStateForegroundActive` scenes and external display retained; **no `UISceneDidEnterBackgroundNotification`** in those windows.
- At **actual unplug**: both CarPlay scenes transition to background and external screen disappears. This is a distinct, strongly evidenced event boundary.
- Home: **unresolved** by this passive observer because it does not identify actual frontmost CarPlay application/scene ownership during Home. Do not mislabel missing CarPlay background event as proof DuoNavi remains foreground during Home.
- Importantly, QA124 previously showed **DuoFaceNativeHost** own CPTemplate scene backgrounds and kills all owned YouTube/GOFA scenes at 10:50:16, 10:50:47, 10:51:04; this **different** DuoFace app/process lifecycle is not disproved by the healthy `CarPlay` system process here.

## Source-backed comparison to the existing QA124 failure

- QA124 live file: `main:sideplay/log/DuoFaceAudit 10.txt`, blob `81b6ae1aa699ec383af85112f8eddf524c409e9f`; audit `sideplay/audit/qa124-real-device-log-20261030/QA124_LOG10_BACKGROUND_AND_UNDERLOCK_ABI_ROOT_CAUSE.md`. At 10:50:16.443 app says `qa124-scene-resign-retained-await-background`; 5.2 ms later 10:50:16.448 `scene-background` revokes session and 10:50:16.505 Chrome detached/hosted apps invalidated. Existing `sceneDidEnterBackground:` unconditional stop `DFNativeHostAppDelegate.m:265–268`.
- Static original `DuoNaviDashboard.dylib` three underlock registration callsites `0x2ecf80/0x2ecfa0/0x2ecfc0`, but live selector `shouldBeUnderLockForScene:` is missing here: separate actual ABI evidence is stronger than a belief that all three original replacements are installed.
- The system CarPlay external display in original test reports **640 × 331.333 pt**, scale 3. The separate QA124 log had UI viewport/dock geometry **640 × 360 pt** with content 595×360. Different external screen physical geometry/sessions; **do not adjust first-party Dock/frame sizes based on this alone** or claim these are identical hardware modes.

## Next implementable steps and test conditions

1. Source QA125 should first replace the **all-or-nothing** `DFInstallOwnedUnderLock123` preflight with a narrowly gated flow for **ABI-confirmed** `_shouldBeBackgroundUnderLockForScene:withSettings:` only. Never add/hook an absent method; ensure original IMP valid; owner-only scoping, main-thread safety, external display + current session and no passcode bypass. The observed `interceptUpdateForScene:withNewSettings:` is `void` and remains unmodified pending actual scene ownership necessity.
2. Differentiate **DuoFace own hosted CPTemplate app** Background from actual external CarPlay foreground ownership and genuine Home/disconnect with independently validated state. Do NOT simply make `sceneDidEnterBackground:` a no-op or force every scene active. Preserve native Apple Dock/QA120, YouTube orientation QA90, ratio/divider QA92 and cleanup on real Home/disconnect.
3. After a source patch, run signed macOS CI, publish a **distinct QA125** via Sileo with exact SHA and public APT proof, then do *parked-car* physical regression with explicit Play when iPhone is locked, true CarPlay Home, disconnect/reconnect. Avoid triggering passcode or suppressing legitimate iPhone lock.
4. More exact DuoNavi original per-function tracing (e.g., CBBridgeManager auto-resume or host AppScene return path) is still **not supplied**. This log proves runtime API shape and OS lifecycle, not which vendor methods actually executed. If further function proof is essential, design a separate safe and narrowly scoped non-mutating tracer instead of guessing from strings.

**This task status:** one newly uploaded **physical log** actually parsed; new missing-selector root cause proven; CarPlay persistence/disconnect boundaries proven; no QA125 fix, CI or Sileo deployment performed during this analysis. Original DuoNavi videos or Play success cannot be asserted from this exported diagnostic alone.
