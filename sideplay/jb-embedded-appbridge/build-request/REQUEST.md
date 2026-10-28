## ROLLBACK REQUEST — revert experimental .93 to last published .92 (2026-10-28)

- USER: "Quay về bản trc đây cho tai". Immediately cancel/supersede .93 phone app-manager and CarPlay filtered-picker candidate, return runtime code, nativehost/control, packaging and source tests to exact verified .92 commit b29c5c63a75a71510eed9435950ca3fa90cc4f7e. Do not touch already public Sileo .92 or rollback .90 files. Do not publish .93.
- The rollback commit updates this request for history. Packaging workflow guards rollback-prefixed commits so it SKIPS builds. Existing .93 run 40711856334 was queued at initial check and needs post-check; no claim of cancellation until observed.
- Scope restored: .92 original source and Sileo 0.0.92~logo3s1; Source SHA a31eb5f6f89eb34a0faff3346c354b3125b365cb; build 40707934981 and public verification 40708684634 SUCCESS. .93 work remains accessible only in git history and preserved forensic audit; not installed or published.
- Next only upon new user instruction: resume 25-group Native12 audit without altering verified live DEB.
---
## DuoFace .92 immutable one-DEB QA archive retry, 2026-10-28

- Actual CI 40707030521 compiled four current-source modules and merged signed `0.0.92~logo3s1` with SHA256 `3c1031b61147faa6b029080f364dbff137c6ae79f6b6c53651cfed38488b442a`; rootless inputs, YouTube ABI, 3-second logo contracts, macOS build, dpkg tests and artifact upload PASS. GitHub Actions artifact 12824921313 exists, **but run conclusion FAIL due ONLY final archival step**.
- Exact saver traceback at 2026-10-28T14:36:45Z: `ValueError: expected exactly one signed integrated DEB in this run` (`sideplay/tools/append_086_ci_handoff.py:26`). Existing source checkout contains old .91 integrated DEB and saver blindly `cp packages/*.deb`; old helper also rejects version .92. These are archive script defects, not a failed compilation or device test.
- Fix scope: archive exact newly signed .92 file, upload just .92, SHA256SUMS just .92, teach existing handoff append helper version .92 and preserve older versions. Re-run same macOS integrated workflow with source HEAD as immutable provenance; no Sileo until archive + checksum verified.
- Trigger: 092-fix-archive-exact-one-qa-and-handoff-version-20261028.

---

## DuoFace .92 — USER AUTHORIZED INTEGRATED SIGNED DEB, 2026-10-28

- User: “Ko. Đã quét rồi thì tích hợp vào deb luôn”. Supersedes source-only position of checkpoint 96d2d215. Build one NEW rootless integrated DEB from verified feature source; do not ship .91 renamed as .92 or copy vendor binary/license.
- Integrated Version `0.0.92~logo3s1`, NativeHost `0.1.101~logo3s1`. Source includes `DFLogoHoldGate.h`, `DFNative12Chrome.m` 3-second hold, same split/SOLO, .90 YouTube verified rotation, and .91 Maps opt-in code untouched.
- Use existing macOS one-DEB packaging pipeline, dpkg-deb version/SHA, provenance, unit tests, YouTube ABI, signed artifact and immutable project-run archive. Preserve .90 rollback and no silent live-system mutation. Source-only run 40705259552 PASS; physical hold and native map pixels NOT tested.
- Once build passes, publish exact version/hash through existing Sileo workflow and verify remote Packages+DEB hash. Device test parked only. Native12 full parity remains unproven.
- Build trigger: 092-logo3s-current-source-signed-one-deb-20261028.

---

## DuoFace .91 single DEB retry 3: all NativeHost .90-version test references reviewed, 2026-10-28

- Run `40689188238` failed before build at `test_youtube_scene_feedback_089.py`: legacy native host 0.1.99 assertion. Updated only native host module expected version to 0.1.100; **retained historical .90 YouTube runtime/hook tests and six .90 protected files**.
- Explicitly scanned 17 test Python files under `sideplay/duoface-native-scene-host/tests` and `sideplay/jb-embedded-appbridge/tests`; remaining strings `0.0.90~nativegetters1` refer to unchanged .90 telemetry and baseline and must NOT be erased.
- Rerun one build; QA only pending CI PASS, pin hashes and Sileo audit. Trigger `091-test-nativemap-version-cleanup-three-20261028`.

---

## .91 signed one-DEB retry 2 — preserve nine preset layouts, 2026-10-28

