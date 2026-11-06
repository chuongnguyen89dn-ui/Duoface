# STATUS QA178 — h1wake1 (2026-11-06)

- Base: QA171 tip cad8d7d164f7a203aee5faff5396d110316e4877 (0.0.171~gofadiag1,
  the build Nguyen device-verified: keyboard OK). DFSceneHost.m and the
  render contract are byte-identical to QA171; maps/native work untouched.
- Change 1 (proven H1, hunk-for-hunk as in QA172R logorecall1):
  DFAppTouch177.h + DFAppTouchPolicy177.h + DFKeyboardState177.h added;
  DF154GeneralAppStateRelay.m and DFYouTubeOrientationRelay.m gained only
  the DF177_APP_SIDE_SENDER import + DF177InstallAppTouchHook call
  (byte-identical to the recovered QA172R-lineage files).
- Change 2 (the swallow, new): DF177SendEventHook in DFAppTouch177.h —
  while the host reports controls hidden and no keyboard is live in the
  app, the first touch sequence is not forwarded to the app at all and
  only the H1 wake signal is emitted. Fail-open on unknown state.
- Change 3 (host wiring, companion instead of editing the 129 KB
  DFNative12Chrome.m, which stays byte-identical to base): DFH1Wake188.m
  swizzles start/stop/layoutControls of DFNative12Chrome: registers the
  DF156 wake, on wake validates the record (freshness via
  DFAppTouchPolicy177) and calls noteUserActivity, and publishes the
  controls-hidden state (ControlsHidden188 in the qa177 prefs plist +
  com.duoface.controls188.state notify) on every layoutControls change.
  NOTE: record validation here is freshness + count dedupe; the deeper
  live-process validation of the recovered tree is not replicated.
- Version mechanics: build.sh/control 0.1.178~h1wake1, Info.plist
  CFBundleVersion 178, package_integrated.py VERSION=0.0.178~h1wake1,
  build labels in DFDeepTrace.h/DFTouchOwnerProbe.m, version re-pin in
  test_integrated_package_144.py.
- DEVICE_TESTED=false. Acceptance: A2 on car — after idle-hide, first
  tap only recalls logo/controls (log: qa188-h1-app-touch-wake
  swallowed=1), second tap reaches the app, 3 consecutive cycles, on a
  DF155-scope app and on YouTube.
