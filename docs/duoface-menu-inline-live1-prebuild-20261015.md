# DuoFace menu-inline-live1 — prebuild and release gate (2026-10-15)

## Scope and owner's approval protocol
- Target only `chuongnguyen89dn-ui/Duoface` branch `main`, with existing rootless native v12 DEB serving as immutable base. The owner requests a rebuilt DEB containing all approved UI fixes, but the standing project gate requires a **full user-visible change list BEFORE invoking any DEB build, and owner confirmation of that list**. This document is preparation, NOT package/build authorization or a successful run.
- Original `com.duonavi.app` package ID MUST NOT change; no entitlement/license/trial/time changes. Keep native `DuoFaceDashboard.dylib` unchanged, native split ratio and fullscreen actions, native picker X, red activity border.

## Exact UI changes intended for the one pending candidate
1. Menu-only DuoFace horizontal brand logo with true alpha background, visually inline with existing native 30pt App/Zoom/Style/Close row; source uses left 120pt slot and reserves 48pt for separate native X.
2. Clear picker-owned dim, blur, 1pt frame outline and divider while retaining the dismiss view and original click callbacks; underlying CarPlay application must remain visible while menu is open.
3. Tabs display App, Zoom, Style, Close. Zoom arrows adapt to expanded state, unchanged message and functionality; native + Add App tile becomes ellipsis, original action retained.
4. Close/recent header no longer shows `Đang hoạt động: N ứng dụng`; original native close-all button moves into its former position, caption `Clear All`, menu-style compact trash icon, keep native callback.
5. Native recent cards show app icon—app name—small colored ● all horizontally centered; GREEN `#34C759` for in-current-CarPlay-slot Live, RED `#E3020F` for offslot/background. Hide status words, PID numbers and Left/Right column labels. Name truncation handles long titles.
6. Native action button remains in its original wide hitbox with NO visible text: green `arrow.clockwise` refresh icon for active-slot, original `restartSingleAppTapped:`; red `xmark.circle` for offslot, original `closeSingleAppTapped:`. No new app-processing logic.
7. Leave the previously working fullscreen and native activity red border untouched; Sileo release NOT part of package candidate build.

## Source and exact base/asset
- Source `runtime/fullscreen/DFPickerZoomMenu.xm`; critical ObjC++ compile error from commit `612a724` (`UIImage *template` is a C++ keyword) was fixed at `ba71ebe009f57fb8214a96af135ad179f0e3835f` (`templateImage`). Both source workflows PASS: [38671242031](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38671242031), [38671242205](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38671242205). Source-only, NOT device tested.
- Immutable base: `dist/candidates/menu-zoom2/com.duonavi.app_1.0.3-12_menu-zoom2_iphoneos-arm64.deb`, SHA256 `0a44524456caa6a530fd1e605020f592e79500738de643a59ef0ff8e02296ad4`.
- Native Dashboard target path `/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib`, SHA256 `bc1df854ec7a2ddfeec4cb81b080ead34b54df80143d4a8f6254bb8b618003ce`, immutable.
- Original logo retained `/var/jb/Library/Application Support/DuoFace/duoface-logo.png`, SHA256 `78450d8ee4759353bdc21f27a06016c03fab61038ae60109ba21515c087b0089`.
- Menu-only alpha logo source `dist/visual-1.0.3-12/assets/duoface-logo-picker-alpha-v2.png` — SHA256 `43b6dafb8fc0550c2b3032c11acae1e0712350ca5b4dd235b7dc14c7951c74f7`, dimensions 627×228 RGBA; install as NEW `/var/jb/Library/Application Support/DuoFace/duoface-logo-picker-alpha-v2.png`.
- Compile native bridge to `DuoFaceFullscreenBridge.dylib` arm64, `ldid -S`; preserve/verify both rootless SpringBoard `.plist` filters. Compile existing `DuoFaceVisualHook.dylib`, `ldid -S`; do not edit original source of red activity border.

## Manual candidate workflow and artifact contract
- Prepared **manual only** (not run yet): `.github/workflows/duoface-approved-border-deb.yml`, workflow name `Build DuoFace menu inline Live candidate (manual-only)`.
- Destination (new, collision-free): `dist/candidates/menu-inline-live1/com.duonavi.app_1.0.3-12_menu-inline-live1_iphoneos-arm64.deb`.
- Control: `Package: com.duonavi.app`, `Version: 1.0.3-12+menu-inline-live1`, original architecture. No overwriting earlier `menu-compact1`/previous candidates.
- Mandatory outputs: `SHA256SUMS.txt`, `BUILD_AUDIT.json`, `CONTENTS.txt` in `dist/candidates/menu-inline-live1/` and GitHub Actions artifact `duoface-menu-inline-live1`; the workflow compares staged vs DEB-extracted native dylibs, plists, approved old/new logos and native dashboard by SHA256, asserts version, architecture, package ID, and commits candidate only if all checks pass.
- Preflight script `scripts/validate_duoface_candidate_workflow.py` verifies source keys, original/alpha SHA, unique output location, manual-only YAML structure, bash syntax and embedded Python AST without invoking any package or Sileo. It is run first by compile-only gate `.github/workflows/duoface-next-compile-gate.yml`. Latest triggered [run #38673907914](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/38673907914) (static preflight step PASS at initial check; final source compile conclusion pending at time of writing).

## Remaining gates and actual user-device QA
1. Wait for compile-only gate `38673907914` to reach SUCCESS and persist SHA evidence. If failure, investigate exact job log and fix before any DEB.
2. Report full change list to owner and receive the required post-list confirmation to build. **Do not auto-trigger** this manual workflow on a push or re-run a stale workflow using an older source SHA.
3. Once confirmed and executable, run manual workflow from GitHub Actions on `main`, ONE RUN; watch steps to completion, inspect candidate checksum, rootless DEB metadata/content, artifact IDs, commit SHA and evidence. If a validation fails, do not publish/upload a broken candidate.
4. Install approved candidate on CarPlay by owner's preferred method ONLY after valid build; check actual transparent background/white-black logo artwork, tab spacing/native X, Add App ellipsis actions, Zoom direction, Clear All action, green/red dot placement and Refresh/X tap behavior, scrolling, red split-view border and fullscreen regression.
5. Sileo publication is a separate later approval; no automatic Sileo push.

## Explicit state
- Source written and compiled. Manual packaging source/workflow PREPARED but has **NOT run**, **NO NEW DEB**, **NO SILEO**, **NO DEVICE PASS**. Do not convert plans or CI green status to claimed artifact or device result.
