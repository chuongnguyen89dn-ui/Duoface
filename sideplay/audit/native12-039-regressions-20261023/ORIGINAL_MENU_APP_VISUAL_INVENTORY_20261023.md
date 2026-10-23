# Original Native12 HUD8 Menu/App Gallery: forensic inventory versus DuoFace 0.0.41

Date 2026-10-23 ICT. Analysis only; no source change, build, Sileo publication or device test.
Repo chuongnguyen89dn-ui/Duoface, branch feature/duoface-jb-embedded-appbridge-20261020.

## Binary provenance
Original DEB dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb; SHA256 2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad. Dashboard Mach-O SHA256 9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea. This turn read actual pre-extracted, SHA-identified original ARM64 evidence stored in sideplay/audit/native12-continuation-4888299/original-picker-close-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json (14 methods, 6289 instructions; blob 2a8b03008c8ebb2b40d42d43a68846d08bf5c9c1), 03_ORIGINAL_HEADER_TABS_AUDIT.md, CARD_HEADER_LITERALS.json, ORIGINAL_OUTER_LAYOUT_CONSTANTS.json and 05_ORIGINAL_APP_RECENT_CLOSE_CROSSWALK.md. This is NOT a fresh DEB extraction or on-device visual/pixel test.

## Do not conflate two different menus
- The user-approved OUTER four commands App, Zoom, Style, Close with logo and X in current DFNative12Chrome.m are DISTINCT from the original INNER CBMultitaskingOverlayView.setupCardContent @0xa2a58 THREE tabs Apps, Layout, Recent plus an xmark dismiss.
- Outer current row: 30pt height, button base widths [43,51,47,51] scaled to available width, logo <=120pt, dark UIKit blur, X. This is current independent implementation ONLY. Original four-command exact artwork/color/dimensions are NOT independently byte-verified as a matched original outer row. Do not assert parity.

## Native original sheet, INNER header: actual dimensions (pt)
- Original outer sheet CBMultitaskingOverlayView.layoutSubviews @0xa28e8: width=min(screenW-(screenW<500?10:24),680), height=min(screenH-(screenH<300?8:18),380); center each using rounded half difference. Dynamic, not fixed 480x330. Source: original address 0x311740=500, 0x311748=300, 0x311758=680, 0x311760=380.
- Inner header height: 32 when cardH<260, otherwise 38. Separator white alpha 0.12 at y=32/38, height 0.5. Content begins y=32.5/38.5.
- Three-tab zone: 190 wide for cardW<440, otherwise 210. Zone frame x=cardW-36-zone, y=4/5, h=24/28. Each internal tab width floor((zone-4)/3) with residual width on third; font is adaptive 10/11pt.
- Header mode icon x=14, 18x18, vertical center; icon names square.grid.2x2.fill / rectangle.split.2x1.fill / app.badge.fill. Header title x=36, y=(headerH-20)/2, h=20, width=max(cardW-zone-74,80); exact UIFontWeight after dyld binding remains unresolved.
- Close X is a dedicated xmark UIButtonTypeCustom with short frame (cardW-32,4,24,24), tall (cardW-34,6,26,26). X dismisses overlay, not an app. Current independently coded frame calculations in DFNative12CardHeaderGeometry.h match these static numbers.

## Verified original palette
- Selected INNER tab background RGBA(0.08,0.52,1,1) approx #1485FF; selected lettering white. Original 0xa362c,0xa386c,0xa3b58, exact doubles 0x311720 and 0x311728.
- Inactive INNER tab background clear, lettering UIColor(colorWithWhite:0.68 alpha:1) approx #ADADAD. Font 10/11pt adaptive; exact UIFontWeight is not proven. In current DFAppPickerVC.m updateNativeModeButtons, both active and inactive titles are white: confirmed mismatch.
- Separator white alpha .12. X background RGBA(.18,.18,.22,.90) with corner radius half 24/26, historical SHA-locked audit. Apps page indicator dots inactive white alpha .25, active white. Close-All button red RGBA(.88,.18,.22,.95) confirmed original audited literal.
- Current DFAppPickerVC.m has modal sheet background white=.10 alpha1, corner radius20 and border white alpha.25; these are SOURCE-CURRENT only, not proven exact original sheet palette.

