# QA162 — GOFA Speed8 in DuoFace: physical test plan and evidence

## Proven build, not a passed device test
- Current source branch: `feature/duoface-qa162-gofa-speed8-20261101`, signed/source SHA `171f481b33324d8ebdfd076bf6abc18e20c58242`.
- Integrated package identity: `com.duoface.jb.embedded` version `0.0.162~gofaspeed8test1`, rootless `iphoneos-arm64`.
- SHA256 exact signed DEB: `c287de0621bb3f61bcc7c80d264a7c110da8a2208e0a49563c9245d08a86cb71`, size 1,210,124 bytes.
- Original candidate from CI [41300598527](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41300598527) PASSED compile/tests/sign/package:
  `sideplay/jb-embedded-appbridge/evidence/runs/41300598527/com.duoface.jb.embedded_0.0.162~gofaspeed8test1_iphoneos-arm64.deb`
- Existing Sileo publisher is `chuongnguyen89dn-ui/carplaydsp` with validation run `41301064956` PASS. Live publisher run `41301064886` must complete and public APT SHA must match before calling it released. Keep QA161 (`0.0.161~firstframe1`, SHA256 `441e1312d5b262abb764bf799ac710a07cbae6f757ead800941e527d2cc2fa85`) as rollback. No separate Speed8 package.

## What QA162 actually does
1. Builds the pre-existing own-source HUD `DFNative8SpeedHUDView.mm` **inside the existing DuoFace SpringBoard host dylib**. Shows it only above the live, owner-verified, visible `com.lumi.GOFA` pane, never globally over Home/Dock.
2. Narrowly injects `DFGofaSpeedSource162.dylib` into `com.lumi.GOFA`, obtains **CoreLocation speed** if GOFA already has user-approved location authorization (no permission prompt, no private GOFA API).
3. Transports only GOFA GPS speed via `com.duoface.speedhud.v1.gofa` and `DFSpeedProtocol.hpp` (5-second age threshold). Displays unknown data as dashes. A valid speed of zero is allowed.
4. **Does not** extract GOFA's actual speed-limit, camera, road signs or turn instructions. The traffic-sign ring is placeholder `—`; do not call it a working road speed limit alert.

## Device test, parked car first
- Verify device is iPhone X iOS 16.7.16 rootless JB and GOFA can access Location (user-granted). Confirm exact QA162 Sileo version and checksum; do **not** install duplicate Speed dylibs or a separate CarPlayPro DEB.
- Connect CarPlay with DuoFace split view, select GOFA in one slot. Check HUD bubble draws **inside GOFA's owned pane** and does not appear on native CarPlay Dashboard or other app panes.
- Confirm no stale/fabricated number: if location unavailable or older than 5s, speed `—`. If GOFA provides authorized location, numerical `0` at rest may be observed (test near stationary location before any vehicle movement). Road limit should remain `—`.
- Check that dragging only the HUD bubble works without stealing app touch; long-press settings show Source GOFA. Verify YouTube in other pane, Dock/Home navigation, split/solo, reconnect and GOFA replacement.
- Disconnect CarPlay and go Home. Verify HUD removed immediately and no orphan window; reconnect and restore GOFA should reattach. Watch for battery impact/duplicate CoreLocation listeners.
- Collect exact time, logs with `[DuoFaceSpeed8]`, `DuoFaceSceneHost.log`, `DuoFaceNativeSceneJoin.log`, SpringBoard crash logs and screenshot/video evidence; save in source repo under an appropriate evidence folder. **Do not assume test success without these.**

## Failure triage
- HUD absent: first confirm live GOFA scene is truly hosted, `DFNative12Chrome.refreshGOFASpeedHUD162` called after `sceneReady:`. This feature does not work by merely opening GOFA from native CarPlay Home.
- HUD shows `—`: inspect GOFA app permissions, `[DuoFaceSpeed8] GOFA GPS publisher started` and `GOFA valid GPS speed publish`; note iOS may not deliver CoreLocation updates to this process/scene even with permission. Do not invent speed or reuse other app's legal limit.
- Wrong touch, crash, Dock/Home regressions: collect exact log and rollback QA161. Do not modify GOFA's Mapbox layout hook to fix unrelated speed.
- Do not conflate build CI PASS with runtime GPS or road safety accuracy.

Status at creation: **SOURCE/COMPILE/SIGNED PASS, PUBLIC PUBLISHER/DEVICE RUNTIME NOT YET VERIFIED**.
