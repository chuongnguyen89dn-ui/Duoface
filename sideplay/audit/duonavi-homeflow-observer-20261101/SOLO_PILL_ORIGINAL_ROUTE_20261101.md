# DuoNavi 1.0.4: dấu ba chấm khi mở app ngoài — đối chiếu bridge một ô (2026-11-01)

## New user-supplied device observation

User physically sees DuoNavi's own **three-dot menu** while an unsupported iPhone application is bridged on CarPlay. User hypothesizes the app runs inside the DuoNavi single-pane/no-split host. Treat the observation as real user evidence; the exact layout mode (solo preset vs focused split) remains **unverified**.

## NEW VERIFIED original binary evidence

Read existing original SHA-pinned ARM64 method extraction, not Native12 HUD8 substituted for DuoNavi:
- `sideplay/audit/qa146-native-home-dock-parity-20261031/runs/41189165129/DUONAVI_DUODASH_REPACK_NATIVE_APPBRIDGE_METHOD_CROSSWALK.json`, blob `137bc9f1b4abaee1d1e48e3bb446a632afb4057d`.
- `sideplay/audit/duonavi104-vs-duoface118-dock-20261029/ORIGINAL_DUONAVI104_DOCK_IMP.json`, blob `d72422d899119444a2045466de2ed9a20c4a9cea`.
- Vendor source bytes are SHA-pinned original `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb` SHA256 `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`, Dashboard dylib SHA256 `44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15`.
- `CBBridgeManager.appForBundleIdentifier:frame:` @0x1bf25c has a real `initWithBundleIdentifier:frame:` factory call. Full class chosen at runtime on each branch not independently proven by this short callsite.
- **`CBBridgedSplitApp.initWithBundleIdentifier:frame:showSplash:` @0x109bc8** (original DuoNavi, not HUD8) reads `splitPreset`, `splitMode`, `splitRatio`, `splitApp1..4`; constructs UI views, directly references **`multitaskingPill`**, attaches **`setOnPillTapped:`**, `setOnPillLongPressed:`, `setOnExpandTapped:`, `setOnRestoreTapped:`, `setShowsExpandButton:`, `setCompactMode:`, `configureDividerButtons`.
- **`CBBridgedSplitApp.layoutSplitViews` @0x10bad8** manipulates actual `appViews` / `setFrame:` / `setAudioOnlyBackgroundMode:` / `refreshSceneLayout`, and **`setFocusedMode:`**, **`setCompactMode:`**, **`setShowsExpandButton:`**, `bringSubviewToFront:`. The original pill is therefore part of a real bridge-container layout, not only a mock AppDock state.
- **`CBBridgeManager.showAppPickerForSlot:` @0x2a2630**, `showLayoutChooser` @0x2a2760, `showRecentApps` @0x2a2954 resolve against `currentApp` and its `window`. The original menu is tied to that manager-owned current application.
- Dashboard-side original `CBBridgeManagerDashboard.startBridging:withCompletion:` @0x2c5ce0 -> `prepareAndRequestActivation:` -> `requestActivation:`; `bridgeDidActivate:` @0x2c70cc writes Dock/Home state; `stopBridgingWithCompletion:` @0x2c5d54 -> `requestDismiss`. Real Observer3 phone log proves actual three bridged launches and Home stop/dismiss synchronous with Home (but not the preset count or visual outcome marker).
- These static methods are from DuoNavi104 and **not** the Native12 HUD8 addresses such as `CBMultitaskingPillView.pillTapped` @0x83cb4: do not swap code provenance.

## First-party DuoFace code mismatch

- Current `sideplay/duoface-native-scene-host/DFHomeStandalone144.m:485-568`: `DF144Solo.begin` constructs a bare full-screen `UIRootSceneWindow` and a `DFSceneHost.hostViewForBundleID:` as its single source-owned app surface. Explicit comment line 558-560: solo, **does not call DFNative12Chrome or app picker**. No per-pane pill/menu, no manager-owned picker on this path.
- `DFNative12Chrome.m:1037-1047,1718-1764` DOES own `DFAppPickerVC` and an appPickerWindow; however that is a **separate CPTemplate DuoFace path**, not the Home-launched solo owner.
- `DFCarPlayOwnerObserver.h:127-164` posts an async `standalone144.stop` on Home then forwards Apple original Home immediately; SpringBoard solo release + CarPlay Dock restore complete later. DuoNavi original callback stops/requests dismiss inside Home before return; Log26 current Home->stop 29.365-52.047 ms and user confirms wrong page.

## Revised root-cause assessment

**Confirmed architectural gap**: DuoFace standalone bridge has a direct SB-hosted scene but lacks the integrated **bridge container / single-pane UI controller / pill and picker state** present in original DuoNavi's `CBBridgedSplitApp` class. The user's three-dot observation makes this gap operationally relevant. This means a Dock-only fix cannot recreate the original app-selection UX.

**NOT YET proven**: user observed exact menu implies DuoNavi's actual saved `splitPreset=solo` rather than a focused multi-pane preset; original Observer3 sampled native CarPlay controller tree but not the vendor bridge's own pill/window tree, and had no manual `RESULT_APP_CHOOSER` marker. Nor is the exact Apple Home navigation target proven.

## Correct independent remediation design (not yet deployed)

1. Keep **one first-party bridge owner per request**, reusing current `DF144Solo` SpringBoard scene-host/lease lifecycle; do not install a second competing scene host.
2. Add a **source-owned Solo container** around this existing scene with a small pill/menu and the **same installed-app picker contract**, not a new fake Apple Dashboard window. Reuse first-party `DFAppPickerVC` data/model and make its app selection issue a **generation-checked replacement request** through the existing CarPlay↔SpringBoard broker, not a direct SB app launch that bypasses native Dock ACK.
3. Define solo states `idle -> hosted -> menu/picker -> replacing -> hosted`, plus `home exit -> cleanup -> chooser owner`; enforce one active owner/request/session, cancel stale callbacks; never overwrite native Music/Calendar. Do not synthesize `showingApp=YES`, change vendor licensing, copy any original implementation, swallow Apple's Home callback, or invent a timer.
4. The native Home callback's actual UI destination still needs an explicit observed/presented first-party page state; confirm owner + Home before/after state and chooser visibility, rather than equating native Dock=nil with chooser visible.
5. Once these independently written ownership contracts are implemented and statically/integration tested, build with existing DuoFace signed CI; publish via existing carplaydsp Sileo only if compile/archive/signature/diff pass. Physical acceptance = Safari chosen -> opens with first-party 3-dot menu -> its menu can show app picker -> Home lands in correct app chooser (not generic CarPlay Home); VLC/YouTube still work, native Music/Calendar remain normal, Dock and touchscreen work. Any failing checkpoint retains nativebridge4 as REJECTED.

**Execution status this investigation**: Existing original disassembly and current source read, side-by-side causality traced. No runtime source edited, no DEB build/deploy and no device test; this is a verified basis for an owner refactor, **not a falsely claimed fix**.
