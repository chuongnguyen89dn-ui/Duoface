# QA170 GOFA probe logger fix — 2026-11-02

## Confirmed source defect and fix
- File: sideplay/duoface-native-scene-host/DFGofaTrafficNavProbe166.m
- Defect: NSFileManager attributesOfItemAtPath:error: returns NSDictionary; the old code sent [attrs fileSize], which is not a NSDictionary selector. If the log file exists, the next logger call can raise an unrecognized-selector exception. No device crash trace is available, so this is a source-level defect, not a proven device crash cause.
- Fix commit: 373a3ed073638a7fca4a143efd7aa2659c94c612
- Replacement: attrs[NSFileSize]; add sanitized NSLog fallback with prefix [DuoFaceGOFAProbe QA171]; file rows now start QA171.
- No payload values, location, alerts, route values or GOFA getters are read by this fix.

## Build evidence
- GitHub Actions run: 41380310578
- Source SHA: 373a3ed073638a7fca4a143efd7aa2659c94c612
- All job steps completed success, including native host compile/sign, merged DEB assembly, static checks, upload and archive.
- Archive commit: c4df2dd2c00a7f50b8fc8712caff348fbeba2915
- DEB: sideplay/jb-embedded-appbridge/evidence/runs/41380310578/com.duoface.jb.embedded_0.0.170~transparentxgps1_iphoneos-arm64.deb
- Size: 1,236,928 bytes
- SHA256: 0e0f72e0ddcdafc8b46e397499445804d9dd3df0f1ffeb2224da272602be3a25
- SHA256SUMS.txt and PACKAGING_PROVENANCE.json read back and agree.
- CI_RESULT: BUILD=success; SIGNED=true; SILEO_PUBLISHED=false; GOFA_REAL_ROAD_ALERTS_CONNECTED=false; GOFA_REAL_NAVIGATION_TURNS_CONNECTED=false; GOFA_RUNTIME_PROBE_VERIFIED=false; DEVICE_TESTED=false.
- Package version remains 0.0.170~transparentxgps1, same as public QA170. It is private and not an apt upgrade. Do not claim Sileo contains this fix.

## Not yet committed / blocked
- Planned QA171 expansion: read-only property names/type categories and selectors cameraUpcoming, gofaAlertGroups, navigationSample, distanceRemaining, upcomingManeuvers; no getter invocation or value extraction.
- In-tool consistency checks passed, but GitHub multi-file commit/workflow changes were blocked by the safety gate. No QA171 source/package/workflow update is present on the branch.
- A standalone blob/tree object from the test draft is not referenced by the branch and is not a deliverable.
- Next exact operation requires explicit authorization to modify the existing GitHub Actions workflow and bump versions to native host 0.1.171~gofaprobe1 and integrated package 0.0.171~gofaprobe1. Then run private signed build and verify DEB/SHA. No Sileo publish or device acceptance from build alone.

## Device evidence required
After a compatible QA171 package is installed, open GOFA with its existing Location permission. In DuoFace Native Host tap “Xuất log / lỗi CarPlay” then “Tạo báo cáo” and share the report. It includes DuoFaceTrafficNav166.log and GOFA notification evidence state. If the shared file is absent, capture system logs with prefix [DuoFaceGOFAProbe QA171]. Actual notification delivery and payload schema remain unverified.

## Skills
Read central README.md, SKILL_INDEX.md, PROJECT_INSTRUCTIONS.md, AGENTS.md and DEB_IPA_SKILL.md. Fetched skills/02-ios-deb-ipa-carplay.zip as base64 but did not successfully reconstruct/extract it; ZIP contents are not claimed as read.
