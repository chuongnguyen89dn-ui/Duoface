# .84 integrated rootless Sileo test build — 2026-10-28

User: “Bắt đầu làm đi. Lưu lại những thành công để sau này còn tìm ra.” Continue known-good .83 video/no-crash result by isolating orientation repair as **0.0.84~portraitpolicy1**; NEVER change, delete or relabel immutable .83.

Source branch: `feature/duoface-jb-embedded-appbridge-20261020`. Build nativehost **0.1.93~portraitpolicy1** from EXACT current checkout; 4 self-owned signed modules; combined package **com.duoface.jb.embedded_0.0.84~portraitpolicy1_iphoneos-arm64.deb**. Require source SHA, SHA256 and unique GitHub artifacts.

Evidence:
- .83 playback/no-crash confirmed by user; wrong orientation after zoom persists.
- Read-only five-DEB audit run 40621241302 verified Native12 portrait-only eligible main-scene hook and two native size setters absent in .83.
- .84 first-party code `DFSceneOrientationPolicy.m` + strict owner registration in `DFSceneHost.m`; **do not modify the .83 manual observer crash fix**.
- Separate source/runtime gate **40623550032 SUCCESS**; executable fake-SpringBoard, Python and original lifecycle boundary tests passed. Not a device test.
- Explicit known-good snapshot: `sideplay/audit/native12-083-rotation-20261028/KNOWN_GOOD_083_AND_084.md`.

Packaging safety: use existing `.github/workflows/duoface-jb-embedded-appbridge-package.yml`, macos-15, Theos, ldid, four component builds, integrated provenance, signed binary, one immutable archive by run ID. No vendor source/DEB/licensing, no alternate project repo. Keep all older Sileo binaries.

Acceptance of CI is only SIGNED PACKAGE and checksum; not a real-world fix. Public Sileo publisher in `chuongnguyen89dn-ui/carplaydsp` must be updated ONLY for this new version AFTER package SHA checks. Test on iPhone X/CarPlay: YouTube fullscreen/split/solo, no crash, correct orientation, Dock/Zoom/logo unaffected. If device fail, revert to immutable .83 and collect new scene-orientation traces.
