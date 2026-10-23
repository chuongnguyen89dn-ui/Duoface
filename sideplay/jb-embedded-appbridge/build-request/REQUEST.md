# Explicit one-DEB user test build request — 2026-10-23 (Asia/Ho_Chi_Minh)

- Requested by project owner: build an actual rootless ARM64 DuoFace integrated `.deb` for installation/testing using Sileo.
- Source branch: `feature/duoface-jb-embedded-appbridge-20261020`.
- Build workflow: `.github/workflows/duoface-jb-embedded-appbridge-package.yml`.
- Expected signed component: `com.duoface.carplay.nativescenehost_0.1.49~native12cards1_iphoneos-arm64.deb`.
- Expected staged single-package candidate: `com.duoface.jb.embedded_0.0.38~native12sourcehost49_iphoneos-arm64.deb`.
- This explicit file-change triggers the scoped packaging workflow (other pushes do not).
- DO NOT claim exact Native12 Speed8 parity: own 8-speed HUD view is not yet linked, real-device UI/zoom/media/safe-mode tests pending.
- This build workflow emits a signed QA DEB and immutable run evidence. It explicitly DOES NOT publish a Sileo source; publication requires a verified repository index/update step after a successful build.
- Do not add original third-party binaries or license checks.

## 2026-10-23 — follow-up explicit user test candidate 0.0.39 (real device photo regression)

- Device screenshots after public .38 prove its OUTER four-action menu paints a blank approx. 446×224pt translucent sheet across both black (unselected) panes. Do not call .38 exact original Native12 UI.
- Current source-only iOS16 ARM64 tests **SUCCESS**: GitHub Actions run 39875524353 and latest 39875654424.
- User already expressly requires us to fix the photographed discrepancy and publish directly to Sileo, so build the next single signed test `com.duoface.jb.embedded_0.0.39~native12menuheader1_iphoneos-arm64.deb` from current feature HEAD and save its immutable archive.
- Exact source patch `DFNative12Chrome.m`: eliminate empty 224pt outer modal body, keep original-header-height 32/38 action row and all original evidenced App/Zoom/Style/Close wiring. No original proprietary binary or license.
- Publish new QA only after signed package build, SHA and artifacts are verified; preserve .38 rollback and separate `com.duoface.independent` Speed8 Hub.
- Real two app scenes and Speed8 HUD still **NOT validated**; black slots without app selection do not prove hosting failure.

## 2026-10-23 — .39 reported regressions, consolidated .40 candidate

Continue user's requested repair on current feature branch. Source fix 589464194e76a82f239cce1c640902580ff1b6f0; source-only iOS SDK CI 39878692429 job120170538359 SUCCESS (53 source contracts, geometry, package/protocol checks, Objective-C ARM64 syntax). Expected candidate com.duoface.jb.embedded_0.0.40~native12regression1_iphoneos-arm64.deb. Contains exact original native appDockViewController selector, Custom menu buttons, 4s divider/input policy and scene reentry guards/diagnostic stages. Preserve .39 immutable artifact. Build and archive this single package. No device/YouTube crash success claim and no automatic Sileo pin change by this request. See sideplay/audit/native12-039-regressions-20261023/FINDINGS.md.

## 2026-10-23 — owner requested media scene crash mitigation plus real 3s circular grip

- The owner explicitly requested fixing the new SpringBoard/YouTube ExitSafeMode regression and connecting Native12's movable circular divider logo to the integrated current build. This file change is the scoped workflow packaging trigger; the actual Sileo publishing workflow is separate.
- Source fixes: `DFSceneHost.m` commit `bbcec6decc56783b4da077460e4d32a6bc4ea5eb` removes .38-introduced synchronous `layoutIfNeeded` inside private scene-settings commit while retaining `setNeedsLayout`, correct original Portrait=1, scene frame and 0.30s debounce. **Hypothesis isolation, not hardware crash resolution proof**.
- Logo fix: `DFNative12Chrome.m` commit `458b3ec9b653434db3749fbbb690198747c14f26` keeps divider/window alive from UIButton TouchDown across the entire requested 3s recognizer delay despite the independent 4s automatic hide timer; late TouchUp cannot swap after a recognized hold. Logo fraction persists without changing split ratio; current original first-party swap PNG preserved. Historical SHA-bound Native12/visual12 reference used 0.30s, but user's later explicit instruction **overrides** to 3.0s.
- Source test fixes `03add7c38d957d1efc294a6165886b08259fe3c1`, `b1326708e1a0aaf2705bf6dcec4f0ca887b5c589`; source SDK CI `39891663165` completed SUCCESS (initial candidate CI failed one stale expected log string, now corrected). Additional version-pin source CI may run concurrently.
- **New immutable signed rootless test candidate to build ONLY (no automatic Sileo publication)**: native host `com.duoface.carplay.nativescenehost_0.1.50~scenelogo1_iphoneos-arm64.deb`; integrated same existing package `com.duoface.jb.embedded_0.0.41~medialogo3s1_iphoneos-arm64.deb`.
- Preserve archived `0.0.37`, `0.0.38`, `0.0.39`, `0.0.40`, original Native12 DEB and all unrelated packages untouched. Device QA gates remain YouTube playback/seek/orientation, no SpringBoard SIGABRT, 3s hold+logo longitudinal drag, tap-to-swap, normal divider ratio drag, 4s hide/wake, Zoom, Style, Close, reconnect.

