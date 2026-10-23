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

## 2026-10-23 — follow-up explicit user test candidate 0.0.39 (real device photo regression)

- Device screenshots after public .38 prove its OUTER four-action menu paints a blank approx. 446×224pt translucent sheet across both black (unselected) panes. Do not call .38 exact original Native12 UI.
- Current source-only iOS16 ARM64 tests **SUCCESS**: GitHub Actions run 39875524353 and latest 39875654424.
- User already expressly requires us to fix the photographed discrepancy and publish directly to Sileo, so build the next single signed test `com.duoface.jb.embedded_0.0.39~native12menuheader1_iphoneos-arm64.deb` from current feature HEAD and save its immutable archive.
- Exact source patch `DFNative12Chrome.m`: eliminate empty 224pt outer modal body, keep original-header-height 32/38 action row and all original evidenced App/Zoom/Style/Close wiring. No original proprietary binary or license.
- Publish new QA only after signed package build, SHA and artifacts are verified; preserve .38 rollback and separate `com.duoface.independent` Speed8 Hub.
- Real two app scenes and Speed8 HUD still **NOT validated**; black slots without app selection do not prove hosting failure.

## 2026-10-23 — .39 reported regressions, consolidated .40 candidate

Continue user's requested repair on current feature branch. Source fix 589464194e76a82f239cce1c640902580ff1b6f0; source-only iOS SDK CI 39878692429 job120170538359 SUCCESS (53 source contracts, geometry, package/protocol checks, Objective-C ARM64 syntax). Expected candidate com.duoface.jb.embedded_0.0.40~native12regression1_iphoneos-arm64.deb. Contains exact original native appDockViewController selector, Custom menu buttons, 4s divider/input policy and scene reentry guards/diagnostic stages. Preserve .39 immutable artifact. Build and archive this single package. No device/YouTube crash success claim and no automatic Sileo pin change by this request. See sideplay/audit/native12-039-regressions-20261023/FINDINGS.md.
