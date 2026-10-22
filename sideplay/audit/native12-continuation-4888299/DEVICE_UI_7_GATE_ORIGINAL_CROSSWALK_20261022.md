# 7 Native12 original UI gates — CarPlay device rejection 2026-10-22

Original SHA256: 2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad; Dashboard: 9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea; commit 1286a3ef868cf7e29804bcddf7e20b2eae707ce1. Only Native12; no DuoNavi/license.

User attached 4 real CarPlay photographs showing current public integrated 0.0.37 unacceptable. Source changes are NOT hardware PASS.

## Gate 1 — YouTube rotated 90 degrees: FAIL device
Original CBBridgedUIAppView.calculateNativeSizeForSlotRect: @0xacc28 returns rounded 2x slot sizes. updateLayout @0xacc6c uses identity transform, real contentReferenceSize Portrait=1, home grabber mode=1, uniform scale and center. updateSceneSettingsFrame @0xad5bc uses Portrait=1 on child 2- and 3-argument setters and main setter. refreshSceneLayout @0xade58 orders layout, settings, setNeedsLayout and layoutIfNeeded. New DFSceneHost source commit bb5f2e43 wired real setNeedsLayout/layoutIfNeeded after readiness and original portrait setters. NOT proven fixes YouTube; no invented Landscape override or fake remote touch.

## Gate 2 — original PNG for pill/Zoom: PARTIAL
Original assets verified visually via actual immutable bytes: duoface-fullscreen.png 88x88 red-black four corners; duoface-swap.png 120x120 round face logo; duoface-picker.png 256x70 is face+line composite, not ellipsis. Original 43-file payload has NO separate verified three-dot PNG. DFNative12Chrome commit 94ec356 uses real fullscreen/swap PNG, UIKit ellipsis where original separate glyph bytes absent. Device pixels not yet PASS.

## Gate 3 — auto-hide menu and round logo: STATIC WIRED
DFNative12Chrome controlsUntil 3 seconds, actual hosted UIKit hitTest DFSceneHostDidObserveTouchNotification wakes controls, fully populated scenes can hide menu, empty slot keeps picker. Source commits 94ec356, 1b4d2f0, 7f06428. Device test absent.

## Gate 4 — 3-second hold relocate round logo: STATIC WIRED
Existing DFNative12Chrome.logoHold: uses UILongPressGestureRecognizer.minimumPressDuration=3.0 then updates persisted logoFraction along divider (not ratio). Original CBDividerView.handleMoveButtonLongPress: and CBDividerButtonInfo.relativePos evidence. Device test absent.

## Gate 5 — App/Zoom/Style/Close clipped: STATIC WIRED
Removed tiny UIButtonConfiguration imagePlacement=Top, restored one-row UIButton title labels, removed invented duplicate context row. X closeMenu: is distinct from Close case3 closeHostedSlot:. Compile signed .48 only, no device screenshot PASS.

## Gate 6 — original ratios and Style preview: FAIL visual
Original setupPresetCards... @0xa5e78, presetSelected @0xaa4f0, 9 presets; 5/6 columns threshold 560, inset14/gap10, preview54, card66. DFLayoutEngine original ratios 1/3 for three columns and 1/2 others; snap 1/3,1/2,2/3. User photo still shows blank white layouts. Original 43-file payload has no 9 thumbnail PNGs: generated in original setupPresetCards via UIImageView and UIImage. Need decode exact rendering before changing colors/shapes; cannot invent thumbnails.

## Gate 7 — Close has real running-app content: FAIL original
Original CBMultitaskingOverlayView.setupRecentAppsCards... @0xa678c gets CBBridgeManager.runningBridgedApplications; original closeSingleAppTapped @0xa9484 gets bundle ID via accessibilityIdentifier and calls terminateApplicationWithBundleID: @0xa9598; restartSingleAppTapped @0xa91ec calls restartApplicationWithBundleID: @0xa9300; closeAllBridgedAppsTapped @0xa9838 invokes terminateAllBridgedApplications @0xa9914. Original running cards have icon/name/pid plus OVERLAY_CLOSE_SINGLE, OVERLAY_RESTART_SINGLE, OVERLAY_CLOSE_ALL. Current independent Close case3 REALLY releases selected DFSceneHost, and X only dismisses menu, BUT it lacks original running list, close-all and restart. Do not say complete.

## App card paging / Recent: original evidence, source updated
Original setupAppPickerCards... @0xa3e5c reads CBDashboardSettings.gridCols (max 4) and gridRows (default 2), true paging UIPageControl @0xa427c and horizontal scroll. DFAppPickerVC source commit 51b59fc changed to 4 x 2 / 8 cards per page; currently Recent uses local selection history, not real runningBridgedApplications; this remains missing.

## Verified original-DEB audit and build
Original 14 App/Close IMP bodies extracted from actual SHA-pinned DEB in CI https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39754754498 SUCCESS, 6289 instructions; stored original-picker-close-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json.
Original 9 video/layout IMP bodies extracted in CI https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39755224411 SUCCESS, stored original-video-layout-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json (376 updateLayout instructions, 510 renderSizeForBundleID instructions, 1254 layoutSplitViews instructions).
Signed isolated .48 native host CI https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39753616565 SUCCESS; SHA256 363901e25d5bdf6255f474a00e042fa14518a320f03a35bfbbc087ad3df6d008. Original method parity still 0/25 feature gates. Source .49 App grid was staged but NOT COMPILED: workflow .github/workflows/duoface-native-template-smoke.yml currently manual workflow_dispatch ONLY and explicitly prevents automatic partial DEBs; DO NOT bypass this release guard. Public Sileo 0.0.37 unchanged.

## Exact next work
1. Extract original card frame/UIColor/action target details in original-picker-close-imp and implement ONLY those proven running-app Close/Restart/Close All controls over actual DFSceneHost; never a blank/placeholder screen.
2. Crosswalk original updateLayout 0xacc6c scale/child orientation sender; inspect actual device /var/mobile/Library/Logs/DuoFaceSceneHost.log and real YouTube scene orientation. Portrait=1 cannot be guessed away.
3. Decode original style UIImage preview generation; do not draw arbitrary style cards. Recheck X/menu and 3sec gesture on vehicle.
4. Keep existing public .37 and earlier rollback packages immutable. Sign/test .49 only through authorized manual workflow, integrate/release after verification; no device success claim.
