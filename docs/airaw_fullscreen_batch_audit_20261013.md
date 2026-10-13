# Airaw fullscreen: batch inspection (2026-10-13)

Input: user-supplied `com.999.airaw_1.7.1k_iphoneos-arm64.deb`. Local evidence: `/mnt/data/airaw_audit/root`, `airaw_arm64_disasm.txt`, `objc_metadata.txt`.

Verified together:
1. Root preference bundle exposes **Host Menu** with explicit description "Fullscreen button and host menu while an app is open", controller `AirawChromeController`. This is distinct from separate Split View preference entries.
2. `Airaw.dylib` includes selectors `toggleFullscreen`, `requestFullscreenToggle`, `setDefaultAppChromeHidden:`, `setNativeChromeHidden:`, `arwExitNativeFullscreen`, and `applyDockChromeForScale:`.
3. CarPlay-related classes in the binary: `DBDockWindow`, `DBDockRootViewController`, `DBApplicationViewController`, `DBStatusBarWindow`, `CARStatusBarWindow`.
4. `llvm-objdump --macho --syms` confirms constants `_kARWHostFullscreen`, `_kARWCarPlayChrome`, `_kARWKeyNativeChromeHidden`, `_kARWKeyNativeFullscreen` in both arm64 and arm64e.
5. Existing disassembly contains `objc_getClass`, `class_addMethod`, `MSHookMessageEx` sequence for `DBDockWindow` and a subsequent lookup for `DBApplicationViewController`. Presence of these calls does **not** prove which selector actually hides the sidebar.
6. Airaw injection filter includes CarPlay-related host process and SpringBoard.

Conclusion: **Airaw's Host Menu fullscreen is a distinct binary subsystem from its Split View settings**. To implement in DuoFace v12, the missing critical proof is mapping actual dock-hide and host-frame-resize callsites on iOS16.7.x; the current evidence does not establish safe direct API calls. Do not replace original v12, transplant commercial Airaw binary, or claim fullscreen implementation/test.

Inspection commands: `dpkg-deb -x`; Python `plistlib.loads` on Airaw.bundle/*.plist; `llvm-objdump --macho --syms`; `llvm-objdump --macho --disassemble --arch=arm64`; `strings`. No modified DEB created.
