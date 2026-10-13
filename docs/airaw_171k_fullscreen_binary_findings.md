# Airaw 1.7.1k fullscreen binary findings — 2026-10-13

User-provided DEB: `com.999.airaw_1.7.1k_iphoneos-arm64.deb` (8,527,360 bytes), SHA256 `7819fb51c069211a68823c7c0998ca1b7edb733a276a639ad341406b31be88fc`. Package `com.999.airaw`, version `1.7.1k`, rootless.

Extracted main Mach-O: `var/jb/Library/MobileSubstrate/DynamicLibraries/Airaw.dylib`, 1,214,560 bytes, arm64+arm64e, SHA256 `46115c8f0a1d2d81cf4c003be58468d2a9b5c69e595f0f68d5fff5de53be4a9d`.

`Airaw.plist` targets `com.apple.springboard`, `com.apple.CarPlayApp`, `com.apple.CarPlayWallpaper`, `com.apple.UIKit`, `com.apple.mobilephone`.

Relevant literal symbols/strings found using `strings`:
- fullscreen entry/exit: `toggleFullscreen`, `requestFullscreenToggle`, `_setFullScreenEnabled:`, `arwExitNativeFullscreen`, `carplayFullscreen`
- system chrome: `setDefaultAppChromeHidden:`, `setNativeChromeHidden:`, `nativeChromeHidden`, `_kARWKeyNativeChromeHidden`, `jp.airaw.carplay.chrome`
- CarPlay windows/controllers: `DBDockWindow`, `DBStatusBarWindow`, `CARStatusBarWindow`, `CARRootStatusBarViewController`, `DBDockRootViewController`
- host fullscreen: `_kARWHostFullscreen`, `_kARWKeyNativeFullscreen`, `jp.airaw.host.fullscreen`

`llvm-objdump --macho --syms` confirms exported `_kARWHostFullscreen`, `_kARWKeyNativeChromeHidden`, `_kARWKeyNativeFullscreen` in both arm64 and arm64e.

**Verified:** the supplied DEB was actually unpacked and the above symbols are present in the binary. **Not verified:** callsite behavior, which class owns sidebar on target iOS 16.7.x, whether Airaw fullscreen preserves both DuoFace panes, or actual device behavior. This is binary evidence, not recovered source code. Do not transplant commercial binary or modify existing DuoFace v12 until compatibility is established.

Commands: `dpkg-deb -I`, `dpkg-deb -c`, `dpkg-deb -x`, `file`, `sha256sum`, `strings`, `llvm-objdump --macho --syms`.
