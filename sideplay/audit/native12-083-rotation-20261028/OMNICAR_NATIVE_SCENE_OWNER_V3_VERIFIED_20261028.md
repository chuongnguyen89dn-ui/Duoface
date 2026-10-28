# OmniCar original 1.0.3: native CarPlay map ownership / scene repair, static ARM64 V3

## Evidence chain
- Original binary: `Omnicar/com.anlai.omnicar_1.0.3_iphoneos-arm64.deb`, SHA256 `d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd`; source reference **READ-ONLY**.
- Gpt-training ZIPs `skills/02-ios-deb-ipa-carplay.zip` (SHA256 `c87b5ed9ef196c13f42dd41df49a032369028742cc8f6d56569637daf76ec7cf`) and `skills/05-research-debug-testing.zip` (SHA256 `fcb1122412a11664c2c6b8666cbc4f76e86ad20f96e697138d96c6425137dc98`) were downloaded by GitHub Actions, SHA-verified, and `SKILL.md` / `references/VERIFICATION.md` extracted and printed; evidence job `122620428372`. Skills require no uncontrolled original hooks, no unverified production claims.
- First-party audit script `sideplay/tools/audit_original_omnicar_native_owner_v3.py`; exact GHA run [40628918504](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40628918504) **SUCCESS**, original SHA match, 20/21 selected ObjC IMPs present (one name intentionally not present, reported absent), no mobile execution.
- Archived SHA-pinned original-only report `sideplay/audit/native12-083-rotation-20261028/OMNICAR_ORIGINAL_NATIVE_OWNER_V3_RUN_40628918504.json` (Git blob `ffc17d7c47f2f3e02642a4e9f2857fd2b9c21cde`); GitHub artifact [12790049447](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40628918504/artifacts/12790049447).
- Every following offset is from actual ARM64 CFString reference in extracted original OmniCarSplitScreen dylib (not decompiled source code, not proof of path running on iPhone).

## NEW original facts beyond V2

### 1. OmniCar has a scene owner lookup, not just an app-bundle whitelist
- `SCPCarSplit.adopt:slot:` IMP `0x1942c`: asks `applicationInfo` at `0x194a8` and `0x19534`; `proxyApplicationInfo` at `0x1955c`/`0x19598`. Guards invalid slot via `CarSplit: bo qua dua VC vao o %d (chi co %d o)` @`0x194fc`; logs actually adopting `CarSplit: dua %@ (%@) vao o %d` @`0x19b08`.
- `SCPCarSplit.sceneOfViewController:` IMP `0x1aaf4` has verified `sceneHandle` @`0x1ac64` and `scene` @`0x1ac84`; checks for nonnil scene before returning. This shows **actual view-controller/scene association** rather than making up a scene from the app ID.
- `SCPCarSplit.publishCarPlayApps` IMP `0x21b1c`: original log `CarSplit: %lu app CarPlay cho Settings, %lu app iPhone da chon (App Bridge)` @`0x21c68` verifies two separate app inventories. `isCarPlayApp:` IMP `0xff20` verifies `carPlayDeclaration` along with hidden/fullscreen/bridge flags, not visual scaling.

### 2. Original checks actual scene frame and repairs a mismatched scene
- `SCPCarSplit.verifySceneOfPane:expected:retry:` IMP **`0x1cce0`** (NEW): reads `settings` at `0x1cd9c`/`0x1cdc0`/`0x1cdfc`, `frame` at `0x1ce5c`/`0x1ce80`; logs `CarSplit: scene %@ that = %@ (can %@)%@` @`0x1d004` with markers `-> van sai` @`0x1cfd4` / `-> ve nen roi len lai` @`0x1cfdc`. Then original requests `backgroundSceneWithCompletion:` @`0x1d084`; if eligible to retry, it requests `foregroundSceneWithSettings:completion:` @`0x1d2fc`. Explicit original error logs at `0x1d19c` / `0x1d3d4`.
- `SCPCarSplit.pushSceneSizes` IMP `0x1c550`: same `foregroundSceneWithSettings:completion:` @`0x1c738`, and **a guarded `sceneHostView` getter** @`0x1ca04` with `respondsToSelector:` branch @`0x1ca20`; fallback KVC-like read @`0x1ca40`; logs `sceneHostView %@ -> %@` @`0x1cb5c`. This is a real native **host view + scene frame** route independent of scaled phone MainDisplay app frame.
- A `background → foreground` recovery is **conditional** original behavior for mismatched actual frames, not an instruction to force-switch scenes every zoom and not proof it will fix an AVPlayer orientation bug. Any independent DuoFace implementation must verify its own scene owner before attempting analogous transitions; blindly repeating will risk the known .83 SpringBoard crash regression.

