# Original app-state route and current readiness boundary

2026-10-31. Continuation of `../original-execution-route-20261031/ROUTE_FINDINGS.md`.
Research checkpoint only: QA147 remains rejected by device Log23. No production source change, new DEB, Sileo release or new physical-device success is claimed.

## Evidence pins and verification

Original dylib SHA256: `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15` (genuine DuoNavi, not renamed DuoDash/repack).
`verify_app_state_route.py` passes **62 sparse static checkpoints**. The earlier 71-checkpoint verifier also remains a separate bounded audit. Counts are verification checkpoints, not complete call-graph edges.

First-party source head: `5d068755742134b9dfb55ccb7d30a73c837d1d77`. GitHub readback matched local Git blobs:

| File under `sideplay/duoface-native-scene-host/` | Git blob |
|---|---|
| DFSceneHost.m | ec2924c145be4edaaa27b7320bb869b18de12c6b |
| DFHomeStandalone144.m | 63b12c0577c0384b779004a216d4782ee7d7661c |
| DFYouTubeOrientationRelay.plist | bb8042a571c2580aa6e84108eee8ed14ba4fb3db |
| DFHostedMapRenderSize.h | dabd6784d94cb7ad5b9f4ad56c123bbd695c22aa |
| build.sh | 172f9d2b9740367c66582d1e976889e828059410 |

## Newly connected original app-side path

| Boundary | Original evidence | What this establishes |
|---|---|---|
| App startup -> listener | Function `313090` caches process bundle via `2ca8f0`, calls `2d02a4` at `313114`. That callback loads CBAppStateListener class ref `3aad58` and calls `sharedInstance` at `2d02bc`. | A real caller of the listener exists; this is not merely an unused class in metadata. Which runtime constructor branch selects this startup still needs full reconstruction. |
| Listener initialization | `CBAppStateListener.init` calls `checkStateFile` at `2cf450`, registers state notification (`2cf4b4`) and didBecomeActive (`2cf4fc`), then requests state (`2cf514`). | Recovery/request path is present when the app starts. |
| Reactivation | `handleAppDidBecomeActive:` calls `checkStateFile` (`2cfcf4`) then tail-calls `sendStateRequest` (`2cfd0c`). | Bringing the phone app active rechecks persisted and current state. |
| App requests current state | `sendStateRequest` builds one-key `bundleIdentifier` dictionary at `2cfb98`, posts via supported distributed notification variants. SB `receivedAppRequestNotification:` obtains bundle, calls `isCurrentlyBridging:` (`26bdf8`), then `sendStateToApp:shouldBridge:` YES (`26be14`) or NO on its inactive branch. | Request/response for the requesting app is distinct from CarPlay manager Dock/Home state response. |
| SB sends app state | In `sendStateToApp:shouldBridge:`, dictionary constructed at `1fb26c` has eight keys (below); send at `1fb358` uses deliverImmediately:YES where supported, fallback `1fb39c`. | App-side layout has an explicit state contract, not just a host-controller resize. The large sender contains other branches; this payload suffix does not prove every call reaches it. |
| Real notification center identity | Legacy dyld bind metadata resolves class ref `3aad20` to `_OBJC_CLASS_$_NSDistributedNotificationCenter`. Both sender (`1fb2d8`) and receiver (`2cf458`) load that class ref before defaultCenter. | Corrects ambiguity from reading zero on-disk imported classrefs: this center is distributed, not an inferred local NSNotificationCenter. |
| Notification name linkage | Sender once block `371da0` -> `26e784`, receiver once block `372410` -> `2d0448`; their encoded 21-byte literals at `342ac0` and `3442ef` are equal, SHA256 `e5f650124701a96531297375cbcffad7bd3b6e544cb040df32236f7ef3971f32`. | Matching encoded literals plus observed initializer structure supports the shared channel. No plaintext decoding or vendor channel reuse is required. Runtime delivery is not proven by byte equality alone. |
| Receive -> apply | `handleAppStateNotification:` compares target bundle with process bundle (`2cfdf0`), reads state fields and supported per-bundle size override, validates state/dimensions, clamps orientation and dispatches block `2d0148` via `dispatch_async` (`2d00d8`). | Actual receiver reads the sender contract and schedules application, with guards. Do not copy opaque token-validation implementation into DuoFace. |
| Active application | Block `2d0148` stores active state (`2d0168`), dimensions (`2d018c`), orientation (`2d0194`), split (`2d019c`), then active branch calls layout routine `2ce094` (`2d01d4`). | These values feed application-side behavior, not just telemetry. |
| Layout + retries | Layout enumerates UIApplication windows (`2ce1c4`), checks window eligibility via `2cc3e4`, applies frame (`2ce714`), bounds (`2ce730`), native window rotation selector (`2ce76c`) and needs-layout (`2ce778`). Active continuation schedules 150ms and 500ms retry blocks `2d0264` / `2d0284`; both recheck active state then branch to layout. Persisted-state path has equivalent retries `2cfae8` / `2cfb08`. | Original initialization accounts for delayed window layout. It does not blindly rewrite every window: eligibility branches remain significant. |
| Inactive restoration | Previously-active -> inactive path tail-calls `2ce8e0` (`2d0250`), which resets active/dimensions/orientation/split and conditionally restores eligible windows (`2cee70`, `2cee8c`). | Symmetric app-side exit is part of the original lifecycle. |

