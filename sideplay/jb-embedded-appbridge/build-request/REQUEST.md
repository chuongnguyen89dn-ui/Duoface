# Build request: independent DuoFace .77 mode2frame1

Source-only iOS16 native regression run 40447036874 SUCCESS, source commit c1f3d23027961750466abeb58218fd4e1a23dc35.

Observed issues from user: .76 crashes SpringBoard rapidly when video starts in YouTube and Facebook; previous .74 IPS stack SBAppViewController sceneHandle:didUpdateSettingsWithDiff:+440. No .76 device IPS in repo, so source-only .77 is a targeted **candidate**, NOT verified complete crash repair.

Static SHA-backed direct original research: DuoNavi104 original scene host staged viewport (updateLayout -> updateSceneSettingsFrame -> layoutIfNeeded), DuoDash113 Fullscreen427 repack creates SBAppViewController and requests mode2 before looking up private child; SidePlay1041 original compares remote frame before posting updates. Source audit run 40445716116 PASS; note DuoDash is repack.

Changes in first-party DFSceneHost.m ONLY (besides version, tests and diagnostics):
1. No content-reference size commit until mode2 has been requested and current real hosted scene isReady; eliminates observed pre-mode2 child2/child3/main2 unavailable sequence. Does NOT suppress live scene setFrame.
2. Read live FBScene settings frame where the getter exists. Avoid the **identical frame** private settings update; if different or no getter, retain original .74 playable path. The first/changed media frame write remains enabled.
3. Retain current 2x logical scene, all UIKit split/touch/Zoom/Dock/menu/chrome, preserve .76 fatal reason recorder and audit export. No unverified foreground/orientation private setters, no new hooks in app processes, no previous licensed vendor code.

Pin signed native host 0.1.86~mode2frame1 and integrated DEB 0.0.77~mode2frame1. Validate full suite and UIKit arm64 toolchain on macOS; immutable SHA256 archival artifact. The CI is a candidate, NOT evidence of iPhone playback or crash stability. No automatic respring; existing old immutable packages retained for rollback. Only if packaging succeeds should publisher be updated to this explicit requested .77 test candidate.
