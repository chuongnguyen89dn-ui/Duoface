# DuoFace .86 — original-only native Maps owner + YouTube hosted-scene orientation candidate
2026-10-28 Asia/Bangkok. Repository chuongnguyen89dn-ui/Duoface, feature/duoface-jb-embedded-appbridge-20261020.

## Requested
One Sileo-installable iOS16 rootless integrated DEB. Render genuine CarPlay map like OmniCar original, keep live navigation when DuoFace is foreground, and correct YouTube initial Zoom rotation, with no vendor code/license, no fabricated percent scaling, no regression to .83 video/no-crash or Dock, split, menu, logo.

## Original binary evidence (actual prior SHA-pinned runs, not executed in this edit)
- OmniCar original 1.0.3 DEB SHA256 `d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd`.
  - run 40627902229: `SCPCarSplit.isCarPlayApp:` @0xff20, `adopt:slot:` @0x1942c, `sceneOfViewController:` @0x1aaf4, `pushSceneSizes` @0x1c550, `hostApp:inPane:` @0x3e490. Separate native CarPlay and phone AppBridge scene paths; verified machine/CFString report `OMNICAR_ORIGINAL_NATIVE_MAP_BRANCHES_V2_RUN_40627902229.json`.
  - run 40628918504: native `verifySceneOfPane:expected:retry:`, foreign-scene teardown checks.
  - runs 40629909847 and 40630009621: CarPlayApp/SpringBoard injectable native split and `SCPHostedAppVC.sceneHostView` returns nil (NOT a native map hosting surface). `SCPCarPane` keeps VC, host, handle and sceneSize separately.
  - OmniCar original ABHost.layoutPane: owns hosted **phone** scene and uses `setInterfaceOrientation:` with frame in scene settings; separate from native Maps owner.
- Original Native12 gold SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`; run 40621241302 confirmed eligible hosted phone main-scene orientation allows Portrait=1, two independent reference-size setters preserve original orientation parameters.
- Device V7 log `main/sideplay/log/DuoFaceCarPlayOwner-4C5C8ADB-EE69-458A-B664-1753AB90C797.jsonl` (upload e908517e60b69) shows `DBApplicationSceneViewController` 0x5d0a14140 and view 0x5d0a15160 stayed stable while hosted `FBScene` swapped from `com.google.Maps` 0x2813fc840 at 12:02/12:02:37 to `com.duoface.native.scenehost` 0x2813cbc00 at 12:03/12:03:37. Native Google Maps owner is observed while foreground; coexistence behind DuoFace is **unverified**.

## .86 actual source change (no claim of hardware success)
- `sideplay/duoface-native-scene-host/DFSceneHost.m`: only the current live owned phone scene for `com.google.ios.youtube`, existing generation, and observed remote `settings.interfaceOrientation` (2/3/4) is eligible for original-backed Portrait=1 repair. Runtime method ABI must match; otherwise skip. The existing .83 `DFSceneLifecycle.m` is untouched. For orientation-only transaction the original frame/foreground/background are **not** rewritten. This is an experiment with concrete original machine-code/ABI references, not a device-proven fix.
- `DFCarPlayDockOwner.m` + `build.sh`: link the previously tested read-only V7 `sideplay/native-carplay-scene-v1/DFCarPlayLiveOwnerSnapshot.m` into the native CarPlayApp receiver with a unique symbol. Samples controller, scene, identity, scene-host size every 8 seconds; no reparent, no synthetic CPWindow, no background/foreground changes. This is **not native map rendering**. The monitor is necessary to determine whether a distinct live Maps scene survives foreground switch.
- Retain baseline render `DFHostedMapRenderSize.h` at 0.50 for all phone-hosted apps. Never repeat rejected `.85` 0.80 map-only guess.
- `tests/test_nativeowner_086.py` and updated previous tests assert owner/generation scope, no arbitrary landscape, no guessed map scale. `package_integrated.py`, `build.sh`, native control, diagnostics and package workflow stage distinct `0.0.86~nativeowner1` and nativehost `0.1.95~nativeowner1`.
- Workflow source `.github/workflows/duoface-jb-embedded-appbridge-package.yml` downloads two pinned central Gpt-training skill ZIPs and reads their SKILL.md and verification reference before compilation; it runs existing unit/runtime tests, macOS clang build + ldid + dpkg; archive immutable DEB and append actual result to `sideplay/tiep tuc du an.md` only after CI PASS.

## MUST NOT CLAIM
- Native Google Maps visible *inside* one DuoFace pane while DuoFace remains foreground: **not implemented / not verified**. Current scene from Dashboard is swappable and it is unsafe to assume a second live surface exists. No guessed scene pointer reuse, target reparent, CAContext duplication or entitlement spoofing. Further exact device native scene lifecycle proof required.
- YouTube rotates correctly without inner fullscreen: **not physically tested**. Actual app/player geometry and remote orientation at failure can differ.
- Any new DEB built, Sileo release, or device PASS before workflow and checks establish it.

## Concrete next actions
1. Trigger version-specific build by updating existing `sideplay/jb-embedded-appbridge/build-request/REQUEST.md`, not by touching unrelated projects. Confirm exact run URL + step results.
2. If CI succeeds, read immutable `sideplay/jb-embedded-appbridge/evidence/runs/<run_id>/`, SHA256 and appended handoff. If it fails, report exact failing step and preserve source; no fake DEB.
3. Only publish Sileo test candidate if confirmed build and with transparent label explaining native map still unresolved; keep .83 rollback. On parked CarPlay hardware inspect `DuoFaceSceneHost.log` events `youtube-remote-orientation-observed` and `youtube-owned-native12-portrait-repair-requested` plus CarPlay owner JSONL. Record orientation in split/Zoom, inner fullscreen and restore, crash status, Dock unchanged.
4. To deliver actual OmniCar-equivalent native map, prove real Maps FBScene remains alive while DuoFace foreground and is valid to show in a second pane. Otherwise do not pretend scaling a phone scene fixes it.
