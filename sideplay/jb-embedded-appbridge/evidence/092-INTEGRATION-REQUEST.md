# DuoFace .92 integrated DEB checkpoint — 2026-10-28

Source repo: chuongnguyen89dn-ui/Duoface; branch: feature/duoface-jb-embedded-appbridge-20261020; parent checkpoint: 96d2d2157692cb8916ba5cb290445aea6300770b.

Latest user explicitly orders immediate integration of already-audited Native12 logo three-second hold into new rootless integrated DuoFace DEB. Preserve physical .90 YouTube rotation, original system Dock and current optional native Maps code; no proprietary vendor binary or license; no unsupported claim of 1:1 parity.

NativeHost 0.1.101~logo3s1; merged com.duoface.jb.embedded 0.0.92~logo3s1. Existing four first-party inputs, module signed SHA check and `.github/workflows/duoface-jb-embedded-appbridge-package.yml`; workflow fires on `sideplay/jb-embedded-appbridge/build-request/REQUEST.md`. CI saver must put verified artifact and SHA256SUMS under `sideplay/jb-embedded-appbridge/evidence/runs/<RUN_ID>/` and append main `sideplay/tiep tuc du an.md`. At source commit, no .92 binary or Sileo verification yet. Source-only precedent run 40705259552 PASS; next gate verify actual packaging run and then Sileo hash and physical device.