### 3. Original explicitly protects foreign scene teardown
- `SCPCarSplit.scene:destroyedForViewController:ownScene:` IMP `0x1ad58`: two distinct verified log branches:
  - actual owner destroyed: `CarSplit: scene cua %@ bi huy (app thoat/crash) -> dong ngan %d` @`0x1aec4`
  - **foreign/replaced scene**: `CarSplit: scene %@ bi huy khong phai cua %@ (%@) -> giu ngan %d` @`0x1afc4`.
- Indicates original *identity check* before closing pane, relevant to user requirement that native Maps stay alive. It does **not** prove one Maps app can display its CPWindow concurrently in two surfaces or establish entitlement to borrow it.

### 4. CarPlay-native launch and iPhone AppBridge are distinct
- `SCPCarSplit.openApp:slot:` `0x164d4`: refuses missing CarPlay interface `0x165a4`, handles already opened app `0x166cc`. Native admission/slot logic.
- `SCPCarSplit.sendLaunch:bundle:tries:` `0x16e04`: reads `currentBaseViewController` @`0x16e80`, logs `DashBoard con trinh bay %@ -> doi ve Home xong roi moi mo %@` @`0x16ff4` and after 3 s may proceed `0x170b4`. It manages native Dashboard presentation state, NOT an arbitrary app scale.
- `SCPCarSplit.hostApp:inPane:` `0x3e490`: records `AppBridge: host %@ vao o %d` @`0x3e6f4` and posts `com.anlai.omnicar/appbridge.open` @`0x3ea84`. `launchPhoneAppIfNeeded:` `0x403d0` similarly refers to `AppBridge:`. This is a **second, phone-app path** separate from native CarPlay scene/slot.
- `SCPCarSplit.closeSlot:background:` `0x1d9b8` and `removePaneAt:background:` `0x149a8` are separate methods; never equate closing DuoFace pane with terminating another native navigation app without interpreting exact ownership/flags.

## Actual DuoFace architectural gap and allowed next step
- `sideplay/duoface-native-scene-host/DFSceneHost.m` currently constructs `SBDeviceApplicationSceneEntity initWithApplicationForMainDisplay:` for regular iPhone-app scenes, including Apple Maps. That scene need not be a native CarPlay `CPTemplateApplicationScene`/navigation CPWindow. A zoom percentage only scales the *wrong scene*.
- User explicitly rejected map-only zoom 80%; current DuoFace source restored shared 0.50 visual transform and V3 is read-only. The pre-rollback signed .85 DEB contains the rejected code — retain only as historical artifact, do not represent as the user-requested native-map fix.
- **Unproven:** on-device native CarPlay owner process, concrete scene class/role, whether same active native Maps scene can be viewed in two distinct panes, whether device's current Maps view supports visible native map in both surfaces, exact receiver of private selectors in current iOS16.7.16. Don't create a fake map, fake entitlements, force scene lifecycle, or copy vendor binary.
- **Next precise action:** map `adopt:slot:` incoming VC to live CarPlay owner, scene/handle/settings/current frame and `sceneHostView`; capture read-only scene identity/role/owner while an actual Maps session is running on parked iPhone X/CarPlay. With that verified, implement an independent scene-owner-aware native pane routing branch (preserving original scene lifecycle and standalone phone AppBridge), then sign/publish a *new*, testable DEB to Sileo.

## Publication discrepancy confirmed this session
- Handoff older top checkpoint had marked .85 'not published'. Actual `chuongnguyen89dn-ui/carplaydsp` production repo commit `dac5b323603a8a7671990c5eb879bc43347a4a0a` and published Actions [40627384428](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/40627384428) show **.85 DID reach Sileo before user's rejection**; `build/deploy/verify-duoface-integrated-pages` all SUCCESS. This is **not** validation of its map functionality. Mark .85's scale change as rejected, don't republish it as an approved native-map solution; preserve .83/.84 for rollback. No Sileo mutation made by the V3 audit.
