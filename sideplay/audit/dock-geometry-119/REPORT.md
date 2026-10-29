# QA119: same-session read-only geometry, continuation of d0b22ee0

## Execution lock
- Repo: chuongnguyen89dn-ui/Duoface
- Branch: feature/duoface-jb-embedded-appbridge-20261020
- Baseline: d0b22ee0c768d5e8df9ef6ae3522b219549406ec
- Target: integrated rootless iphoneos-arm64 DEB 0.0.119~geometry-probe1, existing macOS Actions build/sign pipeline.
- USER_DECISION: continue size correction from exact checkpoint; never guess pixels, hide/crop native Dock at connect, or reintroduce suspended pane wake. Preserve .90 rotation and .92 controls.
- CONFIRMED: original/reference comparison already archived in ../duonavi104-vs-duoface118-dock-20261029/. It is not a physical measurement.

## Implemented
The required next step at d0b22ee0 is a read-only measurement before any visual patch. QA119 adds one sample UUID every three seconds to the existing foreground heartbeat. App, SpringBoard and each native CarPlay process independently log their actual UIKit readbacks under the same sample/session, with their own timestamps. No input hooks, system setters or additional window creation. No geometry measurement is consumed by layout or Dock commands.

- App: CPWindow frame, bounds, safe-area, safe-layout, screen-space conversions, scene coordinate space, original pre-clamp ContentRect and empty-safe-frame fallback flag.
- SpringBoard: launch pre/post-clamp region and discovery-window geometry with launch timestamp; current pulse ContentRect; current content region; all four actual physical windows with converted screen frames, hidden/solo/startup/fullscreen flags. Launch values are historical and are labelled as such, not represented as current measurements.
- CarPlayApp/CarPlay/Dashboard: capped actual window inventory, safe-area and scene conversions, native class/controller Dock candidates; optional ABI-checked `activeCarPlayWindow.rootWindow` and `rootWindow` getters. Missing getters remain **unresolved**, never replaced by app CPWindow or a guessed width. Statusbar fallback is excluded from Dock measurement candidates.
- Dedicated per-process JSONL logs capped at ~1 MiB. Existing iPhone **Xuất log / lỗi CarPlay** export includes the last 256 KiB of each. No automatic upload.
- Offline `analyze_geometry.py` groups by sample+session, rejects stale/mismatched/ambiguous/transitional samples and reports candidate pane/Dock gap in points. Matching dimensions/scale alone is not proof of native display identity; it never authorizes a layout patch or claims device PASS.

## Preserved / not yet done
The .118 safeLeft behavior remains exactly unchanged until native measurements establish the correct rectangle. QA119 is **not the black-gap fix** and should retain the same visible margin. No new hardcoded size. No change to Zoom, .90 orientation, .92 logo/divider logic, GOFA, microphone or app input.
No connected vehicle/iPhone control is available in this session. Native root owner and physical Dock/pane gap are still UNVERIFIED. Signed build and distribution are separate states, recorded in handoff when confirmed.

## Commands / verification
From repository root:
```
python -m unittest discover -s sideplay/duoface-native-scene-host/tests -p 'test_geometry_119.py' -v
python -m unittest discover -s sideplay/duoface-native-scene-host/tests -p 'test_emergency_no_wake_dock_118.py' -v
python -m unittest discover -s sideplay/duoface-native-scene-host/tests -p 'test_logo_092_exact_regression.py' -v
python -m unittest discover -s sideplay/jb-embedded-appbridge/tests -p 'test_integrated_package.py' -v
git diff --check
```
Local result: 8 + 3 + 2 + 7 = 20 tests PASS. These are parser/unit/source safety/packaging checks, not iOS compile or physical testing. Exact output in LOCAL_TESTS.txt.

## Device collection and exact continuation
1. Install distinct signed QA119 via Sileo once publisher is verified; parked vehicle, normal Dock visible, open two panes. Do not press Zoom initially.
2. Stay in DuoFace for at least 10 seconds after splash, observe black gap. Test Home/reentry as a separate phase. Export using existing iPhone **Xuất log / lỗi CarPlay** after observation; no Filza/manual loose tweak installation.
3. Run `python sideplay/audit/dock-geometry-119/analyze_geometry.py /path/to/DuoFaceAudit.txt > geometry-analysis.json` and archive actual input/analysis in this repo (strip unrelated personal contents).
4. Inspect native root identity, converted Dock rail and actual panes for the same sample. Missing root/Dock or disagreement means remain on .118 behavior, identify the missing owner; do not fabricate 42/45/64pt or fullscreen.
5. Only after validated measurements implement one shared native usable-bounds contract for create/resize/split, then regression/build/Sileo and physical acceptance: Dock visible from connection, no extra strip, correct .90 orientation/.92 controls and lower YouTube touch after idle. GOFA hypothesis remains separate.
