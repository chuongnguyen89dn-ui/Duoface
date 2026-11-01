# Original DuoNavi 1.0.4 — stage 2: verify actual bridge owner, two-phase state, and what remains unknown

## Inputs (no version substitution)
- Genuine original DEB pinned SHA256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`; verified `DuoNaviDashboard.dylib` SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`.
- Previously verified original ARM64 method-local metadata and bounded selector xrefs, read again here: `sideplay/audit/qa146-native-home-dock-parity-20261031/runs/41189165129/DUONAVI_DUODASH_REPACK_NATIVE_APPBRIDGE_METHOD_CROSSWALK.json` blob `137bc9f1b4abaee1d1e48e3bb446a632afb4057d`. Earlier verified branch/instruction audit: `sideplay/audit/original-manager-window-route-20261031/{MANAGER_WINDOW_FINDINGS.md,MANAGER_WINDOW_CHECKPOINTS.json}` and `sideplay/audit/original-execution-route-20261031/ROUTE_FINDINGS.md`.
- Actual device Observer3 `sideplay/log/DuoNaviObserver-16990B2B-71E6-4CC1-9AAB-8CBECBD97599.txt` from main commit `4955c852628ce115b095160e480f5f8a879b14cf`, Git blob `ae3f8ec858acd225b1df7ea5a991ed3e24d7bd0a`. The file was completely fetched/parsed in preceding independent read-only analysis. Rotated per-process export segments require UTC ordering.
- Independently written current DuoFace source branch `feature/duoface-qa146-native-home-exit-20261031`: `sideplay/duoface-native-scene-host/{DFHomeStandalone144.m,DFCarPlayOwnerObserver.h,DFNativeDockSync147.h,DFSoloPill157.h}`, fetched and examined again at branch head `9f8cea233bfd135ce3833f7df9fe240e10f0842d`.

## 1. One genuine original bridge-owner transaction: entry, phone-side acceptance, CarPlay state

The original actual two-process device trace confirms **the SAME CarPlay manager receiver** `CBBridgeManagerDashboard:0x282b8f100` for all 3 unsupported-app launches and **the SAME SpringBoard manager receiver** `CBBridgeManager:0x2834d1c80`.

| App | CarPlay start / request | SB request / notify | First CarPlay state / activate | Second CarPlay state / activate |
| --- | --- | --- | --- | --- |
| Facebook | L4297/L4299 | L3616/L3617 | L4303/L4304 | L4313/L4314 |
| YouTube | L4398/L4400 | L3631/L3632 | L4404/L4405 | L4414/L4415 |
| Gemini | L3873/L3875 | L3662/L3663 | L3879/L3880 | L3889/L3890 |

Both CarPlay `handleStateDict:` events have `activated=true` for each app; second response `isSplit=false` for every app. These are actual **two callbacks**, not proof of two distinct user actions and NOT proof that two successful frames were drawn or that any particular native picker/three-dot view appeared. No causal explanation for why two notifications arrive has been proven. SB `CBBridgeManager.notifyStateUpdated` occurs before first CarPlay response. Original SpringBoard manager `receiverActivated=true` occurs before CarPlay manager `bridgeDidActivate:`.

**Critical owner distinction:** Original static `CBBridgeManager -requestStateChange:` @`0x15b578` has bounded proven branches for active/inactive/changed/missing/stale hosted app and calls `loadNewAppFromCurrentRequest:`; callback suffix @`0x192820…0x192e44` owns frame, CBWindow create/resize, app host start, show, then `notifyStateUpdated`. This is a manager-owned state machine, not just a Dock modification. On observed Home, CarPlay manager local `stopBridging → requestDismiss → bridgeDidDeactivate` runs before Home returns, while remote SB teardown/state reply continues afterwards (see earlier `DEEP_ORIGINAL_LIVE_ORDER_REAUDIT_20261101.md`).

## 2. Whether the original 3-dot menu means a concrete split/solo host is **NOT proven**

