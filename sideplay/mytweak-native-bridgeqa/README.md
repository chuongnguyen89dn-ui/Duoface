# DuoFace Native Dashboard Bridge QA 0.0.4 — Native12 Normal ↔ host Fullscreen geometry
New standalone QA package **not** replacing existing MyTweak `0.2.6~recovery1`, Native12/HUD8, QA11 or OwnerProbe.

## Geometry from verified 2026-10-14 Native12 history

This update implements **independent equivalents** of Native12's screen-vs-usable content model; it does not copy proprietary binaries, frameworks or licensing.

- Normal: Apple Dashboard root/window stays full `carPlayScreenBounds`. The child content region is computed from *measured real* content insets `{top,left,bottom,right}`, without hardcoded 45pt/64pt/90% and without changing `UIWindow.frame`.
- Fullscreen (host, NOT per-slot focus): remote V1BC menu `Zoom` is routed over the authenticated SpringBoard→CarPlay session. On the same Dashboard-owned child view, content becomes full screen and the real CarPlay statusbar gets hidden, with hidden state/content geometry snapped first. The source root app and its two split panes are untouched; original selected-pane toggleZoom is not invoked by remote QA's host Zoom.
- Exit: the SAME `Zoom` menu triggers saved normal content geometry and native bar hidden-state restoration. If the system has changed its layout, stop/rollback rather than force a guessed pixel ratio.
- Source Window yield remains a separate short 45-second ACK-gated experiment and is **not** a Native12 semantic replacement. Real Apple Dock/Home is not confirmed until device test. `drawViewHierarchyInRect:` can omit remote application/video pixels.
- User's measured iPhone X screen is 507.333333×240 points and (when the native left bar is onscreen) width 45 → normal pane width 462.333333; fullscreen width 507.333333, **not a universal fixed ratio**.

## Implemented (experimental)
- On SpringBoard, after a 10s delay, reflectively discovers **existing** V1BC `MTBridgeCoordinator.bridgeWindow.rootViewController`; never creates/changes a system UIWindow. An off-by-default pair of opt-in preferences gates activation.
- Publishes an **independent raster mirror** of the two-pane V1BC root, through `CAContext` as a separate CALayer (never reparents the running original `root.view.layer`), up to ~2.5 frames/sec. This is a narrow transport experiment, **not full-motion app graphics**: `drawViewHierarchyInRect:` might omit iPhone remote scene/video pixels even if sender succeeds.
- CarPlay process scans real active Dashboard window `DBDashboardRootViewController`, real `DBStatusBarWindow` visible-screen geometry. Attaches `CALayerHost` inside the measured native content area only. In the actual user owner log `x=-45` statusbar offscreen, it **fails closed** and makes no overlay. Does not force native system statusbar location or make native Apple Dock appear.
- CarPlay-to-SpringBoard Darwin notifications with 2s UUID-session and anti-replay. Pointer mapping triggers **only** the existing V1BC menu buttons (`App`, `Split 2/Single`, `Swap`, `Zoom`, `Close`). iPhone apps cannot yet receive general touch/drag/gesture events via this transport.
- Optional third opt-in NativeSidebarTrial=true in the second plist: for at most 45 seconds, only if a real DBStatusBarWindow is visibly active but entirely offscreen at x=-its actual width, move that exact Apple window to x=0. On expiration, opt-out, session lost or disconnect restore the original frame only if Apple has not already repositioned it. Not a fabricated Dock, and no proof native Home actually works until tested.
- **New verified-code handoff experiment (QA3):** CarPlay reports a short-lived `receiver-ack` record only when its CALayerHost actually attaches to an Apple-owned Dashboard root and remains within the measured native usable bounds. SpringBoard, after checking same session/context and third opt-in `NativeSidebarTrial=true`, temporarily lowers **its own V1BC UIWindow.windowLevel** from 0 to -2 (native Dashboard root level -1 in the original device log), so it should no longer paint over the Apple bar and its Dashboard receiver. Auto-restores original level after 45s, when ACK expires, source window changes, disconnect, or opt-out; never changes Apple's native window level, creates a fake Dock, or removes the source UIView. This is not yet hardware-tested and the raster mirror may omit remote video pixels. It is not proof of Home/CarPlay app registration.
- CarPlay quit, invalid active display, opt-out, session expiry or disconnect removes the overlay/lease and leaves the original host running; no install/upgrade script triggers a respring.

## Config (optional after verified CI / on safe parked device)
Not automatically enabled; unlike the old shell1 it does not touch SpringBoard app discovery/entitlements/LS APIs.
Requires BOTH prefs files with boolean `Enabled=true`:
`/var/mobile/Library/Preferences/com.duoface.mytweak.v1bc.plist`
`/var/mobile/Library/Preferences/com.duoface.mytweak.carplay-bridge.plist`
The second plist must be deliberately created/enabled in Filza **only by the device owner**; additionally set NativeSidebarTrial=true to test the reversible real system sidebar move. Never auto-enable at install.
Optional log: `/var/mobile/Library/Logs/DuoFaceNativeBridgeQA.log`.
Rollback: set second opt-in `Enabled=false`, or uninstall `com.duoface.carplay.nativebridgeqa` from Sileo; no change to recovery package.

**Not completed:** live hardware CarPlay content or Dock/Home test, independent first-party CarPlay app admission/scene activation, actual native statusbar x=-45 restore, full touch into hosted apps, high-quality moving video. Compile success != Dock fixed. It must not be marketed as a working Dock fix.
