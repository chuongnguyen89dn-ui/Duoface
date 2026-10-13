# Airaw fullscreen — multi-component evidence and conclusion

Analyzed the user-supplied `com.999.airaw_1.7.1k_iphoneos-arm64.deb`, not Airaw source code.

## Scope and evidence

1. **Packaging:** rootless `com.999.airaw`, `1.7.1k`. Package contains `Airaw.dylib`, `AirawViet.dylib`, `ARWWidgetInfo.dylib`, preference bundle, control-center bundle and localization files. The primary fullscreen hooks are present in `Airaw.dylib`; `AirawViet.dylib` has localized fullscreen descriptions; `ARWWidgetInfo.dylib` yielded no relevant fullscreen/dock strings.
2. **UI config:** `Airaw.bundle/Root.plist` contains a separate Host Menu group: "Fullscreen button and host menu while an app is open", linked to `AirawChromeController`. This is separate from the Split View preference category.
3. **Toggle / state:** `Airaw.dylib` contains `toggleFullscreen`, `requestFullscreenToggle`, `arwExitNativeFullscreen`, `_setFullScreenEnabled:`, `_kARWHostFullscreen`, `_kARWKeyNativeFullscreen`.
4. **System chrome:** `setDefaultAppChromeHidden:`, `setNativeChromeHidden:`, `applyDockChromeForScale:`, `DBDockWindow`, `DBDockRootViewController`, `DBStatusBarWindow`, `CARStatusBarWindow`.
5. **Actual hook instructions:** arm64 disassembly at `0x42e48` loads `DBDockWindow`; fallback at `0x42e78` loads `_TtC9DashBoard12DBDockWindow`; `0x42edc` and `0x42f10` call `class_addMethod`; `0x42f30` calls `MSHookMessageEx`; next at `0x42f50` looks up `DBApplicationViewController`.
6. **Hook implementation:** `0x43a30` first calls an original-function pointer from `[0x84000+0xa8]`, then invokes an additional helper `0x4af40`, and conditionally accesses `NSDistributedNotificationCenter`. This confirms the hook wraps existing behavior rather than simply replacing it; it does **not** yet prove the selector or dock-visibility effect.
7. **Other codepath:** `0x13508` looks up `DBDockRootViewController` and `0x1351c` checks `objc_opt_isKindOfClass`. This confirms another dock-root reference, not a verified fullscreen path.
8. **Injection:** `Airaw.plist` targets SpringBoard and CarPlay-related bundles. Binary contains log strings labeled `[ALOG][iOS26-Native]`, but a log label is not proof that this branch is used on the user's iOS16 device. No iOS26 compatibility claim is made.

## Engineering conclusion for DuoFace v12

Airaw has a **distinct fullscreen host/chrome subsystem** and hooks Dashboard dock/application classes. The code proves hook existence, not the full sequence needed to hide the sidebar **and** expand both existing DuoFace panes. The decisive missing evidence is the selector stored at `0x80000+0xc68`, helper `0x4af40`, and any layout resize method. It would be unsafe to claim a working iOS16 fullscreen implementation from these findings alone.

**Do not** modify working v12, usage-day files, package ID, or existing split functionality. **No DuoFace fullscreen DEB was built or device-tested.** Next inspect the selector reference and relevant resize calls, then implement a separately switchable original hook with safe restore and a distinct test DEB.

Reproduction: `dpkg-deb -x`, `strings` on three dylibs, Python `plistlib` on preference files, `llvm-objdump --macho --disassemble --arch=arm64 Airaw.dylib` and inspect addresses listed above.
