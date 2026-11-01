# DuoNavi 1.0.4 original: verified app-factory class branches, ordinary single-app pill, manager-owned app picker (2026-11-01)

## Scope and version pins (all facts below verified directly in repo and Actions)

- Genuine original `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb` SHA256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`; exact original `DuoNaviDashboard.dylib` SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`. No original vendor code or licensing implementation copied/executed.
- Read-only exact method probe script `sideplay/audit/qa146-native-home-dock-parity-20261031/verify_original_bridge_factory_20261101.py` commit `96cd6fa12e3d1d47d92d64514f9fb6a93dba1ec0`, CI workflow commit `0c04cafabf22c4b626d08a487f590371dc3b3f6d`. First audit run [41278563346](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41278563346) **SUCCESS**; exactly SHA-pinned 72 ARM64 factory instructions decoded in bounded `CBBridgeManager -appForBundleIdentifier:frame:` `[0x1bf25c,0x1bf37c)`. Its evidence saved at `sideplay/audit/qa146-native-home-dock-parity-20261031/runs/41278563346/ORIGINAL_DUONAVI_FACTORY_BRIDGE_CLASSREFS_20261101.json`.
- Expanded existing read-only metadata scan to include `CBBridgedApp`, `CBBridgedPortalApp`, `CBBridgedPortalAppView`, `CBBridgedSplitApp`, `CBBridgedUIApp`, `CBBridgedUIAppView`, and `CBWindow`; scanner commit `cc467a7103b42a73055b0bf7939f2a79c6a2a664`. Second audit run [41278627569](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41278627569) **SUCCESS**, package SHA verified, old DuoDash REPACK provenance preserved, **153** relevant DuoNavi methods (previous scan had only 113 because the class whitelist was narrower). Immutable new evidence `sideplay/audit/qa146-native-home-dock-parity-20261031/runs/41278627569/{ORIGINAL_DUONAVI_FACTORY_BRIDGE_CLASSREFS_20261101.json,DUONAVI_DUODASH_REPACK_NATIVE_APPBRIDGE_METHOD_CROSSWALK.json,CI_RESULT.txt}`. Runner auto-archive commit `12a74d493983e32830617c8cd3709efdb4fda70f`. All files and receipts read back on GitHub; CI forensic not iPhone testing and not Sileo publishing.

## NEW VERIFIED: same factory method references **three different original classes**

In the genuine original `CBBridgeManager.appForBundleIdentifier:frame:` @`0x1bf25c`, direct SHA-verified ARM64 pointer-table targets and branch sites:

| Function instruction site | Resolved object | Evidence type |
| --- | --- | --- |
| `0x1bf2a8` | `isEqualToString:` | selector reference |
| `0x1bf2c0` | `CBBridgedPortalApp`, class pointer `0x3ab930` | Objective-C `__objc_classrefs` |
| `0x1bf2f4` | `CBBridgedSplitApp`, class pointer `0x3abb60` | Objective-C `__objc_classrefs` |
| `0x1bf300` | `CBBridgedUIApp`, class pointer `0x3ab9d0` | Objective-C `__objc_classrefs` |
| `0x1bf30c` | `initWithBundleIdentifier:frame:` | selector reference |

The bounded 72-instruction method has **9 actual conditional/unconditional branch sites** (e.g., `b.ne 0x1bf298`, `cbz 0x1bf2b8`, `b.ne 0x1bf2d4`). **Proven:** original has *multiple candidate hosted-app class paths in one manager app factory*, not one unconditional type. **Not proven:** for any individual Facebook/YouTube/Gemini session, which of these branches is taken, the exact comparison strings, or what constructor actually runs. Static classrefs cannot answer that. No fabricated app-to-class mapping.

## NEW VERIFIED: the original normal UI app class **also defines a pill interaction**

Prior focus on `CBBridgedSplitApp` alone was incomplete. The expanded exact original method scan proves:

| Class / original IMP | Bounded method-local relevant selectors | Scope |
| --- | --- | --- |
| `CBBridgedUIApp -initWithBundleIdentifier:frame:` @`0xbfcd4` | `setShowsExpandButton:`, `setOnPillTapped:`, `setOnPillLongPressed:`, `showRecentApps`, `initWithSlotIndex:`, `addSubview:`, `bringSubviewToFront:` | Ordinary hosted UI-app class includes actual pill/menu callback wiring; **a visible pill does not establish active SplitApp** |
| `CBBridgedSplitApp -initWithBundleIdentifier:frame:showSplash:` @`0x109bc8` | `splitPreset`, `splitMode`, `splitApp1..4`, `multitaskingPill`, `setOnPillTapped:`, `setOnPillLongPressed:`, `configureDividerButtons` | Split container also wires pill; static presence alone doesn't identify an actual runtime session |
| `CBBridgedPortalApp -initWithBundleIdentifier:frame:` @`0xbf8f4` | `initWithBundleIdentifier:frame:`, `initWithFrame:`, `setView:` | A distinct portal host constructor also exists; no pill call proven in this bounded 232-byte initializer |
| `CBBridgedUIAppView -startInParentViewController:` @`0xadd08` | `initWithIdentifier:andApplicationSceneEntity:`, `addChildViewController:`, `setContentReferenceSize:withInterfaceOrientation:`, `sceneHandle` | Original ordinary app has its own scene/parent lifecycle, not merely drawn app pixels |

