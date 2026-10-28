import unittest
import plistlib
import json
import math
from pathlib import Path
R=Path(__file__).resolve().parents[1]
def file(n):return (R/n).read_text()
class NativeCarPlayHost(unittest.TestCase):
 def test_native12_083_scoped_manual_scene_observer_and_apple_passthrough(self):
  policy=file("DFSceneLifecycle.m")
  self.assertIn("DFIsOwnedManualSceneObserver",policy)
  self.assertIn("owned-manual-observer-consumed",policy)
  self.assertIn("currentHandle!=handle",policy)
  self.assertIn("currentScene!=scene",policy)
  self.assertIn("!NSThread.isMainThread",policy)
  self.assertIn("sPreviousSceneObserver(controller,selector,handle,diff,previousSettings)",policy)
  self.assertIn("if(!DFObjectUpdateABI(method) || !DFObjectUpdateABI(observerMethod))return NO;",policy)
  host=file("DFSceneHost.m")
  self.assertIn('DFHostBool(self.appController, @"setAutomatesLifecycle:", NO)',host)
  self.assertIn("DFSceneLifecycleUnregister(self.appController)",host)
 def test_native12_host_mode_before_containment_commit_and_passive_scene_foreground(self):
  """Native12 original requests Live before didMove; no UI or FBScene override."""
  src=file("DFSceneHost.m")
  start=src.split("- (void)start {",1)[1].split("- (void)layoutSubviews",1)[0]
  self.assertLess(start.index("[parent addChildViewController:self.appController]"),
                  start.index("setRequestedMode:"))
  self.assertLess(start.index("setRequestedMode:"),
                  start.index("[self.appController didMoveToParentViewController:parent]"))
  self.assertLess(start.index("[self.appController didMoveToParentViewController:parent]"),
                  start.index("[self.appController endAppearanceTransition]"))
  self.assertIn('DFObservedSceneForeground(scene)',src)
  self.assertIn('scene-foreground-observed-only',src)
  self.assertIn('scene-foreground-readback-unavailable',src)
  self.assertIn('0.0.83~manualobserver1',file("DFDeepTrace.h"))
  self.assertIn('0.0.83~manualobserver1',file("DFNativeDiagnostics.m"))
  self.assertIn('self.lastObservedForeground=-2;',src)
  self.assertIn('if(fg!=self.lastObservedForeground)',src)
  commit=src.split("void (^setVerifiedNative12Frame)(id)=^(id settings) {",1)[1].split("};",1)[0]
  self.assertIn('NSSelectorFromString(@"setForeground:")',commit)
  self.assertIn('NSSelectorFromString(@"setBackgrounded:")',commit)
  self.assertIn('[settings respondsToSelector:fgSelector]',commit)
  self.assertIn('[settings respondsToSelector:bgSelector]',commit)
  self.assertIn('settings,fgSelector,YES',commit)
  self.assertIn('settings,bgSelector,NO',commit)
  self.assertIn('sceneGeneration!=generation',commit)
  self.assertIn('surface.scene!=hostedScene',commit)
  self.assertIn('scene-settings-live-contract-requested',src)
  self.assertNotIn('NSSelectorFromString(@"setForeground:")',src.split("- (void)start {",1)[1].split("- (void)layoutSubviews",1)[0])
  self.assertNotIn('sceneHandle:didUpdateSettingsWithDiff:previousSettings:',src)

 def test_first_party_independent_manifest(self):
  m=plistlib.loads((R/"Info.plist").read_bytes())
  self.assertEqual(m["CFBundleIdentifier"],"com.duoface.native.scenehost")
  configs=m["UIApplicationSceneManifest"]["UISceneConfigurations"]
  self.assertTrue(m["UIApplicationSceneManifest"]["UIApplicationSupportsMultipleScenes"])
  self.assertEqual(configs["UIWindowSceneSessionRoleCarPlay"][0]["UISceneClassName"],"UIWindowScene")
  self.assertEqual(configs["UIWindowSceneSessionRoleCarPlay"][0]["UISceneDelegateClassName"],"DFNativeHostCarSceneDelegate")
  self.assertIn("UIWindowSceneSessionRoleApplication",configs)
  ent=plistlib.loads((R/"entitlements.plist").read_bytes())
  self.assertTrue(ent["com.apple.developer.carplay-maps"])
  self.assertFalse(any(k.startswith("com.apple.developer.carplay") and k!="com.apple.developer.carplay-maps" for k in ent))
  self.assertEqual(configs["CPTemplateApplicationSceneSessionRoleApplication"][0]["UISceneClassName"],"CPTemplateApplicationScene")
  self.assertEqual(configs["CPTemplateApplicationSceneSessionRoleApplication"][0]["UISceneDelegateClassName"],"DFNativeHostTemplateSceneDelegate")
 def test_system_must_supply_scene_no_foreign_window(self):
  c=file("DFNativeHostAppDelegate.m")
  self.assertIn("initWithWindowScene:ws",c)
  self.assertIn('session.role isEqualToString:DFCarPlayRole',c)
  self.assertIn("ws.screen==UIScreen.mainScreen",c)
  self.assertIn("sceneDidDisconnect:",c)
  self.assertIn("native-carplay-scene-connected",c)
  for forbidden in ("UIRootSceneWindow","initWithDisplayConfiguration:",
             "FBSDisplayConfiguration","windowLevel=", "DBStatusBarWindow",
             "setWindowLevel:", "bar.hidden=", "activateApplication:",
             "requestStateChange:", "SBAppViewController"):
   self.assertNotIn(forbidden,c)
 def test_never_mutate_carplay_dock_or_forge_two_app_success(self):
  c=file("DFNativeHostRootController.m")
  self.assertNotIn("APP 1",c)
  self.assertNotIn("APP 2",c)
  self.assertNotIn("Chưa nối hai ứng dụng iPhone",c)
  self.assertIn("safeAreaLayoutGuide",c)
  for forbidden in ("DBDockWindow","DBStatusBarWindow","CALayerHost","drawViewHierarchyInRect",
                    "SBAppViewController","UIRootSceneWindow","[window setFrame",
                    "entitlementValueForKey"):
   self.assertNotIn(forbidden,c)
 def test_navigation_template_is_system_owned_and_not_tweak_ui(self):
  c=file("DFNativeHostAppDelegate.m")
  for marker in ("#import <CarPlay/CarPlay.h>",
     "CPTemplateApplicationSceneSessionRoleApplication",
     "CPTemplateApplicationScene.class", "DFNativeHostTemplateSceneDelegate",
     "templateApplicationScene:(CPTemplateApplicationScene *)scene",
     "didConnectInterfaceController:(CPInterfaceController *)controller",
     "toWindow:(CPWindow *)window", "setRootTemplate:map animated:NO",
     "native-carplay-template-scene-connected",
     "templateApplicationScene:(CPTemplateApplicationScene *)scene",
     "didDisconnectInterfaceController:(CPInterfaceController *)controller",
     "self.carWindow=nil"):
   self.assertIn(marker,c)
  self.assertNotIn("setWindowLevel:",c)
  self.assertNotIn("DBDockWindow",c)
  self.assertIn("-framework CarPlay",file("build.sh"))
  self.assertIn("ldid -Sentitlements.plist",file("build.sh"))
 def test_no_demo_window_or_forged_native12_split(self):
  app=file("DFNativeHostAppDelegate.m")
  ui=file("DFNative12BasicController.m")
  chrome=file("DFNative12Chrome.m")
  self.assertIn("DFNative12BasicController *root=[DFNative12BasicController new]",app)
  self.assertIn('map.mapButtons=@[]',app)
  self.assertIn('map.leadingNavigationBarButtons=@[]',app)
  self.assertNotIn('initWithTitle:command handler:',app)
  self.assertNotIn('CPMapButton *button',app)
  self.assertNotIn("CHƯA NỐI SCENE",ui)
  self.assertNotIn("APP 1",ui)
  self.assertNotIn("APP 2",ui)
  self.assertNotIn("menuSheet",ui)
  self.assertNotIn("UIPanGestureRecognizer",ui)
  self.assertNotIn("self.leftSlot",ui)
  self.assertIn("self.view.userInteractionEnabled=NO",ui)
  self.assertNotIn("startupSplash",ui)
  self.assertNotIn("dispatch_after(",ui)
  self.assertIn('self.appSceneWindows',chrome)
  self.assertIn('hostViewForBundleID:',chrome)
  self.assertIn('DFSceneHostDidBecomeReadyNotification',chrome)
  self.assertIn('DFSceneHostDidFailNotification',chrome)
  for forbidden in ("DBDockWindow","setWindowLevel:","SBAppViewController","CALayerHost","requestStateChange:","CarBridge"):
   self.assertNotIn(forbidden,ui)
 def test_native12_input_is_routed_through_system_template(self):
  app=file("DFNativeHostAppDelegate.m")
  header=file("DFNative12BasicController.h")
  chrome=file("DFNative12Chrome.m")
  self.assertIn("CPMapTemplate *map=[CPMapTemplate new]",app)
  self.assertIn('map.mapButtons=@[]',app)
  self.assertIn("setRootTemplate:map animated:NO",app)
  self.assertNotIn("performCarPlayControl:",header)
  self.assertNotIn("setPresetRatio:",header)
  self.assertIn("touchowner-state-ack",app)
  self.assertIn("DFDragFinish(&_dividerDrag",chrome)
  self.assertIn('openAppPickerForSlot:',chrome)
  self.assertIn('closeHostedSlot:',chrome)
  self.assertNotIn("sendEvent:",app)
  self.assertNotIn("UIRootSceneWindow",app)
 def test_0_1_0_native12_touch_owner_is_bounded_and_fail_closed(self):
  probe=file("DFTouchOwnerProbe.m")
  injector=(R/"DFTouchOwnerProbe.plist").read_bytes()
  f=plistlib.loads(injector)
  self.assertEqual(f["Filter"]["Bundles"],["com.apple.springboard"])
  self.assertEqual(f["Filter"]["Executables"],["SpringBoard"])
  self.assertIn('isEqualToString:@"SpringBoard"',probe)
  self.assertIn("FBSDisplayConfiguration",probe)
  self.assertIn("UIRootSceneWindow",probe)
  self.assertIn("initWithCADisplay:isMainDisplay:",probe)
  self.assertIn("initWithDisplayConfiguration:",probe)
  self.assertIn("UIScreen.mainScreen",probe)
  chrome=file("DFNative12Chrome.m")
  self.assertIn("DFNative12Chrome *sChrome",probe)
  self.assertIn("CGRectContainsRect",chrome)
  self.assertIn("w.frame=frame",chrome)
  self.assertNotIn("safety-expiry-600s",probe)
  self.assertIn("DFSessionStillActive()",probe)
  self.assertIn("session-revoked-before-window-start",probe)
  self.assertIn("DFWatchdog(generation)",probe)
  self.assertIn("inactive-or-stale-heartbeat",probe)
  self.assertIn('pulse[@"Active"]',probe)
  self.assertIn("age>2.5",probe)
  app=file("DFNativeHostAppDelegate.m")
  self.assertIn("sceneWillResignActive:",app)
  self.assertIn("sceneDidEnterBackground:",app)
  self.assertIn("sceneDidBecomeActive:",app)
  self.assertIn("stopTouchOwnerWithReason:",app)
  self.assertIn("scene-resigned-carplay-home",app)
  self.assertIn("not-active-or-home",app)
  self.assertIn("renewTouchOwnerHeartbeat:",app)
  self.assertIn("timerWithTimeInterval:0.75",app)
  self.assertIn("UISceneActivationStateForegroundActive",app)
  self.assertIn('@"Active":@YES',app)
  self.assertIn("removeItemAtPath:path",app)
  self.assertIn("window-detached",probe)
  self.assertIn("divider-pan-end",chrome)
  self.assertIn("picker-open",chrome)
  self.assertIn("swap-button",chrome)
  self.assertIn("notify_register_dispatch(kStart",probe)
  self.assertIn("notify_register_dispatch(kStop",probe)
  self.assertIn("DuoFaceTouchOwner.log",probe)
  self.assertNotIn("sendEvent:",probe)
  self.assertNotIn("UITouch alloc",probe)
  self.assertNotIn("killall",probe)
  self.assertNotIn("DBStatusBarWindow",probe)
  self.assertNotIn("CBBridgeManager",probe)
  self.assertNotIn("SPDash",probe)
  app=file("DFNativeHostAppDelegate.m")
  self.assertIn('notify_post("com.duoface.nativehost.touchowner.start.v1")',app)
  self.assertIn('notify_post("com.duoface.nativehost.touchowner.stop.v1")',app)
  build=file("build.sh")
  self.assertIn("-dynamiclib",build)
  self.assertIn("DFTouchOwnerProbe.m",build)
  self.assertIn("DFTouchOwnerProbe.plist",build)
  self.assertIn("0.1.92~manualobserver1",build)
  self.assertIn("mobilesubstrate",file("control"))
 def test_native12_independent_geometry_and_complete_action_contract(self):
  chrome=file("DFNative12Chrome.m")
  receiver=file("DFNativeHostAppDelegate.m")
  visual=file("DFNative12BasicController.m")
  contract=file("DFNative12BasicController.h")
  build=file("build.sh")
  for name in ("DFNative12Chrome.m","DFTouchOwnerProbe.m"):
   self.assertIn(name,build)
  # Reference sizes and hitboxes from own DFSPNativeSlotPill and Native12 audit.
  self.assertIn("CGFloat width=focused?(compact?72:80)",chrome)
  self.assertIn("CGFloat width=focused?(compact?72:80):(compact?64:76)",chrome)
  self.assertIn("CGFloat height=compact?19:22",chrome)
  self.assertIn("pill.layer.cornerRadius=11",chrome)
  self.assertIn("sheet.layer.cornerRadius=MIN(20,ph/2)",chrome)
  self.assertNotIn("hold.minimumPressDuration=3.0;",chrome)
  self.assertNotIn("requireGestureRecognizerToFail:hold",chrome)
  self.assertIn("DFCSnap",chrome)
  self.assertIn("UIVisualEffectView *pill",chrome)
  self.assertIn('systemImageNamed:@"ellipsis"',chrome)
  self.assertIn('systemImageNamed:@"arrow.left.arrow.right"',chrome)
  self.assertNotIn('UIImage *pickerArt=DFCArtwork(@"duoface-picker")',chrome)
  self.assertNotIn('UIImage *swapArt=DFCArtwork(@"duoface-swap")',chrome)
  self.assertIn("fabs(x-stop.doubleValue)<.04",chrome)
  self.assertIn("self.preset=selected",chrome)
  self.assertIn("self.focus=(self.focus==slot)?-1:slot",chrome)
  self.assertIn("DFDragFinish(&_dividerDrag",chrome)
  self.assertIn("divider-pan-begin",chrome)
  self.assertIn("divider-pan-end",chrome)
  self.assertIn("divider-axis-locked-logo-no-hold",chrome)
  self.assertIn("self.pillWindows",chrome)
  self.assertNotIn("safety-expiry-600s",file("DFTouchOwnerProbe.m"))
  self.assertNotIn("self.basicController setPresetRatio:",receiver)
  self.assertNotIn("self.basicController performCarPlayControl:",receiver)
  self.assertIn('state[@"Owner"] isEqualToString:@"SpringBoard"',receiver)
  self.assertIn("notify_post(DFAckNotify)",receiver)
  self.assertIn("self.lastTouchSequence",receiver)
  self.assertIn('@"ContentRect"',receiver)
  self.assertNotIn("performCarPlayControl:",contract)
  self.assertIn("- (NSDictionary<NSString *, id> *)stateSnapshot;",file("DFNative12Chrome.h"))
  self.assertIn('@"FocusLeft"',chrome)
  self.assertIn('@"FocusRight"',chrome)
  self.assertIn('@"Restore"',chrome)
  self.assertIn('@"Style"',chrome)
  self.assertIn("self.preset=selected",chrome)
  self.assertIn("self.focus",chrome)
  self.assertNotIn("self.leftSlot",visual)
  self.assertNotIn("CHƯA NỐI SCENE",visual)
  for text in ("SPDash","CBBridgeManager","checkAndSyncLicense",
               "SBDeviceApplicationSceneEntity","sendEvent:"):
   self.assertNotIn(text,chrome)
  self.assertNotIn("DBDockWindow",chrome)
  self.assertNotIn("requestStateChange:",chrome)
 def test_native12_divider_ratio_uses_static_screen_coordinates_not_moving_window(self):
  # Original Native12/visual12 puts ratio movement in a static content root.
  # Chrome instead re-frames a tiny divider UIWindow on every move. Measuring
  # translationInView: that same view feeds window motion back into the input.
  chrome=file("DFNative12Chrome.m")
  start=chrome.index("- (CGPoint)dividerTouchOnScreen:")
  end=chrome.index("// Native12: second divider alters",start)
  pan=chrome[start:end]
  self.assertIn("self.dividerWindow.screen.coordinateSpace",pan)
  self.assertIn("convertPoint:local toCoordinateSpace:screen",pan)
  self.assertIn("[self beginDividerDragAt:screen];",pan)
  self.assertIn("[self updateDividerDragAt:current];",pan)
  self.assertIn("[self finishDividerDragAt:current cancelled:",pan)
  # Translation is used ONLY at Began, before the track starts moving.
  self.assertIn("CGPoint initial=CGPointMake(local.x-translation.x,local.y-translation.y);",pan)
  # Three original actions are still discrete after the pointer correction.
  self.assertIn("[self swapPressed:sender]",chrome)
  self.assertIn("if(self.touchTracked && self.touchMoved)self.touchMoved(self);",chrome)

 def test_original_native12_logo_hit_owner_is_separate_from_ratio_pan(self):
  # Original Native12 method index (CBDividerView): pointInside,
  # handleMoveButtonLongPress, moveButtonTouchUp, and handlePan are distinct.
  chrome=file("DFNative12Chrome.m")
  self.assertIn("@interface DFNativeDividerGripButton : UIButton",chrome)
  self.assertIn("CGRectInset(self.bounds,-12.0,-12.0)",chrome)
  self.assertIn("DFAppPickerDelegate, UIGestureRecognizerDelegate",chrome)
  self.assertIn("trackPan.delegate=self",chrome)
  self.assertIn("gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer",chrome)
  self.assertIn("shouldReceiveTouch:(UITouch *)touch",chrome)
  self.assertIn("gestureRecognizer.view!=self.dividerTrack",chrome)
  self.assertIn("CGRectInset(self.dividerLogo.frame,-12.0,-12.0)",chrome)
  self.assertIn("return self.dividerLogo.hidden || !CGRectContainsPoint(logoHit,p);",chrome)
  self.assertIn("logo.touchMoved=^(UIButton *sender)",chrome)
  self.assertIn("self.activeTouch=touch;",chrome)
  self.assertIn("- (void)touchesCancelled:(NSSet<UITouch *> *)touches",chrome)
  self.assertIn("initWithTarget:self action:@selector(dividerPan:)",chrome)
  self.assertNotIn("requireGestureRecognizerToFail:hold",chrome)
  self.assertIn("forControlEvents:UIControlEventTouchUpInside",chrome)
  self.assertIn("[self swapPressed:sender]",chrome)
  hold=chrome[chrome.index("- (void)logoTouchChanged:"):chrome.index("- (void)logoTouchFinished:",chrome.index("- (void)logoTouchChanged:"))]
  self.assertIn("[self updateDividerDragAt:",hold)
  self.assertNotIn("swapPressed",hold)
  pan=chrome[chrome.index("- (void)dividerPan:"):chrome.index("// Native12: second divider alters")]
  self.assertIn("[self finishDividerDragAt:current",pan)
  self.assertNotIn("self.logoFraction=",pan)



 def test_native12_approved_artwork_iphone_home_and_launch(self):
  info=plistlib.loads((R/"Info.plist").read_bytes())
  self.assertEqual(info["CFBundleDisplayName"],"DuoFace")
  self.assertEqual(info["UILaunchStoryboardName"],"DuoFaceLaunchScreen")
  self.assertIn("CFBundleIcons",info)
  self.assertTrue((R/"DuoFaceLaunchScreen.storyboard").exists())
  splash=file("DuoFaceLaunchScreen.storyboard")
  self.assertIn('image="duoface-logo"',splash)
  self.assertIn('initialViewController="DF-Launch"',splash)
  self.assertIn('backgroundColor',splash)
  build=file("build.sh")
  self.assertIn("xcrun ibtool",build)
  self.assertIn("duoface-logo-picker-alpha-v2.png",build)
  self.assertIn("DuoFaceIcon60@2x.png",build)
  self.assertIn("DuoFaceIcon60@3x.png",build)
  for path in ("duoface-logo.png","duoface-logo-vert.png",
               "duoface-picker.png","duoface-fullscreen.png","duoface-swap.png"):
   self.assertIn(path,build)
  visual=file("DFNative12BasicController.m")
  phone=file("DFNativeHostRootController.m")
  spring=file("DFNative12Chrome.m")
  self.assertNotIn("startupSplash",visual)
  self.assertNotIn("duoface-logo",visual)
  self.assertIn('DFCArtwork(@"duoface-logo")',spring)
  self.assertIn('@"Trạng thái",@"Ứng dụng"',phone)
  self.assertIn('self.mainLogo=logo',phone)
  self.assertIn("LSApplicationWorkspace",phone)
  self.assertIn("DFIsEligibleAppID(bundle)",phone)
  self.assertIn("DFIsEligibleAppID(bundleID)",file("DFAppLibrary.m"))
  eligible=file("DFAppEligibility.h")
  self.assertIn("com.apple.Maps",eligible)
  self.assertIn("com.apple.mobileipod",eligible)
  self.assertIn("com.apple.mobilesafari",eligible)
  self.assertIn('[bundleID hasPrefix:@"com.duoface."]',eligible)
  self.assertIn("reloadLiveStatus",phone)
  self.assertIn("self.installedApps",phone)
  self.assertNotIn('@"APP 1"',phone)
  self.assertNotIn('@"APP 2"',phone)
  self.assertNotIn("mainContent",phone)
  self.assertIn('UIImage *smallArt=DFCArtwork(@"duoface-swap")',spring)
  self.assertIn("self.dividerLogo.layer.cornerRadius=size/2",spring)
  self.assertIn('DFCArtwork(@"duoface-logo-picker-alpha-v2")',spring)
  self.assertNotIn('DFCArtwork(@"duoface-picker")',spring)
 def test_original_native12_scene_settings_frame_block_has_original_abi_guard(self):
  evidence=json.loads((R.parent/"audit/native12-continuation-4888299/scene-block-invoke/SCENE_SETTINGS_BLOCK_INVOKE_ARM64.json").read_text())
  self.assertEqual(evidence["dashboard_sha256"],"9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea")
  self.assertEqual(evidence["block_invoke_pc"],"0xadc74")
  ins=evidence["original_machine_instructions"]
  for addr in ("adc84:","adcb4:","adcc8:","adce4:","add30:","add64:","add98:","addcc:","ade00:","ade34:"):
   self.assertTrue(any(x.startswith(addr) for x in ins),addr)
  scene=file("DFSceneHost.m")
  commit=scene.split("- (void)commitSceneGeometry:(NSTimer *)timer {",1)[1].split("- (UIView *)hitTest:",1)[0]
  self.assertIn("if (self.ready && self.scene)",commit)
  self.assertIn('NSSelectorFromString(@"updateSettingsWithBlock:")',commit)
  self.assertIn('NSSelectorFromString(@"setFrame:")',commit)
  self.assertIn("CGRectMake(0,0,logical.width,logical.height)",commit)
  self.assertIn("settings,frameSelector,nativeFrame",commit)
  self.assertIn("native12-scene-settings-live-contract-requested",commit)
  self.assertIn('NSSelectorFromString(@"setForeground:")',commit)
  self.assertIn('NSSelectorFromString(@"setBackgrounded:")',commit)
  self.assertIn('settings,fgSelector,YES',commit)
  self.assertIn('settings,bgSelector,NO',commit)
  self.assertNotIn('NSSelectorFromString(@"setCanShowWhileLocked:")',commit)
  self.assertIn("if (self.stopped) return;",scene)


 def test_independent_two_real_host_scene_opt_in_and_exit_cleanup(self):
  chrome=file("DFNative12Chrome.m")
  scene=file("DFSceneHost.m")
  picker=file("DFAppPickerVC.m")
  source=file("build.sh")
  self.assertIn("DFSceneHost.m",source)
  self.assertIn("DFAppLibrary.m",source)
  self.assertIn("DFAppPickerVC.m",source)
  self.assertIn("SBAppViewController",scene)
  self.assertIn("SBDeviceApplicationSceneEntity",scene)
  self.assertIn("hostViewForBundleID:",scene)
  self.assertIn("sceneIfExists",scene)
  self.assertIn("scene-handle-observed-render-unverified",scene)
  self.assertIn("DFSceneHostDidBecomeReadyNotification",scene)
  self.assertIn("scene-replace-committed-render-unverified",chrome)
  self.assertIn("real-scene-failed",chrome)
  self.assertIn("invalidate-done",scene)
  self.assertIn("stopAllHosts",scene)
  self.assertIn("DFAppPickerVC *appPickerController",chrome)
  self.assertIn("appPicker:(",chrome)
  self.assertIn("app-replace-pending-existing-retained",chrome)
  self.assertIn("app-host-refused",chrome)
  self.assertIn("closeHostedSlot:",chrome)
  self.assertIn("openAppPickerForSlot:",chrome)
  self.assertIn("appSceneWindows",chrome)
  self.assertIn("releaseHostedView:",chrome)
  self.assertIn("stopAllHosts",chrome)
  self.assertIn("LSApplicationWorkspace",file("DFAppLibrary.m"))
  self.assertIn("installedUserApps",file("DFAppPickerVC.m"))
  self.assertIn("refreshInstalledApps",file("DFAppPickerVC.m"))
  self.assertIn("didSelectBundleID:",picker)
  self.assertIn("not-active-or-home",file("DFNativeHostAppDelegate.m"))
  self.assertIn("inactive-or-stale-heartbeat",file("DFTouchOwnerProbe.m"))
  for prohibited in ("CBBridgeManager","checkAndSyncLicense","SPDash","DuoNaviDashboard","SidePlay.dylib"):
   self.assertNotIn(prohibited,scene)
   self.assertNotIn(prohibited,chrome)
  self.assertNotIn("MTTrialLog",scene)
 def test_native12_source_owned_ratio_and_swap_persist(self):
  chrome=file("DFNative12Chrome.m")
  self.assertIn("com.duoface.nativehost.layout.v1.plist",chrome)
  self.assertIn("DFCRestoreLayout",chrome)
  self.assertIn("DFCSaveLayout",chrome)
  self.assertIn('@"Ratio"',chrome)
  self.assertIn('@"LogoFraction"',chrome)
  self.assertIn('@"Vertical"',chrome)
  self.assertIn('@"Swapped"',chrome)
  self.assertIn("writeToFile:kDFLayoutPath atomically:YES",chrome)
  self.assertIn("if(end){[self saveSplitState];[self noteUserActivity];}",chrome)
  self.assertIn("self.swapped=!self.swapped;",chrome)
  self.assertIn("DFComputePresetFramesWithSecondary(cr,self.preset,p,self.secondaryRatio,pane)",chrome)
  self.assertNotIn("checkAndSyncLicense",chrome)
  self.assertNotIn("licenseWatchdog",chrome)
  self.assertNotIn('@"AppBundleID"',chrome)
  self.assertIn("scene-replace-committed-render-unverified",chrome)
  self.assertIn("scene-handle-observed-render-unverified",file("DFSceneHost.m"))
 def test_native12_real_scene_survives_picker_and_launch_fails_closed(self):
  chrome=file("DFNative12Chrome.m")
  picker=file("DFAppPickerVC.m")
  api=file("DFAppPickerVC.h")
  host=file("DFSceneHost.m")
  # Real hosted app scene remains visible behind menu and app chooser:
  # native12 split controller overlays controls; modal cannot suspend apps.
  self.assertIn("appWindow.hidden=(self.startupActive || focusedElsewhere);",chrome)
  self.assertIn("v.hidden=appWindow.hidden;",chrome)
  self.assertIn("v.userInteractionEnabled=loaded;",chrome)
  self.assertNotIn("appWindow.hidden=(!(loaded||negotiating)",chrome)
  self.assertIn("self.pendingScenes[(NSUInteger)i]!=NSNull.null",chrome)
  self.assertNotIn("appWindow.hidden=(!loaded || self.pickerVisible",chrome)
  self.assertNotIn("self.appPickerWindow.hidden==NO ||",chrome)
  self.assertIn("self.appPickerController refreshInstalledApps",chrome)
  self.assertIn("self.appPickerWindow.hidden=NO",chrome)
  self.assertIn("app-host-refused",chrome)
  self.assertIn("app-replace-pending-existing-retained",chrome)
  self.assertIn("void)refreshInstalledApps",api)
  self.assertIn("inventoryGeneration",picker)
  self.assertIn("owner.inventoryGeneration!=generation",picker)
  self.assertIn("DFAppLibrary installedUserApps",picker)
  self.assertIn("view.backgroundColor=UIColor.clearColor",host)
  self.assertNotIn('view.backgroundColor=UIColor.blackColor;',host)
 def test_native12_six_pill_states_bound_to_real_host(self):
  chrome=file("DFNative12Chrome.m")
  self.assertIn("sceneHandleReady",chrome)
  self.assertIn("self.sceneHandleReady[(NSUInteger)physicalSlot]=@NO",chrome)
  self.assertIn("self.sceneHandleReady[(NSUInteger)i]=@YES",chrome)
  self.assertIn("self.sceneHandleReady[(NSUInteger)i]=@NO",chrome)
  self.assertIn("CGFloat width=focused?(compact?72:80)",chrome)
  self.assertIn("CGFloat width=focused?(compact?72:80):(compact?64:76)",chrome)
  self.assertIn("zoom.hidden=NO",chrome)
  self.assertIn("if(self.focus==slot)self.focus=-1",chrome)
  self.assertIn("if(self.focus==visual)self.focus=-1",chrome)
  self.assertIn("self.sceneHandleReady removeAllObjects",chrome)
  self.assertIn("self.appPickerWindow.hidden=NO",chrome)
 def test_stage_one_two_panes_visible_with_real_controls_and_touch_safe_borders(self):
  chrome=file("DFNative12Chrome.m")
  layout=file("DFLayoutEngine.m")
  # Default Native12 two-pane split, no simulated player or third window.
  self.assertIn("_ratio=.5;_logoFraction=.5;",chrome)
  self.assertIn("_verticalDivider=YES;_focus=-1;_selectedSlot=0;_preset=1;_secondaryRatio=.5;",chrome)
  self.assertIn("return preset==0?1:(preset==1||preset==2?2:(preset==8?4:3));",layout)
  self.assertIn("for(NSInteger slot=0;slot<4;slot++)",chrome)
  self.assertIn("if(i>=activeSlots){w.hidden=YES;continue;}",chrome)
  self.assertIn("if(visualSlot>=activeSlots){appWindow.hidden=YES;v.hidden=YES;continue;}",chrome)
  self.assertIn("appWindow.hidden=(self.startupActive || focusedElsewhere);",chrome)
  self.assertIn("v.hidden=appWindow.hidden;",chrome)
  self.assertIn("v.userInteractionEnabled=loaded;",chrome)
  # Empty slots are visible, but never intercept app or system touches.
  self.assertIn("BOOL empty=(!loaded && !negotiating);",chrome)
  self.assertIn("v.layer.borderWidth=splitVisible?(touched?1.0:(empty?0.75:0.0)):0.0;",chrome)
  self.assertIn("[UIColor colorWithWhite:1 alpha:.25]",chrome)
  self.assertIn("227./255 green:2./255 blue:15./255",chrome)
  self.assertNotIn("line.backgroundColor=[UIColor colorWithWhite:1 alpha:.24];",chrome)
  self.assertIn("self.focus<0",chrome)
  self.assertIn("self.borderUntil=NSDate.date.timeIntervalSince1970+2.0;",chrome)
  self.assertIn("self.dividerWindow.hidden=(self.startupActive||activeSlots==1||self.focus>=0||self.pickerVisible||self.styleVisible||self.appPickerVisible)",chrome)
  # Both REAL per-pane button dispatches remain present at every empty slot.
  self.assertIn("zoom.hidden=NO",chrome)
  self.assertIn("action:@selector(pillPressed:)",chrome)
  self.assertIn("action:@selector(zoomPressed:)",chrome)
  self.assertIn("zoom-requires-real-app",chrome)
  self.assertIn("[self openAppPickerForSlot:slot];",chrome)
  self.assertIn("case 2:[self openStylePicker];break;",chrome)
  self.assertIn("case 3:[self openRunningAppManager];",chrome)

 def test_style_buttons_follow_original_native12_nine_binary_preview_cases(self):
  chrome=file("DFNative12Chrome.m")
  engine=file("DFLayoutEngine.m")
  phone=file("DFNativeHostRootController.m")
  bridge=file("DFNativeHostAppDelegate.m")
  self.assertIn('NSArray<NSString *> *styleNames=@[@"Một khung",@"Trái / phải",',chrome)
  self.assertIn("for(NSInteger idx=0;idx<9;idx++)",chrome)
  self.assertIn("if(!self.styleVisible || selected<0 || selected>8)return;",chrome)
  self.assertIn("DFComputePresetFramesWithSecondary",chrome)
  self.assertIn("DFSecondaryDividerRect",engine)
  self.assertIn("self.secondaryDividerWindow.hidden=",chrome)
  self.assertIn("secondary-divider-pan-end",chrome)
  self.assertIn("return preset==0?1:(preset==1||preset==2?2:(preset==8?4:3));",engine)
  self.assertIn("case 0:out[0]=b;break;",engine)
  self.assertIn("for(int i=0;i<4;i++)out[i]=CGRectNull;",engine)
  self.assertIn('normalized[@"Version"]=@2',chrome)
  self.assertIn("DFCanonicalPreset",chrome)
  self.assertIn('return self.tabs.selectedSegmentIndex==2?9:',phone)
  self.assertIn("active<1 || active>4",bridge)
  self.assertIn('self.preset=selected;',chrome)
  self.assertIn("self.styleWindow.hidden=(self.startupActive||!self.styleVisible);",chrome)
  self.assertNotIn("hold.minimumPressDuration=3.0;",chrome)
  self.assertIn("CGRectGetMidX(pane[i])-width/2",chrome)
  self.assertNotIn('@"4 cột"',chrome)
  self.assertIn('@"Bốn ô"',chrome)
  self.assertIn("for(NSInteger idx=0;idx<9;idx++)",chrome)
  self.assertIn("case 8:",engine)

 def test_native12_approved_one_row_four_actions_no_mock_zoom(self):
  chrome=file("DFNative12Chrome.m")
  self.assertIn("const CGFloat widths[4]={43,51,47,51};",chrome)
  self.assertIn("CGRectMake(bx,(ph-30)/2,widths[i]*scale,30)",chrome)
  self.assertIn('NSArray *names=@[@"App",@"Zoom",@"Style",@"Close"];',chrome)
  self.assertIn("[self layoutContextMenuForPane:pane[menuSlot]];",chrome)
  self.assertIn("self.pickerWindow.frame=CGRectMake(x,y,width,height);",chrome)
  self.assertIn('case 0:[self openAppPickerForSlot:self.selectedSlot];break;',chrome)
  self.assertIn('case 2:[self openStylePicker];break;',chrome)
  self.assertIn('case 3:[self openRunningAppManager];break;',chrome)
  self.assertIn('[self emit:@"Zoom" ratio:nil]',chrome)
  self.assertNotIn("[self zoomPressed:self.pillZoom[(NSUInteger)self.selectedSlot]];",chrome)
  # Button selection is recorded by the real app-card opener, not the invented popup.
  self.assertIn("self.selectedSlot=slot;",chrome)
  self.assertIn("[self openAppPickerForSlot:sender.tag]",chrome)
  self.assertIn("self.pickerWindow.hidden=(self.startupActive||!self.pickerVisible);",chrome)

 def test_real_device_20261023_no_blank_two_pane_outer_menu_body(self):
  # Two actual CarPlay phone-camera photos of .38 show 446x224 EMPTY gray
  # overlay, built only from a one-row header in DFNative12Chrome.m.
  # The original SHA-verified setupCardContent header is 32pt for H<260
  # (38pt for H>=260): no invented 224pt unused sheet body.
  chrome=file("DFNative12Chrome.m")
  geo=file("DFNative12CardHeaderGeometry.h")
  self.assertIn("const double headerH=compactH?32.0:38.0;",geo)
  self.assertIn("CGFloat ph=(CGFloat)DFOriginalCardHeader(cr.size.width,cr.size.height).headerHeight;",chrome)
  self.assertIn("CGFloat height=(CGFloat)DFOriginalCardHeader(cr.size.width,cr.size.height).headerHeight;",chrome)
  self.assertNotIn("CGFloat ph=MIN(280,MAX(140,cr.size.height-16));",chrome)
  self.assertNotIn("CGFloat height=MIN(280,MAX(140,cr.size.height-16));",chrome)
  self.assertIn("CGRectMake(bx,(ph-30)/2,widths[i]*scale,30)",chrome)
  self.assertIn("CGRectMake(bx,(height-30)/2,widths[i]*scale,30)",chrome)
  self.assertIn("CGRect brandFrame=CGRectMake(8,(height-30)/2,logoW,30);",chrome)
  self.assertIn("CGRectGetMinY(pane)+4",chrome)
  self.assertIn("[self layoutContextMenuForPane:pane[menuSlot]];",chrome)
  self.assertIn("case 0:[self openAppPickerForSlot:self.selectedSlot];break;",chrome)
  self.assertIn("case 2:[self openStylePicker];break;",chrome)
  self.assertIn("case 3:[self openRunningAppManager];break;",chrome)
  self.assertIn("self.pickerWindow.hidden=(self.startupActive||!self.pickerVisible);",chrome)
  # Real panes remain owned by DFSceneHost; no black fake content.
  self.assertIn("BOOL loaded=([self.sceneHandleReady[(NSUInteger)i] boolValue]",chrome)
  self.assertNotIn("CHƯA NỐI SCENE",chrome)

 def test_media_scene_deduplicates_private_resize_in_pending_state(self):
  host=file("DFSceneHost.m")
  self.assertIn("if (CGSizeEqualToSize(size,self.lastApplied)) return;",host)
  self.assertIn("self.lastApplied=CGSizeZero;",host)
  self.assertIn("media-viewport-ui-only",host)
  self.assertIn("media-pane-hit-test-target",host)
  self.assertIn("media-reference-committed-after-stable-viewport",host)
  self.assertIn("if (!self.ready) return;",host)
  self.assertIn("if (timer && self.geometryCommitTimer!=timer) return;",host)
  self.assertIn("[self.geometryCommitTimer invalidate]",host)
  self.assertIn("!self.window || !self.appController",host)
  self.assertNotIn("[self commitSceneGeometry:nil];",host)
  self.assertIn("self.pendingReferenceSize=self.bounds.size;",host)
  self.assertIn('DFHostInt(self.appController, @"setRequestedMode:", 2)',host)
  self.assertIn('DFSceneLog(@"resize"',host)
  self.assertIn('setContentReferenceSize:withInterfaceOrientation:',host)
  self.assertNotIn("scene,update,settings,nil,nil",host)
  # Defensive regression only; not evidence of on-device Safe Mode repair.

 def test_scene_ready_needs_scene_handle_and_live_host_state(self):
  host=file("DFSceneHost.m")
  self.assertIn("DFHostingFlag",host)
  self.assertIn('@"canHostAnApp"',host)
  self.assertIn('@"isHostingAnApp"',host)
  self.assertIn("if(scene && supportsHosting && isHosting && viewAttached)",host)
  self.assertIn('DFHostingFlag(self.appController,@"isHostingAnApp",NO)',host)
  self.assertIn('DFHostingFlag(controller,@"canHostAnApp",NO)',host)
  self.assertNotIn('DFHostingFlag(controller,@"canHostAnApp",YES)',host)
  self.assertIn('NSSelectorFromString(@"canHostAnApp")',host)
  self.assertIn('NSSelectorFromString(@"isHostingAnApp")',host)
  self.assertIn('self.appController.view.window==self.window',host)
  self.assertIn("scene-awaiting-real-host",host)
  self.assertIn("supportsHosting=%d hosting=%d windowAttached=%d",host)
  self.assertNotIn('DFHostingFlag(self.appController,@"isHostingAnApp",YES)',host)
  self.assertIn("scene-host-timeout",host)
  self.assertIn("host-preflight-denied",host)
  self.assertNotIn("if (scene) {",host)
  self.assertIn("scene-handle-observed-render-unverified",host)
 def test_atomic_native12_replace_keeps_live_app_until_scene_ready(self):
  chrome=file("DFNative12Chrome.m")
  host=file("DFSceneHost.m")
  header=file("DFSceneHost.h")
  self.assertIn("bundleIDForHostedView:",header)
  self.assertIn("self.live[surface.bundleID]==surface",host)
  self.assertIn("pendingScenes",chrome)
  self.assertIn("app-replace-pending-existing-retained",chrome)
  self.assertIn("scene-replace-committed-render-unverified",chrome)
  self.assertIn("scene-replace-rolled-back-old-app-retained",chrome)
  self.assertIn("replace-same-app-noop",chrome)
  self.assertIn("self.pendingScenes[(NSUInteger)physicalSlot]=host",chrome)
  self.assertIn("self.sceneHandleReady[(NSUInteger)i]=@YES",chrome)
  self.assertIn("host.userInteractionEnabled=NO",chrome)
  self.assertIn("host.userInteractionEnabled=YES",chrome)
  self.assertIn("self.pendingScenes[(NSUInteger)i]=NSNull.null",chrome)
  self.assertIn("self.pendingScenes removeAllObjects",chrome)
  self.assertNotIn("if(self.hostedScenes[(NSUInteger)physicalSlot]!=NSNull.null)\\n         [self closeHostedSlot:slot]",chrome)
  # A new app must not be reported successfully selected before sceneReady.
  start=chrome.index("- (void)appPicker:(DFAppPickerVC *)picker")
  ready=chrome.index("- (void)sceneReady:",start)
  selection=chrome[start:ready]
  self.assertNotIn('[self emit:@"App"',selection)
  self.assertIn("pendingScenes[(NSUInteger)physicalSlot]=host",selection)
  after=chrome[ready:chrome.index("- (void)sceneFailed:",ready)]
  self.assertLess(after.index("self.hostedScenes[(NSUInteger)i]=host"),
                  after.index("[self emit:@\"App\""))
  self.assertLess(after.index("host.userInteractionEnabled=YES"),
                  after.index("[self emit:@\"App\""))
  self.assertLess(after.index("self.hostedScenes[(NSUInteger)i]=host"),
                  after.index("releaseHostedView:prior"))
  # A pending failure leaves an old app: release only the failed pending host.
  failed=chrome[chrome.index("- (void)sceneFailed:"):chrome.index("- (void)closeHostedSlot:")]
  self.assertIn("self.pendingScenes[(NSUInteger)i]==host",failed)
  self.assertIn("self.pendingScenes[(NSUInteger)i]=NSNull.null",failed)
  self.assertNotIn("releaseHostedView:prior",failed)
 def test_separate_package_and_no_boot_scripts(self):
  c=file("control")
  self.assertIn("Package: com.duoface.carplay.nativescenehost",c)
  self.assertIn("Version: 0.1.92~manualobserver1",c)
  self.assertNotIn("Conflicts:",c)
  self.assertNotIn("Replaces:",c)
  self.assertTrue((R/"postinst").exists())
  self.assertTrue((R/"postrm").exists())
  self.assertFalse((R/"prerm").exists())
  for name in ("postinst","postrm"):
   data=file(name)
   self.assertIn("DuoFaceNativeHost.app",data)
   self.assertIn("uicache",data)
   for forbidden in ("killall","sbreload","ldrestart","launchctl","rm -rf","defaults write",
                     "com.apple.developer.carplay","SpringBoard restart"):
    self.assertNotIn(forbidden,data)
  self.assertIn('case "${1:-}" in configure',file("postinst"))
  self.assertIn('case "${1:-}" in remove',file("postrm"))
 def test_native_content_receiver_stays_in_system_scene_safe_area(self):
  s=file("DFNativeHostSurfaceView.m")
  root=file("DFNativeHostRootController.m")
  build=file("build.sh")
  self.assertIn("MTCPBridgeReadSurface(nil)",s)
  self.assertIn("MTCPBridgeExplicitOptIn()",s)
  self.assertIn("UIWindowSceneSessionRoleCarPlay",s)
  self.assertIn("w.screen==UIScreen.mainScreen",s)
  self.assertIn("[self disconnectSurface]",s)
  self.assertIn("self.userInteractionEnabled=YES",s)
  self.assertIn("self.remote.frame=self.bounds",s)
  self.assertIn("safeAreaLayoutGuide",root)
  self.assertIn("[self.nativeSurface start]",root)
  self.assertIn("[self.nativeSurface stop]",root)
  self.assertIn("DFNativeHostSurfaceView.m",build)
  self.assertIn("MTCPBridgeContract.m",build)
  self.assertIn("MTCPBridgeWriteCommand(self.session",s)
  self.assertIn("notify_post(\"com.duoface.mytweak.cp-command\")",s)
  self.assertIn("MTCPBridgeReadSurface(self.session)",s)
  self.assertIn("pointInside:(CGPoint)point",s)
  self.assertIn("touchesCancelled:",s)
  self.assertIn("touchesEnded:",s)
  self.assertIn("self.activeTouch=nil;",s)
  self.assertIn("DFCPNativeBridgeQA.deliverPacket:",s)
  self.assertNotIn("sendEvent:",s)
  self.assertNotIn("UITouch alloc",s)
  for name in ("UIRootSceneWindow","FBSDisplayConfiguration","SBAppViewController",
               "requestStateChange:","setWindowLevel:", "DBDockWindow", "entitlementValueForKey:"):
   self.assertNotIn(name,s)

 def test_integrated_native12_cards_splash_activity_and_media_scene_safety(self):
  picker=file("DFAppPickerVC.m")
  chrome=file("DFNative12Chrome.m")
  host=file("DFSceneHost.m")
  entry=file("DFNativeHostAppDelegate.m")
  self.assertIn("UICollectionViewDataSource",picker)
  self.assertIn("DFNativeAppCard",picker)
  self.assertNotIn("DFRecentKey",picker)
  self.assertIn("appPickerDidRequestRunningApps:",picker)
  self.assertIn("installedIconForBundle:",picker)
  self.assertIn("DFAppLibrary installedUserApps",picker)
  self.assertNotIn("UITableViewDataSource",picker)
  self.assertIn('DFCArtwork(@"duoface-logo")',chrome)
  self.assertIn("duoface-native-loading-line",chrome)
  self.assertIn("self.startupActive=YES",chrome)
  self.assertIn("self.startupActive=NO",chrome)
  self.assertIn("w.hidden=(!show||self.startupActive)",chrome)
  self.assertIn("self.splashWindow.hidden=NO",chrome)
  self.assertIn("noteUserActivity",chrome)
  self.assertIn("self.borderUntil",chrome)
  self.assertIn("BOOL splitVisible=(!self.startupActive && self.focus<0);",chrome)
  self.assertIn("BOOL empty=(!loaded && !negotiating);",chrome)
  self.assertIn("v.layer.borderWidth=splitVisible?",chrome)
  self.assertIn("227./255",chrome)
  self.assertIn("scene.activationState!=UISceneActivationStateForegroundActive",entry)
  self.assertIn("touchowner-deferred-until-carplay-foreground-active",entry)
  self.assertIn("native-app-geometry-reference-only-no-nil-frontboard-transition",host)
  self.assertNotIn("scene,update,settings,nil,nil",host)
  self.assertIn("setContentReferenceSize:withInterfaceOrientation:",host)
  self.assertIn("host.transform=CGAffineTransformMakeScale",host)
  for preserved in ("self.swapped=!self.swapped","DFDragFinish(&_dividerDrag",
                    "self.focus=(self.focus==slot)?-1:slot",
                    "app-replace-pending-existing-retained"):
   self.assertIn(preserved,chrome)
  self.assertNotIn("CBBridgeManager",host)
  self.assertNotIn("checkAndSyncLicense",host)

 def test_native12_home_teardown_hides_windows_before_scene_invalidate(self):
  chrome=file("DFNative12Chrome.m")
  stop=chrome.split("- (void)stop {")[-1]
  self.assertIn('home-teardown-all-external-windows-hidden-before-scene-invalidate',stop)
  hidden=stop.index("for(UIWindow *w in self.windows)w.hidden=YES;")
  scene=stop.index("[[DFSceneHost sharedHost] stopAllHosts];")
  root=stop.index("for(UIWindow *w in self.windows)w.rootViewController=nil;")
  self.assertLess(hidden,scene,"CarPlay Home must hide windows before media scene teardown")
  self.assertLess(scene,root,"Do not nil live roots before scene host release")
  self.assertIn("self.startupActive=NO",stop)
  self.assertIn("self.callback=nil",stop)

 def test_native12_picker_pages_real_apps_with_recent_and_no_fake_items(self):
  picker=file("DFAppPickerVC.m")
  markers=("UICollectionViewScrollDirectionHorizontal","self.cards.pagingEnabled=YES",
           "UIPageControl","pageControlChanged:","updateCurrentPage",
           "scrollViewDidEndDecelerating:","scrollViewDidEndScrollingAnimation:",
           "visibleApps","DFAppLibrary installedUserApps",
           "didSelectBundleID:app.bundleID displayName:app.displayName")
  for x in markers:self.assertIn(x,picker)
  self.assertIn("return [self pageCount]*MAX(1,self.cardsPerPage);",picker)
  self.assertIn("if((NSUInteger)indexPath.item>=display.count)return;",picker)
  self.assertIn("card.hidden=YES",picker)
  self.assertIn("card.hidden=NO",picker)
  self.assertNotIn("UICollectionViewScrollDirectionVertical",picker)

 def test_native12_only_no_duonavi_comparator(self):
  audit=file("tests/compare_source_debs.py")
  self.assertIn("NATIVE12_ONLY_DEB_COMPARISON_STATIC_PASS",audit)
  self.assertIn("ONLY_NATIVE12_VS_NEW_DUOFACE_NO_DUONAVI",audit)
  self.assertNotIn('ap.add_argument("--duonavi"',audit)
  self.assertNotIn("DUONAVI_SHA=",audit)

 def test_real_owner_command_ack_v2_and_single_splash(self):
  app=file("DFNativeHostAppDelegate.m")
  probe=file("DFTouchOwnerProbe.m")
  chrome=file("DFNative12Chrome.m")
  passive=file("DFNative12BasicController.m")
  self.assertIn('@"State":state',probe)
  self.assertIn('@"Version":@2',probe)
  self.assertIn('notify_register_dispatch(kAckNotify',probe)
  self.assertIn('sLastAckSequence=sequence',probe)
  self.assertIn('stateSnapshot',chrome)
  self.assertIn('@"Owner":@"SpringBoard"',chrome)
  self.assertIn('@"RunningScenes":@(running)',chrome)
  self.assertIn('@"SlotCount":@(self.hostedScenes.count)',chrome)
  self.assertIn('@"Version":@2',app)
  self.assertIn('notify_post(DFAckNotify)',app)
  self.assertIn('ack writeToFile:DFAckPath atomically:YES',app)
  self.assertIn('touchowner-state-ack',app)
  self.assertNotIn('touchowner-command-applied',app)
  self.assertNotIn('self.basicController setPresetRatio:',app)
  self.assertNotIn('self.basicController performCarPlayControl:',app)
  self.assertNotIn('performCarPlayControl:',passive)
  self.assertNotIn('startupSplash',passive)
  self.assertIn('duoface-native-loading-line',chrome)

 def test_home_revocation_before_stop_and_no_ten_minute_kill(self):
  probe=file("DFTouchOwnerProbe.m")
  car=file("DFNativeHostAppDelegate.m")
  self.assertNotIn("safety-expiry-600s",probe)
  self.assertNotIn("600*NSEC_PER_SEC",probe)
  self.assertIn("DFSessionStillActive",probe)
  self.assertIn("session-revoked-before-window-start",probe)
  self.assertIn("session-revoked-during-window-start",probe)
  self.assertIn("generation!=sGeneration",probe)
  self.assertIn("sGeneration++;",probe)
  self.assertIn("sActivated=NO;",probe)
  stop=car[car.index("- (void)stopTouchOwnerWithReason:(NSString *)reason {"):
           car.index("- (void)renewTouchOwnerHeartbeat:",car.index("- (void)stopTouchOwnerWithReason:(NSString *)reason {"))]
  self.assertIn('@"Active":@NO',stop)
  self.assertLess(stop.index("[inactive writeToFile:path atomically:YES]"),
                  stop.index('notify_post("com.duoface.nativehost.touchowner.stop.v1")'))
  disconnect=car[car.index("- (void)templateApplicationScene:",car.index("@implementation DFNativeHostTemplateSceneDelegate")+1):]
  self.assertLess(disconnect.index('[self stopTouchOwnerWithReason:@"template-disconnected"]'),
                  disconnect.index("window.rootViewController=nil"))

 def test_owner_retries_only_latest_real_state_without_reapplying_ui(self):
  probe=file("DFTouchOwnerProbe.m")
  app=file("DFNativeHostAppDelegate.m")
  self.assertIn('latest-state-ack-retry',probe)
  self.assertIn('sRetryCount<3',probe)
  self.assertIn('now-sRetryAt>=.8',probe)
  self.assertIn('last[@"Sequence"] unsignedIntegerValue]==sSequence',probe)
  self.assertIn('retry[@"Timestamp"]=@(now)',probe)
  self.assertIn('notify_post(kCommandNotify)',probe)
  self.assertIn('DFReceiveAck();',probe)
  self.assertIn('sRetryCount=0;sRetryAt=0;',probe)
  self.assertIn('@"State":state',probe)
  self.assertIn('@"Accepted":@(accepted)',app)
  self.assertNotIn('self.basicController performCarPlayControl:',app)

 def test_native12_original_nine_1_to_4_scene_layout_contract(self):
  chrome=file("DFNative12Chrome.m")
  layout=file("DFLayoutEngine.m")
  app=file("DFNativeHostAppDelegate.m")
  probe=file("DFTouchOwnerProbe.m")
  build=file("build.sh")
  self.assertIn("DFLayoutEngine.m",build)
  self.assertIn("DFComputePresetFramesWithSecondary(cr,self.preset,p,self.secondaryRatio,pane)",chrome)
  self.assertIn("self.preset=selected",chrome)
  self.assertIn('@"Preset":@(self.preset)',chrome)
  self.assertIn('@"ActiveSlots":@(DFSlotCountForPreset(self.preset))',chrome)
  self.assertIn("for(NSInteger slot=0;slot<4;slot++)",chrome)
  self.assertIn("for(NSInteger i=0;i<4;i++)",chrome)
  self.assertIn('self.focus==2?@"FocusSlot2":@"FocusSlot3"',chrome)
  self.assertIn("NSInteger DFSlotCountForPreset",layout)
  for i in range(9):self.assertIn("case %d:"%i,layout)
  self.assertIn("active<1 || active>4",app)
  self.assertIn("count!=4",app)  # four retained backing hosts, max four visible
  self.assertIn('@"FocusSlot2"',probe)
  self.assertIn('@"FocusSlot3"',probe)
  self.assertNotIn("self.verticalDivider=!self.verticalDivider",chrome)

 def test_native12_live_iphone_layout_settings_drive_real_springboard_owner(self):
  phone=file("DFNativeHostRootController.m")
  probe=file("DFTouchOwnerProbe.m")
  chrome=file("DFNative12Chrome.m")
  header=file("DFNative12Chrome.h")
  self.assertIn('@"Trạng thái",@"Ứng dụng",@"Bố cục"',phone)
  self.assertIn('writeNativeLayoutPreset:',phone)
  self.assertIn('com.duoface.nativehost.layout.changed.v1',phone)
  self.assertIn('@"Preset":@(preset)',phone)
  self.assertIn('com.duoface.nativehost.layout.changed.v1',probe)
  self.assertIn('[sChrome applyLayoutSettingsFromDisk]',probe)
  self.assertIn('- (BOOL)applyLayoutSettingsFromDisk;',header)
  self.assertIn('DFComputePresetFramesWithSecondary(cr,self.preset,p,self.secondaryRatio,pane)',chrome)
  self.assertIn('live-preset-updated',chrome)
  self.assertIn('self.appPickerWindow.hidden=YES;',chrome)
  self.assertIn('DFSlotCountForPreset(self.preset)',chrome)
  self.assertNotIn('UIRootSceneWindow',phone)

 def test_original_native12_split_ratio_numeric_constants_are_exact(self):
  """Compare actual ARM64 __const double values, not a guessed threshold."""
  source=R.parents[1]/"sideplay/audit/native12-layout-forensic-20261021/constants/DIVIDER_CONSTANTS.json"
  result=json.loads(source.read_text())
  self.assertEqual(result["macho_sha256"],
                   "9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea")
  constants={k:v["double"] for k,v in result["constants"].items()}
  self.assertTrue(math.isclose(constants["drag_min"],1.0/3.0,abs_tol=1e-12))
  self.assertTrue(math.isclose(constants["drag_max"],2.0/3.0,abs_tol=1e-12))
  self.assertEqual(constants["snap_threshold"],.04)
  self.assertTrue(math.isclose(constants["snap_offset_a"],-1.0/3.0,abs_tol=1e-12))
  self.assertTrue(math.isclose(constants["snap_offset_b"],-2.0/3.0,abs_tol=1e-12))
  chrome=file("DFNative12Chrome.m")
  self.assertIn("MAX(1.0/3.0,MIN(2.0/3.0,x))",chrome)
  self.assertIn("if(fabs(x-stop.doubleValue)<.04)",chrome)
  self.assertIn('for(NSNumber *stop in @[@(1.0/3.0),@.5,@(2.0/3.0)])',chrome)

 def test_original_preset_dual_write_from_imp_is_live_and_ack_checked(self):
  """presetSelected @0xaa4f0 uses both splitMode and splitPreset, same UIButton.tag."""
  original=(R.parents[1]/"sideplay/audit/native12-layout-forensic-20261021/evidence/REPORT.md").read_text()
  section=original.split("## CBMultitaskingOverlayView.presetSelected: @ 0xaa4f0",1)[1].split("\\n## ",1)[0]
  self.assertIn('splitPreset',section)
  self.assertIn('splitMode',section)
  chrome=file("DFNative12Chrome.m")
  phone=file("DFNativeHostRootController.m")
  receiver=file("DFNativeHostAppDelegate.m")
  for name in ("splitPreset","splitMode"):
   self.assertIn('@"'+name+'":@(preset)',chrome)
   self.assertIn('@"'+name+'":@(preset)',phone)
  self.assertIn('@"SplitPreset":@(self.preset)',chrome)
  self.assertIn('@"SplitMode":@(self.preset)',chrome)
  self.assertIn('splitPreset!=preset || splitMode!=preset',receiver)

 def test_native12_secondary_boundary_not_four_strip_demo(self):
  layout=file("DFLayoutEngine.m")
  header=file("DFLayoutEngine.h")
  chrome=file("DFNative12Chrome.m")
  self.assertIn("CGFloat DFPrimaryDividerCoordinate(",layout)
  self.assertIn("DFSecondaryDividerRect",header)
  self.assertIn("DFSecondaryDividerRect(cr,self.preset,p,self.secondaryRatio)",chrome)
  self.assertIn("self.secondaryDividerWindow.hidden=",chrome)
  self.assertIn("secondary-divider-pan-end",chrome)
  self.assertIn("CGFloat proposed=self.dragStartSecondary+delta/extent;",chrome)
  self.assertNotIn("four independent live quadrants",layout)
  self.assertNotIn("four strips",layout)
  self.assertIn("case 3:",layout)
  self.assertIn("case 7:",layout)
  self.assertIn("case 8:",layout)
  for fraction in (1/3,.5,2/3):
   self.assertGreater(fraction,0)
   self.assertLess(fraction,1)

 def test_springboard_safe_mode_has_manual_iphone_crash_report_export(self):
  phone=file("DFNativeHostRootController.m")
  collector=file("DFNativeDiagnostics.m")
  header=file("DFNativeDiagnostics.h")
  build=file("build.sh")
  self.assertIn("DFNativeDiagnostics.m",build)
  self.assertIn("#import \"DFNativeDiagnostics.h\"",phone)
  self.assertIn("shareCarPlayDiagnostics:",phone)
  self.assertIn("Xuất log / lỗi CarPlay",phone)
  self.assertIn("UIAlertController",phone)
  self.assertIn("UIActivityViewController",phone)
  self.assertIn("prepareShareFiles",header)
  self.assertIn("prepareShareFiles",collector)
  self.assertIn("DuoFaceSceneHost.log",collector)
  self.assertIn("DuoFaceTouchOwner.log",collector)
  self.assertIn("DuoFaceNativeSceneJoin.log",collector)
  self.assertIn("springboard",collector)
  self.assertIn("carplay",collector)
  self.assertIn("MIN((NSUInteger)3,found.count)",collector)
  self.assertIn("8*1024*1024",collector)
  self.assertIn("30*24*3600",collector)
  self.assertNotIn("URLSession",collector)
  self.assertNotIn("dataTaskWithRequest",collector)
  self.assertNotIn("http://",collector)
  self.assertNotIn("https://",collector)

 def test_native12_original_zoom_in_out_arrows_visible_and_connected(self):
  """Prevent a visible text-only Zoom no-op across both host states."""
  chrome=file("DFNative12Chrome.m")
  header=file("DFNative12MenuHeader.h")
  probe=file("DFTouchOwnerProbe.m")
  dock=file("DFDockZoomCoordinator.m")
  historical=(R.parents[1]/"runtime/fullscreen/DFPickerZoomMenu.xm").read_text()
  # The original v12 fullscreen UI uses two SF arrow directions.
  self.assertIn('expanded?@"arrow.down.right.and.arrow.up.left":',historical)
  self.assertIn('@"arrow.up.left.and.arrow.down.right"',historical)
  self.assertIn('DFNative12ZoomArrowSymbol(BOOL expanded)',header)
  self.assertIn('@"arrow.down.right.and.arrow.up.left"',header)
  self.assertIn('@"arrow.up.left.and.arrow.down.right"',header)
  self.assertIn('DFNative12DecorateZoomButton(buttons[1],expanded)',header)
  self.assertIn('expanded?@"Zoom Out":@"Zoom In" forState:UIControlStateNormal',header)
  self.assertIn('i==1?(expanded?@"Zoom Out":@"Zoom In"):names[i]',header)
  self.assertIn('UIControlEventPrimaryActionTriggered',chrome)
  self.assertIn('native12-zoom-button-touchdown',chrome)
  self.assertIn('native12-menu-action-invoked',chrome)
  self.assertIn('[zoomAction addTarget:self action:@selector(menuAction:)',chrome)
  self.assertIn('DFNative12DecorateZoomButton(self.menuActions[1],self.hostFullscreen)',chrome)
  self.assertIn('arrow.frame=CGRectMake((width-16.0)/2.0,1.0,16.0,16.0);',header)
  self.assertIn('button.accessibilityLabel=expanded?@"Zoom Out":@"Zoom In"',header)
  self.assertIn('DFNative12ZoomArrowSymbol(focused)',chrome)
  self.assertIn('@"native12-zoom-in-arrow-pressed-ack-pending"',chrome)
  self.assertIn('@"native12-zoom-out-arrow-pressed-ack-pending"',chrome)
  # Never forge Dock success at a button tap: same real Dock-owner toggle.
  self.assertIn('[self emit:@"Zoom" ratio:nil]',chrome)
  self.assertIn('DFDockZoomToggle(sChrome,sSession',probe)
  self.assertIn('[chrome applyHostFullscreenToScreenBoundsAfterDockAck:bounds]',dock)
  self.assertIn('[chrome restoreHostFullscreenGeometry]',dock)
  self.assertIn('@"real-dock-ack-timeout"',dock)

 def test_zoom_owner_real_native_layout_and_ack_reliability_20261023(self):
  """Prevent three hard source-side Zoom blockers from the last .50 build."""
  chrome=file("DFNative12Chrome.m")
  receiver=file("DFCarPlayDockOwner.m")
  coordinator=file("DFDockZoomCoordinator.m")
  start=chrome.index("- (void)menuAction:(UIButton *)sender {")
  end=chrome.index("- (void)appPickerDidRequestLayout:",start)
  menu=chrome[start:end]
  # The old Style-menu Zoom reintroduced the modal, causing the geometry
  # owner to reject every button press. Close it before the real host request.
  self.assertNotIn("self.styleVisible=keepStyle;",menu)
  self.assertNotIn("native12-global-zoom-modals-cleared",menu)
  self.assertIn('if(sender.tag==1)',menu)
  self.assertLess(menu.index('[self emit:@"Zoom" ratio:nil]'),menu.index("[self closeMenu:nil]"))
  self.assertIn("self.startupActive || !self.windows.count",chrome)
  # A measured native Dock may live under a visible foreground-inactive
  # CarPlay scene; background scenes remain forbidden.
  self.assertIn("UISceneActivationStateForegroundInactive",receiver)
  self.assertIn("UISceneActivationStateForegroundActive",receiver)
  self.assertIn("dock-scene-inventory active=",receiver)
  self.assertIn("else continue;",receiver)
  self.assertIn("if(matches!=1)",receiver)
  self.assertIn("DFZVisibleDockGeometry",receiver)
  # Repeat READ-ONLY ACK lookup when Darwin notify is coalesced.
  self.assertIn("static void DFZPollMatchingAck(NSUInteger generation)",coordinator)
  self.assertIn("DFZPollMatchingAck(generation);",coordinator)
  self.assertIn("DFZConsumeAck();",coordinator)
  self.assertIn("generation!=sGeneration || !sPendingRequest",coordinator)
  self.assertIn('@"real-dock-ack-timeout"',coordinator)
  self.assertIn("DFZEmergencyRestore(sPendingSession)",coordinator)
  self.assertIn('[ack[@"RequestID"] isEqualToString:sPendingRequest]',coordinator)
  self.assertIn('[ack[@"Session"] isEqualToString:sPendingSession]',coordinator)
  self.assertIn('ack[@"DockOwnerVerified"]',coordinator)
  self.assertIn('[chrome applyHostFullscreenToScreenBoundsAfterDockAck:bounds]',coordinator)
  self.assertNotIn('DFHostSetExpanded(',coordinator)

 def test_native12_ellipsis_restores_full_app_card_not_invented_empty_toolbar(self):
  """2026-10-23 head-unit photo: reject .53 thin-only toolbar regression."""
  chrome=file("DFNative12Chrome.m")
  picker=file("DFAppPickerVC.m")
  start=chrome.index("- (void)pillPressed:(UIButton *)sender {")
  end=chrome.index("- (void)closeMenu:(id)sender {",start)
  method=chrome[start:end]
  # The existing first-party card includes real installed apps and pages.
  self.assertIn("[self openAppPickerForSlot:sender.tag]",method)
  self.assertIn("native12-ellipsis-opened-real-app-card",method)
  self.assertNotIn("self.pickerVisible=!sameMenu;",method)
  self.assertNotIn("native12-action-row-%@",method)
  self.assertIn('self.appPickerVisible=YES;',chrome)
  self.assertIn('[self.appPickerController presentInstalledApps];',chrome)
  self.assertIn('[self.appPickerController refreshInstalledApps];',chrome)
  self.assertIn('self.appPickerWindow.hidden=NO;',chrome)
  self.assertIn('self.cards=[[UICollectionView alloc]',picker)
  self.assertIn('[self refreshInstalledApps];',picker)
  self.assertIn('[self.zoomButton addTarget:self action:@selector(zoomTapped)',picker)
  self.assertIn('- (void)zoomTapped {[self.delegate appPickerDidRequestZoom:self];}',picker)
  # The card's Zoom must issue the *whole-host* Dock command with the
  # card dismissed ONLY AFTER ACK, NOT resize one FocusLeft/FocusRight app slot.
  a=chrome.index("- (void)appPickerDidRequestZoom:")
  b=chrome.index("- (void)completeWholeHostZoomRequest:",a)
  zoom=chrome[a:b]
  self.assertNotIn("self.appPickerVisible=NO;",zoom)
  self.assertNotIn("self.appPickerWindow.hidden=YES;",zoom)
  self.assertIn('[self emit:@"Zoom" ratio:nil];',zoom)
  self.assertIn("native12-card-zoom-in-request-real-dock",zoom)
  self.assertNotIn("[self zoomPressed:",zoom)
  self.assertNotIn("FocusLeft",zoom)
  self.assertNotIn("FocusRight",zoom)
  completion=chrome[chrome.index("- (void)completeWholeHostZoomRequest:"):chrome.index("- (void)appPickerDidRequestRunningApps:")]
  self.assertIn("self.appPickerVisible=NO;",completion)
  self.assertIn("self.appPickerWindow.hidden=YES;",completion)
  self.assertIn("self.appPickerWindow.hidden=NO;",completion)
  self.assertIn("native12-card-zoom-rejected-ui-retained",completion)
  self.assertIn("[sChrome completeWholeHostZoomRequest:applied];",file("DFTouchOwnerProbe.m"))
  # Do not make a separate 30pt sheet the entry point.
  self.assertIn("self.pickerWindow.hidden=(self.startupActive||!self.pickerVisible);",chrome)
  old=(R.parents[1]/"runtime/fullscreen/DFPickerZoomMenu.xm").read_text()
  self.assertIn('action:@selector(pressed:) forControlEvents:UIControlEventTouchUpInside',old)

 def test_zoom_real_dock_owner_and_host_geometry_ack_no_older_false_success(self):
  """CarPlay process Dock owner must precede SpringBoard geometry.
  Static contract only; device proof is a separate gate.
  """
  chrome=file("DFNative12Chrome.m")
  app=file("DFNativeHostAppDelegate.m")
  probe=file("DFTouchOwnerProbe.m")
  coordinator=file("DFDockZoomCoordinator.m")
  receiver=file("DFCarPlayDockOwner.m")
  plist=file("DFCarPlayDockOwner.plist")
  build=file("build.sh")
  self.assertIn('[self emit:@"Zoom" ratio:nil]',chrome)
  self.assertIn('DFDockZoomToggle(sChrome,sSession',probe)
  self.assertIn('DFDockZoomDetach(sChrome,sSession)',probe)
  self.assertIn('DFZSend(session,sDesired,sPendingRequest,sPendingSequence)',coordinator)
  self.assertIn('DFZConsumeAck',coordinator)
  self.assertIn('[chrome applyHostFullscreenToScreenBoundsAfterDockAck:bounds]',coordinator)
  self.assertLess(coordinator.index('BOOL owner=[ack[@"Applied"]'),
                  coordinator.index('[chrome applyHostFullscreenToScreenBoundsAfterDockAck:bounds]'))
  self.assertIn('@"DockOwnerVerified":@(applied)',receiver)
  self.assertIn('no-verified-live-native-appdock',receiver)
  self.assertIn('DFZFreshSession(session)',receiver)
  self.assertIn('DFZRestore();',receiver)
  self.assertIn('DFZWatch(++DFZGeneration)',receiver)
  self.assertIn('DFZHistoricalChromeWindow(window)',receiver)
  self.assertNotIn('NSClassFromString(@"CBDashboardShared")',receiver)
  self.assertNotIn('objc_getClass("CBDashboardShared")',receiver)
  self.assertIn('BOOL accepted=!isWholeHostZoom || verified;',app)
  self.assertIn('matchingSession && owner && dock && geometry && request',app)
  self.assertIn('if(![ack[@"Accepted"] boolValue])',probe)
  self.assertIn('DFCarPlayDockOwner.dylib',build)
  self.assertIn('DFDockZoomCoordinator.m',build)
  self.assertIn('<string>CarPlayApp</string>',plist)
  self.assertNotIn('<string>SpringBoard</string>',plist)
  self.assertNotIn('DFHostSetExpanded(',app)
  self.assertNotIn('DFDashboardSetChromeHidden(',app)
  self.assertNotIn('DFRequestHostFullscreen(',app)

 def test_zoom_historic_dashboard_owner_and_ack_budget_reused_safely(self):
  # 2026-10-14 device-observed fullscreen ENTER used the old v12 adapter.
  # The independent host must not silently drop its Dashboard receiver path
  # or halve its already-documented three-second cross-process ACK allowance.
  historical=R.parents[1]/"runtime/fullscreen"
  entry=(historical/"DFRuntimeEntry.mm").read_text()
  transport=(historical/"DFFullscreenTransport.mm").read_text()
  self.assertIn('@"com.apple.dashboard"',entry)
  self.assertIn("3*NSEC_PER_SEC",transport)
  current=file("DFDockZoomCoordinator.m")
  owner=file("DFCarPlayDockOwner.m")
  filt=plistlib.loads((R/"DFCarPlayDockOwner.plist").read_bytes())["Filter"]
  self.assertIn("com.apple.dashboard",filt["Bundles"])
  self.assertIn("dashboard",filt["Executables"])
  self.assertIn("CarPlay",filt["Executables"])
  self.assertIn("CarPlayApp",filt["Executables"])
  self.assertNotIn("SpringBoard",filt["Executables"])
  self.assertIn('[bundle isEqualToString:@"com.apple.dashboard"]',owner)
  self.assertIn('[name.lowercaseString isEqualToString:@"dashboard"]',owner)
  self.assertIn("if(matches!=1)",owner)
  self.assertIn('@"DockOwnerVerified":@(applied)',owner)
  self.assertIn("if(!isfinite(age) || age<0 || age>3.0)return;",owner)
  self.assertIn("if(!isfinite(age) || age<0 || age>3.0)return;",current)
  self.assertIn("(3.0*NSEC_PER_SEC)",current)
  self.assertIn("DFZEmergencyRestore(sPendingSession)",current)
  self.assertIn("DFZHistoricalChromeWindow(window)",owner)
  self.assertIn("DFZCarPlayProcess",owner)

 def test_original_native12_dismiss_child_view_teardown_order(self):
  """Actual SHA-locked Native12 dismiss orders remove(view) before willMove(nil).
  Do not mistake wrapperView.removeFromSuperview for a second invalidate.
  Static parity does not establish an iPhone ExitSafeMode fix.
  """
  orig=R.parents[1]/"sideplay/audit/native12-continuation-4888299/gallery-media-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json"
  d=json.loads(orig.read_text())
  self.assertEqual(d["dashboard_macho_sha256"],
                   "9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea")
  m=next(x for x in d["methods"] if x["class"]=="CBBridgedUIAppView" and x["selector"]=="dismiss")
  self.assertEqual(m["imp"],"0xaf01c")
  pc={line.split(":",1)[0]:line for line in m["instructions"]}
  self.assertIn("ldr",pc["af0f8"]) # original shared removeFromSuperview selref
  self.assertIn("bl",pc["af0fc"])
  self.assertIn("bl",pc["af130"])
  self.assertIn("bl",pc["af158"])
  self.assertIn("bl",pc["af180"])
  owned=file("DFSceneHost.m").split("- (void)stop {",1)[1].split("\n@end",1)[0]
  self.assertLess(owned.index("[self.appController.view removeFromSuperview]"),
                  owned.index("[self.appController willMoveToParentViewController:nil]"))
  self.assertLess(owned.index("[self.appController willMoveToParentViewController:nil]"),
                  owned.index("[self.appController removeFromParentViewController]"))
  self.assertLess(owned.index("[self.appController removeFromParentViewController]"),
                  owned.index('SEL invalidate=NSSelectorFromString(@"invalidate")'))
  self.assertNotIn('DFHostBool(self.appController,@"setInvalidated:"',owned)
  self.assertNotIn('DFHostBool(self.appController,@"setHosting:"',owned)

 def test_native12_fullscreen_geometry_is_real_reversible_but_gated_by_dock_owner(self):
  """Original @0xb0ef4/@0xb1aac screen/usable invariants; no invented Dock ack."""
  chrome=file("DFNative12Chrome.m")
  header=file("DFNative12Chrome.h")
  owner=file("DFTouchOwnerProbe.m")
  app=file("DFNativeHostAppDelegate.m")
  assert 'applyHostFullscreenToScreenBoundsAfterDockAck:' in header
  assert 'restoreHostFullscreenGeometry' in header
  method=chrome[chrome.index('- (BOOL)applyHostFullscreenToScreenBoundsAfterDockAck:'):
                chrome.index('- (void)restoreHostFullscreenGeometry {')]
  assert 'anchor.screen.bounds' in method
  assert 'anchor.screen==UIScreen.mainScreen' in method
  assert 'CGRectContainsRect(actual,saved)' in method
  assert 'self.normalContentRect=saved' in method
  assert 'self.contentRect=actual' in method
  assert 'DFComputePresetFramesWithSecondary(self.contentRect,self.preset' in method
  assert '[self layoutControls]' in method
  assert 'self.appSceneWindows[(NSUInteger)i]' in method
  assert 'CGRect observed=appWindow.frame;' in method
  assert 'BOOL innerMatched=' in method
  assert 'self.preset=' not in method
  assert 'self.ratio=' not in method
  assert 'self.focus=' not in method
  restore=chrome[chrome.index('- (void)restoreHostFullscreenGeometry {'):
                 chrome.index('- (void)stop {')]
  assert 'self.contentRect=previous' in restore
  assert 'self.hostFullscreen=NO' in restore
  assert 'self.preset=' not in restore
  assert 'self.ratio=' not in restore
  assert 'self.focus=' not in restore
  assert 'if(self.hostFullscreen)[self restoreHostFullscreenGeometry];' in chrome
  assert '@"HostFullscreenGeometry":@(self.hostFullscreen)' in chrome
  # The new independent native Dock receiver is in CarPlay, never
  # fabricating a Dock inside this SpringBoard host or template app.
  assert '[self applyHostFullscreenToScreenBoundsAfterDockAck:' not in chrome
  assert 'applyHostFullscreenToScreenBoundsAfterDockAck:' not in owner
  assert 'applyHostFullscreenToScreenBoundsAfterDockAck:' not in app
  assert 'BOOL accepted=!isWholeHostZoom || verified;' in app
  assert 'DBDockWindow' not in chrome
  assert 'DFDockZoomToggle(sChrome,sSession' in owner


 def test_native12_user_device_ui_and_media_regression_gates(self):
  """Protect original artwork+scene callback source path, not hardware parity."""
  chrome=file("DFNative12Chrome.m")
  host=file("DFSceneHost.m")
  header=file("DFSceneHost.h")
  self.assertIn('DFCArtwork(@"duoface-fullscreen")',chrome)
  self.assertIn('DFCArtwork(@"duoface-swap")',chrome)
  self.assertNotIn('DFCArtwork(@"duoface-picker")',chrome)
  self.assertNotIn('UIButtonConfiguration *conf=',chrome)
  self.assertNotIn('UIButtonConfiguration *config=',chrome)
  self.assertIn('b.titleLabel.adjustsFontSizeToFitWidth=YES',chrome)
  self.assertIn('action.titleLabel.adjustsFontSizeToFitWidth=YES',chrome)
  self.assertIn('menuAction:',chrome)
  self.assertIn('case 3:[self openRunningAppManager]',chrome)
  self.assertIn('action:@selector(closeMenu:)',chrome)
  self.assertNotIn('hold.minimumPressDuration=3.0;',chrome)
  self.assertIn('self.controlsUntil=NSDate.date.timeIntervalSince1970+4.0',chrome)
  self.assertIn('BOOL allReady=YES',chrome)
  self.assertIn('show=show && (!allReady',chrome)
  self.assertIn('self.dividerLogo.hidden=',chrome)
  self.assertIn('DFSceneHostDidObserveTouchNotification',chrome)
  self.assertIn('DFSceneHostDidObserveTouchNotification',host)
  self.assertIn('DFSceneHostDidObserveTouchNotification',header)
  self.assertIn('CGSize logical=CGSizeMake(round(size.width*2),round(size.height*2));',host)
  self.assertNotIn('native12-layout-invalidated-deferred-no-sync-flush',host)
  self.assertNotIn('[self.appController.view layoutIfNeeded]',host)
  self.assertIn('logical,UIInterfaceOrientationPortrait,UIInterfaceOrientationPortrait);',host)
  self.assertIn('DFComputePresetFramesWithSecondary',chrome)
  self.assertIn('for(NSInteger idx=0;idx<9;idx++)',chrome)
  self.assertIn('self.ratio=DFNative12DefaultPrimaryRatio(selected)',chrome)

 def test_039_regression_original_button_and_dock_selector(self):
  chrome=file("DFNative12Chrome.m")
  dock=file("DFCarPlayDockOwner.m")
  self.assertNotIn("buttonWithType:UIButtonTypeSystem",chrome)
  self.assertIn("buttonWithType:UIButtonTypeCustom",chrome)
  self.assertIn('@"appDockViewController"',dock)
  self.assertIn("toCoordinateSpace:window.screen.coordinateSpace",dock)
  self.assertIn("NSMutableOrderedSet<UIWindow *>",dock)
  self.assertIn("UIApplication.sharedApplication.windows",dock)
  self.assertIn("if(matches!=1)",dock)
 def test_zoom_native_dock_discovery_diagnostics_do_not_fake_ack(self):
  # This logs actual CarPlay runtime ownership evidence for a failed Zoom.
  # A source test cannot prove the Dock was hidden on the physical display.
  source=file("DFCarPlayDockOwner.m")
  coordinator=file("DFDockZoomCoordinator.m")
  self.assertIn("DuoFaceDockOwner.log",source)
  self.assertIn("native-dock-discovery-rejected matches=%lu windows=%lu",source)
  self.assertIn("dock-candidate view=%@ window=%@ frame=%@ screen=%@",source)
  self.assertIn("dock-reply applied=%d expanded=%d owner=%@ reason=%@",source)
  self.assertIn("listener-ready process=%@",source)
  self.assertIn('@"DockOwnerVerified":@(applied)',source)
  self.assertIn("if(matches!=1)",source)
  self.assertIn("no-verified-live-native-appdock",source)
  self.assertIn("DFZConsumeAck",coordinator)
  self.assertIn("DFZEmergencyRestore",coordinator)
  self.assertNotIn("DockOwnerVerified\":@YES",source)
 def test_039_hidden_divider_does_not_intercept_app_touches(self):
  chrome=file("DFNative12Chrome.m")
  self.assertNotIn("line.tag=718;",chrome)
  self.assertNotIn("viewWithTag:718",chrome)
  self.assertIn("stroke.hidden=!controlsVisible",chrome)
  self.assertIn("self.dividerWindow.userInteractionEnabled=YES",chrome)
  self.assertIn("self.secondaryDividerWindow.userInteractionEnabled=YES",chrome)
  self.assertIn("[owner noteUserActivity]",chrome)
  self.assertIn("self.panActive ||",chrome)
 def test_native12_grip_pulses_only_on_existing_activity_session(self):
  chrome=file("DFNative12Chrome.m")
  self.assertIn('- (void)updateGripBlinkForVisibleSession:(BOOL)visible',chrome)
  self.assertIn('@"dfNative12GripPulse"',chrome)
  self.assertIn('blink.toValue=@1.18;',chrome)
  self.assertIn('blink.autoreverses=YES;',chrome)
  self.assertIn('[self updateGripBlinkForVisibleSession:controlsVisible];',chrome)
  self.assertIn('[self.dividerLogo.layer removeAnimationForKey:@"dfNative12GripPulse"]',chrome)
  self.assertIn('if(existing)return;',chrome)
  self.assertIn('logo.touchBegan=^(UIButton *sender)',chrome)
  self.assertIn('initWithTarget:self action:@selector(dividerPan:)',chrome)
  self.assertNotIn('self.dividerLogo.transform=',chrome)
 def test_media_scene_037_reference_no_extra_layout_reentry(self):
  """Keep the user's prior playable v0.0.37 scene sizing path."""
  host=file("DFSceneHost.m")
  block=host.split("- (void)commitSceneGeometry:(NSTimer *)timer {",1)[1].split("- (UIView *)hitTest:",1)[0]
  layout=host.split("- (void)layoutScene {",1)[1].split("- (void)commitSceneGeometry:(NSTimer *)timer {",1)[0]
  self.assertIn('CGSize logical=CGSizeMake(round(size.width*2),round(size.height*2));',layout)
  self.assertIn('CGSize logical=CGSizeMake(round(size.width*2),round(size.height*2));',block)
  self.assertIn('CGAffineTransformMakeScale(size.width/logical.width,size.height/logical.height)',layout)
  self.assertNotIn('host.layer.cornerRadius=native.cornerRadius',layout)
  self.assertIn('NSSelectorFromString(@"updateSettingsWithBlock:")',block)
  self.assertIn('NSSelectorFromString(@"setFrame:")',block)
  self.assertIn('UIInterfaceOrientationPortrait',block)
  self.assertNotIn('[self.appController.view setNeedsLayout]',block)
  self.assertNotIn('[self.appController.view layoutIfNeeded]',block)
  self.assertNotIn('[inner layoutIfNeeded]',block)



 def test_039_layout_reentry_and_real_touch_phase(self):
  host=file("DFSceneHost.m")
  self.assertIn("self.layingOutScene || self.committingSceneGeometry",host)
  self.assertLess(host.index("self.layingOutScene=YES"),host.index("host.transform="))
  self.assertIn("@finally { self.layingOutScene=NO; }",host)
  self.assertIn("@finally { self.committingSceneGeometry=NO; }",host)
  self.assertIn("touch.phase==UITouchPhaseBegan",host)
  self.assertIn('DFSceneLog(@"geometry-before-reference-setters"',host)

 def test_original_native12_app_card_pagination_four_by_two(self):
  """Original immutable Native12 card grid uses at most four columns,
  and a two-row default from real 0xa3e5c selector path.
  """
  picker=file("DFAppPickerVC.m")
  self.assertIn("self.cardsPerPage=8;",picker)
  self.assertIn("NSInteger capacity=self.runningMode?4:8;",picker)
  self.assertIn("CGFloat w=width/4.0;",picker)
  self.assertIn("CGFloat h=collectionView.bounds.size.height/(self.runningMode?1.0:2.0);",picker)

 def test_original_raster_preview_and_running_close_real_owners(self):
  """Source/ABI checks only; does not assert hardware visual parity."""
  chrome=file("DFNative12Chrome.m")
  preview=file("DFNative12PresetPreview.m")
  header=file("DFNative12PresetPreview.h")
  picker=file("DFAppPickerVC.m")
  pheader=file("DFAppPickerVC.h")
  build=file("build.sh")
  self.assertIn('#import "DFNative12PresetPreview.h"',chrome)
  self.assertIn('DFNative12PresetPreview(idx,idx==self.preset,CGSizeMake(thumbW,thumbH))',chrome)
  self.assertNotIn('segment.backgroundColor=[UIColor colorWithWhite:1 alpha:.43]',chrome)
  self.assertIn('UIGraphicsBeginImageContextWithOptions',preview)
  self.assertIn('UIGraphicsGetImageFromCurrentImageContext',preview)
  self.assertIn('bezierPathWithRoundedRect:CGRectInset(canvas,2,2)',preview)
  self.assertIn('cornerRadius:6.5',preview)
  self.assertIn('colorWithRed:.04 green:.04 blue:.06 alpha:1',preview)
  self.assertIn('DFNative12PreviewRects',preview)
  self.assertIn('DFNative12PresetPreview',header)
  self.assertIn('DFNative12PresetPreview.m',build)
  self.assertIn('case 3:[self openRunningAppManager];break;',chrome)
  self.assertIn('presentRunningApps:[self ownedRunningBundleIDs]',chrome)
  self.assertIn('bundleIDForHostedView:surface',chrome)
  self.assertIn('appPicker:(DFAppPickerVC *)picker closeRunningBundleID:',chrome)
  self.assertIn('appPicker:(DFAppPickerVC *)picker restartRunningBundleID:',chrome)
  self.assertIn('appPickerCloseAllRunning:(DFAppPickerVC *)picker',chrome)
  self.assertIn('self.runningMode?4:8',picker)
  self.assertIn('verifiedRunningIDForIndex:',picker)
  self.assertIn('if(self.runningMode)return;',picker)
  self.assertIn('OVERLAY_RESTART_SINGLE',picker)
  self.assertIn('OVERLAY_CLOSE_SINGLE',picker)
  self.assertIn('closeRunningBundleID',pheader)
  self.assertIn('restartRunningBundleID',pheader)
  self.assertIn('appPickerCloseAllRunning',pheader)
  self.assertNotIn('self.runningBundleIDs=[self recentApps]',picker)


 def test_SHA_original_inner_modal_three_modes_vs_outer_four_actions(self):
  src=file("DFNative12Chrome.m")
  geo=file("DFNative12CardHeaderGeometry.h")
  lit=json.loads((R.parent/"audit/native12-continuation-96fa4ec/CARD_HEADER_LITERALS.json").read_text())
  self.assertEqual(lit["macho_sha256"],
                   "9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea")
  nums=lit["constants"]
  for key,value in [("header_311768",260),("header_311770",440),
                    ("header_311830",210),("header_311838",190)]:
   self.assertEqual(nums[key]["double"],value)
  self.assertIn("const double headerH=compactH?32.0:38.0;",geo)
  self.assertIn("const double zone=(w<440.0)?190.0:210.0;",geo)
  self.assertIn("m.contentY=headerH+0.5;",geo)
  self.assertIn("m.tabButtons[2]",geo)
  self.assertIn('const NSInteger innerModeTags[3]={0,2,3}',src)
  self.assertIn('NSArray *innerModeNames=@[@"Apps",@"Layout",@"Recent"]',src)
  self.assertIn('UIImage systemImageNamed:@"rectangle.split.2x1.fill"',src)
  self.assertIn('UIImage systemImageNamed:@"xmark"',src)
  self.assertIn('DFNative12CardHeader originalMenu=DFOriginalCardHeader(width,height);',src)
  self.assertIn('self.menuDismiss.layer.cornerRadius=originalMenu.dismiss.width/2;',src)
  self.assertNotIn('self.menuDismiss.frame=CGRectMake(width-42,9,32,26);',src)
  self.assertIn("CGRectMake(0,native.contentY,styleW",src)
  self.assertNotIn("const CGFloat styleTabWidths[4]",src)
  # Preserve user-facing outer four actions, real Close and Zoom callback.
  self.assertIn('NSArray *names=@[@"App",@"Zoom",@"Style",@"Close"]',src)
  self.assertIn('case 3:[self openRunningAppManager];break;',src)
  self.assertIn('if(sender.tag==1){',src)
  self.assertIn('[self emit:@"Zoom" ratio:nil]',src)


 def test_20261023_actual_grip_owner_and_full_host_ack(self):
  src=file("DFNative12Chrome.m")
  dock=file("DFCarPlayDockOwner.m")
  grip=src[src.index("@interface DFNativeDividerGripButton"):src.index("// Observe activity")]
  logo=src[src.index("- (void)logoTouchChanged:"):src.index("- (void)logoTouchFinished:")]
  menu=src[src.index("- (void)menuAction:"):src.index("- (void)appPickerDidRequestLayout:")]
  geometry=src[src.index("- (BOOL)applyHostFullscreenToScreenBoundsAfterDockAck:"):src.index("- (void)restoreHostFullscreenGeometry")]
  self.assertIn("DFNativeDividerGripButton *logo=[[DFNativeDividerGripButton alloc]",src)
  self.assertIn("logo.touchBegan=^(UIButton *sender)",src)
  self.assertIn("if(self.touchBegan)self.touchBegan(self);",grip)
  self.assertIn("if(self.touchTracked && self.touchMoved)self.touchMoved(self);",grip)
  self.assertIn("if(self.touchEnded)self.touchEnded(self,inside,NO);",grip)
  self.assertIn("[self updateDividerDragAt:",logo)
  self.assertIn("self.ratio=_dividerDrag.ratio;",src)
  self.assertIn("self.logoFraction=_dividerDrag.logo;",src)
  self.assertLess(menu.index('[self emit:@"Zoom" ratio:nil]'),menu.index("[self closeMenu:nil]"))
  self.assertNotIn("self.pickerVisible || self.styleVisible",geometry)
  self.assertIn("DFZHandledSession",dock)
  self.assertIn("sequence<=DFZHandledSequence",dock)
  self.assertIn("DFZHandleCommand();\n    if(DFZDockView)",dock)

 def test_real_app_close_overlay_separate_visibility_and_lifecycle(self):
  chrome=file("DFNative12Chrome.m")
  self.assertIn("@property(nonatomic,assign) BOOL appPickerVisible;",chrome)
  self.assertIn("self.appPickerWindow.hidden=(self.startupActive||!self.appPickerVisible);",chrome)
  self.assertIn("self.pickerWindow.hidden=(self.startupActive||!self.pickerVisible);",chrome)
  op=chrome[chrome.index("- (void)openAppPickerForSlot:"):chrome.index("- (NSArray<NSString *> *)ownedRunningBundleIDs")]
  self.assertIn("self.appPickerVisible=YES;",op)
  close=chrome[chrome.index("- (void)openRunningAppManager {"):chrome.index("- (void)appPicker:(DFAppPickerVC *)picker closeRunningBundleID:",chrome.index("- (void)openRunningAppManager {"))]
  self.assertIn("self.appPickerVisible=YES;",close)
  done=chrome[chrome.index("- (void)appPickerDidCancel:"):chrome.index("- (void)sceneReady:")]
  self.assertIn("self.appPickerVisible=NO;",done)
  self.assertIn("self.appPickerVisible=YES;",done) # failed host retains genuine App chooser
  self.assertIn("self.pendingScenes[(NSUInteger)physicalSlot]=host;",done)


 def test_original_three_real_mode_picker_owner_and_no_pseudo_recent(self):
  picker=file("DFAppPickerVC.m")
  delegates=file("DFAppPickerVC.h")
  chrome=file("DFNative12Chrome.m")
  self.assertIn('NSArray<NSString *> *names=@[@"Ứng dụng",@"Bố cục",@"Đang mở"]',picker)
  self.assertIn('DFOriginalCardHeader(w,h)',picker)
  self.assertIn('self.currentMode=2;',picker)
  self.assertIn('case 1:[self.delegate appPickerDidRequestLayout:self];break;',picker)
  self.assertIn('case 2:[self.delegate appPickerDidRequestRunningApps:self];break;',picker)
  self.assertIn('appPickerDidRequestRunningApps:',delegates)
  self.assertIn('- (void)appPickerDidRequestRunningApps:(DFAppPickerVC *)picker {',chrome)
  self.assertIn('[self openRunningAppManager];',chrome)
  self.assertNotIn('DFRecentKey',picker)
  self.assertNotIn('UISegmentedControl',picker)
  self.assertIn('self.pageControl.pageIndicatorTintColor=[UIColor colorWithWhite:1 alpha:.25]',picker)
  self.assertIn('self.pageControl.currentPageIndicatorTintColor=UIColor.whiteColor',picker)
  self.assertIn('@"square.stack.3d.up.slash"',picker)
  self.assertIn('@"checkmark.shield.fill"',picker)
  self.assertIn('self.emptyImage.hidden=!empty',picker)
  self.assertIn('self.closeAllRunningButton.frame=CGRectMake(',picker)
  self.assertIn('CGFloat top=header.contentY;',picker)
  self.assertIn('return self.apps;',picker)
  self.assertIn('self.cardsPerPage=capacity;',picker)
  self.assertIn('CGRect chooserRect=styleRect;',chrome)


 def test_carplay_home_stop_reconnect_drops_app_menu_visibility(self):
  chrome=file("DFNative12Chrome.m")
  start=chrome[chrome.index("- (BOOL)start {"):chrome.index("- (void)layoutControls {")]
  self.assertIn("self.appPickerVisible=NO;",start)
  self.assertIn("self.pickerVisible=NO;",start)
  stopped=chrome[chrome.index("- (void)stop {"):]
  self.assertIn("self.appPickerVisible=NO;",stopped)
  self.assertIn("self.pickerVisible=NO;",stopped)
  self.assertIn("for(UIWindow *w in self.windows)w.hidden=YES;",stopped)


 def test_20261023_device_photo_restores_ratio_and_hold(self):
  chrome=file("DFNative12Chrome.m")
  self.assertNotIn("logoPan requireGestureRecognizerToFail:hold",chrome)
  self.assertIn("self.dividerWindow.userInteractionEnabled=YES;",chrome)
  self.assertIn("self.secondaryDividerWindow.userInteractionEnabled=YES;",chrome)
  self.assertIn("return self.dividerLogo.hidden || !CGRectContainsPoint(logoHit,p);",chrome)
  self.assertIn("DFDragBegin(p.x,p.y,self.verticalDivider,self.ratio,self.logoFraction,extent,span)",chrome)
  self.assertIn("[self.dividerTrack convertPoint:local toCoordinateSpace:screen]",chrome)
  self.assertNotIn("hold.minimumPressDuration=3.0;",chrome)
  self.assertNotIn("hold.allowableMovement=28;",chrome)



 def test_device_photo_hidden_logo_still_wakes_and_holds(self):
  chrome=file("DFNative12Chrome.m")
  self.assertIn("self.dividerLogo.hidden=NO;",chrome)
  self.assertIn("self.dividerLogo.alpha=controlsVisible?1.0:0.02;",chrome)
  self.assertIn("self.logoWakeOnlyTap=(NSDate.date.timeIntervalSince1970>self.controlsUntil);",chrome)
  self.assertIn("if(justWaking){DFCLog",chrome)
  self.assertNotIn("hold.minimumPressDuration=3.0;",chrome)








 def test_native12_v37_per_slot_real_window_ownership_instead_of_boxed_shared_window(self):
  """Signed playable v37 source 9601fdc865: each physical slot owns
  external UIWindow with split, swap, solo and host zoom geometry.
  Preserve independent current draggable logo, menu, system Dock.
  """
  chrome=file("DFNative12Chrome.m")
  self.assertIn("media37-four-physical-scene-windows-restored",chrome)
  self.assertIn("UIWindow *slotWindow=[self makeWindow:slotRect root:slotRoot level:0.5];",chrome)
  self.assertIn("[self.appSceneWindows addObject:slotWindow];",chrome)
  self.assertIn("[self observeActivityInWindow:slotWindow];",chrome)
  self.assertIn("[slotRoot.view addSubview:container];",chrome)
  self.assertIn("UIWindow *appWindow=self.appSceneWindows[(NSUInteger)i];",chrome)
  self.assertIn("if(!CGRectEqualToRect(appWindow.frame,target))appWindow.frame=target;",chrome)
  self.assertIn("CGRect localFrame=(CGRect){CGPointZero,target.size};",chrome)
  self.assertIn("appWindow.hidden=(self.startupActive || focusedElsewhere);",chrome)
  self.assertIn("self.appSceneContainers[(NSUInteger)i]",chrome)
  self.assertIn("return hit==self?nil:hit;",chrome)
  self.assertNotIn("sharedAppWindow",chrome)
  self.assertIn("grip-native12-scale-pulse-start-visual-1.18",chrome)
  self.assertIn("self.dividerLogo.hidden=NO;",chrome)
  self.assertIn("DFComputePresetFramesWithSecondary(cr,self.preset",chrome)
  self.assertIn("CGRect observed=appWindow.frame;",chrome)
  self.assertIn("BOOL innerMatched=",chrome)
  self.assertIn("self.hostedScenes[(NSUInteger)i]!=NSNull.null",chrome)
  self.assertIn("for(UIWindow *w in self.windows)w.hidden=YES;",chrome)

