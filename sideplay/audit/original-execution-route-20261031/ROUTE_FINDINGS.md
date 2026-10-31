# Original execution route: verified checkpoints and remaining gaps

Date: 2026-10-31. Status: static reconstruction, NOT runtime parity or a release.

The user's criterion is the same lifecycle/execution route, independently implemented. QA147 does not meet that criterion yet. Matching Dock setters alone did not establish it. QA147 remains rejected based on Log23; no QA148 was built or published in this investigation.

## Evidence scope

Original DEB SHA256: `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`.
Original DuoNaviDashboard.dylib SHA256: `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`.
All addresses below are unslid ARM64 virtual addresses in this exact dylib. Read-only metadata/disassembly, no execution of vendor code and no vendor implementation copied into DuoFace. Methods can contain unrelated/license callees; these were not followed or reproduced.

DuoFace comparison: feature head `a3dec1d9bc62dcafac4d34fff3988e886493bc47`, `DFSceneHost.m` Git blob `ec2924c145be4edaaa27b7320bb869b18de12c6b` (local content hash matched connector readback). Existing Log23 findings remain in `../qa147-user-log23-failure-20261031/`.

## Route reconstructed so far

| Stage | Verified original evidence | Implication / boundary |
|---|---|---|
| Home app entry | `SBHIconManager launchIconForIconView:` hook registration `2f5848`, replacement `2f6410`, intercepted launch calls `startBridging:` at `2f64b0`. Another registration is `_CARDashboardHomeViewController iconManager:launchIconForIconView:` at `310858`, replacement `311094`. | Genuine bridge entry is integrated into Home launch. All DB/CAR variants and which one runs on the user's iOS still need complete mapping. |
| Dock entry | `DBAppDockViewController _dockButtonPressed:` registration `30f360`, replacement `30f8f4`; intercepted app calls `handleDockIconTap:` at `30f99c`. Non-intercepted app forwards Apple only when manager is not pending (`30fa08`). | QA147's active-bundle setter hook does not provide this Dock tap-to-manager route. |
| Pending | `startBridging:withCompletion:` saves completion at `2c5d18`, prepares at `2c5d2c`; `prepareAndRequestActivation:` refuses duplicate pending work and sets pending. | There is a manager transaction before the scene host. |
| Pending expiry | Timeout block `2c5ebc`, scheduled after 2.5 s, clears pending and pending completion. | This bounded timeout does NOT dismiss/stop the host. It is different from QA147's 10 s pending watchdog. Do not infer every Log23 stop was a watchdog. |
| Native foreground preparation | `prepareHomeScreenForBridge:` asks `showingApp`; if true, `closeOfficialTopApp:` gets foreground scene/application and submits `DBMutableWorkspaceStateChangeRequest`, `deactivateApplication:` (`2c6358`), `setCompletionHandler:` (`2c6388`), workspace `requestStateChange:` (`2c6398`). | Native workspace preparation precedes the activation continuation. A shared once-wrapper `2c6124` also has a 250 ms fallback; this does not guarantee workspace completion before activation. |
| Activation continuation | Block `2c5f28` captures manager/bundle and tail-calls `requestActivation:`. Activation request contains source, activate, bundleIdentifier, appFrameX/Y/W/H. | Frame and selected bundle are part of the request transaction. |
| Cross-process request | Dashboard `requestStateChange:` posts local notification, writes request dictionaries to two paths and posts Darwin notification. SB local receiver dispatches block `26c778` to `requestStateChangeWithDictionary:`; Darwin callback `1f2f20` dispatches main block `26da90`, which reads the request files. | Runtime-initialized on-disk zero globals are UNKNOWN, not nil. Encoded path literals match sender/receiver, but this investigation does not claim plaintext channel decoding. |
| SB request manager | `CBBridgeRequest initWithDictionary:` at `15b534`, manager `requestStateChange:` at `15b54c`; manager also has `loadNewAppFromCurrentRequest:`. | Exact branches inside the large requestStateChange method have not all been reconstructed. Do not claim every request reaches host creation. |
| Remove app from phone | `loadNewAppFromCurrentRequest:` constructs stack block with invoke `18c708` at `179cb0`; captures manager at block+32 (`179cc8`), passes block as completion (`179ce4`) to `evictAppFromPhoneScreen:completion:` (`179cec`). | This proves the host continuation is attached to the phone-screen eviction operation, beyond merely finding similar selector names. |
| Eviction completion | `evictAppFromPhoneScreen:completion:` checks foreground bundle, uses `SBUIController clickedMenuButton` where supported and `SBMainWorkspace` / `SBHomeScreenEntity`; transition request supports context modification (`setActivatingEntity:`), completion block or completion handler and execution. Wrapper `26d838` is once-only; fallback `26d908` scheduled after 120 ms invokes it. Some branches call the supplied completion directly. | It is a conditional native transition route with bounded fallback, not a universal wait-for-success guarantee. |
| Construct / start host | In callback `18c708`, `192820` advances block pointer by32 and loads captured manager. `appForBundleIdentifier:frame:` at `192a90`, regular fallback class `CBBridgedUIApp`; app state `shouldBridge:YES` at `192db4` on the shown non-split branch; start-in-parent `192e10` or start `192e20`; window show `192e34`; manager notify `192e44`. | Verified continuation and local suffix. Large callback contains other branches; this is not a complete CFG. |
| Nested host start | `CBBridgedUIApp startInParentViewController:` sets hosted-view frame at `f2fec` and calls its start-in-parent at `f3000`. `CBBridgedUIAppView startInParentViewController:` begins `add08`. | Outer app, view host and manager are separate lifecycle participants. |
| State response | `notifyStateUpdated` builds `activated` and `bundleIdentifier` dictionary (`26ca6c`) and posts state. Dashboard response block `2c6f74` calls `handleStateDict:`; clears pending (`2c6fbc`), dispatches `bridgeDidActivate:` (`2c7034`) or deactivate (`2c7050`), then consumes completion. | Original Dock/Home follows manager state. This response path does not use our custom scene-ready + PID ACK. This does not prove absence of all PID checks elsewhere. |
| Dock/Home update | `bridgeDidActivate:` sets activated, native Dock active/history/refresh and Home in-app state; deactivate performs inverse. Exact setter arguments already recorded in `../qa147-native-dock-sync-20261031/`. | Calling these APIs in isolation is not proof of the preceding route. |
| Home exit | `DBRootStatusBarViewController homeButtonUp:` replacement `30f4d4` calls manager stop at `30f5a0` if activated, then forwards saved Apple implementation unconditionally at `30f5c0`. | CORRECTION: forwarding Apple Home alone cannot explain our wrong destination, because the genuine implementation also forwards. Need whole stop/native workspace state transition. |
| SB teardown | `deactivateCurrentApp`: app-side shouldBridge:NO, hosted app stop (`1bef84`), remove view, destroy windows (`1befe4`), clear activated/bundle and notify (`1bf010`). | Full teardown/state publication matters before assessing Home behavior. |