The actual previously verified original device Observer3 log showed three bridged launches (Facebook, YouTube, Gemini), each followed by an activated state dictionary with **`isSplit=false`**. This confirms a manager state flag, *not* an active class identity. It is compatible with multiple original internal host implementations; thus neither the user's suggested single-pane nor SplitApp-as-SOLO may be asserted as the observed class without further runtime proof.

## NEW VERIFIED: original app picker is tied to the manager-owned window

The now-included **original CBWindow implementation** directly connects the manager and its own on-screen content:

1. `CBBridgeManager -showAppPickerForSlot:` @`0x2a2630` has `currentApp`, `focusedSlotIndex`, `restoreSplitAnimated:`, `window`, `showAppPickerForSlot:` as same-method references. It is manager-dispatched picker logic, not independent native Home deciding how to display a menu.
2. `CBWindow -showAppPickerForSlot:` @`0xb3148` directly references `contentView` and `multitaskingOverlay`, then `showAppPickerForSlot:parentView:`. `CBWindow -showLayoutChooser` @`0xb31f8` references those same objects and `showLayoutChooserInParentView:`. `CBWindow -showRecentApps` @`0xb32a0` references `contentView` and `showRecentAppsInParentView:`.
3. `CBWindow -createWindows` @`0xb173c`, `resizeWindows` @`0xb24ac`, `destroyWindows` @`0xb2d14` form the actual window lifecycle. The 2026-10-31 audited ARM64 `MANAGER_WINDOW_FINDINGS.md` separately checked `CBWindow` root/usable frame and pass-through touch policy.

This is **static call-site/selector metadata for original classes**, not visual proof of which picker was on screen after Home on the user's device.

## DuoFace QA157 audited difference, without claiming cause

- `sideplay/duoface-native-scene-host/DFHomeStandalone144.m:182-242` creates a first-party CarPlay broker/transaction; `:246-257` synchronously resets **only its Dock lifecycle** upon native Home; `:510-620` mounts the hosted `DFSceneHost` into its own SpringBoard `DF144Solo` external `UIRootSceneWindow`.
- `DFSoloPill157.h` uses first-party `UIButton` and `DFAppPickerVC` mounted under `DF144Solo.root`; `df157ReturnHomeToPicker` reacts to the async SpringBoard stop notification and changes its local hosted surface to picker.
- `DFSoloPickerCarPlay157.h:1-65` makes a separate validated picker-request IPC into `DF144BeginSelectedBridge`. The original has a manager app factory selecting among three candidate classrefs and its **CBWindow** owns the `multitaskingOverlay`/picker parent. This is a concrete architectural difference in *type selection and owner boundary*. **It is not a verified single cause** for wrong Home page or Dock; no QA157 device trace exists and original visible Home target remains undocumented in the export.

## Constrained next step: required evidence before new DuoFace behavior change

1. Extend the **existing** `sideplay/duonavi-observer/HomeFlowSnapshot.h` read-only snapshot on the `CBBridgeManager` receiver (already seen in real device log at `CBBridgeManager:0x2834d1c80`): capture actual `currentApp` object class and bundle via exact typed getter or read-only verified ObjC ivar; capture its `window` object/class, `appViews` count if SplitApp, and app-picker overlay/window visible state on Home callback. Never guess ivar layouts, execute original license logic, mutate vendor runtime state, or install two active bridge versions together.
2. Capture manual user result marker of **real screen after Home** (app chooser / Apple Home), which Observer3 log lacks; mere controller tree presence doesn't answer this.
3. Align per-selected bundle/run with `isSplit` and actual `currentApp` identity, start-to-stop manager lifecycle, and native Dock. Only then determine whether DuoFace needs an ordinary `CBBridgedUIApp`-equivalent host contract, split-container contract or another independently implemented route.
4. Source-only audit/CI is not device PASS. No production source changes, no new integrated DEB/Sileo and no physical QA during these two forensic CI runs.

## Reproduce / verify

```sh
# macOS/Linux GH Actions runner with capstone==5.0.7 and verified metadata parser
# Exact commands already executed successfully by runs 41278563346 and 41278627569
dpkg-deb -x dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb /tmp/duonavi-original
ORIG="$(find /tmp/duonavi-original -type f -name DuoNaviDashboard.dylib -print -quit)"
test -n "$ORIG"
PYTHONPATH=/tmp/parsers python3 sideplay/audit/qa146-native-home-dock-parity-20261031/verify_original_bridge_factory_20261101.py \
  --binary "$ORIG" \
  --out /tmp/ORIGINAL_DUONAVI_FACTORY_BRIDGE_CLASSREFS_20261101.json
```

Results are archived under run IDs above; exact runner paths and verification receipts are stored in `CI_RESULT.txt`. Reproduce only with the pinned parser and real original package; do not substitute DuoDash REPACK or Native12-derived binary.