class MediaSceneRevision077(unittest.TestCase):
 def test_mode2_precedes_reference_size_changes(self):
  src=file("DFSceneHost.m")
  start=src.split("- (void)start {",1)[1].split("- (void)layoutSubviews {",1)[0]
  self.assertIn('DFHostInt(self.appController, @"setRequestedMode:", 2)',start)
  self.assertNotIn("[self commitSceneGeometry:nil]",start)
  geom=src.split("- (void)commitSceneGeometry:(NSTimer *)timer {",1)[1].split("- (UIView *)hitTest:",1)[0]
  self.assertIn("!self.ready",geom)
  self.assertIn("self.appController.view.window==self.window",geom)
 def test_remote_frame_dedup_does_not_box_video(self):
  s=file("DFSceneHost.m")
  self.assertIn('remoteSettings=DFCall0(hostedScene,@"settings")',s)
  self.assertIn("CGRectEqualToRect(observed,nativeFrame)",s)
  self.assertIn("if (!unchanged)",s)
  self.assertIn("hostedScene,update,setVerifiedNative12Frame",s)
  self.assertIn("native12-scene-settings-live-contract-requested",s)
  self.assertNotIn("DFEnableUnverifiedFBSceneFrameMutation",s)

if __name__=="__main__":unittest.main(verbosity=2)


