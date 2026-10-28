# V7 actual CarPlay log — Google Maps app scene proven; switches to DuoFace native host

Date: 2026-10-28. Verified by reading 46 JSONL records from GitHub main/sideplay/log/DuoFaceCarPlayOwner-4C5C8ADB-EE69-458A-B664-1753AB90C797.jsonl. Upload main commit e908517e60b69; Git blob ffe9c6e6f0a0382426cf3dd78fd3da45d5a3fecc; 141845 bytes.

46/46 valid JSON. 40 records schema=1 V6 (PID 68379), with 7 live two-scene snapshots and 33 empty-scene snapshots. 6 records schema=2 V7 (PID 68776), 4 live two-scene snapshots and 2 empty-scene snapshots. V7 session D0177F7C-EFD1-446C-8253-9EB9F95553DA. Four active V7 records each have 21 controllers, no truncation.

## Live V7 timeline (2026-10-28 Asia/Bangkok UTC+7)
| Time | app bundle from DBApplicationSceneViewController.applicationInfo | FBScene.identifier | FBScene pointer |
| --- | --- | --- | --- |
| 12:02:09 | com.google.Maps | Car[2-3]:com.apple.CarPlayTemplateUIHost:com.google.Maps | 0x2813fc840 |
| 12:02:37 | com.google.Maps | Car[2-3]:com.apple.CarPlayTemplateUIHost:com.google.Maps | 0x2813fc840 |
| 12:03:07 | com.duoface.native.scenehost | Car[2-3]:com.apple.CarPlayTemplateUIHost:com.duoface.native.scenehost | 0x2813cbc00 |
| 12:03:37 | com.duoface.native.scenehost | Car[2-3]:com.apple.CarPlayTemplateUIHost:com.duoface.native.scenehost | 0x2813cbc00 |
| 12:04:07–12:04:37 | no connected UIKit scenes returned | unresolved | unresolved |

## Verified findings
- The actual Dashboard application controller DBApplicationSceneViewController.scene returns class FBScene, nativeSceneStatus=present. Its applicationInfo is DBApplicationInfo with a real bundleIdentifier. The controller is currently presenting Google Maps first, then DuoFace's independently declared CarPlay app. The latter identifier is confirmed in sideplay/duoface-native-scene-host/Info.plist, which declares CFBundleIdentifier com.duoface.native.scenehost.
- CRITICAL: The exact SAME DBApplicationSceneViewController pointer 0x5d0a14140 and same sceneHostView pointer 0x5d0a15160 remain across all four samples. The embedded FBScene and app identity SWITCH underneath the unchanged controller/host between 12:02:37 and 12:03:07. Therefore checking only view controller pointer is inadequate for lifecycle/scene ownership. V6 also showed replacement of VC/host in another session, so both patterns are possible.
- The host UIView is _UIScenePresentationView with frame/bounds 427x240 in DBDashboard-Car[2-3]. The system Dock is in its own statusbar-Car[2-3] scene with DBStatusBarWindow width 45; do not crop it. Dashboard Maps widget 179x224 and 179x69.5 are separate from this application scene.
- On this iPhone iOS16 runtime the native controller has no sceneHandle selector; use its scene object. FBScene has no client selector exposed by the ABI guard. Therefore the successful identity path is controller.scene.identifier and controller.applicationInfo.bundleIdentifier, NOT scene.client.process.bundleIdentifier borrowed from SpringBoard code. nativeProxyApplicationInfo exists but the displayed app must be checked against real applicationInfo.
- The literal mapsNativeOwnerProven=false is hard-coded in diagnostic V7 and does not contradict the positive Google Maps identity observation.

## Unproven / safety
- Log proves ownership of CURRENTLY PRESENTED native Google Maps scene, not that it continues guiding after switching foreground to DuoFace, not that a single scene can be safely cloned/reparented to a split pane, and not that any zoom fix is achieved.
- Empty connectedScenes samples beginning 12:04:07 do not prove crash, navigation termination, or why CarPlay scenes disappeared. New crash logs would need separate evidence.
- No code or DEB engine changed during this log review. Preserve working DuoFace 0.0.83 player and Apple Dock; never test an arbitrary zoom % or copy OmniCar license/binary.

## Next exact engineering step
Investigate the independent DuoFace native split adapter against the verified owner pair: DBApplicationSceneViewController (stable/replaceable) and its hosted FBScene (swappable independently), plus DBApplicationInfo.bundleIdentifier. Safely inventory whether the Google Maps scene remains alive behind the foreground DuoFace native scene, without background/foreground mutations. Only attach native Maps to a pane after real scene continuity and generation/ownership checks; first verify this with read-only instrumentation and existing Sileo flow. Google Maps is com.google.Maps, not Apple Maps. If native Maps cannot be observed behind DuoFace, report unresolved rather than fake it.

Source used: GitHub JSONL main commit e908517e60b69, sideplay/native-carplay-scene-v1/DFCarPlayLiveOwnerSnapshot.m, sideplay/duoface-native-scene-host/Info.plist, and prior OmniCar V3/V5 original-only audit reports.