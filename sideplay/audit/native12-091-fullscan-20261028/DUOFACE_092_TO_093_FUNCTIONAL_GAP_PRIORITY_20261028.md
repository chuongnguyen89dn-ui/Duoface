# DuoFace .92 -> .93: Native12 original UI/function missing matrix, 2026-10-28

## Decision and correction of scope
User explicitly clarified that 3-second logo behavior is already finished and the current assignment is **full Native12 interface and functional comparison** (not another logo-only version), especially CarPlay single-app choice and iPhone-side Apps Manager/Settings. Earlier assistant in this chat delivered .92 logo-only despite the existing comprehensive audit. That was an incorrect scope/priority, not new original research. Focus now on verified gaps, one traceable integration at a time. Never import Native12 licensing or binary.

## Evidence actually re-read this turn
- Original rootless Native12+Speed8 reference SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`; independent .91 SHA256 `e15b9b2c2da351a64a125f5057c6c6e0f6d44aefbcc73de8fe023b6c4d5ab741`; archive run [40696267785](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40696267785): original 43 payloads/8 Mach-Os/66 classes/1385 ObjC methods vs .91 34 payloads/8 Mach-Os. Its 25 parity gates are 'not proven', **not 25 missing features**. .92 changes logo source; app/phone/Maps gaps from .91 still apply to .92.
- 12 original picker/manager methods [run 40699487806](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40699487806) report `original-app-picker-single-vs-bulk-imp/REPORT.md`: CarPlay CBMultitaskingOverlayView.appSelected: @0xa9ea8 saves ONE bundle for ONE slot; Add More @0xa7f20 is an iPhone-directed frosted alert, NOT multi-app picker. iPhone separate CBAppsManagerViewController.showActionMenu @0x100013604 uses Enable Recommended/All/Disable All, per-app switch setApp:enabled:.
- 22 iPhone/CarPlay original methods [run 40700551205](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40700551205) `NATIVE12_UI_22_CONTROLLER_ORIGINAL_VERDICT_20261028.md`: iPhone CBSplitViewController didSelectRow @0x1000178fc opens CBAppPickerViewController, setApps:, setDisabledBundleIDs:, setOnSelectApp: for **one app per slot**. iPhone general settings include Hide Labels, Screen Blank, Language, Reset Defaults, Auto Launch, Dock Monitor. CBBridgedSplitApp.moveSlot:/rotateAllSlotsClockwise implement multi-slot reorder.
- Current first-party source read: `sideplay/duoface-native-scene-host/DFNativeHostRootController.m`, `DFAppPickerVC.m`, `DFAppLibrary.m`, `DFNative12Chrome.m`, `DFSceneHost.m`, source tests and build workflow; stable .90 user-verified YouTube orientation and current .92 rootless Sileo release frozen.

## Real missing vs implemented vs unverified, not a percentage

| UI/feature | Original evidence | DuoFace .92 baseline | Current source .93 change/status |
|---|---|---|---|
| CarPlay App choose one bundle per target slot | appSelected: @a9ea8, saveSlotIndex:bid | Already single-choice DFAppPickerVC.didSelect -> DFSceneHost; not batch | **Preserved**; no 'Select All' in CarPlay |
| iPhone app allow/disable switches | CBAppsManagerViewController.appSwitchToggled: | Read-only full installed-app list, no permission config | **CODED** per-item UISwitch with first-party atomic prefs; physical UI pending |
| iPhone app bulk action menu | CBAppsManagerViewController.showActionMenu | Absent | **CODED** Enable All, Enable User Apps, Disable All. 'Enable User Apps' is an independent option, **not proven exact original recommended category** |
| CarPlay picker catalog respects enabled apps | CBMultitaskingOverlayView.loadInstalledApps reads bridgedApps | DFAppLibrary lists all eligible installed; not settings-filtered | **CODED** reads first-party `EnabledBundleIDs` per picker refresh; explicit []=none, no config=legacy all; physical scene not yet verified |
| iPhone Split Settings choose app per slot | CBSplitViewController -> CBAppPickerViewController, disabledBundleIDs | **MISSING**: currently 9 layout rows + native Maps QA only | **NOT IMPLEMENTED** in .93; next first-party UI owner and safe slot live-state design |
| Retain selected apps across reconnect | saveSlotIndex:bid:toSettings:prefs: | DFCSaveLayout saves ratio/preset/logo/swapped only | **MISSING**; do not pretend active scenes persisted |
| CarPlay 'Add More Apps' info modal | @a7f20 frosted alert directing to iPhone | **MISSING** in DFAppPickerVC | **NOT IMPLEMENTED** |
| App picker 4/5/6 columns, grid rows, hide labels | settings selectors, @a40c0... | 4x2/8 fixed, labels always | **MISSING** adaptive config |
| Running Apps with actual PID/background and restart | CBBridgeManager.runningBridgedApplications | DFSceneHost verified ready-slot-only, close/re-host | **PARTIAL**, not process PID/terminate parity |
| Phone general settings | CBGeneralSettingsViewController | only Status / Apps / Layout + QA Maps | **MISSING** Hide Labels, Blank Screen, Language, Auto Launch, Dock Monitor, Reset; exclude vendor Subscription |
| Multi-slot rotate/reorder 3-4 | moveSlot:/rotateAllSlotsClockwise | boolean swapped for 2 slots; 9 presets but no true 3–4 rotate | **MISSING** |
| UI outer/inner sizes, preview, splash, 4s idle, Zoom/Dock | many original controller calls | Source present, actual on-car pixel/gesture parity **unverified** | **No new claims** |
| YouTube split rotation | ABI reference and user acceptance .90 | **DEVICE CONFIRMED .90**, .92 carries same protected source | **No code change** |
| Logo hold 3s | custom user requirement, not original exact delay | .92 signed+public, no new .93 edit | **ALREADY DONE; DO NOT REVISIT** |
| Native Google Maps next to phone scene | OmniCar scene owner sizing vs SpringBoard actual windows | Native map coordinator attached inside CarPlay Dashboard root, not SpringBoard physical pane | **P0 NOT CONNECTED/DEVICE UNVERIFIED**; needs owner-scope proof, no zoom guesses |
| Native HUD8 and voice assistant | original HUD/assistant framework | speed8 source present but not in signed .92; voice missing | **UNBUILT / MISSING** |

## Verified engineering activity in this turn
- Feature source commit `30a953bd708ef042dda93b5fa59d4dc5fde3ab5d`: authored `sideplay/duoface-native-scene-host/DFEnabledAppsPolicy.h`, added phone per-app toggles and phone action menu in `DFNativeHostRootController.m`; filtered App catalog during `DFAppPickerVC.refreshInstalledApps` using same first-party persisted state. Does NOT touch Logo/YouTube/Dock/Maps source; no third-party binary/license.
- Test wiring commit `f7be368fd1b8bc30f8b989932c86c3c564c2659e`: regression `tests/test_native12_phone_apps_manager_093.py`, added macOS iOS16 clang source-only syntax for phone controller and unit regressions. Source CI run [40711301704](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40711301704) **SUCCESS**.
- Package request commit `c868a78534d562b94a26746d004e184b33391b75`: set NativeHost `0.1.102~appmanager1`, integrated `0.0.93~appmanager1` in one-DEB packaging workflow and tests; `REQUEST.md` push triggered [packaging CI 40711856334](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40711856334). Build outcome must be read from CI before claiming binary. .92 remains current public until a new exact .93 SHA is verified and Sileo published.

## Next confirmed action (do not switch back to logo)
1. Read CI 40711856334 job result/log. If FAILED, fix exact compiler/test/archival error, do not repeat blind.
2. On actual .93 archive success, confirm exact filename, source sha, dpkg Package/Version/Architecture, payload filter, SHA256SUMS, and protected .90 video source; then publish immutable .93 to existing Sileo via `chuongnguyen89dn-ui/carplaydsp` without overwriting prior DEBs.
3. Finish original iPhone `CBSplitViewController`-style per-slot app picker **with actual cross-process scene commit**; no decorative/inert picker. Add tests for slot persistence, disabled occupied bundles, concurrent render and rollback.
4. Implement original-informed Add More explanation, gridCols 4/5/6, hide labels and legitimate iPhone general settings on separate tests; sample original screenshot/current device before asserting pixel parity.
5. Prove native Maps same physical pane/process owner and HUD on real parked vehicle before claiming feature parity. Preserve user-verified .90 YouTube and native Apple Dock unchanged.
