# Audit16 / QA185 vehicle verdict — 2026-11-07
## Scope and correction
User explicitly confirms Maps has NEVER disappeared in DuoFace. Actual complaint: constrained/cropped Maps UI and blank adjacent pane. Revoked membership is not disappearance, destruction, or lost pixels. Earlier acceptance framing was wrong and is superseded here.
Read-only investigation; no runtime patch/build/deploy/device operation.

## Immutable inputs
Log upload main commit 68a931798d48447322699bb95ff3448107638492, 2026-11-07 13:01:51 ICT:
- sideplay/log/DuoFaceAudit 16.txt blob 79d8d3637c182517508dddf16a50cbfefd85aaca; 458 explicit build=0.0.185~admission1 records.
- sideplay/log/DuoFaceMapsGate0-CarPlay.jsonl blob 66441d5a1df6057fc243ef1ddab850f4579385ad; 2349 parsed JSON rows.
- Preferences unchanged in this upload; do not call it a fresh sample.
Source read from feature/duoface-qa184-native-map-owner-sourceonly-20261107 head bf3e9a569c41e807e4abcc0e6b8e56a592cf001a: sideplay/native-carplay-scene-v1/DF182NativeMaps.m.
GitHub in_progress query returned 0 at investigation; no jobs started.

## Measured sequence
Two assignments, both workspace-restore (not fresh picker):
1. 79DC7C09-04D4-4623-80DB-119A4C1387B3, session EC58A966-BF34-4F82-AE6C-1528F1CA98B2:
Audit24429 PRESENTED admitted,24469 COMMITTED at1794030937.868540,24470 frame placed198.333x360 at x441.667.
Audit24473 at1794030938.133009 fails COMMITTED view.frame actual0x0 expected198.333x360;24474 restores original640x360;24475 revokes membership.
First commit to failed attestation0.264469s; to revoke0.273046s.
2. 9FC0C233-7F75-43C8-A36A-9AA9EB0D8C89, session C905F2C1-DF56-4615-B1B6-F5EC25B1B464:
Audit24581 PRESENTED admitted,24643 COMMITTED1794030955.643345,24646 SpringBoard acknowledges same membership.
24650 reflow to297.5x360 x342.5;24652 renews COMMITTED1794030955.917531.
24660 at1794030956.179223 COMMITTED view.frame actual0x0 expected297.5x360;24661 restores original640x360;24662 revokes.
First commit to failure0.535878s; latest commit to failure0.261692s.
Thus2/2 assignments reach admission AND actual initial containment/hit-test commit (3 commit log events due one reflow), but neither sustains pane geometry. This is real admission progress, not a visual fix.

Gate2205/2218 initial Maps view414x736 in window640x360. Gate2208 and2221/2222 independently record same controller view0x0 while native scene remains present, window attached/visible and weak controller alive. Gate2209–2215 retains scene after first membership revoke. Confirms why revoke must not be equated to Maps disappearing. Logs do not identify the writer that zeros frame or prove which layer supplies user-visible remaining pixels.

## Adjacent pane
Waze host created/scene attached (24397,24417;24550). Actual scene readback414x736 vs requested793x720 (24434,24572). Later readback793x720 vs new target595x720 (24654). Viewport changes are measured; render remains explicitly unverified. These prove creation != correct dimensions/render, but do not yet isolate blank pane root cause.
Maps placement log target-SpringBoard-window=hidden refers to Maps' target slot, not proof Waze peer is hidden.
Do not claim current414x736 is permanent: later Waze readback actually becomes793x720.

## Source interpretation and next step
DF182NativeMaps.m lines~550–578 reparents DBApplicationSceneViewController view into plain UIView pane while controller remains child of DBDashboardRootViewController. Tick lines~496–518 only resets owner.view.frame when target RECT CHANGES; otherwise re-attests and rolls back on0x0. DF185 COMMITTED guard at~297 correctly reports view.frame zero. Native layout/containment interaction is a hypothesis requiring tracing the actual root/controller layout and comparison with independent DuoNavi containment architecture, not a proven culprit.
Next: inspect existing root/controller layout hooks, scene-size transaction and SpringBoard peer-window stacking together; identify frame-zero writer and stable containment mechanism before patch. Preserve Home/watchdog, keep heartbeat/AppDelegate separate. Do not merely remove view.frame validation or repeatedly force frame as a substitute for ownership/layout repair.
Acceptance must use real user-visible outcome: Maps fits pane, adjacent app renders, both sustain layout through reflow, touch maps correctly. Membership is intermediate evidence only. No further repeat install of QA185 needed just to rediscover this.
## Reproduction
Downloaded public raw files to /tmp/audit16.txt and /tmp/gate.jsonl using curl -LsSf (URL refs main); validated Audit explicit build markers and parsed every JSONL row with Python json.loads. Connector fetch_file for large Audit returned empty content; blob fetch transport closed, so raw download was used. Inputs pinned above by Git blob IDs for durable reproducibility.
