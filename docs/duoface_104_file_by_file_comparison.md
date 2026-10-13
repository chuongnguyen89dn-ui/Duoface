# Verified directory and hash comparison (2026-10-13)

Inputs: original DuoNavi 1.0.4 DEB and **v12-first delta** DEB (not original 35-file v12). Extracted via `dpkg-deb -x` to `/mnt/data/duoface_diff/up` and `/mnt/data/duoface_diff/base`. Compared exact relative paths and full file bytes in Python.

- **22 shared paths, all 22 byte-identical:** 21 voice audio assets under `Library/Application Support/DuoNavi/Audio/` and `usr/lib/ellekit/OldABI.dylib`.
- **28 upstream-only paths:** `Applications/DuoNaviUI.app` 20 (18 AppIcon files, executable, Info.plist); `Application Support/DuoNavi` 3 (logo/icon); `MobileSubstrate/DynamicLibraries/DuoNaviDashboard` 2 (dylib/plist); `etc/sudoers.d/duonavi` 1; `usr/bin/cboptimize` 1; `usr/libexec/cboptimize_helper` 1.
- **35 v12delta-only paths:** `Applications/DuoFaceUI.app` 20; `Application Support/DuoFace` 7; `MobileSubstrate/DynamicLibraries` 4 (DuoFaceDashboard and DuoFaceVisualHook dylib/plist); `etc/sudoers.d/duoface` 1; `usr/bin/duoface-cboptimize` 1; `usr/libexec/duoface_cboptimize_helper` 1; `var/mobile/Library/Preferences/com.duonavi.sync.plist` 1.

The 28 upstream-only paths include renamed counterparts of v12, **not 28 independent missing features**. Preserve v12 interface/assets and its Dashboard. Native 1.0.4 voice classes live inside the different upstream Dashboard binary, not in the 22 identical files. Copying its Dashboard or application as extra files would cause duplicates; no proof of working voice integration. Need original v12 DEB for original-vs-original comparison and device tests before a release.
