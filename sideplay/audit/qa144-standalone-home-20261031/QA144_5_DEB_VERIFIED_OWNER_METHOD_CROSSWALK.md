# QA144 — Five real original/derived DEBs: verified native Home -> independent app scene ownership

**Checked 2026-10-31, NO QA144 runtime changes, NO new DEB, NO Sileo publication.** Fresh actual runner [41179261436](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41179261436) SUCCESS, job `124473114983`, source `c22622d695518f38eee85fee47a52f18a31e17d9`; GitHub results archive commit `92617a344732a719724dc9086694abc0cc47d011`. The earlier attempt `41179216398` failed when the script had not created a local extraction directory for `dpkg-deb -x`; corrected then **all verification, original full scan, artifact upload and permanent GitHub push passed**. Real original code was *never run*.

## 1. Every package file and Mach-O freshly scanned, signed-input SHA verified

| Package / provenance | Version | Package SHA256 | Files | Mach-O |
| --- | --- | --- | ---: | ---: |
| **DuoNavi ORIGINAL** | 1.0.4 | `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd` | 50 | 4 |
| **Native12-DERIVED reference** (not independently vendor stock) | 0.1.0~native12+speed8compact | `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad` | 43 | 8 |
| **DuoDash REPACK** (not pristine stock) | 1.1.3+fullscreen1 | `ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465` | 44 | 4 |
| **OmniCar ORIGINAL** | 1.0.3 | `d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd` | 176 | 8 |
| **SidePlay ORIGINAL** | 1.0.4-1 | `7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c` | 136 | 7 |

All **449 files and 31 Mach-O images** were enumerated (no vendor binary embedded in our independent package). Every extracted file has its SHA256 in machine report. **Read three exact central skill ZIPs** 01,02,05 by checksum in runner. Actual package control, tweak filters, all images and selected ObjC class/method metadata were examined. Distinguish historical symbol names vs proven runtime hooks.

## 2. Exact original DuoNavi Home tap handlers — six ARM64 code bodies, not guesses from strings

The new runner decoded the **six separate original Home tap functions**, bounded by Mach-O LC_FUNCTION_STARTS, in the SHA-pinned **DuoNaviDashboard.dylib** `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`. All six contain the following **ordered selector references**:

```
setIcon: -> shouldInterceptLaunchForApp: -> startBridging:
        -> pending -> activated -> stopBridging
```

Actual six handler starts: `0x311094` (iconView), `0x311238` (iconView with actions), `0x311400` (icon), `0x3115a4` (icon+location), `0x31176c` (icon+location+animated), `0x311938` (alternative icon). At the iconView callback, the checked selector reference PCs were `0x3110f4` shouldIntercept, `0x311144` startBridging, `0x311164` pending, `0x31119c` activated, `0x3111d8` stopBridging. This is **true same-method ARM64 code reference evidence**, stronger than a package string match. It still does not establish which runtime branches were followed on the user's iOS 16.7.16.

No evidence in this original Home callsite cluster of substituting the selected icon with the DuoNavi app's icon or launching its split-panel UI, as **our QA143 wrongly did**.

## 3. Verified original classes separate standalone single-app from multi-pane

**DuoNavi 1.0.4** `DuoNaviDashboard.dylib` original ObjC class/method metadata (fresh parsed from original dylib):

- **Native tap producer** is a Home/Dashboard callback; the per-app admission decision references `+shouldInterceptLaunchForApp:`.
- **Standalone bridge owner** `CBBridgeManagerDashboard` defines `-startBridging:`, `-startBridging:withCompletion:`, `-stopBridging`, `-stopBridgingWithCompletion:`, `-prepareHomeScreenForBridge:`, `-bridgeDidActivate:`, `-bridgeDidDeactivate`. `CBBridgeManager` also has `-trackBridgedBundleID:`, `-sendStateToApp:shouldBridge:`, `-requestStateChange:` (from previous exact IMP), and `-loadNewAppFromCurrentRequest:`.
- **Scene host** `CBBridgedUIAppView` defines `-hosting`, `-setHosting:`, `-hostedScene`, `-refreshSceneLayout`, `-updateSceneFrame`, `-updateSceneSettingsFrame`. Actual same image has `SBDeviceApplicationSceneEntity` and `SBAppViewController` references.
- **Explicit split feature is separate**: `CBBridgeManager -switchToSplitWithLeft:right:ratio:`, `-switchToMultiSplitMode:apps:ratio:`; `CBBridgedSplitApp -layoutSplitViews`, `-splitPreset` / `-splitRatio`. Hence a Home tap is not inherently an App-picker or forced split request.
- **Remote app process**: same original Dashboard tweak filter covers SpringBoard, CarPlay and specific app bundle IDs including YouTube/VLC/Maps; its verified metadata has `setAudioOnlyBackgroundMode:`/scene layout, potentially app-side state. **Cannot conclude an app-side ACK works in current device solely from these strings.**
- **Native12-derived** module `DuoFaceDashboard.dylib` contains the comparable `CBBridgeManagerDashboard` / `CBBridgeManager` / `CBBridgedUIAppView` / `CBBridgedSplitApp` class and method separation; this is a derived reference, not an untouched vendor DEB.