Eight sender payload keys: `shouldBridge`, `bridgeToken`, `fixedKeyboardWidth`, `displayWidth`, `displayHeight`, `orientation`, `isSplit`, `bundleIdentifier`. Persisted-state reader additionally handles `bridgedBundleID`, `activeBridgedBundleIDs` and `size_<bundle>` overrides. The opaque token and validation logic were not reproduced; an independent implementation should define its own ownership/session contract.

Packaged original filter lists **23 bundles**, including YouTube, Google Maps, Waze, VLC, Safari and others. This proves broader shipped coverage than a YouTube-only relay, NOT automatic injection into all arbitrary apps. Dynamic filter expansion/settings behavior is still untraced. The filter list is captured in `APP_STATE_CHECKPOINTS.json`.

## Comparison with current DuoFace

Current packaging explicitly enforces a YouTube-only filter for DFYouTubeOrientationRelay and GOFA-only filter for DFGofaMapResize141 (`package_integrated.py`, lines69–79). There is not yet a demonstrated equivalent shared state listener covering the other enabled app processes. This is a missing demonstrated boundary, not evidence that every native CarPlay app needs iPhone-scene resizing; genuine CarPlay map scenes remain a separate route.

The new evidence DOES NOT justify forcing a landscape orientation or doubling size again. Original host initial reference orientation arguments are1, and current `DFHostedLogicalSizeForBundle` ALREADY uses twice slot width/height. Startup ordering, ownership, native transition and application-side state are the issues to establish.

## Readiness investigation: exact known facts and unknowns

`FIRST_PARTY_BOUNDARIES.json` is generated by a pinned-source audit:

- Scene factory calls `[controller loadViewIfNeeded]` at DFSceneHost.m:882, before surface startup. Original bounded host path puts occlusion/lifecycle flags before obtaining hosted view. In our start, addSubview occurs at356 and automates-lifecycle flag at363.
- Geometry commit gate at433–435 rejects before `ready`; original bounded startup sets reference sizes before finishing parent containment. This mismatch is confirmed; it is only a candidate explanation for attach failures, not a proven throw site.
- Host `pollScene` sets ready and posts the notification once per observed hosting generation (727). Standalone `sceneReady:` (337–346) then independently checks matching surface, visible window, live owner, matching bundle, verified PID and duplicate status. No branch-specific rejection logs exist.
- There are TWO PID reads in the standalone source: the readiness callback (342) and result serialization (229). Reading PID in `reply:` does not promote `pending` to a successful ready outcome. A late PID is a plausible missed-ACK scenario because no readiness retry is scheduled; actual late-PID causation remains unmeasured.
- `begin:` sets self.surface then adds the surface at319, which synchronously invokes UIKit window-attachment/start callbacks; after that returns it unconditionally writes pending at320. A nested attach failure can already have stopped/cleared the owner. Log23 confirms eight attach exceptions followed by null-identity pending. The same ordering also permits a successful synchronous ready result to be overwritten by pending; that success-overwrite scenario is a structural risk, NOT demonstrated in Log23 (which logged zero successful ready outcomes).
- Log23's 16 host-ready observations and zero standalone-ready ACKs establish a failed boundary; without rejection telemetry they do not identify which readiness predicate failed. Preserve real ownership and PID checks until the failure is measured.

## Next concrete implementation boundary

Do not release another isolated Dock-only patch. Implement and measure the independently owned manager transaction around native app preparation, eviction, host startup, shared app-side state/recovery, manager response, native Dock/Home state and teardown. Before a device build, identify each startup operation in exception diagnostics, log individual ready rejection predicates, distinguish pending expiry from host lifetime and prevent a completed/failed launch from writing stale pending. Retrying the exact ready outcome requires retained matching request/bundle/display/generation and live ownership, not a fabricated ACK.

Still unproven: full manager request CFG; selection of app startup/Home hook variants on this iOS; all window eligibility/restore conditions; opaque state validity branches; actual original process-to-process delivery; pixels, orientation, touch latency and native Home destination on the user's device.

## Reproduce

Python and capstone5.0.7; same recovery-branch metadata parser as prior audit, SHA256 `13e1de1371d02f22b3749878ad5ea1134b630616e82f823c2fef72f25b0eb9ed`.

```bash
python verify_app_state_route.py --binary /path/to/DuoNaviDashboard.dylib --parser /path/to/audit_native12_license_class_xrefs.py --filter /path/to/DuoNaviDashboard.plist > APP_STATE_CHECKPOINTS.json
python audit_first_party_boundaries.py --repo /path/to/Duoface > FIRST_PARTY_BOUNDARIES.json
```

`macho_bind_metadata.py` is independently written metadata parsing code, not vendor logic. It decodes legacy bind records with 64-bit wrapping address arithmetic, validates mapped addresses, and rejects unsupported formats; it does not load an image. Reference constants: https://www.llvm.org/doxygen/BinaryFormat_2MachO_8h_source.html (BindOpcode enum). Sparse call checks carry manually verified semantic annotations; they are not automatic proof of complete receiver dataflow or runtime equivalence.
