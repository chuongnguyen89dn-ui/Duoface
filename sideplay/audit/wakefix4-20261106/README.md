# QA172 wakefix4 — hosted activity and native-map restoration

This continues the user-authorized sideplay repair from verified wakefix3 commit
`6e5e199b95dba2b97568edaab4407630afeba3eb` on isolated branch
`feature/sideplay-wakefix4-20261106`. The user asked to continue fixing the project;
this is an implementation candidate, not another diagnostics-only release.

## Repairs and evidence

| Source-level defect | Shipping repair | Executable regression evidence |
| --- | --- | --- |
| The global app-touch mailbox accepted any nonempty bundle, so an unhosted phone app could extend CarPlay control timers. | Upgrade both shared relay senders and receiver to a v2 record with PID. Before changing timers, require an exact bundle/PID from a currently live hosted surface, valid typed fields, a timestamp within this Chrome session and no more than two seconds old, with no future timestamps. | `app_touch_177_runtime.m` calls the production Foundation policy for valid hosted apps, unhosted apps, wrong/restarted PIDs, malformed and legacy records, JSON round trips and time boundaries. |
| An app-touch delayed callback only compared a recheck counter, which teardown did not invalidate. A reused instance could accept a callback from its previous session. | Track an active session generation and current Chrome object identity. Invalidate at start/stop; guard queued touch/keyboard notifications and deferred layout before reading state or changing layout. | The same production policy is exercised across stop, restart, repeated start, replaced instances and coalesced callbacks. |
| A retained restoration superview could still be in the old window after its parent view or ancestry changed. | Capture the exact original parent view. Before any restore mutation, recheck parent view/window identity, the full superview ancestry and both view/controller containment cycles. Reject a changed destination without reparenting. | `native_map_restore_policy_runtime.m` mutates Foundation object graphs and calls the shipping policy, including the reviewed ancestor-into-descendant view cycle. This is not a live UIKit transaction. |
| Pane validation truncated fractional slot values and checked uniqueness only for visual slots. | Accept only numeric values exactly equal to 0 or 1; require a bijection for both physical and visual slots. | `physical_map_binding_runtime.m` accepts valid swapped layouts and rejects duplicate physical/visual slots, fractional, nonfinite, out-of-range and wrong-type values. |

The stale fatal-exception trace label is also corrected to `0.0.172~wakefix4` so
future logs identify the actual build. Existing UI geometry, Dock, player,
keyboard-unknown behavior and previously repaired disconnect policies remain
covered by the retained workflow gates.

## Compatibility and boundaries

- V1 touch records have no PID and are rejected. Already-running app processes
  that still have the old relay loaded need an app relaunch to load the matching
  v2 sender. No process is restarted by this patch or by this work.
- Bundle/PID validation proves a currently hosted **process**, not which scene
  within that process produced a touch. It does not claim same-app phone touches
  are distinguishable from touches in that app's CarPlay scene.
- Activity is an expiring event; keyboard state remains a retained per-process
  snapshot. Unknown keyboard state still defers layout and does not consume
  touches, so controls can remain visible beyond four seconds.
- Native-map adoption is still limited to an already-observed matching native
  scene. Automatic native launch/keepalive is not implemented. Existing device
  evidence confirms an activation selector exists but does not establish a valid
  activation object or usable receiver route. The saved original launch analysis
  delegates through another helper and does not close that semantic gap.
- A rejected restoration leaves existing ownership intact. Cleanup of an empty
  abandoned pane and deferral for a pane containing a replacement scene retain
  the wakefix3 behavior; this does not prove every reconnect case is solved.

## Build and audit status

Versions: native host `0.1.172~wakefix4`; integrated package
`0.0.172~wakefix4`. Workflow:
`.github/workflows/duoface-172-wakefix4-signed-private.yml`.

Local validation passed 162 Python tests across 39 retained suites (zero skipped),
8 portable C/C++ programs and workflow/build-script syntax. The first local run
found a missing fixture in the sparse checkout; its exact unchanged tracked blob
was restored and the remaining gates completed. See `local-validation.json`.
Ten Foundation runtime harnesses and two iOS compile steps require the macOS CI
run; a signed build or physical runtime result is not inferred from these local
checks. The workflow runs the retained regression
suite, the three additional Foundation harnesses, iOS compile checks, a signed
build, and a complete DEB integrity audit.

Only the requested DEB, packaging provenance and an allowlisted aggregate audit
summary are exported by CI. Detailed binary strings, symbols and extracted
metadata stay private, following the previous automatic review rejection of a
public metadata dump. The public comparison receipt contains aggregate counts
and booleans only.

`SILEO_PUBLISHED=false`; `installed_by_this_work=false`; `DEVICE_TESTED=false`.
Physical acceptance remains repeated app/hidden-control taps, keyboard cycling,
unplug/reconnect and exact native-map ownership on the actual iPhone/CarPlay.
