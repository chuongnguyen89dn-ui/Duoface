# 0.0.39 regression continuation — 2026-10-23

Execution lock: chuongnguyen89dn-ui/Duoface, branch feature/duoface-jb-embedded-appbridge-20261020, baseline 2873d731e7a4f87730e8acc0095bc5bd4d8adb58. Current user reports YouTube ExitSafeMode, white menu/missing icons, inconsistent divider visibility and whole-host Zoom failure. Treat as device failure reported by user; no crash stack supplied. Preserve independent implementation, original artwork/layout, nine verified presets, split and per-pane focus; no vendor binary/licensing copied.

## Actual binary evidence

Both DEBs downloaded from project Git and extracted with dpkg-deb. Original immutable commit 1286a3ef868cf7e29804bcddf7e20b2eae707ce1, dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb SHA 2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad. Current .39 archive evidence/runs/39875912901 SHA 08183c187d0aeb2e68e721531cc599c32edb4e4981c208cb26a031c1b9467317. See binary-verification.json and original-button-dock-arm64.txt.

1. Original CBMultitaskingOverlayView setupCardContent at a2fb8 sets x2=0 before buttonWithType: — UIKit Custom. Current source used System for outer and inner menu controls. Changed to Custom with explicit existing title/tint, retained PNG AlwaysOriginal across relayout; avoids system CarPlay button styling. Visual success still needs device.
2. **NEW EXACT SELECTOR FINDING:** original CBDashboardShared.appDockVC at 121834 reads selref **0x37eaf8 = appDockViewController**, then guards respondsToSelector and invokes it. Prior .39 receiver only tried appDockVC/currentAppDockVC on the Apple root. Those are vendor-wrapper names, not this actual native getter. Added exact native getter with existing ABI, loaded UIViewController, measured rail and unique-owner guards. Search includes deduplicated legacy UIApplication windows, not only UIWindowScene windows. Geometry now uses screen coordinate space rather than comparing window-local x to screen width. No fallback to hiding statusbar, no forged ACK; restore preserved. Runtime dock ownership remains untested.
3. .39 timer used 3s, no startup expiry task, hid logo but left visible/hit-intercepting divider; hitTest alone could extend activity without a new touch. New policy uses requested 4s, starts expiry after splash, hides both strokes and logo, disables hidden divider input, preserves in-progress pan/hold, wakes on actual touch-began. Empty slots retain app-launch buttons as before. Three-second logo hold remains unchanged.
4. SceneHost layout and private scene geometry commits had no reentry guard around transform/frame/layoutIfNeeded. Added try/finally guards and pre-operation persistent markers for reference setters, scene frame, layout flush. **Hardening, not a proven YouTube crash fix.** No crash stack/exception signal identifies the actual ExitSafeMode cause yet. Kept original portrait orientation, uniform logical-size scaling, debounce, host ownership and teardown. No speculative landscape or settings flag changes.

## Verification and commands

CWD repository root. Central skill ZIPs 01,02,05 read including references. Read current sideplay handoff plus relevant root history (Zoom/Dock), prior media and dismiss evidence. GitHub latest five runs checked: completed, no duplicate started.

- `python -m pip install capstone==5.0.9` (analysis dependency only).
- `python sideplay/audit/native12-039-regressions-20261023/verify_original.py ORIGINAL.deb sideplay/jb-embedded-appbridge/evidence/runs/39875912901/com.duoface.jb.embedded_0.0.39~native12menuheader1_iphoneos-arm64.deb sideplay/audit/native12-039-regressions-20261023` — actual bytes/selector/type assertions PASS.
- `python sideplay/audit/native12-continuation-9b88aa4/verify_preview_reference.py ORIGINAL.deb sideplay/audit/native12-039-regressions-20261023/reference` — original nine-case preview assertions PASS.
- `python -m unittest discover -s sideplay/duoface-native-scene-host/tests -p test_scenehost_safety.py` — 53 source-contract tests PASS, not UIKit execution. First run failed stale 3s assertion; updated to user's 4s requirement, retained other checks.
- `python -m unittest discover -s sideplay/duoface-native-scene-host/tests -p test_preview_geometry.py` — 9 compiled geometry tests PASS.
- `git diff --check` — PASS.

Next: remote iOS SDK syntax CI; build one candidate only after passing. Device acceptance requires opening YouTube/Maps, start playback, four-second hide/wake on both panes, hold/drag without hiding mid-gesture, Menu Zoom enter/restore with native Dock. For continuing crash diagnosis collect matching SpringBoard/YouTube .ips and DuoFaceSceneHost.log/DuoFaceTouchOwner.log; identify crashing process/exception/backtrace and last geometry stage before changing private lifecycle. Do not claim all four bugs fixed or Native12 parity from source tests.
