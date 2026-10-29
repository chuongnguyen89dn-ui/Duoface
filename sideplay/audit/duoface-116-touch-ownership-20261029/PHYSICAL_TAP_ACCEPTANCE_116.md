# DuoFace .116 root-window touch diagnostic: parked-car test contract

Status: .116 is a **read-only input diagnostic**, not yet a proven touch fix. Signed QA run [40870166155](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40870166155) passed, source `6d4174321f2d71190fe11bec6b24a810b58d7eb1`, immutable rootless archive `sideplay/jb-embedded-appbridge/evidence/runs/40870166155/`, SHA256 `fc87ceb4a8492469563246c00a9a205b838498f7652f8515bb08b9ca356285a8`. Actual device touch not tested.

## Scope

Only install from the known, verified Sileo package entry when Pages verification passes. Do not attempt Filza installation or unverified direct DEB. Park before tapping the head unit. Preserve .115 rollback and the known .90 YouTube rotation/.92 divider/Apple Dock.

## One continuous session (essential)

1. Confirm Sileo version `0.0.116~pane-trace1` and connect CarPlay once.
2. Open two real apps with YouTube in the same split pane as the failure. **Immediately** touch a visible upper card AND a visible lower card; write down which played and approximately how many seconds elapsed after scene first appeared.
3. Without changing split ratio, wait until the failure develops. Again touch the same upper/lower cards; then scroll the whole YouTube list, including near the bottom. Do not confuse a visible card with a confirmed click.
4. After the 4s UI auto-hide, touch a safe blank area of each pane; record whether logo and controls wake. Verify normal drag of the .92 divider, Dock and no duplicate touch, then leave CarPlay Home and reenter once.
5. Preserve the **same-session** logs from the device: `/var/mobile/Library/Logs/DuoFaceTouchOwner.log` and `/var/mobile/Library/Logs/DuoFaceSceneHost.log`, with the physical results and elapsed times. An old .88 screenshot/log is not adequate for .116. Never put identifiers or secrets in public evidence.

## Read-only trace fields to correlate

- `pane116-pointInside`: actual external pane window `frame/bounds/rootBounds`, `inside=0/1`, `point`, `fractionY`.
- `pane116-hitTest`: original UIKit superclass target class or `nil`; `targetIsWindow`.
- `pane116-sendEvent`: proves a real touch-Began UIEvent reached the traced pane UIWindow and original UIKit superclass dispatcher; does **not** prove that the remote YouTube app received it.
- `DuoFaceSceneHost.log` reference and app reflow markers: `scene-attached`, `scene-frame-readback`, `geometry-before-reference-setters`, `media-reference-committed-after-stable-viewport`, `youtube-app-handshake-ack`, `scene-geometry-suspended`.

## Diagnosis matrix: what actually distinguishes the causes

- A failed touch has no matching `pane116` event but working upper touch does: physical window routing or a remote-input bypass is plausible; inspect window order/CarPlay event owner, do not claim a clipped scene from a missing log.
- Failed lower touch arrives with `pointInside=0` or `hitTest nil` while upper target succeeds: physical window frame/root hit region mismatch likely; inspect the relevant local bounds.
- Both touches arrive in the **same** window with valid hit targets, but lower YouTube never acts: deeper remote scene/app UIKit input transform or a gesture owner mismatch is plausible. Compare the app-side orientation/geometry relay and scene reference transaction, not just the 4s logo timer.
- Both upper and lower fail only following an orientation/scene-geometry update: prioritize app/host geometry scheduling mismatch, and compare with exact original Native12 `layoutSubviews -> updateLayout -> updateSceneSettingsFrame -> layoutIfNeeded` order verified in the original SHA-pinned binary.
- If no tracer events for either, do not infer no physical touch: CarPlay may deliver directly to a remote-hosted app outside the local UIWindow `sendEvent` path. A separate scoped event owner probe would be required.

## Exit criteria

Only call a later .117 a fix when the installed binary passes all-pane upper/middle/lower click + scroll + play after prolonged use, both panes, 4s logo-wake, split/solo/reconnect, Dock and .90/.92 regressions on the user's actual car. Source compilation or a green CI is **not** hardware pass.
