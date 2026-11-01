# QA159 physical device report — Dashboard is NOT the CarPlay app grid (2026-11-01)

## Latest device feedback (USER-REPORTED, not uploaded QA159 log)
After installing QA159 from the existing Sileo feed, the user reports:
- DuoFace's own custom picker no longer appears when tapping Home from a third-party standalone CarPlay Home app.
- Home instead lands on the native **CarPlay Dashboard (map + Now Playing)**.
- Required destination is **the native Apple CarPlay Home app-icon GRID** from which the next app can be selected. Do not replace it with a DuoFace picker or DuoNavi split/pill.

This is a **new QA159 physical FAIL for the destination** and updates the earlier checkpoint's device-pending status. It confirms only the visible page described by the user, not code-level cause or timing. Version on-device is based on the user's current QA159 follow-up, not a new device package-version receipt.

## Distinct native surfaces — external official documentation
Apple distinguishes *CarPlay Dashboard* (maps / audio / Siri suggestions) from *CarPlay Home* (pages of app icons), with separate on-screen buttons; source: https://support.apple.com/en-ie/guide/iphone/iph5f6b2beb5/27/ios/27.
An earlier CarPlay behavior description additionally says return may depend on which native page a full-screen app was opened from; source: https://www.macstories.net/stories/carplay-in-ios-13-a-big-leap-forward/ . This is reference context, **not evidence** of which branch executed on this iOS16 QA159 phone.

## Repository log availability (rechecked in this turn)
- Latest available DuoFace export on main remains `sideplay/log/DuoFaceAudit.txt` blob `6a9565a3980e931dea6695f94c512d90227747c2`, uploaded by `ee0ac797ae32ca561a397fdd7d7a86dca2506ff1` at **2026-11-01 07:09:08 UTC**, BEFORE QA159.
- Latest original DuoNavi Observer3 remains `sideplay/log/DuoNaviObserver-16990B2B-71E6-4CC1-9AAB-8CBECBD97599.txt` blob `ae3f8ec858acd225b1df7ea5a991ed3e24d7bd0a`, uploaded `4955c852628ce115b095160e480f5f8a879b14cf`.
- Large original export bodies were blank via the present GitHub file connector; no claim they were freshly fully reparsed. Read existing **actual log excerpts and previously parsed, SHA-pinned, versioned reports** instead:
  - `sideplay/audit/qa156-log26-home-rejected-20261101/LOG26_EXCERPTS.txt` (five correlated launches and Home stop).
  - `sideplay/audit/duonavi-homeflow-observer-20261101/DEEP_ORIGINAL_LIVE_ORDER_REAUDIT_20261101.md` and `REAL_DEVICE_LOG_16990_ANALYSIS_20261101.md` (9 native Home enter/return, original CarPlay local stop/dismiss, later SB state).
  - `sideplay/audit/duonavi-homeflow-observer-20261101/OBSERVER4_LIVE_APP_OWNER_PICKER_TRACE_20261101.md` (actual original app-factory classes and manager-owned UI; no visual result marker).
- **No new post-QA159 device export** exists in the inspected repo. Do not treat QA158 Log26 or QA158 Custom-Picker Log as QA159 proof.

## Original DuoNavi: evidence, not invented UI result
- Original observer: (3) unsupported-app manager starts (Facebook, YouTube, Gemini); native Home calls stop bridge + request dismiss locally *before* original Home returns for the bridged cases; local manager updates dock and home button while SpringBoard teardown/state remains async. It still forwards Apple's original Home callback.
- Observer4 shows manager-owned `CBBridgeManager.currentApp` as `CBBridgedUIApp` for Facebook/YouTube and `CBBridgedSplitApp` for BarcodeScanner, not an interchangeable solo overlay. It recorded picker on a SplitApp. Nothing here establishes native Home page GRID vs Dashboard visually.
- **Missing:** explicit `RESULT_APP_GRID` / `RESULT_DASHBOARD` visual marker for original. Do not infer a native navigation selector from the vendor pill or controller class names.

## QA159 source: pinpointed gap (source-verified, causation NOT proven)
Source SHA `2b6fef143c19dfd4d4b8557ca03b322aba711ae2`.
1. `sideplay/duoface-native-scene-host/DFHomeStandalone144.m`: `DF144Launch` intercepts selected `DBDashboardHomeViewController iconManager:launchIconForIconView:` taps and does **not** forward the native original when `DF144BeginSelectedBridge` succeeds. It creates a separate SpringBoard-hosted standalone scene. Whether that skips the native app-grid navigation history is **not measured**.
2. `DFNativeDockSync147.h`: `DF147ActivateDock` saves native Dock active bundle and `DBStatusBarHomeButton.displayState`, sets active bundle and button state0. `DF147RestoreDock` restores these values. There is **no independently established native Home app-grid page state/history snapshot** in these functions.
3. `DFCarPlayOwnerObserver.h`: `DFOwnerDBHome` sends scoped async standalone stop and forwards Apple's original `homeButtonUp:`. `DF157NativeHomeCallbackObserved` clears first-party Dock state before that forwarding. QA159 also removes custom picker and makes `[DF144Owner stop:@"native-Home-exit"]` unconditional on the SpringBoard receiver. Neither function explicitly restores Apple's app-icon grid.
4. Older Log26 did confirm native Dashboard workspace owner and `showingApp=NO` at **launch**, and a successful stop/Dock restore after Home, but **does not record** grid-versus-Dashboard destination / true Home page ownership at QA159 runtime. The source gap is a candidate mechanism, not a proven singular root cause.

## Next bounded engineering step (do not publish a guessed fix)
- Compare exact native **app-icon grid** state/owner when tapping an unsupported icon versus a native Music/Calendar icon, at four timestamps: icon tap, independent hosted-ready, native Home `homeButtonUp:` entry and return (plus delayed readback). Record the native window/controller class, actual foreground workspace, Home button displayState, page/folder visibility if safely accessible, the corresponding app bundle/request ID, and on-device **GRID or DASHBOARD user result**.
- Compare equivalent native state from original DuoNavi only with **actual** typed observer calls; original Home manager stop-before-return is real, but does not alone establish native page target. No vendor license implementation or binary copying.
- If and only if native app-grid context is absent/overwritten on the supported first-party path, make the smallest **independent** page/state integration fix that maintains Apple's native Home/navigation, not a synthetic DuoFace picker, guessed private selector, fabricated `showingApp`, delayed second Home tap, or unconditional app activation.
- Keep native Music/Calendar, original Home callback, Dock, YouTube/GOFA/split, and current Sileo repo unchanged until the required evidence exists. For behavioral fixes use the existing `Duoface` source CI and `carplaydsp` publisher and verify build/sign/Pages separately from physical device.

## Execution status
This turn: checked latest log commits, read existing original- and current-device excerpt reports, compared QA159 source functions, checked Apple's official Home/Dashboard distinction. No current QA159 raw device log, no code edit, no compile/DEB, no new Sileo publication, no claim of a root cause. Evidence and handoff saved in the actual project repo.