class DuoFaceDeviceZoomAck056(unittest.TestCase):
 def test_one_nonowner_cannot_preempt_real_apple_dock_ack(self):
  z=file("DFDockZoomCoordinator.m")
  o=file("DFCarPlayDockOwner.m")
  failbranch=z[z.index("if(!owner) {"):z.index("CGRect bounds=CGRectFromString")]
  assert "DFZComplete(NO" not in failbranch
  assert "nonowner-awaiting-real-ack" in failbranch
  assert "real-dock-ack-timeout" in z
  assert "nonowner-reply-preserved-verified-positive" in o
  assert '[prior[@"RequestID"] isEqualToString:command[@"RequestID"]]' in o


class HistoricalOwnerRegression(unittest.TestCase):
 def test_dedicated_chrome_window_hidden_is_not_owner_disconnection(self):
  owner=file("DFCarPlayDockOwner.m")
  self.assertIn("DFZDockView!=DFZWindow",owner)
  self.assertIn("window.hidden && view!=window",owner)
  self.assertIn('if(matches==0)',owner)
  self.assertIn('if(matches!=1)',owner)
  self.assertIn('DFZFreshSession(session)',owner)
  self.assertIn('DFZDockView.hidden=DFZSavedHidden',owner)

class WholeHostZoomGeometry059(unittest.TestCase):
 def test_guard_matches_focused_pane_and_accepts_subpixel_rounding(self):
  c=file("DFNative12Chrome.m")
  assert "self.focus>=0 && visual==self.focus" in c
  assert "CGRect rendered=(self.focus>=0 && visual==self.focus)?actual:pane[visual];" in c
  assert "const CGFloat eps=0.5;" in c
  assert "host-zoom-validation-rejected slot=" in c
  assert "if(!contained || !matched || !innerMatched)" in c
  z=file("DFDockZoomCoordinator.m")
  assert "source-host-geometry-rejected" in z
  assert "if(!owner)" in z
  assert "DFZEmergencyRestore(session)" in z

