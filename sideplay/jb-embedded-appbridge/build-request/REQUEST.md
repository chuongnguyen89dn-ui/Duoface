# Build new immutable .76 reason1 — capture actual uncaught assertion reason

Why: 3 real .74 SpringBoard EXC_CRASH/SIGABRT .ips show SBAppViewController sceneHandle:didUpdateSettingsWithDiff:+440 but omit NSException.name/reason. Two/three crashes had frame-write log; one crash had NO frame-write log. The .75 frame OFF gate boxed video and did not prevent crash; reverted from source and PUBLIC Sileo, NOT to be reused.
Source CI https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/40442229289 SUCCESS at e67bb2e33bd0de0bcefdb34c6803efb416a433ae.
New NativeHost 0.1.85~reason1, integrated 0.0.76~reason1.
Preserve .37/.74 frame path: SBAppViewController 2/3 content reference + FBScene.updateSettingsWithBlock:/setFrame:, 4 physical per-pane UIWindows, logo, Zoom, Dock, ratio, swap.
Only addition: active CarPlay uncaught Objective-C exception reason/stack recorder, chains old handler and never swallows, and built-in audit exports DuoFaceFatalException.log; no private OS scene-method swizzles.
Rootless iOS16 signed integrated one-DEB CI. No auto respring, no effect unless user explicitly installs.
This is an INSTRUMENTED DIAGNOSTIC BUILD, NOT a verified crash fix. Public .74 stable-geometry baseline retained for rollback. Crash validation only on parked physical device.
