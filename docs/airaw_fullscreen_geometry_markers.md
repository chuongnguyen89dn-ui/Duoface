# Airaw fullscreen geometry markers — 2026-10-13

Actual input: user-provided Airaw 1.7.1k package, extracted `Airaw.dylib` at `/mnt/data/airaw_audit/root/var/jb/Library/MobileSubstrate/DynamicLibraries/Airaw.dylib`.

Command executed in local container: `strings Airaw.dylib | grep -Ei 'bounds|frame|size|fullscreen|chrome|safearea|dock'` and narrower checks for frame/scale/resize methods.

## Verified markers (exact binary strings)
- `[ALOG][ARWHostedSceneManager] hostBounds: %@`
- `[ALOG][ARWHostedSceneManager] frame: %@`
- `[ALOG][ARWHostedSceneManager] updateFrameWithSettingsBlock: %@`
- `[ALOG][HS][LayerHost] created via appViewWithSize host=%@ logical=%.0fx%.0f`
- `[ALOG][HS][LayerHost] applied host=%@ logical=%.0fx%.0f scale=%.3f recreate=%d`
- `[ALOG][HS][LayerHost] recreate sizeChanged=%d scaleChanged=%d`
- selectors: `hostBounds`, `updateFrameWithSettingsBlock:`, `appViewWithSize:`, `appViewWithSize:interfaceOrientation:`, `setBounds:`, `setFrame:`, `preferredChromeSizeForHostSize:`
- dimensions: `baseWidth`, `baseHeight`, `kDockWidth`, `kDockHeight`, `kStatusbarWidth`, `kStatusbarHeight`, `_hostWidth`, `_scaleRatio`
- fullscreen/chrome: `requestFullscreenToggle`, `toggleFullscreen`, `setIsFullscreen:`, `_setFullScreenEnabled:`, `setNativeChromeHidden:`, `setDefaultAppChromeHidden:`, `nativeFullscreen`, `nativeChromeHidden`.

## Narrow conclusion
The binary contains **explicit host dimensions and logical dimensions, scaling, and recreation when size changes**. These are stronger geometry clues than merely finding a dock-hide selector. However **no numeric before/after fullscreen sizes** were found in these static strings. Crucially, `ARWHostedSceneManager` and `LayerHost` markers may belong to a separate hosted/split subsystem: their presence does **not** prove that Host Menu fullscreen calls them. Need a call graph from fullscreen toggle to geometry functions, or runtime before/after window bounds captured on iOS16.7.x.

## Next exact validation
1. Trace Objective-C calls from `requestFullscreenToggle`/`toggleFullscreen` to `setNativeChromeHidden:`, dock hook, `setFrame:` and `updateFrameWithSettingsBlock:`.
2. Compare before/after actual `DBDockWindow.frame`, `DBApplicationViewController.view.frame`, CarPlay root bounds and status-bar frame on test device.
3. Apply only verified hide-dock + expand-app geometry path to DuoFace v12, keeping both panes and existing package/day state intact.

No DuoFace DEB modified or built in this checkpoint.