class ImmediateDividerDragContract(unittest.TestCase):
 def test_both_routes_share_state_and_no_old_hold_survives(self):
  c=file("DFNative12Chrome.m")
  for old in ("logoHold", "logoRatioDwell", "gripHold", "logoLongPressGesture:"):
   self.assertNotIn(old,c)
  self.assertIn("DFDragMove(&_dividerDrag,p.x,p.y)",c)
  self.assertIn("DFDragFinish(&_dividerDrag,p.x,p.y,cancelled)",c)
  self.assertIn("BOOL allowSwap=tap && inside && !self.logoWakeOnlyTap && duration<=0.5;",c)
  self.assertIn("self.touchEnded(self,NO,YES);",c)
  self.assertIn("self.logoTouchPending=_dividerDrag.active;",c)
  self.assertIn("BOOL controlsVisible=self.panActive || self.logoTouchPending ||",c)
  self.assertIn("blink.toValue=@1.18;",c)
  self.assertNotIn("line.tag=718;",c)
  finish=c[c.index("- (BOOL)finishDividerDragAt:"):c.index("- (void)logoTouchDown:")]
  self.assertLess(finish.index("DFDragFinish"),finish.index("[self saveSplitState]"))
  self.assertIn("if(!cancelled && _dividerDrag.axis!=DFDragUndecided)",finish)