## 2026-10-23 — OWNER REQUEST: signed 0.0.42 integrated APP+MEDIA+3S LOGO for Sileo

- The owner specifically asked to update Sileo immediately after the original native APP inspection, incorporating independent APP selected/other-slot badges, new original dark SystemMaterialDark sheet, and previous YouTube scene regression mitigation + 3.0-second movable circular divider logo.
- Use **current checkout HEAD**, not old signed 0.0.41. Package versions: NativeHost `0.1.51~appmodal1`, integrated `0.0.42~appmodal1` (same single-package ID `com.duoface.jb.embedded`). Preserve version 0.0.41 and SHA `da2275c2a9ef7efe8879a7121677d2771c809b78066b4552a2294d4b8a1715c2` immutable.
- Source-owned `DFNative12Chrome.m` still uses `hold.minimumPressDuration=3.0` and touch-hold survival during four-second chrome auto-hide. Source-owned `DFSceneHost.m` still defers synchronous layout flush in private scene settings to reduce SpringBoard/YouTube ExitSafeMode risk; **runtime recovery is a hypothesis awaiting device logs, not a proven YouTube fix**.
- New independent APP source `DFAppPickerVC.m/.h`, `DFNative12Chrome.m`: current slot blue check, other scene-ready slot orange swap, actual original badge geometry and palette. New frosted material sheet: dim black alpha.65, SystemMaterialDark blur, border 1pt alpha.18, corner20, shadow .65/radius26/y10. Evidence `sideplay/audit/native12-app-2debs-20261023/APP_BADGE_EXACT_OFFSET_SOURCE_20261023.md` and real original two-DEB run 39897816882.
- Trigger only this packaging workflow `.github/workflows/duoface-jb-embedded-appbridge-package.yml` from this file. Validate **all actual source tests, iOS16 ARM64 signing**, merged source SHA and SHA256, immutable run archive; THEN adapt Sileo publisher in `chuongnguyen89dn-ui/carplaydsp` only once known-good DEB SHA is confirmed, preserving prior package files and public Sileo rollbacks.
- Strictly distinguish **built → signed → archived → Pages published → actual installed/played on-device**. Missing original adaptive 4/5/6 App grid, Add dialog, true physical YouTube/split/timer/pixel parity are still QA blockers. Do not claim 100% Native12 parity or YouTube ExitSafeMode definitively cured by source changes.

### Retry .42 after failed real signed NativeHost compiler

- Actual prior CI [39901475378](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39901475378) FAILED in step **Build OWN current-source NativeHost** with exact clang `DFNative12Chrome.m:1106:44: error: comparison of integers of different signs: NSInteger (aka long) and NSUInteger (aka unsigned long) [-Werror,-Wsign-compare]`; no DEB, artifact or Sileo published from failed run.
- Source fix commit `907418bf8ca04e3aaba160df501226bee3cd589f`: compare `(NSUInteger)otherPhysical>=self.hostedScenes.count` only after `otherPhysical<0` guard (short-circuit) so unsigned range is safe. No UI/behavior change.
- Owner's existing explicit Sileo permission remains valid. Re-trigger same version `0.0.42~appmodal1` only after this compiler fix; preserve original .41 unchanged and require successful actual signed package archive and SHA before publisher.

## 2026-10-23 — Zoom native AppDock runtime diagnostic 0.0.43~zoomtrace1

