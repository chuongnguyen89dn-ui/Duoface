# 2026-10-28 — User rejected 0.80 map zoom: OmniCar original behavior is the only accepted reference

## Superseding requirement (source of truth)
User: "Thứ tôi cần là bạn làm giống theo deb gốc ko phải là dự đoán hoặc tự tăng % tỷ lệ zoom lên".

The user explicitly rejects the provisional `DFHostedMapRenderSize.h` .85 map zoom `0.80`; do not publish or describe it as a correct map implementation. Exact expected behavior:
- Show **actual native navigation map** in DuoFace's CarPlay split pane rather than a scaled iPhone app directions-only view.
- Existing Apple/other CarPlay navigation may remain running; must not forcibly close/restart native Maps.
- Based on SHA-pinned **OmniCar original 1.0.3** exact `SCPCarSplit` and `OmniCarAppBridge` method/scene routing, not copied vendor binaries/licensing and not invented percentages or CarPlay entitlement bypass.
- Keep independently first-party DuoFace, last real-device video playback/no crash .83, .84 public, working Dock/Zoom/SOLO/divider/logo/4s controls.

## Correction committed in DuoFace source (not a new device fix)
- `sideplay/duoface-native-scene-host/DFHostedMapRenderSize.h` **commit `f978276a24d8908fe193ca8d6414b0ad57338cf8`** removes unapproved 80% map-only branch, restoring old iPhone host geometry (logical = `round(2×pane)`, transform 0.5) for *all* apps, while retaining map bundle ID classification ONLY for future native-owner routing. This prevents slipping a subjective visual multiplier in as "original".
- Regressions `tests/test_omnicar_maps_085.py` commit `361e9eb3` and `tests/map_render_profile_runtime.m` commit `fca7a8a6` now explicitly assert no map-specific zoom and unchanged baseline geometry. Prior .85 compiled DEB `sideplay/jb-embedded-appbridge/evidence/runs/40626852244/com.duoface.jb.embedded_0.0.85~mapscene1_iphoneos-arm64.deb` checksum `d3f47cc420dec924e5e2ddb2e66c15ca461e341c189bf21a8db8e6ceab7afa1f` remains archived as **REJECTED/UNSUPPORTED .85**, cannot silently relabel or publish it. **Not recompiled after rollback at this checkpoint**.
- No edit of `DFSceneLifecycle.m` known-good .83 crash mitigation. No Sileo publisher changes.

## Original DEB facts already verified (not inferred runtime)
- Original OmniCar `com.anlai.omnicar_1.0.3_iphoneos-arm64.deb` SHA256 `d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd`.
- Read-only GitHub Actions run `40627274416`, report `OMNICAR_NATIVE_MAP_ROUTING_ARM64.json`: original `OmniCarSplitScreen` has `SCPCarSplit.isCarPlayApp:` IMP 0xff20, `openApp:slot:` 0x164d4, `hostApp:inPane:` 0x3e490, `paneSize:forBundle:` 0x1b328, `publishCarPlayApps` 0x21b1c, `pushSceneSizes` 0x1c550, `pickerMapForPane:height:` 0x329a0. Confirms separate native CarPlay category/slot/size pipeline.
- Original `OmniCarAppBridge.layoutPane:` manipulates iPhone-host `frame/transform`, `appBridgeZoom/100` range 0.6..1.0; includes `sceneHandle/sceneIfExists` and guarded remote `setInterfaceOrientation` settings. That is a **different owner** than native CarPlay map. Its 0.6..1.0 valid range DOES NOT justify choosing 0.80 for Apple Maps. No evidence that changing this alone retrieves `CPWindow`.
- DuoFace `DFSceneHost.m` uses `SBDeviceApplicationSceneEntity initWithApplicationForMainDisplay:`, i.e. iPhone app scene; not a proven adapter for native `CPTemplateApplicationScene` or native CarPlay Maps.

## New original-first forensic action
- `sideplay/tools/audit_original_omnicar_native_map_cfstrings_v2.py` commit `7bede3a2e31dfe09c678a54156f053ec50499600`: SHA-pinned read-only original 7-method full ARM64 disassembly, actual `__cfstring` references and branch maps to distinguish native CarPlay-app classification from iPhone-host route; not a replacement source.
- Workflow `.github/workflows/duoface-original-omnicar-map-branches-v2.yml` commit `be3500a673f8d0ac35ac56e2c22230a6a5899f52`: audit only, run-specific report archive under `sideplay/audit/native12-083-rotation-20261028/OMNICAR_ORIGINAL_NATIVE_MAP_BRANCHES_V2_RUN_<runid>.json`, no DEB build, no Sileo or device mutation. CI status needs verification before asserting success.
- Native CP scene owner still unproven by a mere static string; avoid fake CPWindow, spoof navigation entitlement, inject into unrelated Maps process or terminate active CarPlay app.

## Next step / acceptance
1. Read V2 original method/CFString branch report and identify actual native map classification and target owner at callsites. If still ambiguous, produce explicit limited read-only live diagnostics of native CarPlay app owners, scene role, and pane/slot, with Apple native map still running. Never guess.
2. Implement only *verified* original *behavior* via independently coded scene-owner adapter. Preserve existing CarPlay native navigation owner if already active and show actual map not only textual turn prompts. Do not use a standalone arbitrary scale.
3. Test on parked iPhone X: map visible inside DuoFace while CarPlay map continues running without forced close, split/solo/zoom; YouTube first zoom orientation fixed without inner fullscreen; video/no Safe Mode; rollback .83/.84 available; signed new DEB Sileo after source+device gates (device gate may require release candidate for real test).
4. Update `sideplay/tiep tuc du an.md` and verify. Keep rejected .85 history clear.

States: **[CODE REVERTED]** guessed map zoom, **[AUDIT STARTED]** exact original map branch reconstruction, **[NOT YET VERIFIED]** native map in DuoFace, full scene orientation fix, new signed build and public Sileo.
