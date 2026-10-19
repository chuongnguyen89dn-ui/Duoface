# DuoFace CarPlay remote presentation prototype — NOT a release

Branch `feature/mytweak-carplayapp-presentation-20261019`, baseline V1B+C `67ba830685416a3810255c383dc9aa1b1f9033d8`.

This directory **is not compiled into** `DFV1APreflight`; no Sileo package contains this code. GitHub Actions validates ObjC syntax for iOS 16 and checks source contracts.

## Implemented source (not device verified)
- `MTCPBridgeContract`: versioned 2-second envelope with session UUID, replay sequence, surface context ID, bounded normalized rect, finite pointer coordinates and **two independent opt-in switches**. Preferences: `com.duoface.mytweak.v1bc.plist` and `com.duoface.mytweak.carplay-bridge.plist`, both `Enabled=true`. Neither opt-in is set by the prototype.
- `MTCPRemoteLayerProducer`: SpringBoard-only, explicit call creates a `CAContext` remote context from caller-provided `CALayer`; holds context lifetime and clears only the matching session's record on invalidate.
- `MTCPRemoteLayerReceiver`: CarPlay/CarPlayApp-only, explicit call requiring caller-supplied, **already system-owned** external `UIWindowScene` content view with identifier `duoface.native.content.host` and system safeArea; attaches `CALayerHost` only within that owner view's usable rectangle. Never finds/patches Apple's Dashboard root window.
- Touch packet sender: single-pointer begin/move/end/cancel normalized to the viewer; 60 Hz move limit; strict opt-in, anti-stale session and monotonic sequence.
- `MTCPCommandRelay`: SpringBoard session-bound notify reader with replay checks and supplied callback, no automatic touch synthesis or arbitrary application launch.
- `MTCPHostCommandAdapter`: explicit SpringBoard-side receiver for already-validated `swap`, `split`, `zoom`, `close` commands, using existing V1BC root methods. `home` and `pointer` deliberately return unsupported; does not yet have a running installation/call site.

## Not implemented / blockers to resolve before UI candidate
1. **Who supplies the legitimately CarPlay-owned content view?** No connection to Apple's `CPTemplateApplicationScene` or private Dashboard roster is implemented; official Apple access to a custom CarPlay window is restricted and cannot be assumed for an arbitrary app.
2. **The actual live V1BC layer:** no call site publishes `MTBridgeRootViewController.view.layer` from SpringBoard; need prove moving/publishing it does not stop host/touches.
3. **Full input delivery:** packet transport exists, but receiving a normalized pointer is NOT equivalent to injecting a UIKit touch into the hosted iPhone scene. No touch injection adapter exists.
4. **Navigation:** Home action enum exists but no Dashboard-owned Home transition is attached to a live workspace.
5. **CAContext compatibility:** `CAContext` and `CALayerHost` selectors are private and unverified on target iPhone X iOS 16; static compiler success cannot prove remote surface is visible, scene admitted, or native Dock operational.

Stop gate: do not add to production Makefile or distribute on Sileo until native view ownership, two-app frame rendering, full pointer round-trip, Home and safe rollback have proof. No other package or license binary is used. Existing emergency recovery `0.2.6~recovery1` remains the Sileo version; QA11/Native12/HUD8 are untouched.
