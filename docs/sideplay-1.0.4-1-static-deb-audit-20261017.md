# SidePlay 1.0.4-1: DEB static audit for independent DuoFace
Date 2026-10-17. User supplied package com.sideplay_1.0.4-1_iphoneos-arm64.deb (4,352,576 bytes); SHA256 7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c.
Actual commands performed: dpkg-deb -I/-c/-x/-e, find, strings -a on Mach-O binaries, llvm-objdump --macho --private-headers for SidePlay.dylib, read control/postinst/prerm/plists. Inspection is static, NOT device-tested.

## Answer: Is source code included?
NO. The 136 unpacked files contain no .m/.mm/.h/.xm/.swift/.c/.cpp or Theos/Xcode build project. Mach-O compiled binaries retain Objective-C runtime selectors/class names and diagnostic strings; they are not the original editable source.

## Components observed
- var/jb/Library/MobileSubstrate/DynamicLibraries/SidePlay.dylib: 899088 bytes, arm64 MH_DYLIB. Its plist injects com.apple.springboard and com.apple.UIKit. Core host strings include SBApplicationController, SBDeviceApplicationSceneEntity, SBAppViewController, SBDeviceApplicationSceneView, FBScene, FBSceneMonitor, FBSSceneSettings, FBSSceneParameters, UIApplicationSceneSettings, sceneHandle, CarPlayIsConnectedDidChange, initForCarPlayShell, currentCarPlayExternalDevice, geometry update refused, app-scene init failure, app termination and CarPlay reconnection. Indicates a real scene-host implementation is present; not proof two apps ran on the test phone.
- var/jb/Applications/SidePlay.app/SidePlay: 178672 bytes; CPTemplateApplicationSceneDelegate, CPTemplateApplicationScene, CPInterfaceController, CPWindow, openSidePlay.
- SidePlayPrefs.bundle/SidePlayPrefs: 613648 bytes; settings and log viewer.
- SidePlayHUDRelay.dylib: 240128 bytes; SpringBoard relay/lifetime and 20-second disconnect timer.
- SidePlayHUDGofa.dylib: 129936 bytes; filtered to com.lumi.GOFA.
- SidePlayHUDVietMap.dylib: 162752 bytes; filtered to vn.vietmap.live.
- SidePlayHUDWaze.dylib: 145328 bytes; filtered to com.waze.iphone.

Control: firmware >=15.0, mobilesubstrate, preferenceloader, iphoneos-arm64 rootless; developer description says one/two arbitrary CarPlay apps, not independently validated. Conflicts list com.cortex.carplayenable, com.pavunato.carsurf, com.bmt.dash, com.chou.googlemaps.vietmap; DuoFace absent but injection/scene-owner conflicts remain possible.
postinst executes uicache -p; prerm on removal executes SidePlay --sp-goodbye (script says contacts its server to report uninstall) then uicache -u. Those scripts were read, not run.
var/jb/usr/share/sideplay-hud/LICENSE-GMapHUD is MIT for GMapHUD contributor component ONLY, not a SidePlay-wide open source license. No SidePlay source/license for redistribution found. Core string scan did not find CBLicenseSyncManager or CBBridgeManager or plain license in SidePlay.dylib; absence of strings is NOT proof no entitlement/licensing.

## DuoFace reuse assessment
Useful research reference: create SpringBoard scene host, attach SBAppViewController/sceneHandle, configure geometry, coordinate one/two app lifetimes, handle physical CarPlay connection, clean tear-down. Our existing replacement/visual12/engine/runtime/DFIRuntime.m already refers to the same general SpringBoard private scene APIs; compare contracts and observed behavior rather than rewriting again. SidePlay is not drop-in compatible with DuoFace original CBMultitaskingOverlayView / CBBridgedSplitApp / CBBridgeManager, Fullscreen, or Hub8. Do NOT redistribute proprietary SidePlay binaries or copy implementation without permission. Preserve user's existing VisualTest12 UI; keep Native12 Hub8 package unchanged.

Next action: compare SidePlay scene lifecycle evidence against source-owned DFIRuntime.m, test a single real hosted app, then two simultaneously on a safe parked-car device with no concurrent scene owner, then see whether original VisualTest12 UI can bind through a limited adapter. Neither independent execution nor reuse of original UI with expired DuoNavi trial is proven. No code change, DEB build, Sileo deployment, or device test in this checkpoint.
