# Evidence: YouTube orientation — 2026-10-28

Actual original SidePlay 1.0.4-1 disassembled in GitHub Actions run 40645459488 (SUCCESS). SHA256 original package: 7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c. Evidence: sideplay/audit/native12-083-rotation-20261028/SIDEPLAY_YOUTUBE_ORIENTATION_CALLBACK_RUN_40645459488.json.

Verified machine code: SPPane.appReportedOrientation @0x34e38 reads live scene.clientSettings.interfaceOrientation, distinct from scene.settings.interfaceOrientation. SPPane.applySceneOrientation: @0x31050 updates requested scene orientation. SPPane.enforceSceneGeometry @0x3467c compares app-reported orientation and requested orientation and can send a per-app orientation notification. SPPane.watchOrientationFor:token: @0x33ac8 and callback @0x33bd8 repeatedly invoke enforceSceneGeometry while token remains valid. Original receiver behavior is not yet fully traced.

Current DuoFace .86 DFSceneHost.m:302-310 returns if pane size equals committedReferenceSize, thereby skipping orientation-only work. DFSceneHost.m:399-468 reads scene.settings.interfaceOrientation but does not compare scene.clientSettings.interfaceOrientation. DFSceneHost.m:521-586 does not watch app orientation changes. Device .86 YouTube rotation remains failed per user's test.

Finding: original SidePlay has orientation feedback beyond one-off pane resize; DuoFace .86 lacks that mechanism. This is verified architectural difference, not yet a proven full device fix. Preserve .83 playback/crash fix and freeze Google Maps. No runtime or package modifications. Next: validate app-side orientation notification receiver and correlate live clientSettings versus settings during pane Zoom and YouTube's own fullscreen; then implement only the verified minimum connection.
