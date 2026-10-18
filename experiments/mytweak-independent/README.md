# MyTweak — independent SpringBoard/CarPlay scene-host experiment

**2026-10-18, source-only, NOT built/deployed/installed.** This is not Native12 and is not a CB* adapter. The original user-supplied ZIP is **`mytweak.zip`**, SHA256 **`caf1557d1f9ac4828cf13cf8a5876a60c4b596b57b2951a8e9ac4d428225e015`**, with 24 source/config files.

## Scope and reconstruction

This directory contains the **changed source overlays**, not a full repeat of the MyTweak archive. The full edited, self-contained 25-file ZIP was produced locally and delivered as a ChatGPT attachment named `MyTweak_Independent_SceneHost_trial_source_20261018.zip`, SHA256 **`57187bebc193f13dd5f16fd4613032bb56064eabe6a10c7915ef8b0252d5da02`** (26,444 bytes). The user’s ZIP and generated ZIP are **not currently stored on GitHub**; do not claim GitHub hosts them. Source overlay on GitHub is for persistent code review/handoff, and is not necessarily byte-identical to the separately delivered ZIP.

Reconstruct source locally by extracting the original user `mytweak.zip` to a `mytweak/` folder, then **replace** the six files with this overlay:
- `MTSceneHost.h` — lifecycle/public API; `MTSceneHost.m` — SpringBoard scene entity, controller, async scene handle, resizing, teardown, logging.
- `MTBridgeCoordinator.m` — `AVExternalDevice` CarPlay display to `CADisplay`, `FBSDisplayConfiguration` and one `UIRootSceneWindow`.
- `MTAppSlotViewController.m` — release old hosted surface and display async error.
- `MTAppLauncher.m` — report pending rather than already successfully launched.
- `Tweak.x` — disables SpringBoard startup modal to avoid obstructing testing.

All **other original MyTweak source**, headers, picker, split UI, Makefile, control, workflow and injection plist remain from the user's ZIP. This is a DIFFERENT, independent implementation; **do not import the vendor `CB*` classes** or install it concurrently with Native12 HUD8.

## Exact experiment contract and validation

- Runtime preflight: only SpringBoard main thread; `SBApplicationController`, `SBDeviceApplicationSceneEntity`, `SBAppViewController` class and selectors must exist; failure logs `preflight-failed`.
- Only ONE external window owner (the MyTweak root), no Native12 owner or duplicate root. Host response is **PENDING**, not video shown.
- Required on-device log event chain: `carplay-window-ready` -> `host-created` -> `mode-2-requested` -> `scene-attached` -> `scene-ready`; then `invalidate-done` upon closure. Errors: `scene-failed`, `display-preflight-failed`, `geometry-warning`.
- Log, if SpringBoard can write: `/var/mobile/Library/Logs/MyTweakSceneHost.log`; otherwise `[MyTweakScene]` via system NSLog. On crash also collect SpringBoard `.ips` with exact occurrence time.
- Six static source-integrity tests on **the delivered complete ZIP**: PASS (no active vendor CB dependencies, rootless SpringBoard filter, one CarPlay window, host selectors, slot teardown, all 10 Makefile source members). These do NOT compile or test iOS.
- Theos SDK and iPhone device were not available in this container; **no build, no Sileo deploy, no live app launch proof**. No automatic publication of the experimental tweak. Do not install a separate CarPlay owner beside Native12.

Useful reference: `replacement/visual12/engine/runtime/DFIRuntime.m` (independent QA source host), `DFCarPlayBridgeAPI.h` (one-owner contract), official-ish Theos `SBAppViewController.h` header, and historic jailbreak headers. Private API behavior is unverified on user iPhone X iOS 16.7.x.

**Next:** make a **separate test-only DEB only in a permitted build environment**, install on isolated test iPhone without Native12 host concurrently active, run one app selection, inspect the event sequence and `.ips`. Never claim real CarPlay success from static checks.
