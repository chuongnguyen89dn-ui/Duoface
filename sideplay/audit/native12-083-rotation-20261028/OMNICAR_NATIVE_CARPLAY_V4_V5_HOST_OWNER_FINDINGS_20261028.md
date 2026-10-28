# 2026-10-28 — Original OmniCar V4/V5: native CarPlay process and **real controller vs AppBridge placeholder**

## Read-only original archive and actual results
The original signed `Omnicar/com.anlai.omnicar_1.0.3_iphoneos-arm64.deb` SHA256 `d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd` was fetched, checked by sha256sum, unpacked only in GitHub Actions Linux workers; **no vendor dylibs or license copied into DuoFace**.

- V4 original package process owner [run 40629909847](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40629909847) **PASS** after a diagnosed/repaired CI issue: the first run 40629849226 failed `ModuleNotFoundError: No module named 'capstone'`; adding pinned `capstone==5.0.7` in workflow commit `e357b6841f92112dcf39a56041164ca228590e73` fixed that; rerun on push successfully archived `OMNICAR_ORIGINAL_PROCESS_OWNER_V4_RUN_40629909847.json` blob `61415bac942541a21a74c7c57612a1dc362f738f`. Source `sideplay/tools/audit_original_omnicar_process_owner_v4.py` commit `d9916bff`; workflow `.github/workflows/duoface-original-omnicar-owner-v4.yml`.
- V5 original native hosted view controller [run 40630009621](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40630009621) **PASS**, persisted `OMNICAR_ORIGINAL_HOSTED_VC_V5_RUN_40630009621.json` blob `29a0c6e8c990428638b81ee7792bca82f11fe41d`. Source `sideplay/tools/audit_original_omnicar_hosted_vc_v5.py`, commit `a4c0b410c86051b229ec6b942afe3a770446a18a`; workflow `.github/workflows/duoface-original-omnicar-hosted-vc-v5.yml` commit `bad8b4ce`. Methods from ARM64 original, **not guesses or source imitations**.

## V4: actual process injection responsibilities (from original *.plist Filter)
| Original dylib | Actual bundle filter in original DEB |
|---|---|
| `OmniCarSplitScreen.dylib` | `com.apple.CarPlayApp` **and** `com.apple.springboard` |
| `OmniCarCarProbe.dylib` | `com.apple.CarPlayApp` **only** |
| `OmniCarCore.dylib` | `com.apple.springboard` **only** |
| `OmniCarAppBridge.dylib` | `com.apple.UIKit` |
| `OmniCarSpeedBubble.dylib` | springboard, CarPlayApp and specified map bundles |
| `OmniCarStartupScreen.dylib` | CarPlayApp and springboard |

**Inference grounded in package ownership:** OmniCar's native split code belongs to the **CarPlay system host process path**, with SpringBoard-side participation, whereas the ordinary phone-app bridging hook is system UIKit. A native CarPlay map cannot be reproduced by changing transform of DuoFace's SpringBoard-hosted `SBDeviceApplicationSceneEntity initWithApplicationForMainDisplay:` alone. Filter is eligibility for loading, not live proof it loaded on a specific device. The original package is rootless `iphoneos-arm64` package `com.anlai.omnicar 1.0.3`; original DEB's extracted maintainer control dir contains only `control` (no vendor maintainer scripts seen), per V4.

## V5: CRITICAL — `SCPHostedAppVC` is NOT a native map scene owner

