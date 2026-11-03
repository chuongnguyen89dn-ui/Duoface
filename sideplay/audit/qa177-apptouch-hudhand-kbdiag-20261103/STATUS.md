# QA177 — app-touch recall / HUD exit handover / keyboard diagnostics round 2

Status: PUBLISHED to Sileo 2026-11-03 (carplaydsp commits 8ed037be +
fix a37de836; publisher run 41552468225 SUCCESS; public index verified:
exactly 1 stanza 0.0.177~apptouch1, SHA 70e5117f…, Size 1270336).
First publisher run 41551792852 failed on a stale selected-stanza SHA
pin (QA176's) in the index-completion assert; fixed and re-run.
NOT device tested.
Branch: feature/duoface-qa177-apptouch-hudhand-kbdiag-20261103 (from QA176 tip 6fdf6af9)
Code tip: 627f39d89ff9 (test re-pin fix on top of fcad40b2)
Build: private run 41550814513 SUCCESS (first run 41550619395 failed step 3:
test_integrated_package_144 version pins, re-pinned and re-dispatched)
Archive commit: b7657a3624cf
Integrated: com.duoface.jb.embedded 0.0.177~apptouch1 (host 0.1.177~apptouch1)
DEB: 1,270,336 bytes, SHA256 70e5117f290576b7958d9dfbd8cf734cb60b79d0dfba2ba621fc7dad553f122b
Verified from the DEB itself: control fields, Conflicts/Replaces complete,
postinst/postrm byte-identical to QA176 (md5 5d016787… / eddecdc6…), and the
QA177 markers present in the right binaries (qa177-app-touch / qa177-recall /
qa177-hud-handover in DFTouchOwnerProbe; the v177 touch mailbox + sendEvent:
in DF155 relay and the YouTube relay; qa177-overlay attach/detach + the
overlay record path in DFCarPlayDockOwner).

## Step-0 results
- H1 transport: DF156 mailbox, app -> SpringBoard — the direction QA176's
  keyboard diagnostics already proved on device (app wrote, SpringBoard
  read, 9 records). Latest-value payload {bundle, count, ts}; the mailbox
  post is the wake; sender throttle 250ms is far inside its capability.
  Chosen as expected; no fallback needed.
- H1 coverage: DF155 pilot scope = 14 apps (Safari, VLC, Facebook, TikTok x2,
  ChatGPT, Gemini, Netflix, Twitch, YouTube Music, Chrome, Spotify, Google
  Maps, Waze). YouTube (com.google.ios.youtube) is NOT in DF155 — it carries
  its own relay, so the identical sender was installed there too (shared
  header DFAppTouch177.h). Apps with NO app-side relay (GOFA, other
  third-party apps, non-whitelisted Apple apps) cannot recall the controls
  until they get a relay.
- H2 channel: the overlay (CarPlay process) demonstrably writes files
  (DuoFaceDockOwner.log), so it became the single writer of its own
  HUD-visible record (com.duoface.speedhud.overlay163.plist). The full
  handover (hold up to 4s waiting for the flag) was implemented, not the
  2.5s fallback.
- H3 pane mechanism: DFSceneHost.layoutScene keeps the hosted scene at a
  per-bundle LOGICAL size (DFHostedLogicalSizeForBundle, e.g. 414x736),
  sets the host view's frame to that size and scales it into the pane with
  a non-uniform CGAffineTransformMakeScale, centered. The FBScene commit
  uses the pane size as reference, but the app's scene/client frame stays
  at the logical size — readback actual (414x736) != target by design.
  The keyboard lives in logical space: 414 wide x ~0.65 scale ≈ 270pt of
  the 640-wide car display (≈42%, matching the 2026-11-02 photo), height
  scaled by ~0.47 and bottom-anchored in the 736-tall space. The fault is
  the geometry contract, not a keyplane or a driving ban. Fix: QA178.

## H1 — app-side touch signal (DONE)
- DFAppTouch177.h: sendEvent: observation (original IMP runs FIRST, then
  read-only scan for a Began touch), DF156 mailbox sender, 250ms throttle
  (kDF177TouchThrottleSeconds), cumulative count. Kill switch
  AppTouchRecall177 in com.duoface.nativehost.qa177.plist (absent = ON),
  read live by both sides.
- Installed in the DF155 relay (pilot scope) and in the YouTube relay
  (noted deviation from that file's no-swizzle rule; the work order
  explicitly chose sendEvent: as the observation point).
- Chrome: Darwin wake registration in start (cancelled in stop); handler
  reads the mailbox, materializes `qa177-app-touch bundle=.. count=..`
  (<=1 line / bundle / 5s + on bundle change — only SpringBoard file logs
  reach the exporter), calls noteUserActivity, and logs
  `qa177-recall source=app-touch bundle=..` only on hidden->visible.
- QA176's H1(a)/(b) wiring left in place per the work order.

## H2 — HUD exit handover + overlay file log (DONE)
- Overlay: every attach/detach appends ONE line to DuoFaceDockOwner.log
  (exported) via a reason funnel (qa177-overlay attach/detach reason=..),
  publishes/clears its HUD-visible record, heartbeats it while attached.
  A fresh Retiring Chrome lease overrides both yield signals (session
  pulse + chrome lease) so the overlay attaches during the handover.
- Chrome stop: if the HUD is up, its window is stashed out of the window
  list before the mass hide, the lease is published Retiring, and a 0.25s
  watcher holds the HUD until the overlay record reads visible+fresh or
  kDF177HUDHandoverMaxSeconds = 4.0s expires; finish hides the window,
  retracts the lease, logs `qa177-hud-handover done=<how> waited=..s`.
  A reconnect finishes a pending handover as "superseded".
- Limit ring + red X untouched; QA176 lease priority unchanged.

## H3 — keyboard diagnostics round 2 (DONE, log only)
- Relay: rate limit split per notification name (lastKbDid176) so
  DidShow is no longer starved by WillShow; record gains kbLevel and
  sceneBounds (scene coordinate-space bounds).
- Chrome's combined qa176-kbdiag line gains kbLevel/scene plus host view
  facts for the bundle: hostF/hostB (logical frame), hostT (transform
  a,b,d = the pane scale), surfB (surface bounds = pane size).
- No keyboard behaviour change; the no-setKeyplane contract test holds.

## Risks / open
- sendEvent: hooks live in third-party app processes (pilot + YouTube):
  observe-only and original-first, but any crash there would be in the
  app; the kill switch disables sending without a respring (flag is read
  per note) and Chrome ignores signals when disabled.
- Handover holds one window past stop for up to 4s; bounded by the timer
  and finished early on overlay-visible or reconnect.
- DEVICE_TESTED=false. Device tests owed: H1 tap in YouTube/Maps (controls
  appear, ~4s hide, app still receives the tap; export shows
  qa177-app-touch > 0); H2 exit DuoFace (no blink) + steady-state HUD
  count; H3 keyboard in Maps (pane) and Waze (full screen) + photo +
  export after each.
