# Build request .81 foregroundcontract1 — guarded Live scene policy (not device-proven)

Source commit a36140be518723abf103e2cf87b5802d7b4b5661 is a source-level comparison-based test candidate after the confirmed .80 YouTube/TikTok SpringBoard SIGABRT. The user requested continuation from f6120366 and investigation of whether .37 was truly successful. .37 CI build was successful but its CI_RESULT explicitly says DEVICE_TWO_APP_BRIDGE_VERIFIED=false; a user reported one YouTube play session with wrong rotation, not a stable pass.

The .77 fatal reason proves the Live scene observer received a foreground=BSSettingFlagNo diff; .80 has the same SpringBoard method +440 crash but its reason/writer is not directly recorded. Original DuoNavi/OmniCar ARM64 evidence shows guarded foreground/background policy in the existing frame settings transaction. Candidate .81 only adds selector-checked setForeground:YES and setBackgrounded:NO to the existing owner+generation+hosting-verified updateSettingsWithBlock while a new frame diff is requested. It does NOT prove preventing a later competing actor from backgrounding the scene.

KEEP UNCHANGED: current UI/layout, video frame/viewport algorithm, split, logo, Zoom, Swap, Dock, orientation, gesture ownership, timers, package ID and every other repository. No license/vendor binary copied.

Build on this exact request HEAD using existing macOS rootless workflow:
- NativeHost version: com.duoface.carplay.nativescenehost 0.1.90~foregroundcontract1
- Integrated DEB: com.duoface.jb.embedded 0.0.81~foregroundcontract1
- Architecture: iphoneos-arm64
- Run Python source tests and iOS SDK syntax, package one immutable DEB, check dpkg control+SHA256+4 independent inputs+30 file allowlist; save run evidence.
- No auto-install or respring. This build is NOT a device PASS.
- Then publish only verified artifact to the existing Sileo repository as a new version, keeping previous archives unchanged. On a parked vehicle test YouTube/Facebook/TikTok open, playback, seek, both panes, focus, close/reopen. Export DuoFaceFatalException.log and matched IPS on crash.
