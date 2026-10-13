# Fullscreen-only batch: package modules and UI configuration

Inspected local user-supplied Airaw 1.7.1k DEB across all preference plist files and the main Airaw dylib; commands: Python `plistlib.load` across `Airaw.bundle/*.plist`, `strings Airaw.dylib | grep -E 'savedRect|savedEdgeInsets|nativeChromeHidden|fullscreen|Fullscreen|fullScreen|FullScreen|hostBounds|setFrame:'`.

Findings: Root.plist has separate `Host Menu` group with description `Fullscreen button and host menu while an app is open` and controller `AirawChromeController`. Separate groups for `Split View Native`, `Split View Standard`, `Split View Shared`. Main binary has `jp.airaw.host.fullscreen`, `HostFullscreen`, `requestFullscreenToggle`, `toggleFullscreen`, `carplayFullscreen`, `savedRect`, `savedEdgeInsets`, `setFrame:`, `hostBounds`, `nativeChromeHidden`, `_setFullScreenEnabled:`, `setIsFullscreen:`, `arwExitNativeFullscreen`.

Important scope distinction: Binary also contains `nativeSplitFullscreen`, `postNativeSplitFullscreen:`, `postNativeSplitLayout:nativeOnLeft:vertical:fullscreen:baseRect:`. These are *split-view* pathways, and must not be confused with whole-host fullscreen requested for DuoFace v12.

The package and selectors do not give numeric before/after frame values or a working iOS16 host-resize sequence. No v12 DEB modified, compiled, or device-tested. Next inspect actual host-fullscreen notification receiver and its frame changes, not native split layout.