## Host initialization order: concrete difference from QA147

The original bounded `CBBridgedUIAppView.startInParentViewController:` has this observed order:

1. Create application scene entity / host controller with supported initializer variants; add child controller.
2. Set ignores-occlusions YES (`ae228`) and automates-lifecycle NO (`ae254`).
3. Calculate native size from slot bounds (`ae278`). `calculateNativeSizeForSlotRect:` at `ac788` doubles positive slot width/height, converts through float and rounds away from zero at ties. Fallback uses doubled usable CarPlay bounds.
4. Obtain hosted controller view (`ae2d8`), request mode (`ae310`), construct wrapper/view hierarchy.
5. Set child reference size through TWO INDEPENDENT supported-selector guards (`ae61c`, `ae658`), then main controller (`ae690`), using the computed native size. All three orientation arguments here are 1; do not replace them with landscape based only on display shape.
6. Finish parent containment (`ae9c8`), update layout (`ae9d8`).

Current first-party `DFSceneHost.m` adds `appController.view` as a subview at line356 BEFORE flags at362–363. It defers initial reference-size setters until readiness: `commitSceneGeometry:` returns when `!self.ready` (430–435), also using a 300 ms timer. Therefore initialization timing/order differs, even though many selectors and portrait arguments match. This may contribute to Log23 attach exceptions (`bogus reference size`) or a readiness deadlock; causation and the exact Apple throw site are NOT established. Do not simply remove ownership/PID checks or fabricate readiness.

## What is still unproven

- Complete request-manager CFG, split/special-app branches, cancellation and replacement concurrency.
- Every Home/Dock hook variant selected on actual iOS16; precise native Home destination after original teardown.
- Full app-side receiver of `sendStateToApp:shouldBridge:` and its layout/orientation/window restoration. Sender alone is not end-to-end proof.
- Exact rejection predicate that prevents QA147 ready ACK, PID arrival timing and the exception's throwing receiver/call.
- Original/independent runtime traces on the same device, pixel orientation, touch latency and Dock correctness.

Next implementation work should first establish an independently owned manager transaction and preserve its order: native preparation, SB app eviction, host initialization, manager state publication, native Dock/Home update and complete teardown. Instrument individual startup stages/exception receiver and readiness predicates before any new device build. Pending timeout must not be confused with host lifetime. Do not ship a Dock-only or timeout-only patch as route parity.

## Reproduce checkpoint verification

Use Python with `capstone==5.0.7`. The metadata parser already exists in the project's `feature/visual12-duodash-recovery` under `migration/full_payload/native_test/audit_native12_license_class_xrefs.py`; only its MachO/select_arm64 metadata APIs are used. Parser SHA256 used here: `13e1de1371d02f22b3749878ad5ea1134b630616e82f823c2fef72f25b0eb9ed`.

```bash
python verify_route_checkpoints.py --binary /path/to/original/DuoNaviDashboard.dylib --parser /path/to/audit_native12_license_class_xrefs.py > VERIFIED_CHECKPOINTS.json
```

The script asserts the binary pin, sparse instruction/call-site facts, selector references and encoded-literal equality. Its named annotations record bounded manual tracing; it does not automatically infer all receivers, execute methods, establish complete reachability or prove runtime parity. No entire vendor disassembly is saved. Apple block layout reference: https://clang.llvm.org/docs/Block-ABI-Apple.html (64-bit invoke at+16; captures from+32).