Original Objective-C class roster proves `SCPHostedAppVC` and `SCPCarPane` are separately implemented native split classes. Disassembly of the exact **original** implementation:
- `SCPHostedAppVC.sceneHostView` at **0xfdbc**: `mov x0, #0; ret` — it **returns nil**, rather than exposing a real CarPlay scene host view.
- `SCPHostedAppVC.applicationInfo` at **0xfdac**: `mov x0, #0; ret`, **nil**.
- `SCPHostedAppVC.proxyApplicationInfo` at **0xfdb4**: `mov x0, #0; ret`, **nil**.
- `SCPHostedAppVC.backgroundSceneWithCompletion:` 0xfd14 and `foregroundSceneWithSettings:completion:` 0xfd60: small methods that call supplied completion block if nonnull, with no observed native scene transition in their 19 ARM64 instructions (recheck all instructions if needed); NOT a real UIKit map scene.
- `SCPHostedAppVC.viewDidLoad` @0xfc58 has 47 instructions. This proves it is a separate class but **not** an operational replacement for the real map scene owner. Its role as a placeholder for iPhone AppBridge is a plausible inference from original method design; exact application of this class in each runtime branch still requires tracing `adopt:slot:`.

**This corrects an earlier ambiguity:** the fact that OmniCar original calls `sceneHostView` does *not* mean all hosted panes return a usable native view. The original has a **nil-backed hosted-controller variant**, and a native CarPlay view controller path must remain distinct.

## V5: concrete native pane data structure
`SCPCarPane` original has **37 actual methods**, including:
- `vc/setVc:` @0xf8e8/0xf8f0
- `host/setHost:` @0xf958/0xf960
- `handle/setHandle:` @0xf990/0xf998
- `bundleID/setBundleID:` @0xf8d8/0xf8e0
- `hostFrame/setHostFrame:` @0xfb50/0xfb5c
- `hostHandle/setHostHandle:` @0xfb68/0xfb70
- `sceneSize/setSceneSize:` @0xfba0/0xfba8

These are **distinct slots/fields** for the pane's native VC, owning scene/handle, and geometry; no unverified scaling percentage is found in these metadata methods. They strongly support a native scene-first approach with owner identity, not phone view scaling.

`SCPCarSplit.adopt:slot:` @0x1942c specifically checks `applicationInfo` / `proxyApplicationInfo`; `sceneOfViewController:` @0x1aaf4 checks real `sceneHandle`/`scene`; `pushSceneSizes` @0x1c550 conditionally accesses `sceneHostView` and calls `foregroundSceneWithSettings:completion:`. `scene:destroyedForViewController:ownScene:` @0x1ad58 keeps a pane on *foreign* scene destruction and closes it only on *owned* destruction. This method group now has an actual original class/metadata grounding.

## Consequence for independent DuoFace implementation — no guessing
1. Native branch: route through the actual **CarPlayApp's live native application VC and associated scene/host**, preserve existing Maps navigation scene and Dock ownership, verify controller/scene identity before touching geometry. Never instantiate a `SCPHostedAppVC` analogue and claim it provides native Maps: its original getters are nil.
2. Phone-only branch: keep existing DuoFace MainDisplay bridge for iPhone apps. Do not apply AppBridge visual scale or phone scene orientation policy to real CarPlay Maps.
3. Before code: collect **read-only live evidence** from actual CarPlayApp process for the native controller class, scene role/identifier, `sceneHostView` presence/size and active navigation when the map is opened. The existing `sideplay/native-carplay-scene-v1` passive observer is an appropriate independent starting point; do not modify CarPlay Dock or app lifecycle just to collect evidence.
4. Only after owner proof, independently implement a CarPlay native scene adapter with generation guard and foreign scene protection, test in signed DEB published to Sileo, and test real native map in split while original navigation remains running; separately fix initial YouTube orientation without regressing .83 video/no-crash.
5. No new runtime feature/DEB was built in V4/V5. `.85~mapscene1` was published previously (verified `carplaydsp` run 40627384428) but its guessed 0.80 zoom has been removed in current source and is **rejected as solution**. Do not republish or claim it works. `.83` device video pass and `.84` publication remain historical rollback baselines.

**Proof levels:** [VERIFIED] source DEB filters, class method names/offsets/instructions, GHA runs and saved reports. [INFERRED] `SCPHostedAppVC` serves as a placeholder for phone AppBridge. [NOT VERIFIED] exact live native CarPlay Maps owner, whether one CPWindow is safely reusable in two displays, real map rendered in DuoFace, video rotation fixed, runtime device pass.
