# QA163 – ma trận kiểm thử hiển thị Speed8 toàn CarPlay

## Exact delivery verified on GitHub
- Source branch `feature/duoface-qa163-global-speed8-20261101`; compiled SHA `774364911eb3d9a765890a1d5bfaa08921e7443e`.
- Build/sign/packaging private CI `41302551181`: COMPLETED SUCCESS; one package `com.duoface.jb.embedded_0.0.163~globalspeed8test1_iphoneos-arm64.deb` in `sideplay/jb-embedded-appbridge/evidence/runs/41302551181/`; SHA256 `332ec6a8e490bbb5e5048bb78c51a8327724c2daf02f147a2f773c7a7d2d3c55`.
- Existing Sileo repo `chuongnguyen89dn-ui/carplaydsp`, workflow `.github/workflows/build.yml` source commit `0b6aaa96ad596d0badf514990aaa2986cc3c40b1`. YAML validator `41302983264` SUCCESS. Build/publish/deploy+public-download verification `41302983199` COMPLETED SUCCESS, jobs `build`, `deploy`, `verify-duoface-integrated-pages`, `verify-duonavi-observer-pages`, `verify-qa11-pages` all SUCCESS. Public `Packages`: **one latest DuoFace entry QA163**; binary checksum matches SHA; QA162 and QA161 binary rollback preserved. No new Sileo repo.
- **This is only code/signing/public APT proof, NOT real CarPlay HUD visibility**; no physical log/screenshot available.

## Display contexts to check (all currently UNTESTED PHYSICAL)
| ID | Display mode | Expected after QA163 change | Evidence required |
|---|---|---|---|
| CP1 | DuoFace split with **GOFA** in pane | One Speed8 overlay, independent of chosen pane | Photo, app actual package version, log |
| CP2 | DuoFace split with **YouTube** + Facebook, no GOFA pane | One Speed8 overlay; value may be `—` if GOFA GPS publisher absent | Photo, native/SB process logs, touch test |
| CP3 | DuoFace SOLO Facebook or YouTube | One Speed8 overlay; app content and swipe/tap continue working | Photo, touch and focus result |
| CP4 | DuoFace empty pane or app picker | One Speed8 overlay on visible source-owned pane if Chrome active; no blocking App picker | Photo, tap |
| CP5 | Native CarPlay Dashboard/Home (DuoFace hidden/exited) | One Speed8 overlay **only if actual native external UIWindow available** | Screenshot + native owner log/foreground screen inventory |
| CP6 | Native CarPlay Maps or another CarPlay app | One Speed8 overlay independent of native app | Screenshot + log |
| CP7 | Disconnect/reconnect, native Home, GOFA process unavailable | No stale/double HUD; sample absent `—`; no crash/Dock obstruction | Log timestamps, screen before/after |
| CP8 | Switch between DuoFace and native CarPlay Dashboard | At most one visible HUD at each moment; never interfere Home/Dock/YouTube | Video or two screenshots; duplicate/gap report |

## Known boundary and logs
- `DFNative12Chrome.m:refreshGlobalSpeedHUD163` chooses one actually visible external DuoFace pane without GOFA bundle filter; do **not** assume other-app content appears over native Home.
- `DFSpeedNativeOverlay163.mm` is compiled into already-existing `DFCarPlayDockOwner.dylib`, injected only into native CarPlay/CarPlayApp/dashboard processes. Foreground external UIKit UIWindow is required; creates **no** UIWindow. Native log marker `[DuoFaceSpeed8] QA163 native owner attached process=... class=...`. A missing marker may indicate no native owner found, injection problem, logging capture gap, or display not connected: do not guess.
- GOFA source remains `DFGofaSpeedSource162.dylib` and logs `[DuoFaceSpeed8] GOFA GPS publisher started` or `GOFA valid GPS speed publish`; uses iOS `CLLocation.speed` only, not GOFA speed-limit/camera.
- If HUD **visible but speed shows `—`**, display layer may work while GPS provider doesn't. If HUD **not visible**, identify display owner/window/process first. Do not treat an invisible HUD as missing GPS.
- Native scene and display z-order, window activation and device permissions must be measured from actual device before marking **global HUD VERIFIED**. Do not test interaction while actively driving; video/photo/log capture in a parked car or by a passenger.
- If QA163 breaks Dock/touch or crashes, rollback via old `0.0.162~gofaspeed8test1` package already retained on the **same Sileo feed**. Do not use Filza or reinstall repeatedly.

## Accurate current status
BUILD=PASS, SIGNED=PASS, SAME_REPO_ARCHIVE=PASS, SILEO_PUBLIC_APT_AND_SHA=PASS, DEVICE_UI_ALL_CONTEXTS=UNTESTED, SOURCE_GOFA_SPEED_LIMIT=NOT_IMPLEMENTED, CARPLAYPRO_LICENSE_OR_BINARY_COPIED=NO.
