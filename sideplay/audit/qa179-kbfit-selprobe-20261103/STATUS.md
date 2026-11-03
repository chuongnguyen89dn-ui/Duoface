# QA179 — STATUS

- Branch: feature/duoface-qa179-kbfit-20261103 (from QA178 tip 935db176)
- Integrated: com.duoface.jb.embedded 0.0.179~kbfit1; host 0.1.179~kbfit1
- Implementation commit: 399dc3d435efdd1a65156938ba7cbc03a992dbcc
- Private build run: 41562273711 SUCCESS (verified by direct foreground query; a backgrounded poll produced a phantom run id + invented failure and was discarded, same failure mode as QA177/QA178)
- Workflow archive commit: c3ad59ff1b5e511e2812e4752cc20ef0a4e55fb4
- DEB: 1,277,328 bytes, SHA256 9e83b36c9e381575fa3704da308170b5f79f91d998b422ac545ad7ac6f0b22a6 (computed from the downloaded artifact)
- Control verified from the DEB (Package / Version 0.0.179~kbfit1 / Architecture iphoneos-arm64); postinst/postrm md5 5d016787d5af05ce8a353942f1dfa091 / eddecdc6cbe35384fd72bf23a831d801 — byte-identical to QA177/QA178
- Markers verified in the built dylibs: KeyboardFit179 + selProbe179 in DF155GeneralAppStateRelay.dylib; qa179-kbfit + build=0.0.179~kbfit1 in DFTouchOwnerProbe.dylib
- SILEO_PUBLISHED=false (awaiting Nguyen's approval)
- DEVICE_TESTED=false

## H1 — keyboard fit (Maps + Waze only): DONE
- In DF154GeneralAppStateRelay.m: at UIKeyboardDidShow captures (immediate + the QA178 0.3s late capture), when ALL guards hold — flag KeyboardFit179 on (qa176 plist, live file read, absent = ON), bundle in {com.google.Maps, com.waze.iphone} (DF155PilotAppScope.h lines 26-27), keyboard window found, key window (level 0, not Keyboard/TextEffects class) found, key-window size != UIScreen.mainScreen size, kb frame != key frame — the keyboard window frame is set to the key window frame. Original frame saved on first apply.
- Idempotent (already-fit skip), fresh window enumeration on every evaluation (a divider drag 397->595 is seen at the next DidShow).
- Restore: UIKeyboardDidHide (new observer, restores to the saved original frame or the screen bounds), plus in-capture restores when the flag is off or the app is no longer hosted (key == screen).
- Known coupling (by construction, per the work order): the fit rides the kbdiag DidShow capture path. It still runs when the diagnostics flag is off (fit-only registration + handler gate), but if BOTH flags are off nothing is registered.
- Forbidden strings verified absent from the relay (setKeyplaneName/setKeyboardName/setKeyboardWidth count = 0); DFSceneHost.m and DFHostedMapRenderSize.h untouched; no keyplane/input-mode/hwKB hooks.

## H2 — fit measurements: DONE
- Every apply/skip/restore emits one qa179-kbfit line (Chrome side, from the mailbox record): bundle, action + guard reason (flag-off / no-kb-window / no-key-window / not-hosted / already-fit / exception), screen bounds, key frame, kb frame before + after, late flag, direct subviews of the kb window (class+frame, <=6) with first child each (<=3), capped; notification FrameBegin/FrameEnd appended by Chrome. DidHide restores travel as fit-only mailbox records (logged even if the diagnostics flag is off).

## H3 — selector-ownership probe: DONE
- Once per app session (attached to the first 3 captures so a mailbox overwrite cannot lose it): for UIKeyboardImpl, UIKeyboardLayoutStar, UIKeyboard, UIRemoteKeyboardWindow, UIInputWindowController, UIKeyboardInputModeController x keyboardWidthForScreen:withOrientation:, keyboardWidth, keyboardScreenReferenceSize — logs instancesRespondToSelector AND class_respondsToSelector per pair as qa179-selprobe (Chrome dedupes per bundle). Responds-checks only; no selector is invoked, nothing is hooked; the banned setter name appears nowhere in the relay.

## Tests
- CI battery green in run 41562273711, including the newly added discover lines for test_qa176_recall_hud_kbdiag and test_qa177_apptouch_hudhand_kbdiag (the battery previously ran neither), plus test_qa154, test_qa155, test_qa178, test_qa179 (new, 9 tests: versions, forbidden strings, flag default-on/live-read, scope, guards, restore paths, measurement fields, probe read-only), and test_integrated_package_144.
- Local clang syntax checks clean for DF154GeneralAppStateRelay.m and DFNative12Chrome.m.
- One local-only failure was a staging artifact (test_qa176 reads its own workflow file, absent from the local staging) — not a code failure; CI is authoritative.

## Device test owed (per the work order)
1. Waze full screen: tap search, photograph the keyboard, export the log immediately.
2. Waze split pane: same.
3. Maps split pane: same.
4. Drag the divider to resize, open the keyboard again.
5. Exit DuoFace; open Waze/Maps standalone: keyboard must be normal.

## Publish amendment (2026-11-03, approved by Nguyen)
- Publisher commits (carplaydsp): 0d4cfc46840f (QA179 selected, retained 124->125), c694f60681 (retrigger comment), c3e46572877e (block placement fix), 14d6323a44c9 (CFBundleVersion pin fix).
- Publisher runs: 41563094115 FAILURE (curl 56 in the index step with the QA179 block misplaced mid-script), 41563559696 FAILURE (same point), 41564189146 FAILURE (QA179 block verify: CFBundleVersion pin still '178' — a bare-number pin the version-tally missed), 41564754006 SUCCESS (all 5 jobs, queried directly).
- Public index independently verified: exactly 1 embedded stanza 0.0.179~kbfit1, Size 1277328, SHA256 9e83b36c9e381575fa3704da308170b5f79f91d998b422ac545ad7ac6f0b22a6. The published DEB was downloaded and hashed: byte-identical to the artifact of private build run 41562273711.
- QA178 rollback: 0.0.178~kbhud1 DEB still served from the repo (HTTP 206 on range request after the QA179 publish).
- CI tests in run 41562273711 (from the job log, per-test lines): test_qa154 4/4 ok, test_qa155 4/4 ok, test_qa176 7/7 ok, test_qa177 12/12 ok, test_qa178 10/10 ok, test_qa179 9/9 ok, test_integrated_package_144 4/4 ok; 36 test modules ran in total.
- NOTE: three backgrounded poll outputs during this publish fabricated run ids/results (41561078001, 41563697831, 41564415560 — all 404 on direct query). Every conclusion above rests on foreground queries only.
- SILEO_PUBLISHED=true. DEVICE_TESTED=false.
