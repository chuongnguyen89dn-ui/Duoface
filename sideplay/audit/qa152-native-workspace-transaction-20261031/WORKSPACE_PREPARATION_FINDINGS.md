# QA152 — Genuine native Dashboard workspace preparation before remote scene request (independent implementation)

Date: 2026-10-31. Branch `feature/duoface-qa146-native-home-exit-20261031` in `chuongnguyen89dn-ui/Duoface`.

## Scope and evidence

This adds a **conditional native state-changing step**, unlike the QA150/151 read-only probes. It is **not** a claim of runtime correctness on iPhone X iOS16.7.16 or full proprietary DuoNavi parity. The app selection is already user-opted-in; no activation occurs for unsupported/existing native CarPlay apps outside this existing gate.

The pinned original DuoNaviDashboard dylib SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15` has a bounded native prefix: `prepareHomeScreenForBridge:` checks current app, `closeOfficialTopApp:` uses `DBMutableWorkspaceStateChangeRequest.deactivateApplication:` and `setCompletionHandler:` then `DBWorkspace.requestStateChange:`, and a **250ms once-only continuation** starts the custom bridge. The independently inspected [CarSurf `CSCarLaunch.m`](https://github.com/pavunato/carsurf/blob/main/sbtweak/CSCarLaunch.m) corroborates that DashBoard maintains separate dashboard vs instrument-cluster `DBWorkspace` and that workspace requests must use the **actual dashboard-owned instance**. Neither source proves the actual device's method encoding, nor did we transplant their source/permissions.

## Exact changes committed

- `sideplay/duoface-native-scene-host/DFNativePrepOnce152.h`, commit `d811df8267e29c220376bb53fba9356b54dfad84`: first-party C generation gate for one logical continuation per request, stale completion and cancelled Home/switch rejection.
- `sideplay/duoface-native-scene-host/DF152NativeWorkspacePrepare.h`, commit `5fc56b6a4ecb3d75f33b3bab404656b46846dbfd`: runtime-ABI-checked **optional native deactivation of the actual currently visible official app**, before issuing the remote SpringBoard request. It requires, all at once: actual weak live `DBDashboardWorkspaceOwner` + captured Dashboard workspace + same object from the Home `workspace` getter, supported BOOL `showingApp` ABI with true result, native workspace `state.activeBundleIdentifier` as a nonempty distinct bundle, matching bundle object via `DBApplicationController.sharedInstance applicationWithBundleIdentifier:`, matching `bundleIdentifier` of that object, exact supported `requestStateChange:`, `deactivateApplication:`, `setCompletionHandler:` method encodings. **Any unknown or unsupported ABI, incomplete owner, wrong app or nil request performs NO native mutation** and resumes older native-independent scene path with a precise logged refusal.
- Only the validated native path constructs a genuine `DBMutableWorkspaceStateChangeRequest`, deactivates the verified official app, installs a completion callback and asks the **actual captured DBWorkspace** for `requestStateChange:`. Both Apple's actual completion and a 250ms fallback go through the same first-party `DF152FinishOnce` gate; exactly one can continue, and a replaced or revoked request is ignored.
- `sideplay/duoface-native-scene-host/DFHomeStandalone144.m`, commit `3d58d6f6ecb161c7551437169de406e0c20fdc2a`: CarPlay selected native Home path now enqueues a real SpringBoard scene IPC **after** the bounded native workspace phase, not before. The posted request must still match current RequestID/bundle/display, live SpringBoard receiver, explicit opt-in, CarPlay content window and native pending generation. Any replaced/revoked owner drops the pending request. Physical native Home return revokes the in-flight workspace continuation before sending its existing stop notification. Original Apple Home forward and regular app entry remain unchanged.
- Tests `tests/native_workspace_once_152.c` (commit `592e92fe3fcf1ce0c45a10458fb508b584f6f522`) cover synchronous callback + late fallback, fallback + late callback, stale request, cancellation and newer generation. Python `tests/test_qa152_workspace_prepare.py` (commit `0c960b3ca85148700cf739236b56cad890e4071d`) covers exact owner/ABI/callee guard ordering, session identity, native-before-remote ordering, Home cancellation and frozen scene-host.
- Legacy QA150/151 source assertions were updated to reflect **native workspace snapshot now precedes** the deferred SpringBoard request; their earlier positional checks were for the old QA151 immediate-notification route. Commits `60abdc153457cd7cd8e8d7328eb5150690e10ec1`, `c6df3da4e69fe699ead716854e398dbac97f435a`; old pre-build failure `41213847732` was a stale QA150 source test, not a native Objective-C crash.
- Workflow `.github/workflows/duoface-qa147-mount-ready-guards.yml` updated `f55e559436b6c07ce9fa8cb4839270790d42d877`; signed PRIVATE workflow `.github/workflows/duoface-146-native-home-exit-private.yml` updated `e714f4fcbdeda35530753c4ded66ff9873736c88`. New C/Python tests run before expensive iOS native compilation. No public Sileo trigger.
- Historical original+Log23 static checker `sideplay/audit/qa147-full-route-evidence-20261031/verify_full_route_evidence.py` re-pinned to source and extended to 27 checks, commit `8d8c40c4b1e8d8df210a963b543e08d3f69ad87d` with workflow marker `be3b5526c565890ad0c0f8c1f43e6feec2be6778`. The original binary and physical Log23 are **NOT re-run** by this checker.

## Testing and current boundary

- Source-bound fast C/Python guards [Actions 41213973275](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41213973275): **SUCCESS**, including once-only C and Python native-preparation order. Tests are not device execution.
- Pinned 27-check historical/source audit [Actions 41214067398](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41214067398): **SUCCESS**. The earlier `41214050252` failed before updating the grep marker 25→27.
- macOS iOS16 rootless private build [Actions 41213982305](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41213982305) has been triggered with commit `e714f4fcbdeda35530753c4ded66ff9873736c88`; read its **actual conclusion**, signed SHA256 and archived file before claiming completed. Earlier concurrent runs cancelled by the private workflow's `cancel-in-progress` behavior.

Reproduce:
```bash
cc -std=c11 -Wall -Wextra -Werror sideplay/duoface-native-scene-host/tests/native_workspace_once_152.c -o /tmp/workspace152
/tmp/workspace152
python3 -m unittest discover -s sideplay/duoface-native-scene-host/tests -p 'test_qa152_workspace_prepare.py' -v
python3 sideplay/audit/qa147-full-route-evidence-20261031/verify_full_route_evidence.py --repo .
```

## Explicit remaining blockers and safety

- **Not yet implemented**: first-party SpringBoard native *phone* foreground eviction before hosted scene creation, general app-side role/geometry state distribution, full native Dock press-to-manager routing, and symmetric full app state restoration. No fake success/PID/pixels/touch, no vendor license.
- Native workspace method encodings and whether the captured owner survives on the user's specific iOS16.7.16 remain **unverified**. Only physical device trace can establish that `qa152-native-workspace-deactivate-request` really occurs and completes. When guards fail the code falls back to the earlier path rather than blindly sending private messages.
- Full integration is **not** yet physically QA-tested for Home destination, launch latency, native Dock, GOFA/YouTube layout, touch region, disconnect or reconnect. Keeping Sileo unpublished avoids another unsupported trial.
- Original Apple Home callback, existing CarPlay-supported app route, DuoFace split, and byte-exact `DFSceneHost.m` Git blob `ec2924c145be4edaaa27b7320bb869b18de12c6b` stay intact.

Next exact action: verify new owner / ABI / operation / completion markers on an opted-in physical iPhone run. Then implement independent SpringBoard phone-foreground eviction with actual verified transition recipient and once-only 120ms fallback before creating the hosted scene. No blind `SBUIController` or `SBMainWorkspace` selector calls.

## FINALIZED signed offline candidate — read back from GitHub

- macOS iOS16 rootless CI [run **41213982305**](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41213982305), job `124574651259` **completed SUCCESS** on source commit `e714f4fcbdeda35530753c4ded66ff9873736c88`. Regression suite, native Objective-C compile, original baseline dependency builds, ldid signatures, integrated private DEB packaging, artifact upload and GitHub archive all succeeded.
- Exact **PRIVATE UNPUBLISHED** integrated DEB: `sideplay/jb-embedded-appbridge/evidence/runs/41213982305/com.duoface.jb.embedded_0.0.147~native-dock-sync1_iphoneos-arm64.deb`, Git tree size **1,176,064 bytes**, Git blob SHA1 **`be99c50c758fec2e92db98f110d153e48e37be7d`**, internal SHA256 **`6e0e5df8fe1c324e4b47bbe7c93202a7cad58eff1c89c300ef7e0a023177921b`**.
- `SHA256SUMS.txt` and `PACKAGING_PROVENANCE.json` both contain the exact SHA256 above, and `CI_RESULT.txt` confirms `BUILD=success`, `SIGNED=true`, `SOURCE_SHA=e714f4fcbdeda35530753c4ded66ff9873736c88`, **`SILEO_PUBLISHED=false`**, **`DEVICE_DIRECT_HOME_TESTED=false`**, `HOME_STANDALONE_OPTIN_DEFAULT_OFF=true`.
- Verified all four run files in **nontruncated** GitHub tree at archive head **`deb079b7ce229c172673e575d95a66c2802ae825`** (binary, SHA, provenance, CI). Actions private ZIP artifact ID `13047681846` (archive SHA256 `afd55c002e406698c64e127405f85d66a55c9f536e5160039a16ef20259b6658` is **not** the internal DEB hash).
- The signed iOS binary and static tests passed, but the **native state-changing branch has not been run on the user's CarPlay device**. Target-specific method encodings and owner identity remain dependent on actual device trace; absence of a physical QA run prohibits stating that Home, Dock, launch latency, touch and rotation work.
