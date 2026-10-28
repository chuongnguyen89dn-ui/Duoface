## 3 ảnh thực tế — phát đúng sau fullscreen, giữ đúng khi trở về split (2026-10-28)

**Chứng cứ mới từ người dùng:** sau DuoFace Zoom một ô, YouTube video/controls hiển thị xoay lệch so với thanh Dock CarPlay; sau phóng video riêng toàn màn hình, video ngay lập tức đúng hướng; thoát về chia 2 ô vẫn đúng. **Cần bảo tồn cả thành công “fullscreen làm đúng và restore vẫn đúng”**, đây là đầu mối tìm lỗi khởi tạo orientation, không phải lỗi video mã hóa hoặc cố định bởi aspect ratio. Chưa kiểm chứng version cài trong ảnh; chưa đo được FBScene/UIWindowScene/AVPlayer orientation để khẳng định tầng nào sai.

**Nguồn xác minh trong mã:** `DFNative12Chrome.m zoomPressed:` thay focus/layout, `DFSceneHost.m layoutScene/commitSceneGeometry` chỉ xử lý size/frame khi khác, không có orientation-only handshake; policy .84 `DFSceneOrientationPolicyInstall/Register` chạy muộn trong commit sau scene ready + debounce 0.30s. Cơ chế đúng có thể do fullscreen player kích hoạt lại trình điều phối hướng; đây là **giả thuyết mạnh, chưa có live trace**. [Chi tiết 3 hình, mapping mã, hướng test có tiêu chí](PHOTO_3_STEP_SCENE_ORIENTATION_20261028.md).

Không đổi `DFSceneLifecycle.m`, không ghi đè .83/.84 Sileo, không ép landscape 3/4. Sau khi có trace owner/scene/gen và orientation trước-sau mới quyết định bổ sung đồng bộ tầng thích hợp. **Chưa xây .85; không được nói đã hết lỗi.**

---

## .84 SILEO PUBLISHED + .83 ROLLBACK VERIFIED — 2026-10-28 10:02 ICT

- The official Sileo shared distributor `chuongnguyen89dn-ui/carplaydsp` `main` publisher commit `ba3a182c2a81c176428b002a060d8b9c025d7fd2`, [workflow run 40624072633](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/40624072633) **completed SUCCESS**, with jobs: build `122604712275`, deploy `122605475611`, **public integrated DuoFace verifier `122605680196`**, QA shared Pages verifier `122605680365`; YAML verifier [40624072614](https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/40624072614) SUCCESS.
- Public source `https://chuongnguyen89dn-ui.github.io/carplaydsp/`. One advertised APT record `com.duoface.jb.embedded` `0.0.84~portraitpolicy1`; direct DEB `https://chuongnguyen89dn-ui.github.io/carplaydsp/debs/com.duoface.jb.embedded_0.0.84~portraitpolicy1_iphoneos-arm64.deb` SHA256 **`8cfd377d295b2fb7d5e16f6b81fb03f4744205f0cd0cbfc253d96d7d678de107`**.
- Raw public verifier logs (run `40624072633`, job `122605680196`) observed actual output:
  `2026-10-28T03:02:26.6496384Z DUOFACE_ONE_PACKAGE_PUBLIC_SILEO_INDEX_VERIFIED`
  `2026-10-28T03:02:27.0164944Z /home/runner/work/_temp/duoface-public.deb: OK`
  `2026-10-28T03:02:27.0170024Z DUOFACE_PUBLIC_SILEO_DEB_DOWNLOAD_AND_CHECKSUM_VERIFIED`
  `2026-10-28T03:02:27.1429821Z /home/runner/work/_temp/duoface-frozen-083.deb: OK`
  `2026-10-28T03:02:27.1431565Z DUOFACE_FROZEN_083_PLAYBACK_BASELINE_UNCHANGED_PASS`.
- **IMPORTANT:** Public Sileo availability and correct package checksum are verified, but **the new .84 rotation fix and continued crash-free playback have NOT been tested on physical iPhone**. User's confirmed .83 playback/no-crash remains the last physical success and is byte-for-byte available online for rollback.
- Device test expected: refresh Sileo source, install `0.0.84~portraitpolicy1`, test actual YouTube playback, fullscreen orientation split and zoom, Dock/menu/logo. If fail, revert to .83, export `/var/mobile/Library/Logs/DuoFaceDeepTrace.log`, `DuoFaceSceneHost.log`, latest SpringBoard IPS and exact event/time. Do not call CI pass a device pass.

---

## .84 SIGNED BUILD XÁC MINH — source ≠ device (2026-10-28)

- GitHub Actions **[40623708673](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40623708673)** completed **SUCCESS**; job **122603517125** 5 Python suites, executable .83 lifecycle harness, executable .84 owner-scoped orientation harness, Theos + ldid four builds, package verification, archive to project GitHub all SUCCESS.
- Build input source commit: `c4aabd07573822689025983da53c0b847f754751`. Immutable artifact archive commit: `be8435bc9d7c10be3e48d9f0ed576cb6793f972a`.
- File: `sideplay/jb-embedded-appbridge/evidence/runs/40623708673/com.duoface.jb.embedded_0.0.84~portraitpolicy1_iphoneos-arm64.deb` (985868 bytes), **SHA256 `8cfd377d295b2fb7d5e16f6b81fb03f4744205f0cd0cbfc253d96d7d678de107`**. Crosschecked with `SHA256SUMS.txt` and `PACKAGING_PROVENANCE.json`, 30 files, nativehost signed module `0.1.93~portraitpolicy1` SHA256 `00b06220151504e8ca7e69a7e5b2c35f4a0007ac40256e8d4b2ca2c6a872a591`.
- **Not device tested.** The device-validated no-crash/video .83 checksum is unmodified. New Sileo publisher only: `chuongnguyen89dn-ui/carplaydsp` workflow `.github/workflows/build.yml` commit `ba3a182c2a81c176428b002a060d8b9c025d7fd2`, expected Pages run `40624072633`; pin exact immutable .84 bytes, preserve .83 and index only .84. At this checkpoint publisher run in progress, **do not mark deployed yet**.

---

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
