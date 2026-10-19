# DuoFace CarPlay Native Bridge QA: explicit configuration helper

Problem from iPhone X user screenshot (2026-10-19 ~17:12 VN):
- Sileo installed `com.duoface.carplay.nativebridgeqa 0.0.2~sidebartest1`, but no preferences `com.duoface.mytweak.carplay-bridge.plist` existed because runtime intentionally never writes the opt-in file.
- User attempted to copy an external .plist into `/var/mobile/Library/Preferences` with Filza and got **`FileCopyError -1`**. This could be a sandbox/source or destination permission issue; no proven underlying Filza error cause. DO NOT ask user to repeat failed copy.
- This **SEPARATE** optional Sileo package explicitly activates native QA at install time (not installed automatically as a dependency). It uses dpkg `postinst` (no respring) to write only one bridge-specific plist and saves earlier existing settings, and `prerm` restores them (preserving user edits in an archive). No root UIWindow, LS/SpringBoard hooks, or vendor code. Real Apple statusbar behavior still **hardware unverified** and may pose stability risks; install only while parked and with a known rollback.

Target preferences: `/var/mobile/Library/Preferences/com.duoface.mytweak.carplay-bridge.plist`, both Boolean `Enabled=true`, `NativeSidebarTrial=true`. **Does not change** `com.duoface.mytweak.v1bc.plist` (separate `Enabled=true` still required); leave stable MyTweak/QA11/Native12/HUD8 untouched.

Filenames under `DEBIAN/` are maintainer scripts, not a no-op XML staged in `/var/jb`. Their exact targets are fixed in code. This avoids relying on Filza to copy from an iOS Files sandbox into a protected directory.

Compile locally (Ubuntu/macOS dpkg): `bash sideplay/mytweak-native-bridgeqa/activate-helper/build.sh`.
Test: `python3 -m unittest discover -s sideplay/mytweak-native-bridgeqa/activate-helper/tests -v`.
Test a temporary copy of the scripts with substituted paths (never write to real `/var/mobile` on CI). Verify `dpkg-deb -e/-c/-f`, all hashes. Preserve QA2 SHA and standalone stable packages.

Rollback on device: uninstall **only** `com.duoface.carplay.nativebridgeqa.activate` in Sileo. The `prerm` must restore earlier preference state or delete newly created bridge plist without touching the other QA package. **No automatic restart**.

No claims of CarPlay Dock/Home success until actual device screenshot+log.
