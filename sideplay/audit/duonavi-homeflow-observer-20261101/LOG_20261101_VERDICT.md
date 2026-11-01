# DuoNavi Observer3 — newest device log (2026-11-01)

Source: Duoface main commit 4955c852628ce115b095160e480f5f8a879b14cf, file sideplay/log/DuoNaviObserver-16990B2B-71E6-4CC1-9AAB-8CBECBD97599.txt, blob ae3f8ec858acd225b1df7ea5a991ed3e24d7bd0a.

Parsed 4,439 lines, 4,426 JSON records, 1,002 Observer3 records. 13 hook-ready records installed; 9 actual homeButtonUp enter/return pairs and 9 delayed snapshots; 0 manual result markers. Rotated export requires sorting by UTC, not line order.

Original unsupported app activation confirmed: Facebook 04:16:48.288 UTC, YouTube 04:17:04.573 UTC, Gemini 04:17:48.873 UTC. Native Home callbacks at 04:16:59.323 (call 478), 04:17:18.447 (512), 04:17:55.569 (594). Observed order: Home -> stopBridging -> requestDismiss -> bridgeDidDeactivate -> clear native Dock bundle -> Home in-app false / display state 1. Before Home, native dashboard showingApp=false, workspace activeBundle=com.apple.CarPlay.dashboard, foregroundScene=nil. This is real original behavior while an unsupported app bridge is active; showingApp false is not proof of a defect.

Native Music and Calendar differ: first Home can dismiss bridge while native app remains foreground, second Home requests native workspace deactivateApplication via DBWorkspace.requestStateChange. Observed Music calls 540 -> 547 and Calendar 563 -> 571.

No manual RESULT_APP_CHOOSER or RESULT_CARPLAY_HOME markers. UIKit controller tree alone cannot confirm which page user actually sees. Hence original Home destination is not yet proven visually by this log.

Current DuoFace Log26 analysis: sideplay/audit/qa156-log26-home-rejected-20261101/FINDINGS.md. Five current requests resolve correct native dashboard and stop/Dock but user still observes wrong page. Do not issue another Dock-only patch. Next: correlate Home exit, original dismiss state and actual app-picker page owner with DuoFace, without replacing Apple Home callback. No source/build/Sileo change in this log check.