class SceneGenerationSafety074(unittest.TestCase):
 def test_scene_frame_private_write_requires_current_scene_owner(self):
  host=file("DFSceneHost.m")
  geometry=host.split("- (void)commitSceneGeometry:(NSTimer *)timer {",1)[1].split("- (UIView *)hitTest:",1)[0]
  check=geometry.index('observedScene!=self.scene || !hosting || !attached')
  write=geometry.index('NSSelectorFromString(@"updateSettingsWithBlock:")')
  self.assertLess(check,write)
  self.assertIn('DFSceneLog(@"scene-geometry-stale-owner-skip"',geometry)
  self.assertIn('if (self.ready) {',geometry)
  self.assertNotIn('[self commitSceneGeometry:nil];',host)
  # Exact .37 media geometry/frame call path remains available for LIVE scenes.
  self.assertIn('NSSelectorFromString(@"setContentReferenceSize:withContentOrientation:andContainerOrientation:")',geometry)
  self.assertIn('hostedScene,update,setVerifiedNative12Frame',geometry)
 def test_hosting_rebind_cancels_stale_pending_geometry_before_ready_event(self):
  host=file("DFSceneHost.m")
  poll=host.split("- (void)pollScene:(NSTimer *)timer {",1)[1].split("- (void)failed:",1)[0]
  change=poll.index('if (self.scene && self.scene!=scene)')
  cancel=poll.index('[self.geometryCommitTimer invalidate]',change)
  store=poll.index('self.scene=scene;',change)
  self.assertLess(change,cancel)
  self.assertLess(cancel,store)
  self.assertIn('DFSceneLog(@"scene-instance-changed"',poll)
  self.assertIn('self.ready=NO;',poll)
  self.assertIn('self.tries=0;',poll)
  self.assertIn('scene-handle-observed-render-unverified',poll)


