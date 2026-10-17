# Speed8 CarPlay launch regression on iPhone X — 2026-10-17

## New actual user report
- iPhone X: Speed8 previously launched DuoFace CarPlay split and showed a bubble; now the DuoFace iPhone app opens but DuoFace on CarPlay won't open.
- iPhone 8 Plus: same stated iOS and DuoFace Speed8 still launches DuoFace CarPlay.
- The precise failed CarPlay tap behavior (no response, bounce Home, crash, black screen), installed package versions/checksums, jailbreak condition and runtime logs for iPhone X are NOT supplied. No established root cause. Do not attribute solely to iPhone X/iOS architecture.

## Verified repo facts
- Speed8 public immutable DEB: com.duoface.independent 0.1.0~native12+speed8compact, SHA256 2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad, repo feature artifact commit 1286a3ef868cf7e29804bcddf7e20b2eae707ce1.
- Dist/payload-migration/native12-speed8compact/BAO_CAO.json: preserves 42/43 Speed7 payload files unchanged; replaces ONLY DuoFaceSpeedHUD.dylib. Existing DuoFaceDashboard.dylib and filter identical to Speed7; both Speed8 SpeedHUD and SpeedOwner inject SpringBoard, not CarPlayApp.
- runtime/speedbubble/DFSpeedNativeSplit8SpringBoard.mm: native split gate checks CBBridgeManager / CBBridgedSplitApp / >=2 live panes / original CBWindow external root, then mounts one HUD. If DuoFace CarPlay fails BEFORE split creation, HUD is not proof of the trigger. GUI startup and HUD overlay are separate subsystems.
- Real Speed8 log: /var/mobile/Library/Logs/DuoFaceSpeedSplit8-SpringBoard.jsonl; records SPLIT8_LOADED_SPRINGBOARD, SPLIT8_WAIT_* and SPLIT8_MOUNTED_ONE_NATIVE_HOST. Events are throttled and append-only, so examine timestamp after the latest attempt.
- Rootless app at /var/jb/Applications/DuoFaceUI.app; dashboard at /var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib. User reporting the iPhone app launches does not prove CarPlay extension/dashboard activation is healthy.

## Short safe reproduction on failing iPhone X
1. Stationary, reconnect CarPlay; attempt launching DuoFace exactly once. Note: icon missing / tap ignored / returns to CarPlay Home / black screen / SpringBoard restart or whole device reboot.
2. Immediately Filza -> /var/mobile/Library/Logs/ -> share DuoFaceSpeedSplit8-SpringBoard.jsonl; if present also DuoFaceSpeedOwner-SpringBoard.jsonl. Retain the latest attempted-launch timestamps (old stages alone are misleading).
3. Filza -> /var/mobile/Library/Logs/CrashReporter/ (possibly Retired/) -> inspect the newest *timestamp-matching* SpringBoard-, CarPlay-, DuoFace-, backboardd- or JetsamEvent- .ips, if any. Crash reports may include private device/app metadata; review before sharing. No report existing is NOT proof that no failure happened.
4. Optionally on the working iPhone 8 Plus collect the corresponding latest SPLIT8 log after successful CarPlay split; compare first before changing any tweak. Confirm actual installed package and jailbreak state if differences appear.
5. Optional short read-only NewTerm commands, NOT yet run on device: dpkg-query -W com.duoface.independent ; tail -n 25 /var/mobile/Library/Logs/DuoFaceSpeedSplit8-SpringBoard.jsonl

## Triage decision
- No current SPLIT8_LOADED_SPRINGBOARD: inspect tweak injection, package, loader, SpringBoard crash or log file permissions; not proof alone.
- Current SPLIT8_WAIT_MANAGER / SPLIT8_WAIT_CBWINDOW / SPLIT8_WAIT_NOT_NATIVE_SPLIT_APP: native DuoFace owner did not reach split, inspect Dashboard startup/activation and matching crashes.
- Current SPLIT8_WAIT_NOT_TWO_NATIVE_PANES / SPLIT8_WAIT_PANES_NOT_ATTACHED: split pane lifecycle incomplete; inspect selected tile apps/windows.
- Current SPLIT8_MOUNTED_ONE_NATIVE_HOST: native split/HUD gate reached, check visual state/scene handoff rather than conclude no split.
- Fresh matching crash .ips: use termination reason, exception, and crashing stack/image to attribute source before patching.
- No new events and no crash: inspect CarPlay launch intent/UI input and owner initialization using more targeted future probe; do not blindly modify SpeedHUD.

## Safety and next step
- Do NOT erase preferences, reinstall/downgrade, repeatedly respring, toggle dynamic injection plists, or change any other tweak before initial evidence capture. Do not modify working iPhone 8 Plus.
- Next: obtain exact CarPlay failure symptom and most recent Speed8 JSONL OR timestamp-matching crash .ips from iPhone X; inspect it and contrast the working control if necessary.
- Speed9 remains only a staged QA candidate; do not publish it as a fix for this new regression. No device log, new DEB or runtime fix verified during this diagnosis.
