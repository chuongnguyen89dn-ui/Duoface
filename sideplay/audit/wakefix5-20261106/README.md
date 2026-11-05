# QA172 wakefix5 — bounded, explicit native-map launch

**Source checkpoint: implementation, independent review and local regression
gates passed. Signed build, complete-package comparison and physical acceptance
are not yet claimed.**

This continues the user-authorized sideplay repair on
`feature/sideplay-native-launch-wakefix5-20261106`, based on completed wakefix4
head `0a75a3f4f1d943e64deb50a3945cc80630e67e74`. The signed wakefix4 candidate
remains immutable. Native host version is `0.1.172~wakefix5`; integrated package
version is `0.0.172~wakefix5`.

## What this changes

Previously, selecting a native map could only adopt a matching controller that
was already present. The original launch helper's argument and receiver chain
has now been resolved from the exact pinned reference package. This first-party
implementation uses the existing application library, obtains the exact selected
application info and CarPlay declaration, creates native launch-info and an
event, and sends that event to the actual verified dashboard. It does not copy
the reference implementation or its forced-dispatch fallback.

The dispatcher verifies each runtime method signature, argument width and return
object before use. It is restricted to the verified iOS 16 contract and an
observed external CarPlay dashboard/root/window/screen with a genuine captured
workspace owner. If that evidence is unavailable, it refuses with a reason.

| Source-level problem | Shipping behavior |
| --- | --- |
| No native opening route when the explicitly selected map has no observed owner. | A fresh explicit Attach may submit one native event after verification. An existing unique owner goes directly through the retained adoption path; ambiguous or unready owners are refused. |
| Native opening and scene adoption are asynchronous. | Preserve the original request, bundle, slot, physical session, target geometry and weak native identities. Observe the resulting scene within the original six-second request lifetime. Event submission alone never reports success. |
| Home, a replaced dashboard, changed pane or a newer command can invalidate an in-flight request. | Cancel on changed generation, identity, session, pane, ownership, ambiguity or deadline. Recheck immediately before dispatch and adoption, including reentrant callbacks. A cancelled late scene cannot create a choice or lease. |
| A Home-only readiness rule would reject the verified DuoFace screen. | Allow a visible Home with no current base, or the exact already-bound, freshly verified native DuoFace base in the same session/root/window. Freeze the selected readiness mode during preparation. A foreign base is never forced aside. |
| The phone previously read one ACK after 1.5 seconds. | Poll the same immutable request every 0.25 seconds for at most eight seconds / 32 polls. Distinguish Pending, Applied, Rejected and Cancelled. Ignore unrelated, stale or malformed responses. Leaving the controller or entering background invalidates its callbacks. |
| A late old command can resume during native callbacks. | Preserve admission generation across preparation. New explicit intent takes priority; old callbacks do not overwrite a newer result or resume an old launch. |

The pre-dispatch DuoFace base is not a permanent pending identity: opening the
selected map naturally changes that base. The actual physical session,
dashboard/workspace owner, root/window/screen and Home generation must still
remain valid. This does not manufacture an active session or renew an ownership
attestation.

Automatic reconnect remains **reattachment of an already-observed matching
scene only**. It calls the internal path with launching disabled. A saved map
choice is not permission to open an app on reconnect.

## Retained repairs and boundaries

Wakefix3/4 keyboard, disconnect, app-activity identity, deferred-callback,
restoration-ancestry and exact pane-mapping repairs are retained. Existing UI
geometry, Dock, player and injection filters remain covered by the established
gates. The new helpers compile into existing components; they do not add an
injected dylib or broaden its app scope.

- An Applied Attach ACK requires verified exact scene adoption and actual pane
  geometry readback. An Applied Restore ACK requires the pane to be detached.
- The pending request cannot keep a native scene alive, override a system
  revocation, force-close an app or suppress native foreground/background
  lifecycle. If CarPlay revokes the session during opening, the request stops.
- Runtime ABI refusal is expected on unsupported or unverified configurations.
  The retained workspace proof can refuse devices where no genuine workspace
  owner was captured. No fallback invents that evidence.
- Rendering, touch, map tiles, navigation continuity and actual signature
  acceptance still need the physical iPhone/CarPlay. A build or Foundation fake
  object test does not establish those results.
- V1 activity relays already loaded in app processes need a relaunch to load the
  wakefix4/5 v2 sender. No app is restarted by this work. Process identity is
  not a claim of per-scene touch identity.
- GOFA's proprietary road-alert/turn-value feed remains unconnected and
  unverified. This change does not relabel GPS speed as that feed.

## Verification and export policy

Workflow: `.github/workflows/duoface-172-wakefix5-signed-private.yml`.
It retains the proven regression/build/signing/package-audit pipeline and adds
Foundation harnesses for the shipping ACK policy, bounded request lifecycle and
native-shaped runtime dispatcher. The runtime harness supplies fake native
objects to the same production dispatcher; it does not invoke a physical device.
Source integration checks include negative controls against automatic launch,
unclaimed dispatch, premature lease publication and bypassed request guards.

Only the requested DEB, packaging provenance and explicitly allowlisted aggregate
audit receipts are exported by CI. Detailed binary-derived strings, symbols and
metadata remain private, following the earlier automatic approval rejection of
publishing the full extraction to this public repository. Full audit output is
not redirected into public CI artifacts or logs.

At this checkpoint: `SILEO_PUBLISHED=false`, `installed_by_this_work=false`,
`DEVICE_TESTED=false`. Actual local, CI and complete-package results are recorded
in subsequent receipts rather than inferred from this source checkpoint.


## Local verification checkpoint

The frozen source passed **176 Python tests in 41 suites, zero skipped**,
**8 portable C/C++ runtime programs**, and workflow/build-script syntax checks.
The unchanged tracked GOFA fixture omitted by the sparse checkout was restored
and its exact Git blob verified before testing. See `local-validation.json`
for actual commands, source file hashes and results.

**13 Foundation runtime programs and 2 iOS compile checks remain pending
macOS CI at this checkpoint**. Source review and portable tests do not substitute
for those gates or for a real CarPlay device.
