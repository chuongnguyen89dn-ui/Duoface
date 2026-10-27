# Build request .80 lifecycleorder1 — SpringBoard crash QA candidate

User explicitly requested direct repair of SpringBoard crash during YouTube/Facebook/TikTok video. Current playing-app UI, player sizing, Zoom, Swap, split, logo, touch, system Dock and orientation MUST NOT CHANGE.

Changes verified in first-party source: DFSceneHost.m now follows SHA-pinned Native12 original start @0xae538 setRequestedMode:2 BEFORE @0xaebf0 didMoveToParentViewController, and adds read-only, change-only logging of hosted FBScene.settings foreground state and scene generation. It NEVER sets foreground/background, hooks SpringBoard private observers, suppresses exceptions, changes UIKit geometry, or enables DFAppViewportRelay. Includes one regression test for order and diagnostics. This is a lifecycle candidate, NOT proven to stop the original Live + foreground=NO SIGABRT.

Source-only iOS SDK test run 40497248208 SUCCESS for source commit 953db8106951542c0045e2a37a5cf5180dc16058 (including new regression and diagnostic version labels). Prior source-only run 40496961579 FAILED solely because exporter retained old .79 label; fixed by commits 2584c332d3b2b820999cf2584da9cbe2b5c070bb and 0234b0cbe7dd105176831c82a04303b236ada50b, validated in successful run.

Compile and stage exactly:
- NativeHost: com.duoface.carplay.nativescenehost 0.1.89~lifecycleorder1
- Single merged rootless DEB: com.duoface.jb.embedded 0.0.80~lifecycleorder1
- Rootless iphoneos-arm64, vendor exclusion and current-source SHA rules preserved.
- Do not auto-respring or install; inspect archive + SHA, publish to Sileo QA only on successful build, and require manual parked-car device validation of video play/seek, both panes, focus, close/reopen, SpringBoard stability. Do not treat CI PASS as device PASS.