## Native original Apps menu
- Original setupAppPickerCardsInCardW:cardH:contentY: @0xa3e5c: CBDashboardSettings.gridCols @a40b4 capped 4 and gridRows @a40d4 normally 2: standard four columns by two rows, max eight visible icons/cards per page; options/adaptive layout may alter geometry. Actual card width and height come from available content bounds and computed spacing, NOT a single fixed item size. Conditional instructions at a43dc-a449c and branch for gridCols==6 at a44a0 mean detailed sizing still needs full branch decode.
- CBOverlayScrollView horizontal paging setPagingEnabled @a41cc, UIPageControl with inactive-white/.25 active-white and pageControlChanged: @a5de4. No horizontal bar.
- App cards from real loadInstalledApps results; per-app bundleIdentifier @a4d24, native icon @a4f28, displayName @a5110; optional hideIconLabels via DashboardSettings @a40f4. The app icon is image-backed and name is displayed unless settings suppress labels. Native UIFontWeightMedium evidence @a4bbc. Selected/current app slot badges checkmark.circle.fill @a52e0 and arrow.left.arrow.right.circle.fill @a542c.
- Empty state icon square.stack.3d.up.slash @a45ac with localized NO_APPS_TITLE and NO_APPS_DESC; original plus button @a5a0c, OVERLAY_ADD_APP @a5b3c. Original appSelected: @a9ea8 reads actual bundle ID, writes chosen split slot, may swap/replace through bridge then dismisses picker.
- Original exact per-state App card background/border RGB, selected alpha, thumbnail/icon absolute pt frame not fully reconstructed from conditional ARM64 instructions or pixel screenshots. Important: do not present independently coded card gray color as original binary-verified.

## Original Recent/Running menu
- Original setupRecentAppsCardsInCardW:cardH:contentY: @a678c gets CBBridgeManager.runningBridgedApplications @a6818. Records include bundleIdentifier, displayName, icon, inActiveSlot, slotIndex, pid; real Active Count, Close All, Restart and per-app Close actions and foreground/background badges. Empty state checkmark.shield.fill @a7b64.
- Original closeSingleAppTapped: @a9484; restartSingleAppTapped: @a91ec; closeAllBridgedAppsTapped: @a9838 forward original process lifecycle requests. Independent recent lists only owned DFSceneHost live scenes; Close/restart operate owned scene, not identical to process-wide bridge termination; PID and background state not equivalent.

## New implementation code inventory and gaps
- DFNative12Chrome.m currently presents OUTER App/Zoom/Style/Close in 30pt scaled row and separately presents appPickerWindow with native outer geometry. Outer brand PNG/current Material Dark menu are first-party source choices; original pixel parity unverified.
- DFAppPickerVC.m creates DFNativeAppCard with background colorWithWhite(.19 alpha .96), cornerRadius14, white system-font 11pt Medium title, app icon aspectFit min 24/max 43 points (derived from card H), cell size collectionW/4 by collectionH/2 for Apps. These exact values are SOURCE-CURRENT, not original verified App-cell measurements. Original needs further traced conditional call graph.
- Current app picker has 3 inner tabs and exact responsive header geometry but labels are hardcoded English Apps/Layout/Recent whereas original localized native strings have Vietnamese Ứng dụng/Bố cục/Đang mở (see docs/duoface-v12-picker-style-20261014.md). Current inactive title white rather than original gray .68.
- Current collection uses 4x2 icons, actual DFAppLibrary inventory, per-app icon and real selection, with generic SF app fallback if private icon lookup fails. Original actual icon renderer could be different; device match unverified.
- Current running mode reuses app card view with current .19/14 visual, and lists only owned live scenes instead of all original bridge running processes. Running app Close/Restart labels/actions exist but lifecycle not equivalent. Exact Running cell dimension/color parity not established.
- Style gallery is SEPARATE from Apps: original 9 styles with 5/6 column threshold560; card height66, preview54, radius12, selected dark-blue (.04,.20,.45,.95), unselected (.14,.15,.19,.95). Do not transfer Style palette to App cards.

## Priority discrepancies
1. INNER menu text mismatch: current inactive title white but original #ADADAD, and English labels instead of locale-driven original Vietnamese.
2. OUTER four-action menu exact original pixel parity not verified: current Material Dark 30pt row and PNG sizing authored independently.
3. ORIGINAL per-App cell conditional fill/color/geometry and selected-badge map still needs exact full ARM64 control flow or direct original screenshot; current 14pt cell radius/gray .19 cannot be labeled original matched.
4. User app roster original adaptive gridCols/gridRows and hideIconLabels settings vs hardcoded 4x2 and always-visible labels.
5. Original Add app button and live process-level running/Close/Restart/PID states not reproduced exactly.
NO SOURCE MODIFICATION/BUILD/SILEO/DEVICE TEST during this inventory. NEXT: trace original App cell loops conditional branches and exact CGRect/UIColor return, then implement only proven discrepancies, retaining one integrated DEB and rollback packages.