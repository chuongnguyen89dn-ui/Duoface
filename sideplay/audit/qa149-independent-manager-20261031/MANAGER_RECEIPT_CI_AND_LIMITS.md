# QA149 — Independent live-scene manager receipt and real native Dock entry observation

2026-10-31. Working branch `feature/duoface-qa146-native-home-exit-20261031`. **Source and offline regression progress; not yet vendor-route/device parity or a public Sileo package.**

## Why the code changed (bounded evidence, not guesswork)

- Genuine DuoNavi 1.0.4 `DuoNaviDashboard.dylib` pinned SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`; original route audits (71+71+62 sparse binary checkpoints) record manager activation from view/window startup and manager state publication *before* Dashboard Dock/Home sync. That bounded suffix does **not** depend upon the proprietary QA147 `VerifiedPID` outcome. App process liveness and pixel/touch are separate facts. Original full manager/workspace CFG remains unproven.
- Rejected physical DuoFace Log23 pinned SHA256 `c327274898d8d7285259d4bdbfc04b623a81e3cb6263ccda7ccf948d9cca267d` recorded 26 selected Home requests, 16 live scene observations, **zero** custom hosted+verified-PID outcomes and **zero** native Dock active. This was a hard, observed boundary; it was not proof that `DBAppDockViewController` native setters were defective.
- Earlier QA147/QA148 source correction already makes `DF144Solo.begin` reentrancy-safe, retries real verified SBApplication PID and disambiguates physical Home from watchdog/switch. It did **not** remove the PID requirement before all Dock/Home status updates.
- Apple developer documentation on UIKit scene foreground and background lifecycles confirms they are explicit transitions, not proof of touch or rendered pixels: https://developer.apple.com/documentation/uikit/preparing-your-ui-to-run-in-the-foreground . No legitimate API makes unsupported apps automatically CarPlay-capable; first-party independent host remains a jailbreak-specific experiment.
- A public iOS16.3 DashBoard runtime-header index lists `DBMutableWorkspaceStateChangeRequest`, `DBWorkspace`, `DBAppDockViewController`, but **specific 16.7.16 method argument encodings/receiver identities were not obtained**. The old genuine binary bounded trace proves workspace preparation and conditional phone eviction, but does not authorize blindly constructing requests or calling setters with guessed ABIs. No unsafe native foreground mutation was added this pass.

## Implementation

| File | Behavior and explicit boundaries |
|---|---|
| `DFManagerLifecycle149.h` | New independent C transaction for `pending -> managerActive -> revoke`. Manager receipt requires the actual caller's request identity/freshness and a **live owned scene observation**. A PID observation alone **cannot** activate. Late validated PID is retained separately. Duplicate, stale, terminal and coalesced deliveries have deterministic actions. |
| `DFHomeStandalone144.m` | Only after original `DFSceneHost.isLiveSceneForHostedView`, matching owned bundle and nonhidden CarPlay UIWindow, emit `manager-owned-live-scene-pixels-unverified` once per owner generation. This is deliberately NOT a pixel/touch or PID claim. Continue the independent real-PID retry and optional final hosted+PID event. Revoke manager receipt upon the same live scene loss in the SpringBoard lease heartbeat, even if no PID ever resolved. |
| `DFNativeDockSync147.h` | CarPlay validates exact request/bundle/display, freshness and `DF149Manager` transition; updates actual native `DBAppDockViewController` history, active bundle, refresh and Home state **only after a real live-scene manager receipt**, while preserving older strict positive PID ACK as a fallback when notifications coalesce. Optional PID telemetry does not falsely gate an already-verified live scene/window. On native Dock owner/ABI refusal, revoke the standalone owner rather than leave an unowned overlay. The original physical Home and native switch safety paths remain separate. |
| `DFNativeDockSync147.h` | Added read-only native `_dockButtonPressed:` observer with runtime ABI validation. The original Apple's method is ALWAYS called, no custom Dock launch interception and no substitution of another app icon. The captured button class and any resolved bundle are only diagnostics to verify the real native Dock-to-manager route before implementing a press interception. |

This implements **one missing native manager state boundary**, not a complete DuoNavi clone. The actual native workspace deactivation / phone-foreground eviction continuation, full-root pass-through window ownership, app-side general lifecycle, exact Home previous-page navigation and first-touch/latency are still NOT native-route equivalent. Not claiming `manager-owned` equals Apple workspace ownership.

## Safety/regressions and evidence commands

- Pure C source `tests/manager_lifecycle_149.c`: rejects stale identity/freshness and PID-only acceptance; tests live-scene acceptance, repeated receipt, late PID, coalesced live-scene+PID, terminal restore, replacement generation and synchronous attach failure. A real CI failure exposed an early return dropping the PID in a coalesced manager event, then fixed in `DFManagerLifecycle149.h` commit `e72122c3fdcb904ad8bb445a2bde8ff6cb98d33b`.
- Python tests `tests/test_qa149_manager_live_scene.py`: assert scene-and-bundle gates precede manager receipt, verified PID remains separate, real Dock press wrapper always invokes Apple's original function, no synthetic outcome, original scene host unchanged.
- CI workflow `.github/workflows/duoface-146-native-home-exit-private.yml` runs both new tests before iOS16 rootless signing; fast Ubuntu workflow `duoface-qa147-mount-ready-guards.yml` runs fast regressions. QA145's older single string-label test updated from `previous-live-scene-no-longer-hosted` to `manager-live-scene-revoked`, preserving the exact same safety behavior for a manager-visible scene lacking PID. It previously blocked pre-build; test fixture updated without reverting correct runtime safety.
- Existing `DFSceneHost.m` exact Git blob `ec2924c145be4edaaa27b7320bb869b18de12c6b` **unchanged**, retains QA141/YouTube/GOFA geometry behaviors.
- Historic verification `sideplay/audit/qa147-full-route-evidence-20261031/verify_full_route_evidence.py` pins updated source blobs and adds independent manager receipt and native Dock forwarding checks: **21 static assertions**, not true runtime proof. CI [41205688327](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41205688327): completed SUCCESS; old `41205675514` had a stale 19-check string in the workflow and is not a meaningful new source failure.
- CI fast [41205639637](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41205639637): completed SUCCESS after correcting the coalesced PID case; previous runs `41205560476` (coalesced C assertion) and `41205465448` (outdated QA145 assertion) failed before packaging, now corrected.
- Signed private macOS+iOS workflow [41205639630](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41205639630) initiated on source `e72122c3fdcb904ad8bb445a2bde8ff6cb98d33b` after correcting the C manager FSM; **read live run and repository artifact SHA before claiming build completion**.

```bash
cc -std=c11 -Wall -Wextra -Werror sideplay/duoface-native-scene-host/tests/manager_lifecycle_149.c -o /tmp/manager149
/tmp/manager149
python3 -m unittest discover -s sideplay/duoface-native-scene-host/tests -p 'test_qa149_manager_live_scene.py' -v
python3 -m unittest discover -s sideplay/duoface-native-scene-host/tests -p 'test_qa145_controlled_home.py' -v
python3 sideplay/audit/qa147-full-route-evidence-20261031/verify_full_route_evidence.py --repo .
```

## Remaining gated work (must not overpromise)

1. Obtain exact native `DBMutableWorkspaceStateChangeRequest` and DashBoard workspace receiver method ABIs **on the actual iOS16.7.16 target**, then independently implement and prove workspace foreground deactivate + SpringBoard phone eviction as a transaction with once-only fallback. No guess-based calls to deactivate an unrelated native app.
2. On an opted-in physical diagnostic test, correlate **same RequestID** `qa149-manager-live-scene-owned` → `qa149-manager-result-accepted` → `qa147-native-dock-active` and later optional `qa147-ready-verified-pid`. Check native Dock button argument/provenance and ordinary Apple Home continuation. No positive log yet exists; this new code has not been installed.
3. Confirm native app switching, foreground restoration, genuine previous Home page, correct scene geometry and lower touch region, launch→first-frame/tap latency, reconnect and DuoFace split/YouTube/GOFA regressions before Sileo release. If any ABI fails, retain private staging rather than ship fabricated UI state.

**Deliberately unchanged**: normal supported native CarPlay app launch, original Apple Home handler, the actual pass-through Dock region, existing user consent/default-off, third-party vendor licensing and original vendor DEB payloads. No public Sileo publication authorized by an offline compile alone.

## FINALIZED PRIVATE SIGNED BUILD — verified GitHub evidence (2026-10-31)

- GitHub Actions [41205639630](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41205639630), job `124550044100`, source SHA `e72122c3fdcb904ad8bb445a2bde8ff6cb98d33b`: **COMPLETED SUCCESS**. The job verified C+Python regressions, prepared Theos iOS16 macOS toolchain, compiled independent host and current native Dock receiver, signed the integrated package, uploaded it and archived the exact signed file into DuoFace GitHub.
- Signed private DEB: `sideplay/jb-embedded-appbridge/evidence/runs/41205639630/com.duoface.jb.embedded_0.0.147~native-dock-sync1_iphoneos-arm64.deb`, size **1,170,960 bytes**, SHA256 **`0f1c3a2bd28dbfb05e565e3cebdaa28e035a2ab09c77d4899eaafaad32950c64`**, exact Git blob **`71e03d796d620b5b8e7233b9637d1ced125364b6`**.
- Source + artifact archive was read back on GitHub branch at commit **`45156fa0d722779877d89ad9ac05c9f8af45f2b9`**. Nontruncated Git tree (4411 entries) confirms four files under `evidence/runs/41205639630/`: actual DEB, `SHA256SUMS.txt`, `PACKAGING_PROVENANCE.json`, `CI_RESULT.txt`. The latter explicitly states `SILEO_PUBLISHED=false`, `DEVICE_DIRECT_HOME_TESTED=false`, `STANDALONE_OWNER_FOREGROUND_VERIFIED=false`.
- Actions uploaded private artifact `QA147-private-standalone-signed-UNPUBLISHED` ID **13043869789**, ZIP digest `sha256:bfe8135d562cb626bb4812de0260e3723f9811c4ac059f27c6df2d7a8e4ff95f`. ZIP digest is NOT the internal DEB's hash.
- Source and archived artifact **verified and saved durably in `Duoface`**, not `Gpt-training-` or `carplaydsp`. No Sileo release or physical-car testing has been claimed. The original user-rejected public QA147 is **not** replaced by this unpublished private candidate.

