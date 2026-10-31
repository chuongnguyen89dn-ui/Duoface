# QA144 original-DEB complete ownership investigation (read-only)

All five original/reference package binaries have been SHA verified and extracted.
DuoDash is a REPACK, not independently verified stock; Native12 is a derived package.
No original vendor executable ran, no source modification was made, no Sileo release.

## Whole-package original evidence
| Package | SHA256 | Files | Mach-O |
|---|---|---:|---:|
| duonavi | f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd | 50 | 4 |
| native12 | 2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad | 43 | 8 |
| duodash_repack | ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465 | 44 | 4 |
| omnicar | d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd | 176 | 8 |
| sideplay | 7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c | 136 | 7 |

## Actual DuoNavi native Home callbacks — six source code bodies
| Handler | Function start | Direct semantic references |
|---|---|---|
| iconview | 0x311094 | setIcon:, shouldInterceptLaunchForApp:, startBridging:, pending, activated, stopBridging |
| iconview_actions | 0x311238 | setIcon:, shouldInterceptLaunchForApp:, startBridging:, pending, activated, stopBridging |
| icon | 0x311400 | setIcon:, shouldInterceptLaunchForApp:, startBridging:, pending, activated, stopBridging |
| icon_location | 0x3115a4 | setIcon:, shouldInterceptLaunchForApp:, startBridging:, pending, activated, stopBridging |
| icon_location_animated | 0x31176c | setIcon:, shouldInterceptLaunchForApp:, startBridging:, pending, activated, stopBridging |
| icon_alternate | 0x311938 | setIcon:, shouldInterceptLaunchForApp:, startBridging:, pending, activated, stopBridging |

## Evidence interpretation, without speculation
- Native Home registration, Home tap event, per-app bridge request, remote SpringBoard scene host, app-side state, input, Home/Back teardown and native Dock are audited as eight SEPARATE stages in PER_STAGE_OWNERSHIP_MATRIX.json.
- Original DuoNavi Home source references shouldInterceptLaunchForApp: and startBridging: with separate pending/activated/stopBridging markers; actual branch outcome is NOT proven by static selector references.
- DuoDash REPACK has structurally distinct onHostRequest: (single) and onHostRequestSplit: (split). Previous exact IMP archive names functions onHostRequest: 0xf968, onHostRequestSplit: 0xfd90, cnabBuildSceneHostForBid:displaySize: 0x1b7a0; this audit newly checks all actual repack files and module markers.
- QA143 FIRST-PARTY source demonstrably launches the DuoFace native Home icon and calls its DFNative12Chrome slot0 app-picker, so it cannot satisfy direct standalone CarPlay Home launch. The QA144 work branch has excluded that wrong interceptor from future builds.
- Architectural gap: a real separately-owned ONE-APP external CarPlay content surface, and a separately accepted one-app request+readiness/teardown protocol are NOT in the independent code. Original marker existence cannot replace iOS16.7.16 live ABI+scene measurements.
- Full original-device functional parity remains unverified. Do not attempt new Sileo installs until standalone owner exists and passes scene-ready input/teardown gates. Preserve native Apple Dock and all supported apps.

## Files
ALL_FIVE_DEBS_FILES_MACHO_PLISTS_AND_METHODS.json: per-file SHA, binary/class, injected process filters and stage marker evidence.
ORIGINAL_DUONAVI_NATIVE_HOME_TAP_DECODED.json: exact six native ARM64 handler boundaries and resolved selector PC references (no disassembly bytes).
PER_STAGE_OWNERSHIP_MATRIX.json: per-package producer/consumer signal presence (not runtime call traces).
CI_RESULT.txt: exact reproducible run and guarantees.
