# QA124: Decide whether to collect DuoNavi 1.0.4 live logs — source-backed method crosswalk

**Date:** 2026-10-30 Asia/Ho_Chi_Minh. User request: “Có cần phải quét log từ duonavi ko? Xem noa hoạt động và gọi lệnh hay hàm nào để đối chiếu ko?”

## Answer / decision

**YES.** Comparing the *runtime timeline* of a working original DuoNavi CarPlay session on the user's **same jailbroken iPhone X, iOS 16.7.16, car and same Play/lock/Home operations** against DuoFace QA124 is a high-value controlled experiment. This checks whether physical iPhone lock leads to a CarPlay CPTemplate scene Background and whether hosted YouTube remains foreground / app scene owned. It can separate iPhone lock from real CarPlay Home, which QA124's log cannot distinguish. **But standard log text does not guarantee every Objective-C method invocation is recorded:** original static machine-code callsites tell us which hooks exist; live OS logs and the original's own emitted diagnostics only tell us runtime order if those events are instrumented/logged. Do not promise to reconstruct every called method from syslog alone.

## Evidence already verified; no need to repeat static extraction

Original SHA-pinned references in `chuongnguyen89dn-ui/Duoface`:
- `main:dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb` SHA256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`. Extracted original `DuoNaviDashboard.dylib` full file SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`. Static original all Mach-O scan CI 40989729701; imported hook + 3 original exact lock replacements verified CI **40991513805, 40991737734, 40991974285**.
- At original registration PCs `0x2ecf80`, `0x2ecfa0`, `0x2ecfc0` the **real native original** uses `MSHookMessageEx` on `SBSuspendedUnderLockManager`:
  1. `interceptUpdateForScene:withNewSettings:` → signed original IMP `0x2ed954`.
  2. `_shouldBeBackgroundUnderLockForScene:withSettings:` → IMP `0x2eda64`.
  3. `shouldBeUnderLockForScene:` → IMP `0x2edb7c`.
  Last two conditionally return FALSE for verified bridged/selected/hosted eligible scenes. For other scenes original iOS function is called. Unique helper `0x2eeb24` consults original scene-host associations plus `displayIdentity` / `isRootIdentity`. **Do not copy proprietary association markers, vendor code or license**.
- Original other likely relevant methods: `CBBridgeManager.handleCarPlayConnectionChanged:`, `performAutoResume`, `scheduleAutoResumeFallback`, `acquireCarPlaySleepAssertion`, `releaseCarPlaySleepAssertion`, and `CBWindow.activeCarPlayWindow`, `carPlayUIScreen`, `carPlayUsableBounds`. Presence + machine code are verified; **not yet proof of which one executes when the phone is physically locked**.
- Original also contains `SBMainWorkspace` passcode/activation hooks. These must **NOT** be cloned into independent DuoFace; comparing safe hosted-scene and actual CarPlay ownership is sufficient design goal.

## Direct QA124 comparison against actual NEW uploaded device log

