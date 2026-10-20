# DuoFace Test — real app icon + Sileo rootless, not Filza

**User-requested UX:** install `DuoFace Test` as ONE visible iPhone application through the existing CarPlayDSP source. When tapped, it opens an actual UIKit screen with `Bắt đầu thử Dock · 45 giây`, `Dừng thử và hoàn nguyên`, `Kiểm tra kết nối`, `Chia sẻ nhật ký`. Existing QA bridge and stable MyTweak are dependencies resolved by Sileo, not separate manual instructions. This replaces Filza preference files and the old helper activation instructions for **future tests**.

The .deb contains a real ad-hoc-signed `/var/jb/Applications/DuoFaceTest.app` (UIKit executable, Info.plist, compiled LaunchScreen, self-generated icons) and **separate tiny SpringBoard-only receiver** `/var/jb/Library/MobileSubstrate/DynamicLibraries/DFDuoFaceTestController.{dylib,plist}`. Receiver is not a new CarPlay host, does not hook app admission / LS / SpringBoard scene, and **does nothing until the user explicitly confirms Start in the UI**. The app and controller communicate via Darwin notifications and acknowledgements; no user-edited .plist. Only the SpringBoard receiver writes the existing V1BC+bridge preference keys. On Start it checks the base settings exist, stores the previous V1BC Enabled flag, sets both flags and NativeSidebarTrial for up to 45 seconds. On Stop, expiry, or SpringBoard restart with a leftover lease, it **restores the original V1BC Enabled** and forces the experimental native bridge flags false. No respring is executed by install scripts; a single user-controlled SpringBoard restart may be needed to load a newly installed controller dylib.

Known constraints:
- UI is a real app, but native Apple Dock/Home, CarPlay video pixels and general touch are **not** thereby proven. No invented entitlement or vendor license code.
- Darwin notifications are a narrow device-level control channel, not authenticated to the sending app; the experiment is time-limited, off until explicit Start, and code has no boot admission hooks. Do not broaden receiver commands.
- Sandbox access to `/var/mobile/Library/Logs/DuoFaceNativeBridgeQA.log` is **not guaranteed**. `Chia sẻ nhật ký` always shares the app's own timeline and adds the native log only if iOS grants file access. This UX never asks user to use Filza to start/stop.
- Installing the app is an explicit app install; the old `com.duoface.carplay.nativebridgeqa.activate` helper is **not** a dependency and must not be suggested. If previously installed, Start works, Stop forces bridge trial flags off.
- The original stable `com.duoface.mytweak.v1a.preflight 0.2.6~recovery1`, QA11 and Native12/HUD8 are not overwritten.
- No device-side acceptance yet; requires one parked-car test of the icon, ACK response, automatic timeout/rollback and real Dock/Home.

## Reproduce

From this directory on GitHub Actions macOS Xcode runner with `ldid` and `dpkg-deb`:

```bash
python3 -m unittest discover -s tests -v
bash scripts/build.sh
dpkg-deb -f packages/com.duoface.testapp_0.1.0~app1_iphoneos-arm64.deb
```

QA evidence, DEB and checksums committed in `sideplay/test-artifacts/duoface-test-app1/` by workflow. Publish only after build/zip/dpkg exact bundle/filter/schema test and stable package preservation.
