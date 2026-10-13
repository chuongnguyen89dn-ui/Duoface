# Native Objective-C metadata audit — 2026-10-13

Using `llvm-objdump --macho --objc-meta-data` on extracted arm64 Dashboard binaries from the existing v12-first and native 1.0.4 test DEBs.

- v12: `DuoFaceDashboard.dylib` 7,540,464 bytes, Objective-C dump 204,816 bytes.
- 1.0.4: `DuoNaviDashboard.dylib` 7,921,472 bytes, Objective-C dump 260,300 bytes.
- Both class metadata contain `CBSlotPillView`, `CBSplitSplashScreenView`, `CBDividerView`, `CBBridgedSplitApp`.
- `CBSlotPillView` owns `_dotsButton`, `_expandButton`, `_restoreButton` in both; corresponding Objective-C properties typed `UIButton`.
- `CBVoiceSessionManager` occurs in the native 1.0.4 Objective-C class metadata, absent from v12. Native functionality is not integrated into v12 by adding audio assets.

This is **static binary inspection**, not an integration test or confirmation of runtime safety. Keep working v12 Sileo unchanged. Full 1.0.4 feature transfer requires a compatible implementation or a native binary integration strategy validated on device; merely copying binaries creates duplicate Dashboards.
