# MyTweak independent SceneHost — source/code checkpoint (2026-10-18)

**Branch:** `feature/visual12-duodash-recovery`. **Scope:** user's uploaded `mytweak.zip` redesigned as a standalone iOS 16 rootless SpringBoard CarPlay host, NOT bridged to vendor `CBBridgeManager` or `CBLicenseSyncManager`. Native12/HUD8 stable app and Sileo unmodified. User decided to replace the old runtime instead of patching license checks. Do not deploy both native and MyTweak active windows simultaneously.

## Executed change

- Source code: `experiments/mytweak-independent/` with **25 text files**, preserving original MyTweak tree, adding `tests/test_scenehost_contract.py`. Source commit `5999502a9de9278c0c2840e4135684483206f646`; fixed a missing newline during upload in `MTSceneHost.m` commit `be2b650483b37b9301bd7cf6afb5c8745f07dcdd`.
- `MTSceneHost.m`: experimental runtime-guarded calls to `SBApplicationController`, `SBDeviceApplicationSceneEntity`, `SBAppViewController`, `setRequestedMode:2` to request live cross-app scene; poll `sceneHandle.sceneIfExists`; apply 2x source geometry and UIKit scaling for each slot; on stop `setRequestedMode:0`, `invalidate`, restore scene settings. Scene-ready requires non-nil scene; the caller sees PENDING until then; errors surfaced via `MTSceneHostDidFailNotification`.
- `MTBridgeCoordinator.m`: detect CarPlay `CADisplay` by `AVExternalDevice.currentCarPlayExternalDevice.screenIDs`; create exactly one `UIRootSceneWindow` using `FBSDisplayConfiguration`; disconnect cleanup.
- `MTAppSlotViewController.m`: update asynchronous scene failures and cleanup old hosted UIView. `MTAppLauncher.m`: no false claim of scene-ready. `Tweak.x`: no startup alert by default.
- No import/call of vendor CB classes in independent source; private SpringBoard APIs remain version-sensitive. No original vendor license or watch-dog code.
- GitHub workflow added: `.github/workflows/mytweak-scenehost-qa.yml` commit `63c430e189daf34e14d5721386cba8a35b33e05d`. It only runs static tests, builds a rootless Theos test DEB and uploads an Actions artifact; **does not publish to Sileo**. Workflow build completion **NOT confirmed**; PR-filtered workflow run query and combined status returned empty.

## Verification

- Executed **2026-10-18**, cwd `/mnt/data/mytweak_independent_work/mytweak`:
  `python3 -m unittest discover -s tests -v`: **6/6 PASS** (static source contracts only).
- ZIP assembly `/mnt/data/MyTweak_Independent_SceneHost_trial_source_20261018.zip`, **25 regular files**, `zipfile.testzip(): None`, SHA256 `57187bebc193f13dd5f16fd4613032bb56064eabe6a10c7915ef8b0252d5da02`.
- Original attachment `/mnt/data/mytweak.zip`, **24 regular files**, SHA256 `caf1557d1f9ac4828cf13cf8a5876a60c4b596b57b2951a8e9ac4d428225e015`; **7 original files changed, 1 new static test**, no other old files changed.
- Local text bundle `/mnt/data/MyTweak_Independent_SceneHost_trial_source_20261018.txt`, 25 file sections, exists in Library `/DuoFace/MyTweak_Independent_SceneHost_trial_source_20261018.txt`, library ID `libfile_b3733dd305b88191a1d3c434da6e1bde`. This is secondary storage; canonical independent source is the GitHub code directory.
- GitHub source/blob verification: `experiments/mytweak-independent/MTSceneHost.m` fixed blob SHA `df279451164bad690259061e096ab8152d7eb23b` matches exact local file Git-blob SHA, other changed files sampled matched. Full ZIP has not been pushed to GitHub, but source text lives there.

## Not yet accomplished

**No Theos/iOS SDK in local container**, so no local iOS native build, no confirmed GitHub Actions build result, no DEB device install, no CarPlay scene result, no screenshot and no iPhone X log. Private APIs are assumptions based on existing independent QA source, not proof of compatibility on iOS 16.7.x. `MTSceneHost` compile/device acceptance may still fail. The source does not recreate native12 HUD8 layout.

## Next executable actions (no guesswork)

1. Verify latest run for `mytweak-scenehost-qa.yml` using GitHub Actions; if failed, save job ID/error and fix source/toolchain in **MyTweak trial only**, not stable DuoFace.
2. Once built, make package available as a **QA-only artifact**, never update native Sileo or concurrently load both owners. User tests exclusively on iPhone X/DiPlay and collects `/var/mobile/Library/Logs/MyTweakSceneHost.log` or SpringBoard `[MyTweakScene]` log and any SpringBoard `.ips`.
3. Acceptance gate: `carplay-window-ready` → `host-created` → `mode-2-requested` → `scene-attached` → `scene-ready` → actual interactive app in pane; then resize, switch, `invalidate-done`, disconnect/first-respring crash-free.
4. If failure, use **first missing event + actual logs** rather than changing unrelated UI or bypassing vendor licensing.
