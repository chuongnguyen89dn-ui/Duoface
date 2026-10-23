# Native12 media/player — verified original IMPs vs independent DuoFace .37–.40, SpringBoard scene crash

Date: 2026-10-23, Asia/Ho_Chi_Minh. Repo `chuongnguyen89dn-ui/Duoface`; branch `feature/duoface-jb-embedded-appbridge-20261020`. **Audit only**: no source fix, DEB build or Sileo release in this analysis.

## Source provenance
- Original Native12+Speed8 DEB immutable Git commit `1286a3ef868cf7e29804bcddf7e20b2eae707ce1`, path `dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb`, SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`. Original Dashboard Mach-O SHA256 `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`.
- **Read and parsed actual SHA-verified earlier extracted binary disassembly**, Git file `sideplay/audit/native12-continuation-4888299/original-video-layout-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json` blob `aa86461c6f592f0bfe22eb6c3dc71ae89358633f`: 9 original methods/2653 ARM64 instructions. Also `gallery-media-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json`, `SCENE_SETTINGS_BLOCK_DECODE.md` with 118-instruction block trace (GitHub CI `39737949588` PASS). Original DEB **not downloaded or extracted again this turn** due network/DNS; analyzed existing byte-verified persisted extraction. No imported vendor code or license.
- History `sideplay/tiep tuc du an.md` 2026-10-22 ~15:58 ICT: real CarPlay screenshots from user on public **0.0.37** had wrongly oriented YouTube/video and incorrect menus. User NOW recalls earlier video was playable without ExitSafeMode, but photos/handoff alone do not independently establish play/pause or crash absence; .37 is **strongest grounded candidate baseline**.

## Original native video UI/function wiring (static evidence)

Native12 does not invent a YouTube player UI: it hosts the real app's `SBAppViewController` within `CBBridgedUIAppView`; this bridge owns `_appViewController` (SBAppViewController, ivar offset24) and `_wrapperView` (UIView offset32; independently byte-verified original `dismiss` forensic CI `39739371586`).

```text
CBBridgedSplitApp.layoutSplitViews      IMP 0x1044f8
 ├─ calculate slot CGRect, set child frames/bounds and interaction
 ├─ setAudioOnlyBackgroundMode: (conditional visibility/interaction)
 ├─ refreshSceneLayout / updateLayout on per-app bridge
 └─ manage focus/CarPlay usable bounds
CBBridgedUIAppView.updateLayout       IMP 0xacc6c
 ├─ calculateNativeSizeForSlotRect:   IMP 0xacc28: roundf(2*slotW/H)
 ├─ child UIView: reset CGAffineTransform, frame origin zero/native size
 ├─ optional device content reference 2-arg/3-arg orientation Portrait=1
 ├─ setHomeGrabberDisplayMode:1
 ├─ uniform min(width/nativeW,height/nativeH) scale; center, corner/mask
 └─ native hosted child renders its OWN YouTube controls
CBBridgedUIAppView.refreshSceneLayout IMP 0xade58
 ├─ updateLayout                   @0xade74
 ├─ updateSceneSettingsFrame       @0xade84, IMP 0xad5bc
 │   ├─ 3 independent guarded setters child2/child3/parent2 Portrait=1
 │   ├─ find sceneHandle / sceneIfExists / _scene
 │   └─ updateSettingsWithBlock:  call @0xadacc; invoke @0xadc74
 │       ├─ sceneSettings.setFrame: and _frame-ivar fallback
 │       ├─ setForeground:YES; setOccluded:NO; setUnderLock:NO
 │       ├─ setCanShowWhileLocked:YES; setDeactivationReasons:0
 │       └─ setIdleModeEnabled:NO
 └─ hosted child view setNeedsLayout/layoutIfNeeded @0xaded8..0xadf08