Genuine metadata says:
- `CBBridgeManager -appForBundleIdentifier:frame:` @`0x1bf25c` is a real factory with bounded `initWithBundleIdentifier:frame:` reference, but selected concrete subclass/branch for those 3 apps was **NOT recorded at runtime** by Observer3. The runtime `currentApp` and associated `CBWindow` were not sampled.
- `CBBridgeManager -showAppPickerForSlot:` @`0x2a2630` has direct same-method references `currentApp`, `class`, `isKindOfClass:`, `focusedSlotIndex`, `restoreSplitAnimated:`, `window` and `showAppPickerForSlot:`. This supports presence of a manager-to-current-app picker interaction in the original binary, but NOT proof this selector was called for the observed user's three-dot tap.
- `CBBridgedSplitApp -initWithBundleIdentifier:frame:showSplash:` @`0x109bc8` and `-layoutSplitViews` @`0x10bad8` are real vendor layout/controls; they can represent a bridge container with a pill. However `isSplit=false` in all 3 **runtime** CarPlay activation packets does NOT tell us whether `currentApp` is `CBBridgedSplitApp`, `CBBridgedUIApp`, or a different subclass. The user's visual three-dot observation alone cannot make that inference.
- The project observer currently captures `DNFlowVisibleTree()` for CarPlay external UIWindowScene controllers and `showingApp`, workspace, Dock, Home states. It does **not** dereference `CBBridgeManager.currentApp` or `CBWindow`, so it cannot determine actual bridge host class/window/pill.
- Existing `sideplay/duonavi-observer/ExportApp.m:45-48` implements on-device explicit `RESULT_APP_CHOOSER` and `RESULT_CARPLAY_HOME` outcome markers, yet the exported original trace contained **zero such markers**. Do not pretend the controller tree is a pixel-classified result.

## 3. Actual QA157 owner boundary is not yet original-equivalent

- `DFHomeStandalone144.m:182-242` issues an independent `RequestID`+bundle+display scoped request and sends notification to SB after native preparation. This has real safeguards; notification transport itself is **also used by the original** and is not proven faulty merely by its existence.
- `DFHomeStandalone144.m:246-257`: on native Home, `DF157NativeHomeCallbackObserved` stores a chooser session and conditionally calls `DF147Reset` locally; `DFNativeDockSync147.h:50-73` restores owned native Dock **and Home displayState conditionally** if owner still matches and then clears the first-party lease. **Corrects overly broad descriptions that it only restores Dock**: Home displayState can also be restored. But no matching local `CBBridgeManagerDashboard`-style app-host dismiss is part of that function.
- `DFCarPlayOwnerObserver.h:128-165`: native Home callback notifies SpringBoard of standalone stop; then calls Apple's original `homeButtonUp:`. `DFHomeStandalone144.m:817-822`: independent SpringBoard recipient later runs `df157ReturnHomeToPicker` or `stop`. Thus in **source** its hosted scene/picker is not released/restored in the same original CarPlay-owned callback transaction; asynchronous remote cleanup by itself is not an anomaly since the original also uses asynchronous SB cleanup.
- `DFSoloPill157.h:35-70` has a new picker view and manual selected-app notification in **the first-party SB SOLO window**, but it does not show an original-style CarPlay bridge-manager current-app/window readback. Visible three dots therefore do not establish original execution-route parity.
- It is explicitly **unproven** whether this architecture difference alone explains the user's wrong destination in QA156. QA157 has no actual on-phone log, so must not call QA157 fixed/failed.

## 4. Evidence gate before any lifecycle rewrite or new Sileo DEB

The missing discriminant is a **read-only capture** of the original live `CBBridgeManager.currentApp` class/identity, manager `window` class/identity and visible owner at the original start/stop; native `CBBridgeManagerDashboard` state with a cross-process time-correlated bundle; explicit user marker identifying actual Home destination. Inspect against the exact original ObjC getter ABI (the static metadata confirms `-currentApp` @`0x1bf390` encoding `@16@0:8` and original CBBridgeManager ivar metadata `_currentApp` offset 72 / `_window` offset 64); **do not** dereference guessed private offsets or hook vendor license code. Preserve native Music/Calendar and no overlapping DuoFace original-bridge hook.

Current event: only research/readback of real existing log, static DEB metadata, original observer source and QA157 source. **No new device capture, source runtime change, CI build, Sileo publication, or hardware pass** was performed during this stage-2 note. This is a boundary analysis, not a proven fix.
