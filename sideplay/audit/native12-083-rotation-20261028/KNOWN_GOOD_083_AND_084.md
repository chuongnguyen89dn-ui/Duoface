# DuoFace — known-good playback baseline .83 and .84 orientation experiment (2026-10-28)

## ĐIỀU ĐÃ THÀNH CÔNG PHẢI GIỮ
- **Thiết bị xác nhận từ người dùng:** iPhone X jailbreak rootless iOS 16.7.16, DuoFace **0.0.83~manualobserver1** cài qua Sileo: **phát được video, hết crash trong lần thử**. Không phải kiểm thử stress hoặc xác nhận mọi ứng dụng.
- **Vẫn lỗi:** video xoay sai hướng khi phóng to; chưa có ảnh/trace chính xác mô tả 90°/180° và sự kiện người dùng bấm Zoom ô, Zoom toàn host hay fullscreen trong YouTube.
- **Immutable build .83:** source SHA `2a6a92b38f559dcd1e20dccb0a5422b6db9afe2b`; signed integrated rootless DEB `com.duoface.jb.embedded_0.0.83~manualobserver1_iphoneos-arm64.deb` SHA256 `ced5f42db8b9a3285ccf159386f25e8e5ea0fa976e14c3b35ea24dd625534c9b`; GitHub Sileo publication recorded in handoff as run `40617170720` (link may be unavailable through current connector). Keep this DEB for rollback; never overwrite, relabel, or replace it.
- **Crash mitigation that MUST survive:** `sideplay/duoface-native-scene-host/DFSceneLifecycle.m`, owner-scoped manual `SBAppViewController.sceneHandle:didUpdateSettingsWithDiff:previousSettings:` handling; .83 solution in source commit `560da4d9332e9b5d58cf26c98584602a30fda75f`. Original Apple callback is forwarded for foreign, stale, revoked and auto lifecycle controllers. Do not revert to .37.
- Existing Dock, split, menu, long-press movable logo, Zoom handlers, `DFNative12Chrome`, media viewport dispatch and .83 UIKit scene lifecycle are intentionally outside .84 orientation changes.

## Kiến thức đã kiểm chứng từ DEB nguồn (không sao chép giấy phép)
- [Binary verification run 40621241302](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40621241302), persisted raw report `sideplay/audit/native12-083-rotation-20261028/BINARY_DIRECT_083_VS_ORIGINAL.json`.
- Native12 gold handles `SBDeviceApplicationSceneHandle._mainSceneSupportsInterfaceOrientation:`: for qualified bridged app return true only when requested orientation is `1` (portrait); otherwise forward Apple original IMP.
- Native12 gold separately handles 2-/3-orientation variants of `SBDeviceApplicationSceneViewController.setContentReferenceSize`; override reference render size based on target bundle while preserving orientation arguments. .83's 5 shipped dylibs lacked the handle hook.
- **Known boundary:** static byte evidence does NOT prove actual YouTube fullscreen player's orientation or that the missing hooks alone cause the on-device symptom. Forcing global landscape 3/4 or replacing content-reference portrait=1 was rejected, not a confirmed fix.

## Thay đổi .84 (isolated candidate, NOT proven working on device)
- New source: `DFSceneOrientationPolicy.h/.m` first-party, MSHookMessageEx ABI guards and exact owned-handle callback; owner-only portrait eligibility, 2-arg/3-arg size broker, foreign/stale/off-main pass-through, manual unregistration.
- `DFSceneHost.m`: register only from live attached `DFSceneSurface` / correct scene generation, live `isHostingAnApp`, bundle eligible, exact controller/window and map identity. Revoke on scene replacement, suspended ownership and stop. No global setter, no changes to `DFSceneLifecycle.m`.
- `build.sh` compiles separate policy into SpringBoard DFTouchOwnerProbe dylib. New isolated versions: `0.0.84~portraitpolicy1`, nativehost component `0.1.93~portraitpolicy1`. Original .83 remains in GitHub history and Sileo.
- macOS test harness `tests/scene_orientation_policy_runtime.m`, Python guard `tests/test_orientation_policy_084.py`, CI `.github/workflows/duoface-084-orientation-gate.yml`. Gate run [40623550032](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40623550032) completed SUCCESS at 2026-10-28T02:53:52Z; fake SpringBoard ABI and source tests **are not an iOS hardware pass**.

## Tiêu chí nghiệm thu .84 thực tế
1. Build macOS signed current-source .84 DEB, SHA/source manifest and unique persistent artifact; publish **new version only** into current Sileo repo, preserving rollback .83.
2. On parked car / iPhone X after installing .84: YouTube video play and seek without SpringBoard Safe Mode; portrait/landscape inside split, solo, pane zoom, whole-screen zoom, and YouTube player fullscreen upright; restore Dock, app close/reopen and movable logo.
3. If .84 fails: record time/event/bundle, `DuoFaceDeepTrace.log` lines tagged `scene-orientation`, `DuoFaceSceneHost.log`, latest SpringBoard IPS; compare orientation requests and content frames with .83 before any next mutation. Never mark a CI pass as device pass.
