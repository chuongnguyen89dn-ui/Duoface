# DuoFace Native Dashboard Bridge QA 0.0.1
New standalone QA package **not** replacing existing MyTweak `0.2.6~recovery1`, Native12/HUD8, QA11 or OwnerProbe.

## Implemented (experimental)
- On SpringBoard, after a 10s delay, reflectively discovers **existing** V1BC `MTBridgeCoordinator.bridgeWindow.rootViewController`; never creates/changes a system UIWindow. An off-by-default pair of opt-in preferences gates activation.
- Publishes an **independent raster mirror** of the two-pane V1BC root, through `CAContext` as a separate CALayer (never reparents the running original `root.view.layer`), up to ~2.5 frames/sec. This is a narrow transport experiment, **not full-motion app graphics**: `drawViewHierarchyInRect:` might omit iPhone remote scene/video pixels even if sender succeeds.
- CarPlay process scans real active Dashboard window `DBDashboardRootViewController`, real `DBStatusBarWindow` visible-screen geometry. Attaches `CALayerHost` inside the measured native content area only. In the actual user owner log `x=-45` statusbar offscreen, it **fails closed** and makes no overlay. Does not force native system statusbar location or make native Apple Dock appear.
- CarPlay-to-SpringBoard Darwin notifications with 2s UUID-session and anti-replay. Pointer mapping triggers **only** the existing V1BC menu buttons (`App`, `Split 2/Single`, `Swap`, `Zoom`, `Close`). iPhone apps cannot yet receive general touch/drag/gesture events via this transport.
- CarPlay quit, invalid active display, opt-out, session expiry or disconnect removes the overlay/lease and leaves the original host running; no install/upgrade script triggers a respring.

## Config (optional after verified CI / on safe parked device)
Not automatically enabled; unlike the old shell1 it does not touch SpringBoard app discovery/entitlements/LS APIs.
Requires BOTH prefs files with boolean `Enabled=true`:
`/var/mobile/Library/Preferences/com.duoface.mytweak.v1bc.plist`
`/var/mobile/Library/Preferences/com.duoface.mytweak.carplay-bridge.plist`
The second plist must be deliberately created/enabled in Filza **only by the device owner**. Never auto-enable at install.
Optional log: `/var/mobile/Library/Logs/DuoFaceNativeBridgeQA.log`.
Rollback: set second opt-in `Enabled=false`, or uninstall `com.duoface.carplay.nativebridgeqa` from Sileo; no change to recovery package.

**Not completed:** live hardware CarPlay content or Dock/Home test, independent first-party CarPlay app admission/scene activation, actual native statusbar x=-45 restore, full touch into hosted apps, high-quality moving video. Compile success != Dock fixed. It must not be marketed as a working Dock fix.
