# QA176 — STATUS

Branch: feature/duoface-qa176-recall-hud-kbdiag-20261103 (from QA175 tip a9145de9)
Integrated: com.duoface.jb.embedded 0.0.176~recallhud1; host 0.1.176~recallhud1
DEVICE_TESTED=false. SILEO_PUBLISHED=false (awaiting user approval).

## Build
- Private build run 41543719296: SUCCESS (SOURCE_SHA e80a4901).
- Archive commit 35ee950a7f199edd9a41efbb5bd692d096ceec62; DEB at
  sideplay/jb-embedded-appbridge/evidence/runs/41543719296/
- DEB: 1,264,944 bytes, SHA256
  c53598554aee0ce49284338e0a660ebb5db139e0ce0b685ba339be07f7414f23
  (computed by Muse from the downloaded bytes; matches SHA256SUMS.txt).
- Control verified from the DEB: Package/Version/Architecture/Depends/
  Conflicts/Replaces complete; postinst/postrm byte-identical to QA175.
- Built-binary string verification: build=0.0.176~recallhud1 labels,
  the Chrome lease path + kbdiag wake in DFTouchOwnerProbe,
  [DF176KBDiag] + UIKeyboardLayoutStar + the v176 mailbox in
  DF155GeneralAppStateRelay, and the overlay yield line in
  DFCarPlayDockOwner.

## H2 Step 0 census (read-only; source + QA175-built binaries)
THREE presenters, not four (work-order premise corrected by evidence):
1. Chrome gofaSpeedHUD — SpringBoard; own external-display UIWindow,
   level Normal+2.5; anchor content top-right (maxX-107, minY+3,
   104x46); restores the shared saved position. Published NO lease,
   never yielded.
2. DF144-SB speedHUD — SpringBoard; UIRootSceneWindow on the external
   screen (!= main), level Normal+2.5; anchor maxX-108, minY+3,
   104x46; same saved position => presenters 1+2 stack EXACTLY.
   Publishes the standalone lease (0.7s heartbeat) with HUDOwnerVisible
   only while truly visible. Never yielded to Chrome.
3. DFSpeedNativeOverlay163 — CarPlay process; HUD view inside the
   largest visible external window of the CarPlay app. Already yielded
   to (a) the QA162 session pulse and (b) a fresh DF144-SB lease with
   HUDOwnerVisible.
There is NO DF144Solo presenter in the CarPlay process:
DFHomeStandalone144.m keeps the whole owner inside
#if DF144_SPRINGBOARD (lines 339-970), and the QA175-built
DFCarPlayDockOwner.dylib contains DF144's CarPlay-region code plus
DFSpeedNativeOverlay163 but no DF144Solo class (strings check).
=> Implemented priority chain: Chrome > DF144-SB > Overlay163.

## H1 — controls recall (DFNative12Chrome.m only)
(a) start subscribes DFSceneHostDidObserveTouchNotification ->
    realAppTouched: (stop's removeObserver:self removes it
    symmetrically, like the other two).
(b) makeWindow: attaches the passive DFNativeActivityObserver to
    every Chrome window. The recognizer was verified passive in
    source (cancelsTouchesInView=NO, delaysTouchesBegan/Ended=NO,
    self-fails immediately, canPrevent/canBePrevented=NO), so the
    work order's condition for (b) is met.
(c) noteUserActivity: deadlines and the hide timer ALWAYS move;
    only the relayout is throttled (kDF176ActivityThrottleSeconds
    = 0.25). Show/hide still goes through the single layoutControls
    path (QA175 T3 wraps it for the divider).
(d) 4s/2s are now kDF176ControlsVisibleSeconds /
    kDF176ControlsBorderSeconds; every former +4.0 site uses them.
Known limit (per work order): letterbox touches still do not recall
the controls — QA177.

## H2 — HUD lease priority (no presenter removed)
- New shared header DFSpeedHUDLease176.h: lease record {Version,
  HUDOwner, HUDOwnerVisible, Timestamp} in a single-writer plist;
  freshness 2.0s doubles as the handover hysteresis. DF144-SB
  reuses its existing standalone lease record as its HUD lease.
- Chrome: 1s heartbeat (df176HUDLeaseTick) publishes its lease only
  while speedHUDWindow + gofaSpeedHUD are actually visible and the
  DF169 bubble is enabled; retracts on hide and in stop.
- DF144-SB: DF144ApplyHUDYield176 runs at the top of the existing
  0.7s lease heartbeat, BEFORE its own record is composed (so the
  record's HUDOwnerVisible already reflects the yielded state):
  fresh Chrome lease -> speedWindow.hidden=YES and one log line
  "qa176-hud-owner yield=DF144-SB winner=Chrome"; stale -> unhide
  and "qa176-hud-owner resume=DF144-SB". Hide, never destroy.
- Overlay163: poll additionally yields to a fresh Chrome HUD lease,
  logging "qa176-hud-owner yield=Overlay163 winner=Chrome" only
  when it had a HUD attached (once per transition).
- Speed limit ring and the no-GPS red X (QA170) untouched; bubble
  speed stays GPS; the GOFA decoder stays shadow.

## H3 — keyboard diagnostics, LOG ONLY
Flag: KeyboardDiag176 in com.duoface.nativehost.qa176.plist
(absent = ON for this diagnostic round). Shared header DFKBDiag176.h.
- App side (DF154GeneralAppStateRelay — injected into the DF155
  pilot apps, incl. Waze): on UIKeyboardWillShow/DidShow
  (rate-limited to one record per 2s) it records the keyboard
  window's class/frame/screen bounds, the keyplane name (recursive
  search for UIKeyboardLayoutStar), the input-mode identifier
  (private controller, @try-guarded) plus the public input-mode
  language, the hardware-keyboard state (GSEvent and BKSHID via
  dlsym), the notification end frame, and the app window frame.
  The record goes into a fixed DF156 mailbox
  (com.duoface.ipc.v176.kbdiag) and posts the Darwin wake
  com.duoface.kbdiag176.wake; a one-line [DF176KBDiag] NSLog is
  kept locally. The contract test asserts the relay contains no
  setKeyplaneName/setKeyboardName/setKeyboardWidth: nothing about
  the keyboard is modified.
- SpringBoard side (Chrome): on the wake it reads the record and
  writes one DFCLog line "qa176-kbdiag ..." combining the app
  facts with its own slot frames, content rect and the external
  screen bounds — one exported block separates the hypotheses
  (frame overflow / ancestor clipping / wrong keyplane / phantom
  hardware keyboard).

## Device tests owed
1. H1: tap inside a pane (not letterbox) -> logo + menus reappear
   and the app still receives the tap; controls hide again after
   ~4s idle; divider drag and YouTube taps unchanged; no log flood.
2. H2: with GPS running, count visible speed-HUD layers (expect 1);
   limit ring + red X still work; on native Home (no DuoFace
   chrome) the CarPlay-side HUD still appears.
3. H3: park, open hosted Waze, tap the search field, then export
   logs and send them back — the qa176-kbdiag line decides the
   QA177 keyboard fix.
Also still owed from QA175: the driven GOFA navigation session for
the QA172 shadow-decoder verdict.
