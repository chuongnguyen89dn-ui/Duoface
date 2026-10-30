# QA122 deeper verification — DuoNavi really registers under-lock scene hooks; precise safe ownership guard

Date: 2026-10-30 Asia/Ho_Chi_Minh. Project `chuongnguyen89dn-ui/Duoface` branch `feature/duoface-jb-embedded-appbridge-20261020`. **Completed SHA-pinned original binary forensics only. No first-party runtime hook installed, signed .121/.122 DEB built, Sileo release or new physical test in this batch.**

## User physical facts, do not reinterpret
- Physical QA120 native CarPlay content size **FIXED**; preserve current native Dock sizing, .90 YouTube rotation, .92 divider.
- On iPhone lock, **APPLE NATIVE CARPLAY DOCK STAYS VISIBLE** but DuoFace application panes become black. YouTube scrolling and other controls remain interactive while some video Play only works with phone display lit. These are distinct indicators of DuoFace-owned pane-host and remote iPhone YouTube scene lifecycle, not loss of the actual vehicle display.
- Existing schema119 audit proves an actual pane hide/restart at 07:40:31.339 stop → 07:40:31.341–.378 hidden → 07:40:33.292/.846 restored, but lacks exact physical iPhone lock timestamp. No same-session QA120 per-Play remote scene trace yet, so do not call causality certain.

## NEW — correct previous evidence limit: **DuoNavi itself actually installs the same three lock hooks**

Previous QA122 report could confirm only Native12 C hook registration. **This deep audit now confirms DuoNavi 1.0.4 original C registration directly from ARM64 + imported Mach-O LC_DYSYMTAB**:

- Original DuoNavi 1.0.4 DEB exact SHA256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`, FAT `DuoNaviDashboard.dylib` full-file SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`; selected arm64 slice SHA256 `012c3fa0c0b4c32363d09af24bbc890d9baf61e51788d8f086836f6829a5922d`. The slice SHA **differs** from FAT file SHA by design, not a corrupt binary.
- Original Native12 Dashboard SHA256 `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`. Decoder self-test recovers and matches **all 11 known original Native12 hook class+selector arguments in exact order and call PCs**. Therefore DuoNavi class/SEL decoder accuracy is cross-validated against independent previous SHA-pinned proof.
- Actual imported `MSHookMessageEx` stub for DuoNavi at `0x3133b4`; direct machine-code BL callsites to it **259**, vs Native12 **240**. (These counts cover the entire dashboard and are *not* 259 distinct under-lock hooks.) Reports: `DUONAVI_AND_NATIVE12_EXACT_MSHOOK_IMPORT_CALLS.json`, `DUONAVI_HOOK_IMPORT_CROSSCHECK.md`, `EXACT_DUONAVI_REGISTERED_UNDERLOCK_HOOKS.json`.
- **DuoNavi signed exact three** `SBSuspendedUnderLockManager` registrations:
  1. `interceptUpdateForScene:withNewSettings:`: registration PC **0x2ecf80**, replacement IMP **0x2ed954**, previous storage **0x3adfd0**.
  2. `_shouldBeBackgroundUnderLockForScene:withSettings:`: PC **0x2ecfa0**, replacement IMP **0x2eda64**, previous storage **0x3adfd8**.
  3. `shouldBeUnderLockForScene:`: PC **0x2ecfc0**, replacement IMP **0x2edb7c**, previous storage **0x3adfe0**.
- **Two additional** DuoNavi `SBMainWorkspace` hooks in same source registration sequence which are NOT in the earlier verified 11-hook Native12 table: `systemService:isPasscodeLockedOrBlockedWithResult:` (PC `0x2ed0ac` → IMP `0x2ee400`) and `systemService:canActivateApplication:withResult:` (PC `0x2ed0d4` → IMP `0x2ee4ec`). These touch passcode/application activation and must **NOT** be transplanted into independent DuoFace, must not disable physical iPhone security; they are original research evidence only.

## NEW — actual DuoNavi ARM64 behavior of the three under-lock policies

From the same signed DuoNavi binary, 13 replacements decoded, including:

- `_shouldBeBackgroundUnderLockForScene:withSettings:` `0x2eda64`: validates `sharedInstanceIfExists`, `isUIAppBridging`, `shouldBridge:` then **a separate predicate via BL `0x2eeb24` at PC `0x2edb0c`**. Only if this helper returns true does the hook set **`mov w21,#0` at `0x2edb1c`** (NO background under lock). All other paths invoke saved original IMP via **`blr x8` at `0x2edb44`**. This is not a global bypass.
- `shouldBeUnderLockForScene:` `0x2edb7c`: same bridge/selected-bundle checks **and the separate helper BL `0x2eeb24` at `0x2edc14`**, then `mov w20,#0` at **`0x2edc24`** for eligible scene; else invokes original via `blr x8` at **`0x2edc48`**.
- **The helper `0x2eeb24` is an important further distinction from Native12.** Two separately verified callsites above. A bounded decode of `0x2eeb24..0x2eec64` shows first-party host *identification contract in the original*, with literal association markers `CBDuoNaviHosted`, `CBCarBridgeHosted`, plus operations `displayIdentity` and `isRootIdentity`. The code selects the True return branch when a hosted-scene association is present (at `0x2eeba8` `mov w22,#1`), and otherwise continues to inspect display identity. **This is evidence of an added exact scene/identity guard; not enough to claim that every display identity branch succeeds or which physical button action invoked it.** Do not copy vendor marker names into independent project.
- Original Native12 background hook `0x2c8768` and underlock hook `0x2c8870` similarly check `isUIAppBridging` + `shouldBridge:` and return NO for explicitly selected scenes, but do not contain this same DuoNavi helper call. DuoNavi therefore has a **tighter verified ownership/scene-identity predicate** instead of blanket "keep foreground on".
- SHA-checked reports: `DUONAVI_13_LOCK_AND_WORKSPACE_HOOKS_ARM64.json`, `DUONAVI_13_LOCK_AND_WORKSPACE_HOOKS_ARM64_VERDICT.md`, `DUONAVI_UNDERLOCK_EXTRA_GUARD_HELPER_ARM64.json`, `DUONAVI_UNDERLOCK_EXTRA_GUARD_VERDICT.md`.

## Independently rechecked current DuoFace code (feature branch)

- `sideplay/duoface-native-scene-host/DFSceneLifecycle.m` Git blob SHA `42167abf4a49cb842e6c03febadabe13d482dc60`: **no** `SBSuspendedUnderLockManager` explicit hook. It only adjusts `FBScene foreground=NO` for registered, live, manual owner and consumes one `SBAppViewController` settings observer. `DFOwnsScene` is a live scene identity map but is not consulted before iOS **decides** background-under-lock.
- `DFNativeHostAppDelegate.m` blob `0e9c50676b3907c30196678c62c155bff6e2db41`: **no** under-lock differentiation. `sceneWillResignActive` at line250 unconditionally `stopTouchOwnerWithReason:@"scene-resigned-carplay-home"`; background line254 likewise stops. A 0.75s CPTemplate heartbeat only renews while foreground active.
- `DFTouchOwnerProbe.m` blob `caaf8e4a8df616aa72898e94ce9afbe633f7cb32`: at line374 `[sChrome hideAllExternalWindowsImmediately]`. Stale >2.5s heartbeat watchdog also detaches.
- Result: **PROVEN first-party structural deficit vs BOTH originals (not just Native12)** and a **proven existing pane-hide code path** matching native Dock still alive; **not yet physical causality proof** of lock signal vs CarPlay Home, nor YouTube Play remote player state.

## Exact executed CI runs and fixes

- [40991250160](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40991250160) SUCCESS — real imported `MSHookMessageEx` 259 vs 240, exact FAT slice distinction. Prior retry 40990900793 failed unused module import; 40991024172 failed wrongly comparing arm64 slice SHA against FAT whole original SHA; both errors fixed and subsequent CI PASS.
- [40991513805](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40991513805) SUCCESS — 11/11 Native12 crosscheck plus three actually installed DuoNavi under-lock registrations and two extra workspace hooks.
- [40991737734](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40991737734) SUCCESS — signed original 13 replacement ARM64 functions, branch and original IMP readbacks.
- [40991974285](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40991974285) SUCCESS — original **extra** scene-identity helper signed raw ARM64 0x2eeb24, both direct calls, safe file persistence. All report blobs verified on GitHub.

## What this proves / fails to prove / next actions

**Proven:** both DuoNavi and Native12 have genuine, *registered* under-lock decision hooks; DuoNavi uniquely adds an extra scene-eligibility/identity predicate and two workspace passcode/activation hooks. Current DuoFace lacks those under-lock decision boundaries, and has an aggressive CPTemplate resign → pane hide route. **Plausible two-stage failure:** iPhone lock backgrounds hosted YouTube and/or pauses CPTemplate lease → DuoFace panes black (Apple Dock unaffected), video Play eligibility lost until main phone display wakes.

**Not yet proven:** physical iPhone lock-button event correlates exactly with `scene-resigned-carplay-home` QA119 log; whether the Play click reaches remote YouTube scene on locked phone; whether system power assertion would fix anything; whether proprietary original runtime fully prevents black on every iOS version. This is binary/static evidence, not a signed device patch.

**Next precise first-party correction:** independent ownership+generation gate at UIKit/iOS under-lock *decision* for actual selected, live, external-CarPlay-hosted scene; preserve legitimate Apple's lock and Home, other apps, nonowners, stale generations. Do not copy original markers, license or passcode hooks. Independently disambiguate CPTemplate Home vs iPhone lock, else current stop closes chrome even if remote app scene retained. Preserve QA120 size/native Dock, .90 rotation, .92 divider. Compile and ABI regression test before new signed DEB; publish Sileo only after green archive and exact SHA; verify user lock/Play on parked vehicle. There is **no new runtime patch/DEB/Sileo in this audit**.

