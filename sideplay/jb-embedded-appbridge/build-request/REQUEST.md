# Explicit one-DEB user test build request — 2026-10-23 (Asia/Ho_Chi_Minh)

- Requested by project owner: build an actual rootless ARM64 DuoFace integrated `.deb` for installation/testing using Sileo.
- Source branch: `feature/duoface-jb-embedded-appbridge-20261020`.
- Build workflow: `.github/workflows/duoface-jb-embedded-appbridge-package.yml`.
- Expected signed component: `com.duoface.carplay.nativescenehost_0.1.49~native12cards1_iphoneos-arm64.deb`.
- Expected staged single-package candidate: `com.duoface.jb.embedded_0.0.38~native12sourcehost49_iphoneos-arm64.deb`.
- This explicit file-change triggers the scoped packaging workflow (other pushes do not).
- DO NOT claim exact Native12 Speed8 parity: own 8-speed HUD view is not yet linked, real-device UI/zoom/media/safe-mode tests pending.
- This build workflow emits a signed QA DEB and immutable run evidence. It explicitly DOES NOT publish a Sileo source; publication requires a verified repository index/update step after a successful build.
- Do not add original third-party binaries or license checks.
