# 2026-10-28 — Source implementation of independently scoped Native12 orientation contract (NO DEB RELEASE)

## Superseded acceptance
- User confirms DuoFace .89 YouTube video orientation still DEVICE FAIL in split. A prior Sileo/public SHA PASS only validates packaging, not a physical video fix.
- Work MUST be based on original binary, not random size or rotation tweaks; preserve known-good .83 media lifecycle, Maps, Dock, Chrome look, and independent ownership (do not copy vendor code/license).

## Actual original binary proof used for this implementation
- Immutable original Native12 rootless DEB SHA256: `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`.
- Original app-injected DuoFaceDashboard.dylib SHA256: `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`.
- Full 36 real `MSHookMessageEx` callback bodies, direct ARM64 code and original state getters: `sideplay/audit/native12-083-rotation-20261028/NATIVE12_ORIGINAL_36_HOOK_CALLBACKS_RUN_40667230467.json`, verified run `40667230467` SUCCESS.
- Exact ORIGINAL behavior:
  - UIViewController.supportedInterfaceOrientations @0x2acc04 and __supportedInterfaceOrientations @0x2acc60 return mask `1 << max(desiredOrientation,1)` when bridge-active, else saved UIKit IMP.
  - UIWindowScene.interfaceOrientation @0x2ad7f0 and UIDevice.orientation @0x2ad8d0 return bridged requested orientation while active, original otherwise.
  - UIWindow._rotateWindowToOrientation:updateStatusBar:duration:skipCallbacks: @0x2acfd8 and _setRotatableViewOrientation:duration:force: @0x2acef4 intercept LATER window rotation requests while active and forward original method.
  - Original `UIWindow.setFrame/setBounds` and `UIScreen` dimensions also modified in active bridge. **NOT implemented here**: exact app-scoped future window-size virtualization needs further safety proof. No global system-level hooks in SpringBoard.
  - Original bridge-state getter @0x2a8068 uses process-local active byte, orientation @0x2a8080, logical geometry @0x2a8098. Original state resets on bridge end; no unconditional global override.

## Code ACTUALLY changed on feature branch
- New `sideplay/duoface-native-scene-host/DFYouTubeOrientationVirtualization.h` and `.m`. First-party wrappers for those SIX observed original orientation getter/window-rotation selectors, not vendor code. Each hook checks exact YouTube process and installed-method ABI, resolves `MSHookMessageEx` only if supported by the existing hooking runtime; records missing symbol rather than pretending it works.
- Wrappers only return a virtual Portrait orientation during a fresh **main-thread** exact owner/scene lease, expire after 3 seconds unless Host heartbeats renew it; return previously saved UIKit implementation outside lease. Window wrappers additionally check `window.windowScene==DFYTLeasedScene`, nonhidden normal-level. Bounded and removable logically without uninstalling the global method installer. Process filter stays exactly `com.google.ios.youtube`.
- `DFYouTubeOrientationRelay.m` imports the new header, installs wrappers during YouTube-process constructor, updates lease after exact UIWindowScene ownership/heartbeat, clears lease BEFORE scene/window restoration on reset, and adds `virtualization` to ACK.
- `DFSceneHost.m` adds `virtualization=%@` and serializes ACK counters into existing `DuoFaceSceneHost.log`. Future device log can prove if hook runtime was unavailable, partially installed, inactive, or active. Existing .89 scene geometry request and old system layout preserved.
- `sideplay/duoface-native-scene-host/build.sh`: links new .m into the **existing** YouTube-only `DFYouTubeOrientationRelay.dylib`, no additional DEB/tweak. Existing `.github/workflows/duoface-native12-source-only-validation.yml` syntax-checks AND LINKS both files for arm64 iOS16 using Apple SDK.
- New regression `tests/test_native12_orientation_virtual_090.py` verifies exact ORIGINAL callback entry addresses, app-only/scene-owner/lease/ABI/restore conditions and integrated compile linkage.
- No changes to `DFSceneLifecycle.m`, Google Maps/Dock, any original vendor binary, or publisher repo.

## Actual testing/checkpoints
- Source-only iOS16 arm64 SDK syntax, link and existing source contracts: GitHub Actions `40672172967` **SUCCESS** at commit `9eb2d376cddb9982466c10d683abe5c87ac1f00b` (already included new wrapper, relay, source test, build and link).
- The later Host ACK-format logging change source CI run `40672304371` was in progress at the time of initial audit creation; check conclusion before claiming current commit passes.
- **No new signed DEB or Sileo publication**. Current source package metadata still say `0.0.89~splitscene1` (the PREVIOUS released signed .89 is immutable). The new code is NOT in Sileo .89; do not test old .89 and claim this new wrapper is present.
- **Not physically tested:** user iPhone X iOS16.7.16, YouTube split video pixels, hook symbol availability in ElleKit/Rootless, runtime crashes, or if subclass-specific orientation overrides bypass base-class wrapper.
- Versioning release-patch attempt was **blocked by the current tool safety enforcement**, so no package version bump, no signed .90, no Sileo. Do not claim it was released. Keep old versioned rollback.

## Exact next actions
1. Check GitHub Actions `40672304371` and latest branch head; resolve any source linker/runtime warning.
2. Review `DFYouTubeOrientationVirtualization.m` for semantic hazards (base UIKit hook, ABI of `MSHookMessageEx` and selector return encodings, main-thread lease) against original callback report and device log. Retain immediate original IMP fallback.
3. When repository edits are permitted, update all package metadata/version/packager tests to a **new** version. Build a single signed DEB through `.github/workflows/duoface-jb-embedded-appbridge-package.yml`, verify immutable SHA and publish Sileo only after positive CI results. Never overwrite existing .89 DEB.
4. On actual device after install: two panes YouTube immediately, player gestures, SOLO return, 30-sec video playback, no Safe Mode. Export `/var/mobile/Library/Logs/DuoFaceSceneHost.log` showing `youtube-app-handshake-ack virtualization={phase,hooks,leaseActive,split}`. An ACK hook install counter is still not proof that video pixels are upright.
5. If video still sideways despite active hooks, investigate original `UIScreen` metric/frame reconciliation and YouTube's actual video rendering window using confirmed app telemetry before further changes.

## GitHub paths / source execution
Repo `chuongnguyen89dn-ui/Duoface` branch `feature/duoface-jb-embedded-appbridge-20261020`. Source-only workflow `.github/workflows/duoface-native12-source-only-validation.yml`, command `python3 -m unittest discover -s sideplay/duoface-native-scene-host/tests -p 'test_native12_orientation_virtual_090.py' -v`, `xcrun --sdk iphoneos clang -dynamiclib -fobjc-arc -fblocks -target arm64-apple-ios16.0 ... DFYouTubeOrientationRelay.m DFYouTubeOrientationVirtualization.m`. No developer local iPhone shell available to perform physical test.
