# QA172 wakefix5 — guarded explicit native-map launch

**Verified candidate: source checks, macOS runtime gates, iOS compilation,
signed build, complete-package audit, baseline comparison and independent
binary linkage review passed. Physical iPhone/CarPlay acceptance is pending.**

This continues the user-authorized sideplay repair on
`feature/sideplay-native-launch-wakefix5-20261106`, based on completed wakefix4
head `0a75a3f4f1d943e64deb50a3945cc80630e67e74`. The signed wakefix4 candidate
remains immutable. Native host version is `0.1.172~wakefix5`; integrated package
version is `0.0.172~wakefix5`.

- [Draft PR #2](https://github.com/chuongnguyen89dn-ui/Duoface/pull/2).
- Built source: `88702ca96c122c81d06b44032d0e51f41249bc17`.
- [Successful CI run 42122359843](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/42122359843); all 15 job steps passed.
- Archive commit: `9f3b6e37f64920e425bf63e31bd106498aa4d7a0`.
- DEB: `com.duoface.jb.embedded_0.0.172~wakefix5_iphoneos-arm64.deb`, 1,281,620 bytes.
- SHA256: `90efffed61ee5a1a44db3e0371f9d205a54cdb3b55a76cc5ec27f63d26f12d47`.

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

| Source-level problem | Candidate behavior |
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

## Verification

The final CI ran on the standard `macos-15-intel` runner, targeting
`arm64-apple-ios16.0`. The runtime harness supplies fake native objects to the
same production dispatcher; it does not invoke a physical CarPlay device.

| Gate | Actual result |
| --- | ---: |
| Python regression tests | 176 / 41 suites; 0 skipped |
| Portable C/C++ runtime programs | 8 passed |
| Objective-C/Foundation runtime programs | 13 passed |
| iOS compile-check steps | 2 passed |
| Signed build, assembly and full package audit | Passed |
| wakefix4 → wakefix5 comparison | 39/39 passed |
| Independent direct-byte linkage review | 21/21 passed |

The new runtime programs recorded **118 ACK assertions, 240 pending-policy
assertions and 464 native-dispatch assertions**. Retained programs recorded
79 keyboard, 108 app-activity, 25 restoration and 30 physical-binding assertions.

The full DEB scan covered all **40 payload + 3 control files**,
57 tar entries, 11 Mach-O images / 14 slices and
28 CodeDirectories. All **1,292/1,292 CodeDirectory page-hash
entries** match; this is not a count of unique physical code pages.

Seven binary hashes changed. The only changed nonbinary content is the expected
control `Version` field. Paths, modes, owners, resources, scripts, filters,
architectures, dependency load contracts, install IDs, iOS minima, toolchain
metadata and entitlements remain unchanged. The separate linkage parser confirms
the context class and all four versioned helper exports are defined only in Dock;
Map resolves them dynamically without a hard Map → Dock dependency.

The downloaded ZIP matches GitHub's artifact SHA256. The DEB matches packaging
provenance and the archived Git blob byte-for-byte; the archive contains only its
five expected deliverable/receipt files.

## CI follow-up history

The initial source attempt, run `42119125234`, received no runner and executed
zero steps; the run ended in failure with the job cancelled. The queue cause was
not established. The workflow was moved once to the documented standard Intel
runner, preserving its steps and the arm64 iOS 16 product target.

Run `42121665247` then exposed a genuine compile failure in the new ACK test:
its helper named `read` collided with POSIX `read` included through Foundation.
Renaming that test helper to `DFTestReadAck` fixed the collision without changing
the production policy or weakening the assertions. Final run `42122359843`
passed the actual Foundation, iOS, build, signature and package gates.

## Evidence and export policy

`local-validation.json` preserves the original local-run evidence and records
its later CI resolution. `ci-validation.json` is the final actual CI/artifact
receipt. `candidate-comparison-summary.json` contains aggregate comparison
results. The detailed full-package and independent-linkage reports remain private.

Public exports are limited to the requested DEB, existing packaging provenance
and explicitly allowlisted aggregate receipts. Full binary-derived strings,
symbols and metadata are not exported through the repository, CI artifacts or
CI audit logs.

`SILEO_PUBLISHED=false`, `installed_by_this_work=false`, `DEVICE_TESTED=false`.
The draft PR has not been merged. Internal signature hash agreement does not
establish Apple trust-chain or AMFI acceptance, and a Foundation fake-object test
does not establish rendering, touch, navigation or physical scene lifetime.