class PhysicalCrash074FrameWriteRegression(unittest.TestCase):
 def test_user_proven_unboxed_frame_mutation_must_not_be_disabled_without_device_media_pass(self):
  source=file("DFSceneHost.m")
  commit=source.split("- (void)commitSceneGeometry:(NSTimer *)timer {",1)[1].split("- (UIView *)hitTest:",1)[0]
  self.assertIn("if (self.ready && self.scene) {",commit)
  self.assertIn('NSSelectorFromString(@"updateSettingsWithBlock:")',commit)
  self.assertIn('NSSelectorFromString(@"setContentReferenceSize:withContentOrientation:andContainerOrientation:")',commit)
  self.assertIn('NSSelectorFromString(@"setContentReferenceSize:withInterfaceOrientation:")',commit)
  self.assertNotIn("DFEnableUnverifiedFBSceneFrameMutation",source)
  self.assertNotIn("fbscene-frame-write-disabled-crash074",commit)
  chrome=file("DFNative12Chrome.m")
  self.assertIn("media37-four-physical-scene-windows-restored",chrome)
  self.assertIn("self.appSceneWindows[(NSUInteger)i]",chrome)

class CrashReasonCapture076(unittest.TestCase):
 def test_device_fatal_reason_missing_from_ips_captured_without_scene_mutation(self):
  probe=file("DFTouchOwnerProbe.m")
  host=file("DFSceneHost.m")
  exporter=file("DFNativeDiagnostics.m")
  self.assertIn("NSSetUncaughtExceptionHandler(DFCaptureFatalException)",probe)
  self.assertIn("sPreviousFatalHandler=NSGetUncaughtExceptionHandler()",probe)
  self.assertIn("sPreviousFatalHandler(exception)",probe)
  self.assertIn("if (sActivated && sChrome)",probe)
  self.assertIn("DFArmFatalReasonRecorder();",probe)
  self.assertIn("DuoFaceFatalException.log",probe)
  self.assertIn("DuoFaceFatalException.log",exporter)
  self.assertIn("0.0.83~manualobserver1",exporter)
  self.assertIn("if (self.ready && self.scene) {",host)
  self.assertIn('NSSelectorFromString(@"updateSettingsWithBlock:")',host)
  self.assertIn("setContentReferenceSize:withContentOrientation:andContainerOrientation:",host)
  self.assertNotIn("DFEnableUnverifiedFBSceneFrameMutation",host)
