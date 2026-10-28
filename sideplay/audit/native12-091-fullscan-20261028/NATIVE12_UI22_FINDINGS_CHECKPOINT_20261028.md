# Native12 UI control-flow batch: 22 original methods — 28/10/2026

Evidence: GitHub Actions run 40700551205 SUCCESS, signed original Native12 SHA256 2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad, disassembly data stored under sideplay/audit/native12-091-fullscan-20261028/original-ui-controller-22-imp/; archival commit f34b1ee22a97cd8e34aa54de057a38f8bd334f1d.

The first run 40700217106 scanned successfully but copied the wrong output path during archive; the corrected run 40700551205 persisted the right two files: ORIGINAL_UI_CONTROLLER_IMP.json (339576 bytes) and REPORT.md (35140 bytes). No runtime code or DEB changes.

Findings verified from actual ARM64 IMP callsites:
- CarPlay CBSlotPillView.dotsTapped, expandTapped, restoreTapped dispatch distinct callbacks onPillTapped, onExpandTapped, onRestoreTapped. Restore may fall back to onPillTapped.
- CarPlay CBDividerView.handleMoveButtonLongPress references onRotate and onSwap, while touch-down/up separately call onActivity/onSwap. Do not claim the original long press is solely logo drag. User-specific 3-second hold-to-move remains a separate design target.
- CBBridgedSplitApp.rotateAllSlotsClockwise calls swapSlot:withSlot: three times, and moveSlot:direction: also calls swapSlot:withSlot:. DuoFace .91 only has well-defined two-pane swapped boolean; 3–4 pane movement parity not proven.
- focusSlot:animated: and restoreSplitAnimated: each call saveBridgeStateToDisk and layoutSplitViews. DuoFace .91 DFCSaveLayout does not save per-slot app IDs.
- CBMultitaskingOverlayView.showRecentAppsInParentView calls runningBridgedApplications. DuoFace .91 current recent manager lists only verified scene-host-owned ready bundles.
- iPhone CBAppPickerViewController.tableView:didSelectRowAtIndexPath: checks disabledBundleIDs, invokes onSelectApp and pops navigation; cell rendering marks IN_USE_ELSEWHERE.
- iPhone CBAppsManagerViewController renders per-app UISwitch and invokes appSwitchToggled / setApp:enabled:. SetupNavigationItems sets ellipsis.circle → showActionMenu. Original enable-all is an iPhone management action, not CarPlay multi-select.
- iPhone GeneralSettings row renderer includes hide labels, blank screen, language, reset, auto launch, dock monitor. CBSplitViewController sets selected apps, disabled IDs, onSelectApp callback and saves preset.

Confidence: verified selector references inside 22 actual original method instruction bodies. Not verified: complete indirect blocks/receiver binding, visual pixel equivalence, iOS/CarPlay on-device behavior and native Maps+YouTube simultaneous display.

Next: complete original callback receiver graph and per-screen source crosswalk, then safe isolated fixes while preserving .90 YouTube rotation and excluding third-party licensing.
