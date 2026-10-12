# DuoFace v12: direct DEB binary inspection — 2026-10-12

Source: GitHub Actions run 38200927380, artifact 11725147347. Downloaded and extracted DEB SHA256 `a4b1ed0ef049d3fd5af10f5a0067b7f5ed5890a2ed29e39d3060d4cfcd4feddd` with `unzip` and `dpkg-deb -R`. Read-only; no device or binary changes.

- Debian Package ID: `com.duoface.app`; version `1.0.3-12~visualtest`. App bundle ID: `com.duoface.duofaceui`.
- Native executable `DuoFaceUI` 2456784 bytes, SHA256 `3d0f8eac292d2c22d7a773e520ff396d33498a4a14bf6e0f72eb62ccc9c174e3`.
- CarPlay library `DuoFaceDashboard.dylib` 7540464 bytes, SHA256 `bc1df854ec7a2ddfeec4cb81b080ead34b54df80143d4a8f6254bb8b618003ce`.
- Visual hook `DuoFaceVisualHook.dylib` 71632 bytes, SHA256 `448d03dce87f2886401269805f703ec5bf9662dedc74ea932541aa7b22160ca4`.

Both native binaries contain readable strings `com.duoface.license.sync`, `/api/v1/license/sync`, `isLicenseCurrentlyValid`, `remainingLicenseSeconds`, `installAndVerifyLicensePayload:errorMsg:`. Dashboard additionally contains `licenseWatchdogTimerFired:` and `LICENSE_KILL_TRACE` diagnostics for invalid license affecting CarPlay. The visual hook contains no license-check strings.

Neither native binary contains the ASCII substring `com.duonavi` or `license.data`. Absence of a readable substring is not proof the application does not access a path assembled at runtime.

Maintainer post-install script initializes `/var/mobile/Library/Preferences/com.duoface.plist` and optionally migrates `com.tiz.carbridge.plist`; it does not mention the DuoNavi license data path.

User confirms the supplied `com.duonavi.license.data` comes from device 1 after uninstalling original DuoNavi. Its 1020 bytes SHA256 `159155b89e74bb34bb16824f89619ce9d9272e4e93ff2e4dad8e86cd17ece4ae` contain two little-endian uint64 values at offsets 0x08 and 0x10: 1791604360 and 1792209160 (7-day interval, Oct 10–17 2026). This matches the reported ~4 days remaining, but does not prove which file the DuoFace runtime reads.

Next: verify actual runtime file reads or inspect native call references; preserve v12 and device 1. No installation or Sileo deployment.