- Run `40688990879` failed before building because stale independent original-nine-presets source test still required exactly 9 table rows; now the iPhone Bố cục screen intentionally shows nine original layouts plus one separately labeled native Maps QA button (10 total). Test updated at `sideplay/duoface-native-scene-host/tests/test_original_nine_preset_binary_reference.py`, no original 9 preset logic changed.
- Rebuild from this exact checkout; no Sileo release until CI SUCCESS and SHA verified. Trigger `091-native-carplay-maps-optin-layout-test-updated-20261028`.

---

## .91 CI retry 1 — only stale NativeHost .90 version assertions corrected, 2026-10-28

- First GHA run `40688765319` **FAILED before build**, `Self-contained payload / no vendor code unit tests`: legacy tests `test_nativeowner_086` and `test_orientation_policy_084` still asserted old `0.1.99~nativegetters1`; actual bumped module is `0.1.100~nativemapqa1`. Updated those assertions only; all .90 runtime video source remains byte-for-byte unchanged.
- Repeat complete current-source macOS CI, stage one signed .91 QA DEB only if tests/build succeed. No Sileo publication without verified artifact.
- Retry marker `091-nativemapqa-legacy-version-guard-updated-20261028`.

---

# DuoFace .91 native Maps CarPlay same-process controller QA — one DEB CI request (2026-10-28)

- Build `com.duoface.jb.embedded_0.0.91~nativemapqa1_iphoneos-arm64.deb` with the existing macOS signed one-DEB workflow; nativehost `0.1.100~nativemapqa1`. Preserve the complete user-confirmed .90 YouTube playback/rotation source and public .90 DEB SHA256 `c9a6c8f624ce3224ec5cdc7aee9c3280306068c99c9842d4b4f802914c560f27`.
- Implemented native Maps **first-party opt-in QA path**: user opens Google Maps native on CarPlay while car parked, uses DuoFace iPhone app > Bố cục > Thử nghiệm bản đồ CarPlay native > Bản đồ trái/phải or Restore. CarPlay-only `DFNativeMapPaneCoordinator.dylib` matches real `DBApplicationSceneViewController`/FBScene + system Dock bounds and calls `DFNativeMapPaneAdapter` same-process UIKit adopt/restore, never clones `CPWindow`, terminates navigation or scales phone MainDisplay Maps.
- **DEFAULT OFF; NO AUTOMATIC MAP VIEW MUTATION.** Fails closed if owner/pane/screen mismatch, native Map FBScene not current, more than one owner or absent native Dock. Sileo publication/physical device Maps rendering/route continuity are **NOT** proven by macOS compilation. Do not label a rendered map pass until parked-device acceptance.
- New QA package includes its own CarPlay-process-only dylib and existing iPhone DuoFace app; not a separate tweak. Existing .90 Sileo remains rollback. Do not delete .90 bytes or remove other packages automatically.
- Build trigger: `091-native-carplay-maps-optin-owner-dock-bound-20261028`.

---

# DuoFace .90 original Native12 process-local orientation candidate — QA signed DEB request, 2026-10-28

- PRIOR .89 SILEO VERSION IS DEVICE FAIL; do not overwrite or reuse .89 artifacts.
- First-party rootless integrated package 0.0.90~nativegetters1, native host 0.1.99~nativegetters1.
- Original REAL Native12 app injected Dashboard SHA256 9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea; actual original 36 callback ARM64 analysis at sideplay/audit/native12-083-rotation-20261028/NATIVE12_ORIGINAL_36_HOOK_CALLBACKS_RUN_40667230467.json, run 40667230467 PASS.
- YouTube-only ABI-checked first-party UIKit supportedInterfaceOrientations, UIWindowScene.interfaceOrientation, UIDevice.orientation and future UIWindow rotation wrappers. Lease is scoped by exact owner app scene, 3 seconds renewed by live host. Saved original IMP outside lease. Existing .83 media lifecycle, Maps, Dock and Chrome unchanged; no vendor code/license included.
- Source-only iOS16 arm64 compile and dynamiclink PASS run 40672304371, latest full .90 source checks must PASS. User still needs real-device split, solo, swipe, fullscreen and playback validation. Do NOT call this a fix until device confirms.
- Only use the existing one-DEB staging workflow, archive SHA256SUMS and provenance, append existing handoff atomically, then publish to Sileo as separate version only after successful package CI. Do not deploy old .89 under the new filename.
- Build trigger: 090-native12-original-state-hooks-sha-pinned-20261028.

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
