# Build request — owner-scoped manual scene observer .83 — 2026-10-28

User explicitly requests a Sileo-installable test release because local/car CI-only changes cannot be evaluated on their CarPlay device.

- Build integrated **0.0.83~manualobserver1** from current branch checkout using NativeHost **0.1.92~manualobserver1**; preserve package identity `com.duoface.jb.embedded` and versioned immutable artifact.
- Evidence basis: Native12 exact SBAppViewController observer replacement at 0x2c8ca8 / manual lifecycle NO branch 0x2c8e7c; DuoFace .82 three SpringBoard SIGTRAP +720 after YouTube playback, and user-confirmed Choicy AppData Deny+respring **still crashed**. The post-Choicy IPS is not yet uploaded.
- Change scope: first-party `DFSceneLifecycle.m` owner-scoped manual observer; only consume for registered current live controller/handle/scene with `automatesLifecycle==NO`. All foreign, stale, automatically-managed and revoked callbacks must go to Apple original IMP. Do not touch UI, Dock, Zoom, logo, menus, frame or app viewport; no vendor binary/license.
- Require all five Python test suites, executable Foundation runtime observer harness, syntax check, four current-source signed component builds, exact single rootless .83 DEB, source SHA and SHA256, unique GitHub Actions run archive. Do not reuse signed .82 binary or label an .82 file as .83.
- Staging build is NOT a device pass. After CI/artifact verification, publish version **0.0.83~manualobserver1** to the existing Sileo repository only after validating public Packages and binary checksum. Preserve all older packages.
- On user device, parked-car test YouTube playback, other media apps, split/solo, close/reopen, Dock/Zoom/logo, and export newest SpringBoard IPS plus DuoFaceAudit if crash persists.
