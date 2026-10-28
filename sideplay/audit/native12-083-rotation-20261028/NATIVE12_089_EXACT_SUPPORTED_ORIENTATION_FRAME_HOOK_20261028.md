# Native12: exact original hook callback ABI — gap missed in DuoFace .89

## Provenance
Real original Native12 HUD8 rootless DEB, not a standalone technique guessed from UIKit documentation:
- Pinned Git object: `1286a3ef868cf7e29804bcddf7e20b2eae707ce1:dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb`
- DEB SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`; original app-injected `DuoFaceDashboard.dylib` SHA256 `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`.
- Direct original ARM64 instructions and function boundaries (not selector name guesses): `NATIVE12_ORIGINAL_APP_ORIENTATION_HELPER_RUN_40648090838.json` produced by original DEB scanner; hash and installer-site readback reverified in GitHub Actions run `40665510392`, saved inventory `NATIVE12_089_VERIFIED_REAL_DEB_HOOK_GAP.json`.
- Original `DuoFaceDashboard.plist` explicitly includes `com.google.ios.youtube` in injection filter; does **not** prove a particular callback was executed for each player transition on the user's device.

## Exact original callback 1: UIViewController.supportedInterfaceOrientations
ARM64 *installer* @`0x2ac694..0x2ac6bc`:
- `0x2ac694`: `objc_getClass("UIViewController")`;
- `0x2ac6a8`: selector `supportedInterfaceOrientations`;
- `0x2ac6ac`: `adr x2,#1368` => hook callback **`0x2acc04`**;
- `0x2ac6bc`: actual `bl _MSHookMessageEx`.
Actual callback **`0x2acc04..0x2acc60`**:
- `0x2acc18` calls the bridge-state getter `0x2a8068`; `0x2acc1c` branches to unbridged original method at `0x2acc44` if false.
- `0x2acc20` calls the requested-orientation getter `0x2a8080`.
- `0x2acc24..0x2acc34` clamps orientation >=1 and computes `1 << orientation` with `lsl w8,w9,w8`, then returns the resulting UIKit supported-orientation mask.
- For original Native12 payload orientation=1 from `CBBridgeManager.sendStateToApp:shouldBridge:`, active supported mask is **`1 << 1 = 2` (`UIInterfaceOrientationMaskPortrait`)**.
- When not bridging, it jumps to the saved **original UIKit controller implementation**, not an unconditional global Portrait override.
Another installer for `__supportedInterfaceOrientations` at `0x2ac6c4..0x2ac6dc` has callback target **`0x2acc60`**; its callback body is not included in this archived exact-function subset, so cannot assert its return policy without additional disassembly.

**Gap in .89:** `DFYouTubeOrientationRelay.m` calls `[controller setNeedsUpdateOfSupportedInterfaceOrientations]` and `requestGeometryUpdateWithPreferences` one time but never changes an actively bridged YouTube controller's `supportedInterfaceOrientations` answer. That behavior is provably different from the original. Whether this particular difference explains video pixels staying rotated still needs an on-device callback/result log.

## Exact original callback 2: UIWindow.setFrame:
- `0x2ac6e0` gets class `UIWindow`, `0x2ac6f4` selector `setFrame:`, `0x2ac6f8` `adr x2,#1476` => actual callback **`0x2accbc`**, `0x2ac708` actual `bl _MSHookMessageEx`.
- Callback **`0x2accbc..0x2acdd8`**:
  - `0x2accec..0x2accf0` branches on bridge-state getter;
  - `0x2accf4..0x2acd08` reads requested logical width/height, and only applies bridge-specific frame logic with positive dimensions;
  - `0x2acd34..0x2acd50` checks window level against `UIWindowLevelNormal`;
  - `0x2acd5c..0x2acd98` conditionally transforms the incoming CGRect depending on window and size;
  - `0x2acda0..0x2acdd4` tail-calls the saved original `setFrame:` method with adjusted or original values.
- A companion original `UIWindow.setBounds:` installer @`0x2ac710..0x2ac728` points via `adr x2,#1732` to callback **`0x2acdd8`** (body not yet extracted). The preceding frame callback is proven actual code, not just a named selector.

**Gap in .89:** It directly rotates/resizes current windows after a state notification; the original also intercepts later UIKit frame changes while bridged. A subsequent YouTube player/video full-screen/gesture layout can call `setFrame:` later; original may adjust it, .89 doesn't. This is a concrete functional discrepancy. It does not yet prove what UI element is mutated during the user's swipe-down transition.

## Other original active hook installation sites not represented in DuoFace .89
Machine-verified 36 `_MSHookMessageEx` call sites under `0x2ac688..0x2acc04`, including `UIWindowScene.interfaceOrientation` @`0x2aca00`, `UIDevice.orientation` @`0x2aca6c`, `UIScreen.bounds/nativeBounds/_referenceBounds` @`0x2acaf8/0x2acb18/0x2acb38`. These are original app-process **runtime view virtualization** avenues, beyond a one-shot geometry request. Actual callback conditional behavior for these selectors remains to be decoded; don't globally hook everything without understanding them.

## Decision and precise next step
- User's reported **.89 YouTube split video orientation DEVICE FAIL** overrides build/Sileo success; do not claim Native12-equivalence.
- We previously **reused valid facts from original DEB but guessed** that restoring app state + internal windows + one-shot geometry was sufficient. It was not the original's full operational mechanism.
- **Stop releasing .90 until proven callbacks are mapped.** Target the real callbacks `0x2acc60` (second supported-orientation selector), `0x2acdd8` (bounds), plus `UIWindowScene.interfaceOrientation` and `UIScreen.bounds`. Use original LC_FUNCTION_STARTS and SHA-pinned ARM64 to document exact return values and lease predicates; then design an independent YouTube-only equivalent with teardown/phone restore, unit tests, and device logs. Do NOT copy vendor code or licensing. No modification to Maps, Dock, .83 `DFSceneLifecycle.m`, or Sileo index in this audit.