User-uploaded feature-bearing log exists **ONLY for DuoFace**, not for original:
- `main:sideplay/log/DuoFaceAudit 10.txt`, main commit `bd0a31dac35a39cb310188eb56dbfce1d2c9c1e5`, blob `81b6ae1aa699ec383af85112f8eddf524c409e9f`, 2026-10-30 10:56:37 ICT export, 19,448 lines. `mcp__GitHub__fetch_blob` read it successfully. The current entire `main:sideplay/log/` listing has **DuoFace** exports/crashes only; search on latest log found **zero** `DuoNavi` or `CBBridgeManager` runtime lines. **No live DuoNavi trace is yet accessible.**
- DuoFace **QA124 already running** (marker `qa124-scene-resign-retained-await-background`) at 10:50:16.443 then **10:50:16.448** `touchowner-stop reason=scene-background`, **10:50:16.505** Chrome stopped with YouTube/Facebook scene invalidations, new session ~2s after. Repeats 10:50:47, 10:51:04. This source path differs from DuoNavi's connection/window/scene ownership and explicit underlock eligibility.
- More crucial: DuoFace `DFSceneLifecycle.m` `SBSuspendedUnderLockManager` hooks FAIL TO INSTALL on iOS 16.7.16: `qa123-underlock os-underlock-methods-abi-incompatible` in TWO fresh SpringBoard PIDs 82777 and 83173. `DFLockABI` requires bool return, exact 4/3 args, all object argument encodings; log does not distinguish missing selector from type encoding mismatch. Therefore original-vs-current actual **entry point registration difference is confirmed**, not just functional QA speculation. Without reading live method type encodings, cannot safely pick correct replacement signatures.
- Log formatter `DFDeepTrace.h` hardcodes build field `0.0.90~nativegetters1`; not a proof of outdated installed binary. QA124 marker is direct running source proof.

## What to capture in a controlled original-vs-current real-device run

**One runtime at a time**: avoid running original DuoNavi tweak and DuoFace SpringBoard hooks **concurrently** because they may both intercept the same private scene methods / own CarPlay windows. Only use legally held original package and its standard installation behavior; no license bypass. Stop the vehicle and stay parked. Keep versions, jailbreak iOS 16.7.16, iPhone X, external display, power and CarPlay connection constant.

Capture for EACH candidate: 
- *T0 original opens*: physical CarPlay connection / display identity + actual frontmost CarPlay scene + live YouTube hosted scene and video ready.
- *T1 phone lock*: exact manual time, phone backlight off; original CarPlay Dock and YouTube frame still displayed? Play tap while phone locked? Mark actual player response.
- *T2 phone unlock*: does original receive background/foreground scene settings, recreate scene, or keep original scene identity continuously?
- *T3 true CarPlay Home*: does pane owner hide promptly, or is CarPlay scene merely background while underlying hosted app survives? Return to original.
- *T4 unplug/replug*: physical connection end and restart, per-slot restore/auto-resume; note on/off status.

Read-only signals: `SBSuspendedUnderLockManager` selector *availability + type encodings* on **the actual iOS build**, hosted `FBScene` `isForeground` at lock before/after, live scene generation/window identity, `CPTemplateApplicationScene` active/background changes vs system CarPlay Home frontmost state, original `CBBridgeManager` CarPlay connection and sleep-assertion transitions *only if original emits those events*. If original has no diagnostic output, only observe OS logs + user-visible events; don't pretend routine syslog records every hook call. If exact hook invocations are essential, plan a separately safety-reviewed read-only monitor that does not alter hook return, app activation or passcode, avoiding unsafe blind instrumentation.

## Bounded next technical step / acceptance

1. First-party code-only ABI recorder candidate: log **availability, runtime method encoding, argument count and explicit types for BOTH actual `SBSuspendedUnderLockManager` methods** without installing hooks. This is needed irrespective of original log availability. Verify that the log is emitted on a fresh SpringBoard session with exact selector and class, and no crash; do not broad-bypass security.
2. Original DuoNavi runtime log **not available in GitHub today**. If/when a log from a one-at-a-time working original session is uploaded, align by event labels T0–T4, not by wall-clock timestamps of two different runs. Compare actual underlock and frontmost scene events; don't infer method invocations from method names alone.
3. Only then implement a one-owner state model differentiating **genuine CarPlay Home vs physical lock**, preserving native Dock/QA120 geometry, QA90 video orientation, QA92 divider, iPhone security and true disconnect cleanup; make distinct QA125 signed CI & public Sileo only after guard and ABI evidence, then physical acceptance test. Existing QA124 physical failure remains.

**Status:** verified comparative **binary/source/log crosswalk and absence of original live log**; no original DuoNavi live execution, device hook probe, new runtime source change, build or Sileo release in this checkpoint.
