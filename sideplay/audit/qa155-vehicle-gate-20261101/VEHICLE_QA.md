# QA155 — one real-car acceptance session (not yet performed)

Branch: `feature/duoface-qa146-native-home-exit-20261031`. Device: iPhone X, iOS 16.7.16, palera1n rootless, actual CarPlay head unit. **Never describe CI as real-device acceptance.**

## Before testing

1. Install **only** a SHA-verified QA155 rootless DEB through an isolated Sileo QA source. Preserve the known rollback package, disable conflicting DuoFace / CarBridge / vendor modules according to package control dependencies. Do not install using Filza. Stop if the Sileo QA source, DEB SHA, installed version, and actual rootless dylib+plist do not match. No automatic respring or forced process kill from this checklist.
2. In DuoFace iPhone settings, explicitly enable **VLC** (`org.videolan.vlc-ios`) if installed, and enable its standalone/Home test opt-in. Safari is also in the static injection filter but its Apple-bundle selected Home path has a separate policy and must **not** be taken as validated by this trial. Keep YouTube and GOFA on their original paths.
3. With the car parked, record device local clock time, installed package version and whether the physical Home/CarPlay-native apps work **before** selected test. Keep the previous package for rollback.

## Single session and objective result

Test one selected VLC launch from actual CarPlay Home. Confirm: (A) launch delay measured; (B) full-screen touch top/middle/bottom after 30 seconds; (C) landscape not phone portrait; (D) system Home returns to correct app chooser context; (E) system Dock updates active app; (F) lock iPhone without dark CarPlay screen; (G) open YouTube and GOFA once to check no regression; (H) disconnect/reconnect and selected-app restoration; (I) exit and restore the phone app scene.

Open DuoFace on the iPhone and tap **Xuất log / lỗi CarPlay** once at the end. This exports `DuoFaceStandalone144.log`, `DuoFaceDockOwner.log`, `DuoFaceDeepTrace.log` and other named diagnostics, and must include the new `qa155-app-side-ack` lines *if* the app callback was accepted and logged by SpringBoard. Missing ACK = **unverified**, not accepted. Do not upload other personal app data; redact unrelated identifiers when sharing.

For a matching RequestID verify the ordered route: `qa153-verified-phone-target-eviction` (when applicable) → `qa149-manager-live-scene-owned` → `qa155-app-side-ack phase=lease-accepted` → `scene-matched` (or explicit `scene-unmatched`) → `window-adjusted` if a size correction was necessary → `restored` on stop. Absence of `window-adjusted` is not automatically a failure if the app window already matched target dimensions. **No ACK proves touches, pixels or Dock**, so keep the physical checklist separate.

## Go / no-go

**Pass** requires a signed SHA-verified QA package, required callback route, and explicit user-observed physical launch/inputs/orientation/Home/Dock/lock/reconnect. **Fail** when any key UI behavior still breaks or callback missing; preserve exact same-RequestID log and compare the first missing hop with genuine DuoNavi 1.0.4 reference. Revert to prior version through Sileo if unstable, do not push speculative follow-up DEBs. **No official Sileo release** until physical gate passes.

Current evidence: previous QA155 private build `41235256020` included receiver but lacked app-side ACK export and used package version 0.0.147; new code/unique version QA155 test is built separately and must be verified against its own run artifact before installation. Physical result: **NOT TESTED**.
