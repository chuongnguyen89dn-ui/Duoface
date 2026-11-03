# STATUS QA172R — logorecall1 (2026-11-03)

- Base: QA171 tip cad8d7d164f7a203aee5faff5396d110316e4877 (0.0.171~gofadiag1, the build Nguyen device-verified: keyboard OK).
- Change: ONLY the QA177 H1 controls recall, ported hunk-for-hunk:
  new DFAppTouch177.h (verbatim); DF154GeneralAppStateRelay.m +import/install call;
  DFYouTubeOrientationRelay.m +import/install call; DFNative12Chrome.m +imports,
  +3 properties, +wake registration in start, +df177HandleAppTouch, +token cancel in teardown.
- Explicitly NOT included: QA176 H2/H3, QA177 H2/H3, QA173/QA175 touch changes,
  QA178-QA185 keyboard fit/suite/geometry (DFSceneHost.m and the render contract
  are byte-identical to QA171).
- Version mechanics only besides H1: build.sh/control/Info.plist (172),
  package_integrated.py VERSION=0.0.172~logorecall1, build labels in
  DFDeepTrace.h/DFTouchOwnerProbe.m (were stale 0.0.90/0.0.86 at QA171).
- Tests: version re-pins; test_qa155 carries QA177's scoped sendEvent:
  exception verbatim; new test_qa172r_logo_recall.py guards scope.
- DEVICE_TESTED=false; SILEO_PUBLISHED=true (2026-11-03, publisher carplaydsp df4da1cf, run 41634752388 SUCCESS 5/5; public index verified: 1 stanza 0.0.172~logorecall1, SHA 8ddc167b..., Size 1240844; QA171 and QA185 DEBs still served with original hashes).