```

Source-backed original PCs:
- `0xacc38..0xacc54`: double and round slot size; `0xacd24..0xacd74`: reset transform and logical frame; `0xacf9c..0xad004`: two private child reference sizes with Portrait=1; `0xad03c..0xad068` uniform minimum scale and fallback 0.5 when threshold 0.05; `0xad0bc..0xad0cc` center.
- `0xade70..0xade84`: **original refresh invokes updateLayout BEFORE updateSceneSettingsFrame**; original then flushes UIKit child. Independent after private scene call flushes 2 views and scene-size is debounced 0.30s; call order and ownership differ.
- `0xad610..0xad620`: original fallback `CBWindow.carPlayUsableBounds` when bounds are not valid. Current independent only checks own slot and skips invalid sizes.
- `CBBridgeManager.supportsInterfaceOrientation:forBundleID:` IMP `0x24d118` only two instructions, returns true unconditionally; `CBBridgeManager.renderSizeForBundleID:` IMP `0x24c920` 510 instructions with app-ID/render size/CarPlay-usable-bounds conditions. Independent `DFSceneHost` uses 2x slot, lacks this **per-bundle** render policy. Orientation supported by manager is distinct from Portrait=1 passed to scene reference setters: **don't blindly force landscape**.
- Native12 `CBBridgedSplitApp.layoutSplitViews` loads selector `setAudioOnlyBackgroundMode:` @0x1046cc,0x104f68; `CBBridgedUIAppView.setAudioOnlyBackgroundMode:` IMP 0xac858: YES -> alpha 0/touch NO, NO -> alpha1/touch YES and updateLayout+refreshSceneLayout. Independent just hides its own UIWindow when focused elsewhere and sets `appWindow.userInteractionEnabled=loaded`; no equivalent app-scene lifecycle callback. This is a known feature gap but **not proven video-crash cause**.

## Independent current implementation (observed source)

```text
DFNative12Chrome.layoutControls
 ├─ DFComputePresetFramesWithSecondary; 4 distinct own appSceneWindows
 ├─ appWindow.frame = slot rect
 ├─ rootController.view.frame + child.frame = UIWindow local bounds
 └─ hidden=(startup || focusElsewhere), input=loaded
DFSceneSurface.layoutSubviews / DFSceneHost.layoutScene
 ├─ SBAppViewController.view directly hosted, not original wrapper
 ├─ DFNative12MediaGeometry => rounded 2x logical/native size
 ├─ native uniform UIView scale/center/corner/clips
 └─ schedule 0.30s commitSceneGeometry after resize when ready
DFSceneSurface.commitSceneGeometry
 ├─ child2/child3/parent2 optional private selectors, Portrait=1
 ├─ hostedScene.updateSettingsWithBlock: -> setFrame: ONLY
 ├─ synchronous setNeedsLayout / layoutIfNeeded on two views (since .38)
 └─ committed size; .40 protects reentrant layout/commit with BOOL flags
