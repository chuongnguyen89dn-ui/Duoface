# DuoFace .89 first-party YouTube v2 split/scene UIKit parity QA — 2026-10-28

## Reproducible bug (latest physical)
- User DEVICE-FAIL .88: YouTube upside down / rotated wrong in two-pane, upright after solo / swipe-down / fullscreen.
- Read actual newly-uploaded `Duoface/main:sideplay/log/DuoFaceSceneHost.log` SHA blob `cc4f507548c57c15fe37e6ddba95f8e5e52842d6`, 812644 bytes, 7395 lines, commit `fbf9bdbc8afdaf00ce40e6713d0e9c24d7f8e3c7`.
- 105 Host-to-YouTube ACKs (17 with .88 internal window telemetry) confirm app IPC and matched scene. At lines 7238-7244, `sceneOrientation=1` yet `rootViewController.interfaceOrientation=3` AFTER window rotation, then becomes=1 in next ACK. Receiver alone cannot report pixels upright. Host does not read clientSettings orientation. Old injection-missing hypothesis ruled out in observed sessions.

## Bounded change derived from Native12/SidePlay original, implemented independently
- `DFNative12Chrome.m` sends actual split/solo mode (including empty second pane) to owned host, **no layout/visual alteration**. Unit test byte-hashes original Chrome after removing only the new nonvisual message.
- `DFSceneHost.m` sends owner/scene/generation/timestamp/portrait/committed logical size/**isSplit** v2 and reads clientSettings.interfaceOrientation vs settings.interfaceOrientation in ACK. Doesn't mutate foreign FBScene and preserves .83 lifecycle.
- YouTube-process-only `DFYouTubeOrientationRelay.m`: after applying existing exact-owner internal UIWindow reflow, observes if root controller still not portrait. Only when actual Chrome state says split and there is an observed mismatch, one delayed recheck 120ms; if still mismatch, request at most one public UIKit iOS16 `setNeedsUpdateOfSupportedInterfaceOrientations` + `requestGeometryUpdateWithPreferences:errorHandler:` per owner/scene/split/size, record error or issue ACK; no global hook or arbitrary angles.
- `DFYouTubeHostState.h` v2 validates isSplit and lease. Executable Foundation test updated. New unit tests assert exact owner and no Maps/Dock/AVPlayer changes; all other logic from .83 and .88 preserved.
- Proven original path: `sideplay/audit/native12-083-rotation-20261028/NATIVE12_ORIGINAL_HOST_TO_APP_YOUTUBE_HANDSHAKE_20261028.md`, original SidePlay orientation geometry investigation `SIDEPLAY_YOUTUBE_ORIENTATION_DIFFERENCE_20261028.md`.
- Existing source-only iOS16 compile/link/regression workflow `https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40662836808` completed **SUCCESS** at commit `751a353f`. New handoff archive script commit `3c6e61fc` is independent and does not affect compiled runtime.

## Current requested action
Build signed **one integrated DEB 0.0.89~splitscene1** (nativehost 0.1.98~splitscene1) with existing macOS workflow, run all ABI regression, package SHA and immutable archive `evidence/runs/<run_id>`, update existing project handoff. Ensure .88 and .83 immutable rollback. **Do NOT claim real-device video success from CI.** Publish Sileo .89 only with verified package hash and existing Apt repo. Rootless iPhone X iOS16.7.16, test on parked CarPlay two panes/solo/swipe, confirm zero crashes, correct Dock and maps unchanged.
 
Build trigger marker: 089-real-scene-client-split-20261028.

## CI retry after source-only test literal mismatch (no code behavior changed)
- Run 40662947889 FAILED in `Self-contained payload / no vendor code unit tests` before build, because `test_youtube_scene_feedback_089.py` still asserted removed local variable `@"isSplit":@(twoPanes)`. Current source intentionally uses `self.splitUIVisible` from authoritative Native12 Chrome split state.
- Fixed the stale test literal in commit `48011082299ba8c07449cea5e695790492920eac`. Not a runtime change. Rebuild once with complete current source on macOS; no signed package from failed run.
- Retry marker: 089-split-ui-controller-test-corrected-2.
