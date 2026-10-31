# QA151 — Capture the actual CarPlay dashboard workspace owner before the selected app launch

Date: 2026-10-31. Repo `chuongnguyen89dn-ui/Duoface`, branch `feature/duoface-qa146-native-home-exit-20261031`.
Status: **independently written, passive source instrumentation**, NOT full execution parity with original DuoNavi, **no native workspace changes**, NOT device verified / Sileo published.

## Why QA150 could not yet implement the original native workspace transition

QA150 only enumerated `DBWorkspace` and `DBMutableWorkspaceStateChangeRequest` classes and method encodings; it did **not** have the live `DBWorkspace` instance/owner that actually drives the **main dashboard**. A class method's existence does not identify the valid recipient. Original SHA-pinned DuoNavi binary audit (DuoNaviDashboard dylib SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`) established that `closeOfficialTopApp:` submits a native workspace `deactivateApplication:` and asynchronous continuation before the custom bridged app host starts. It did not prove the runtime object's actual class or ABI on iPhone X iOS16.7.16.

**Independent comparable implementation inspected:** [CarSurf `sbtweak/CSCarLaunch.m`](https://github.com/pavunato/carsurf/blob/main/sbtweak/CSCarLaunch.m) on GitHub. It captures the live `DBWorkspace` through `initWithOwner:` and admits only a `DBDashboardWorkspaceOwner`. It explicitly rejects the other instrument-cluster workspace, which may be constructed later, and installs its hook during early process initialization (or load-image callback) rather than at user tap. Its README reports hardware behavior on an iPhone X iOS16.7.12 RootHide; **that is not** our iPhone X 16.7.16 palera1n, and its code is not a vendor DuoNavi reference. We learned architecture/selector candidates only; no CarSurf implementation, license, or vendor bytecode was embedded.

Also checked independent [SpringBoard private declarations](https://github.com/udevsharold/battsafepro/blob/master/SpringBoard-Private.h) and [NoRedirect source](https://github.com/owngoal-dev/NoRedirect/blob/main/NoRedirect.xm) for `SBMainWorkspace` request/transition conditions. These support verifying the **receiver** and entire native transaction rather than invoking random private setters.

## Code changes and exact boundary

- `sideplay/duoface-native-scene-host/DF151WorkspaceOwnerCapture.h` — created commit `db7ee3a220a2137173ee4da31cc3934aa1a6cefd`. Captures **only** `-[DBWorkspace initWithOwner:]` returning a real object **when owner is an instance of `DBDashboardWorkspaceOwner`**. Keeps weak workspace+owner so an already-disconnected CarPlay session cannot be artificially kept alive. Rejects mismatching exact method encoding `@24@0:8@16`, and does not hook unsupported ABIs. Attempts hook early, then retries from `objc_addLoadImageFunc` for dynamically mapped DashBoard classes. The original Apple initializer is **always called** and its result returned; there is no synthetic workspace.
- During a user-enabled, validated *selected* Home app request, read-only `DF151WorkspaceSnapshot` checks actual captured owner and whether `DBDashboardHomeViewController.workspace` (only when its accessor has real object getter ABI) is the same object. Inspects `showingApp` and the real workspace `state.activeBundleIdentifier` only through ABI-checked object getters. Missing getters are recorded as missing, **not guessed** as nil/NO. Writes only `DuoFaceStandalone144.log` with matching request/bundle/display and `qa151-native-workspace-live-owner`. No native activation, deactivate or phone switch.
- `sideplay/duoface-native-scene-host/DFHomeStandalone144.m` updated commit `ef6053b084673e82abacbc3adedd6530448b4d83`, Git blob `a07abf56b5f5dbb749d4bb1c2e838d87c3c85f17`. Calls capture before Home hook installation on CarPlay startup, and records snapshot after the validated request is posted. Existing SpringBoard scene host and source geometry untouched.
- `tests/test_qa151_workspace_owner_capture.py`, commit `32ebedaa9ee9fbc9dcefaf48340a79e19f9189e8`: static invariants on exact ABI / dashboard owner, hook/forward order, load-image fallback, request scope, no workspace mutation, frozen `DFSceneHost.m` blob `ec2924c145be4edaaa27b7320bb869b18de12c6b`.
- Existing scoped and private iOS workflows now require QA151 test, commits `7c7229fa49fb63bad31e0fb823fb2f412c444c48` and `0c75bb216e034426dd55f701104915c8c79c95d7`; no new unrelated feature.
- Historic 10-stage static original-vs-current evidence checker now has 25 assertions with 151 owner-capture source pinned, commit `dc9c549e77c6a9856ffc90ce8645b291b7887880`; CI marker updated `1ec7c144d8665ce4ace2f083bcd1a8a52939f153`. This pins prior Log23 / original binary findings; no new vendor disassembly or physical phone evidence.

## Reproduction and latest measured progress

```bash
python3 -m unittest discover -s sideplay/duoface-native-scene-host/tests -p 'test_qa151_workspace_owner_capture.py' -v
python3 -m unittest discover -s sideplay/duoface-native-scene-host/tests -p 'test_qa150_workspace_preflight.py' -v
python3 sideplay/audit/qa147-full-route-evidence-20261031/verify_full_route_evidence.py --repo .
```

- [Fast QA151 contract CI **41212898487**](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41212898487) **COMPLETED SUCCESS**.
- [Full 25-source-assertion CI **41213017649**](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41213017649) **COMPLETED SUCCESS**. Prior `41212995664` was expected to fail before workflow marker changed from23 to25.
- Private macOS iOS16 signed CI [run **41212885990**](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41212885990), source `0c75bb216e034426dd55f701104915c8c79c95d7`: build was started; **recheck its job, SHA256SUMS, and GitHub artifact archive before stating success**. It supersedes cancelled earlier incremental run `41212829707` (same workflow concurrency).

## Limits and exact next implementation gate

This closes the actual **Dashboard workspace receiver identity gap** before a state-changing native request, not the native preparation itself. On the user's actual iPhone, need correlate:
`qa150-native-workspace-abi` → `qa151-workspace-owner-hook-installed` → `qa151-dashboard-workspace-captured` → `qa151-native-workspace-live-owner`, with RequestID and exact owner role, and match `DBDashboardHomeViewController.workspace` if it exists. If no workspace captured, verify timing of DashBoard image load/hook before blaming the UI. Then implement correct, request-scoped, once-only native `DBMutableWorkspaceStateChangeRequest deactivateApplication:`/completion, SpringBoard conditional phone eviction and symmetric restore **only on actual verified iOS16.7.16 selector ABI**; no unsafe workspace calls before receipts.

No claims of better launch speed, native Dock app history, correct Home return, orientation, touch, or CarPlay state restoration on the phone. Existing public QA147 remains user rejected. No speculative public Sileo update.