stop -> controller requestedMode:0/invalidate; NO private scene-settings restore
```

**Do not falsely blame a newly added .40 selector:** `updateSettingsWithBlock:` and scene `setFrame:` **already existed in .37**, baseline `DFSceneHost.m` blob `d394e19a58023727a7a59d42076606c28dce0fbd` at integrated signed source commit `a8cdec6252b0e772faa726e92b84ee66246590ed`. Original frame-only block does not match original multi-field block plus KVC/ivar; `sceneSettingsBefore` snapshot saved at readiness is NEVER restored at stop. Changing foreground/under-lock settings by copying vendor code would be unsafe; map independent ownership and rollback first.

### Exact 0.0.37 → 0.0.38 `DFSceneHost.m` source diff

Git SHA-bound source .37 `a8cdec6...` (495 lines) vs .38 `ee6df7f...` (529 lines), computed LCS line diff **+37/-3**:
1. `DFNative12MediaGeometry.h` now calculates rounded logical and uniform scale rather than `CGSizeMake(round(size.width*2),...)` and distinct x/y scale, plus corner/continuous curve/clips; used in view and private reference commit. Supported by original math, but exact media orientation on device untested.
2. New **synchronous layout flushing inside `commitSceneGeometry:`** after private `updateSettingsWithBlock:`: `setNeedsLayout` + `layoutIfNeeded` for both app controller view and inner view. This is the **narrowest new possible reentry/scene-settings ordering regression to isolate**.
3. New `DFSceneHostDidObserveTouchNotification` dispatched async on touch from `hitTest`; observers can recalculate all UIWindow frames while a video is playing. Must correlate actual notifications and scene commits to crash stack; not proven cause.
4. Other .37→.38 code notably changes `DFNative12Chrome.m` **+247/-85**, window/UI controls and video behavior can be affected even with `DFSceneHost` unchanged.

.38→.39 source compare 15 commits and **no `DFSceneHost.m` modifications**. .40 source adds `layingOutScene`/`committingSceneGeometry` reentry guards, pre-stage logs, keeps block/setFrame and direct UIWindow architecture. Thus .40 hardening is not proven cure.

## Three uploaded .ips compared to LIVE Pages release chronology

Raw iPhone `.ips` are conversation attachments; **do not upload raw user device IDs**. Local programmatic JSON inspection shows all three iOS 16.7.16 SpringBoard SIGABRT with **identical** `lastExceptionBacktrace`: Foundation `_userInfoForFileAndLine` -> `-[SBAppViewController sceneHandle:didUpdateSettingsWithDiff:previousSettings:]` +440 -> `SBSceneHandle` -> `FBSceneMonitor` -> FrontBoard. Exception reason/failed invariant absent. Loaded first-party libraries and GhostBoard/SnowBoard etc have **no direct frames** in that stack; cannot assign blame from usedImages.

| Public GitHub Pages build status SUCCESS | Verified release completion ICT | Device crash ICT |
|---|---|---|
| .37 `39749437836` | 2026-10-22 15:43 | User's earlier YouTube rotated photos (different occasion) |
| .38 `39871787459` | 2026-10-23 06:29 | 06:57:38 (`Crash-2`, consecutive 5) |
| .39 `39876280425` | 2026-10-23 07:11 | 07:22:50 (`Crash-1`, consecutive 6) |
| .40 `39888031790` | 2026-10-23 09:12 | 09:16:23 (`Crash-0`, consecutive 7) |

**Exact installed DEB at each crash UNKNOWN.** Sileo publish time is not automatic phone install time; correlation is useful for prioritization but not proof .38 caused first crash. Consecutive count 5/6/7 means earlier failures also occurred.

## Confirmed explanation and next isolated test

**Confirmed divergence:** Native12's real bridged app has one coordinated `CBBridgedUIAppView` lifecycle for UIKit, FBSScene settings/flags, background mode and render-size negotiation; current independently owned SpringBoard UIWindows and host directly apply only parts, with different commit timing and no exact scene-state rollback. Wrong YouTube orientation and SpringBoard scene-settings exception **fit** incomplete media/scene integration, but `.ips` lacks failing assertion and thus does not establish exact culprit.

**Next testable plan without changing menu, Style, Zoom, split ratio or license:**
1. Capture `dpkg-query -W com.duoface.jb.embedded` with installed version plus `/var/mobile/Library/Logs/DuoFaceSceneHost.log` and `DuoFaceTouchOwner.log` around next reproduction. Compare markers `geometry-before-reference-setters`, `geometry-before-scene-frame`, `geometry-before-layout-flush`. Avoid running experiments while driving.
2. Preserve immutable signed .37 (SHA256 `2b6f274e684e5a6f1008dac960c87ff51744fddb5342ce42fcd74e5c61314beb`); create source **candidate A** with just the extra synchronous post-IPC `layoutIfNeeded` disabled behind an OFF-by-default gate and test with unchanged .40 GUI + uniform geometry, isolate variable.
3. If A still crashes, create separate **candidate B** with only the independent frame-only `updateSettingsWithBlock:` default-OFF while preserving child reference sizing; do not blindly transplant original foreground/lock/occlusion mutations. Compare crash/no-crash and video orientation as distinct results.
4. Test launch/video/seek, divider resize, focus/restore, Home/reconnect, CarPlay Dock, pills auto-hide and iPhone SpringBoard crash; only declare success with actual phone logs/photo. Source CI/build alone not sufficient.

Audit tools: connected GitHub fetch_file + JSON parsed prior ARM64 disassembly, fetched source at specific immutable commits, LCS source diff, local parse three uploaded IPS JSON, live GitHub Actions statuses. No new original binary extraction/build/device test in this turn.