**DuoDash 1.1.3 Fullscreen427 REPACK**: separate `DuoDash.plist` targets SpringBoard, Preferences, CarPlayApp, UIKit, `mediaserverd`; `DuoDashUnifiedFullscreen.plist` targets `com.apple.CarPlay`. Its `DuoDash.dylib` contains app-side bridge-state and scene host markers. Previous **exact decoded IMP** in `sideplay/audit/duodash-duonavi-media-20261027/ORIGINAL_DUONAVI_VS_DUODASH_REPACK_IMP.json`: `CNABSpringBoardObserver -onHostRequest:` @`0xf968` (one host request) versus `-onHostRequestSplit:` @`0xfd90` (split request); `DDz2 -cnabBuildSceneHostForBid:displaySize:` @`0x1b7a0`; `CNABUIApp -setBridgeState:width:height:orientation:` @`0x1f514`. **The exact native DuoDash icon tap->observer IPC remains unverified**, so do not falsely claim its original Home callback was decoded. This comparison nevertheless proves single-host and split paths are distinct binary methods.

**OmniCar ORIGINAL**: `OmniCarAppBridge.dylib` (app-side/UIKit filter) contains SBApplication host/controller scene markers; **a separate `OmniCarSplitScreen.dylib`** targets CarPlayApp/SpringBoard and contains CARApplication/Home catalog markers. The package contains both, but our bounded Home-tap string list did not identify a specific icon-click handler; this is **unknown, not absence of capability**.

**SidePlay ORIGINAL**: `SidePlay.dylib` contains `SBDeviceApplicationSceneEntity`/`SBAppViewController` and `sendEvent:` markers, with app lifecycle in the executable; no matching Home-icon callback was identified by the bounded scan. It is useful for host/event comparison, but cannot independently specify native Home app activation.

## 4. What our independent QA143 did wrong — exact source line-of-function, not user speculation

`sideplay/duoface-native-scene-host/DFHomeLaunch143.m` forcibly supplies `DF143Original(...,duofaceView)` **instead of the tapped app's icon**, causing system to foreground `com.duoface.native.scenehost`. `DFTouchOwnerProbe.m` starts `sChrome` and `DFHomeRequestReceiver143.m` finally calls `DFHomeSceneBridge143.m` -> `setSelectedSlot:0` -> `DFNative12Chrome appPicker:didSelectBundleID:`. That is the **DuoFace split UI owner** by design. A green Mac build, green Sileo deploy, or even app content visible in the first split slot **does not satisfy** the user's required native Home direct single-app launch.

QA144 code branch `feature/duoface-qa144-standalone-carplay-home-20261031`, commit `26b888d4d8896d994a551da2467c1810d51643e4` has already **removed the wrong QA143 Home icon-substitution hook from future build**. QA144 CI negative guard [41178695732](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/41178695732) PASSED. Already published QA143 bytes remain unchanged. No QA144 replacement build, no Sileo update, no physical app-opening test.

## 5. Evidence-backed engineering criteria before a new package

Before starting code, **resolve each owner/callback contract rather than guessing**:

1. Native selected Home tap, with actual iOS16.7.16 ABI and app bundle from user's Log21; native/unselected/disabled passes original untouched.
2. A *separate, first-party, one-app launch request* accepted by a **real** SpringBoard owner: does not launch DuoFace CPTemplate or `DFNative12Chrome`; never substitutes Home icon. Track request ID, bundle, session, owner.
3. A standalone **single** remote app scene (can reuse independent `DFSceneHost` primitives) with real bounded CarPlay content geometry and Apple Dock staying system-owned; confirm remote view and correct app PID, not just `requestStateChange:` dispatch.
4. App process input/viewport/orientation ownership and asynchronous ready/fail ACK; GOFA/YouTube behavior is not assumed functional from a selector list. No unnecessary `setForeground:YES` or global entitlement patch (QA138 had proven stack recursion).
5. Native CarPlay Home/Back/lock/unplug lifecycle correctly releases **only the app's standalone** host. Keep DuoFace split 1–4 panes completely separate and unchanged.
6. CI compile/unit/negative controls, then a test build, then **only** a verified Sileo release when these prerequisites exist. Physical parked device test remains final acceptance: direct app visible, no DuoFace split, video/touch works, native Dock and Home restore; compare runtime logs.

**Decision:** no more blind install-test loops. Offline static audit now gives an independently reproducible ownership map, but there is no honest claim yet that the original vendor's runtime or the current device's standalone scene acceptance has been proven. Preserve QA142/QA143 exact binary rollback and do not re-ship QA143.

## Exact reproducible artifacts

- Executed audit source `sideplay/audit/qa144-standalone-home-20261031/scan_original_full_ownership.py`, final source commit `c22622d695518f38eee85fee47a52f18a31e17d9`.
- Workflow `.github/workflows/duoface-144-full-original-standalone-audit.yml`, source commit `6e8cfee09c1f674f1bbe6d8e1fba475639c072ad`.
- All files archive `sideplay/audit/qa144-standalone-home-20261031/runs/41179261436/ALL_FIVE_DEBS_FILES_MACHO_PLISTS_AND_METHODS.json`.
- Native Home six handler archive `.../ORIGINAL_DUONAVI_NATIVE_HOME_TAP_DECODED.json`.
- Per-stage matrix `.../PER_STAGE_OWNERSHIP_MATRIX.json`.
- CI receipt `.../CI_RESULT.txt`.
- Original tapped-app vs split decision history `sideplay/audit/qa144-standalone-home-20261031/QA143_WRONG_OWNER_VS_DUONAVI_DUODASH_AND_QA144_CONTRACT.md`.
- All references/DEBs verified by SHA; no vendor licenses or binaries redistributed, no iPhone user action.