- Project owner explicitly requested continuing Zoom and retrying the previously blocked GitHub source update. The source update/diagnostics retry **succeeded**: native CarPlay/CarPlayApp owner now records runtime dock candidate count, view/window class, measured geometry, exact applied/expanded/owner/reason receipt. Best-effort file log at `/var/mobile/Library/Logs/DuoFaceDockOwner.log`; no system UI manipulation or hidden Dock fallback added. This is instrumentation, **not a claim that physical Zoom works**.
- Current source-only native UIKit iOS16 ARM64 regression **39904678769 completed SUCCESS**; actual user-device Zoom owner and ACK remain unverified. Build a fresh **signed** integrated `com.duoface.jb.embedded_0.0.43~zoomtrace1_iphoneos-arm64.deb` using new source (NativeHost `0.1.52~zoomtrace1`). Do not overwrite/publish the immutable earlier .42 package until the new exact SHA is obtained.
- Build from current feature branch using the same one-DEB staging workflow and original independent components; preserve all previous version DEBs and no vendor licenses/binaries. Archive signer logs, exact source SHA and SHA256. Subsequent Sileo test publication must pin only this package and verify live public APT + DEB checksum. Hardware acceptance requires returned `DuoFaceDockOwner.log`/`DuoFaceTouchOwner.log` and real screen Dock hide, full content, Zoom Out restore. A signed static pass **does not establish** that Zoom actually hides the Dock on device.

## 2026-10-23 — Explicit signed test candidate 0.0.45~sceneowner1, user reported two failed functions

- Requested by owner: correct three-second round-divider-logo drag along split and restore YouTube playback from previously playable v0.0.37, without triggering ExitSafeMode. The owner's earlier standing request is to produce a real signed DEB for Sileo testing, not merely source.
- Exact prior playable build source commit `a8cdec6252b0e772faa726e92b84ee66246590ed` (run 39748923126 BUILD_SOURCE.txt); no general reverse-engineering redo; independent first-party scene host only.
- Current focused patches: logo contact/3-second delta `6bf6bca4`, `1fcd3122` and regression test; scene geometry restore compared with .37: `bb30a4bc`, `f374828a`, `df041387`, `cd410a37`, stale contract updated `e837ef00`. Source-only run 39911525744 SUCCESS. These changes are source/test results only, no verified iPhone playback or gesture result yet.
- Versioned NativeHost `0.1.54~sceneowner1`, integrated single rootless DEB `com.duoface.jb.embedded_0.0.45~sceneowner1_iphoneos-arm64.deb`; archive exact source SHA, run ID, signer and package SHA256, never overwrite .37/.43. Use existing Theos/macOS-15 package workflow triggered by THIS build-request file; do not start a duplicate run. Only publish after SUCCESS and independent SHA APT verification. Current expected rollback public .43 remains unchanged until then.
- Acceptance on parked physical CarPlay: long hold circle 3 seconds then move up/down without jump and maintain draggable divider; launch YouTube video, seek/play/fullscreen or split with no SpringBoard ExitSafeMode; validate menu Zoom and Dock separately. No third-party addon blame without clear evidence.

## 2026-10-23 14:xx ICT — Owner explicitly requested signed .45 candidate AND Sileo publication

- Source base `0e6bf1c1e72c0def05bb04fbf2c2ce46e5e03cb4` already passed CI 39916178625 (Objective-C iOS16 syntax + 58 source contracts), not device playback.
- New immutable version: independent NativeHost `0.1.54~sceneowner1`; SINGLE integrated rootless `com.duoface.jb.embedded 0.0.45~sceneowner1` (previous 0.0.44 remains untouched, rollback preserved).
- Incorporates independent first-press App chooser/composed Native12 App/Zoom/Style/Close header, passive hidden-control wake, and scene ownership/geometry-invalidation fix. This package change DOES NOT assert YouTube Exit Safe Mode, Zoom Dock, 3-second grip or player UI parity is fixed on the phone. 
- This request path change is the scoped push build trigger. Verify actual signed iOS16 package workflow and commit immutable DEB+SHA; THEN update Sileo publisher only for integrated DuoFace exact new immutable URL/checksum; verify Pages/deployed public APT and downloaded DEB checksum. Preserve other Sileo packages and earlier DuoFace versions. Physical test gate remains pending; user must test parked device.
