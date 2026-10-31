# QA142 — DuoNavi 1.0.4 and DuoDash 1.1.3: evidence-based Home launch comparison

Checked 2026-10-31 against the DuoFace QA141 source and saved SHA-pinned binary audit outputs. Research-only checkpoint; **no source runtime modification, QA142 build, Sileo update, or device test**.

## Provenance (do not conflate)

- **DuoNavi original 1.0.4**: `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb`, SHA256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`; Dashboard dylib SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`.
- **DuoDash 1.1.3 Fullscreen427 REPACK** (not pristine stock): `chuongnguyen89dn-ui/DauDat-CarPlay/main:DuoDash_1.1.3_Fullscreen427_iphoneos-arm64.deb`, SHA256 `ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465`; dylib SHA256 `b41dd7f892bfd3722e95a40f764a989886078b4a30943c1f0b50d47b6e248a47`. Historic stock hash `16ffab22b4246dea9978cae92df7ec635d833ec067b4d9f425a231b26edec601`, bytes not available in verified input. **Never assert the repack is vendor stock.**
- Actual prior reproducible binary scans: Actions `40445716116` (selected ARM64 bridge IMPs), `41157922214` (both package filters/Home markers), and `41088923434` (original DuoNavi Home semantic callsites, Native12-derived comparison), plus current Log20 report `sideplay/audit/qa142-log20-home-launch-20261031/REPORT.md`.

## 1. Distinct stages observed in real original binaries

| Responsibility | DuoNavi original evidence | DuoDash repack evidence | QA141 current state |
| --- | --- | --- | --- |
| Make selected app appear on native Home | CARApplication `_newApplicationLibrary`, FBS library, DBApplicationInfo, CR declaration, original native catalog merge | Same class/selector **strings present**, bundle filters CarPlay/CarPlayApp/SpringBoard; no exact DuoDash Home IMP graph established | **Device success:** 6 selected Home icons visible; 6 declaration get-readbacks and 8 CR policy callbacks in Log20 |
| Handle tapping native Home icon | Actual Dashboard dylib 0x3110f4 / 0x311144 etc references `shouldInterceptLaunchForApp:` then `startBridging:`, later `pending`, `activated`, `stopBridging` across several `iconManager:launchIcon...` variants | Home-oriented symbols exist; the direct native Home tap-handler-to-observer execution graph is **NOT yet proven** from repack | No first-party selected Home icon tap callback nor verified scene activation |
| Scene host/launch broker | CBBridgeManager/CBBridgedUIAppView selected original IMPs coordinate scene, layout, lifecycle | `CNABSpringBoardObserver.onHostRequest:` @0xf968; split @0xfd90; `DDz2.cnabBuildSceneHostForBid:displaySize:` @0x1b7a0 creates SBDeviceApplicationSceneEntity/SBAppViewController, mode2 | Current pane scene host exists, but no Home icon -> broker routing contract |
| App-side scene state | Original CBBridgedUIAppView updates content size, scene settings and foreground | `CNABUIApp.setBridgeState:width:height:orientation:` @0x1f514; `DDz1.showLayoutPanes:natives:bids:` @0x1543c | No validated roundtrip from Home tap to app-side ready acknowledgement |

This crosswalk is **structural static evidence**, not a claim original DuoDash/Home callback was executed on the user's phone. DuoNavi tap method addresses refer only to the SHA-pinned original dylib, not a hook target on iOS16.

## 2. What current device Log20 resolves

- QA141 CarPlay PID 92302: **six selected ordinary apps** have `declaration-attached ... getterReadback=1` and `newRecords=6`. There are eight selected policy callbacks. Thus the former “icons never appear” failure is resolved on the user device.
- The user confirms **tapping an icon does not open the selected app**. No measured Home tap handler invocation, launch broker request, system launch error, or completed scene activation exists in exported Log20.
- The QA141 `launch=0` log field means `setLaunchAsCarApplication:` setter ABI was unavailable / invocation not performed; it is **not** a measured false policy readback and cannot be declared the root cause.
- GOFA same-PID current 9 direct ACK samples: wrapper + Mapbox + Metal view widths all match the window (793/1190/793/595/397/397/703/703/519 at height 685); 0 stale-size mismatches. Visual correction remains unconfirmed by user.

## 3. Exact next implementation and proof gate

1. On the iOS16.7.16 CarPlay owner, identify current **real** Home icon manager class, selector type encodings and selected bundle extraction. Prior runtime reports `_CARDashboardHomeViewController` absent: **do not hook it by name** merely because original DuoNavi references it. Introspection/trace must be original-first and fail closed.
2. Observe one **explicit user tap** and distinguish native/unselected vs selected; native forwards unchanged. Only selected + installed + opted-in goes through a new independently written first-party broker request with unique generation, bundle, launch outcome and Home/Back teardown.
3. Reuse the existing DuoFace scene owner only after verifying a real accepted host scene, not by forging a path, URL scheme, entitlement, frame/foreground write, or blanket hook. Include timeout and rollback on failure without changing native Home.
4. Test exact first-party handler model (native passthrough, selected once, disabled, missing class, exception, stale generation). Then signed CI/DEB, Sileo SHA, finally real CarPlay Home tap -> live app scene, GOFA split/solo, YouTube touch/rotation, lock, Dock and reconnect.

**Result of this checkpoint:** DuoNavi's native tap-to-bridge chain has concrete selector/callsite evidence; DuoDash's separately owned host/app IPC is concretely decoded but its **native icon tap** remains a real evidence gap. QA141 has only completed the first of these stages. Further logging or changing GOFA frames cannot substitute for the missing launch contract. No proprietary implementation or licensing was copied.
