import unittest
import plistlib
from pathlib import Path
R=Path(__file__).resolve().parents[1]
def file(n):return (R/n).read_text()
class NativeCarPlayHost(unittest.TestCase):
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
             "requestStateChange:", "SpringBoard", "SBAppViewController"):
   self.assertNotIn(forbidden,c)
 def test_never_mutate_carplay_dock_or_forge_two_app_success(self):
  c=file("DFNativeHostRootController.m")
  self.assertIn("Chưa nối hai ứng dụng iPhone",c)
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
 def test_native12_ui1_basic_chrome_contract(self):
  app=file("DFNativeHostAppDelegate.m")
  ui=file("DFNative12BasicController.m")
  self.assertIn("DFNative12BasicController *root=[DFNative12BasicController new]",app)
  for marker in ("APP 1","APP 2","CHƯA NỐI SCENE","App","Zoom","Style","Close","UIPanGestureRecognizer","self.ratio","self.swapped","safeAreaLayoutGuide","self.menuSheet"):
   self.assertIn(marker,ui)
  for forbidden in ("DBDockWindow","setWindowLevel:","SBAppViewController","CALayerHost","requestStateChange:","CarBridge"):
   self.assertNotIn(forbidden,ui)
  self.assertIn("DFNative12BasicController.m",file("build.sh"))
 def test_native12_input_is_routed_through_system_template(self):
  app=file("DFNativeHostAppDelegate.m")
  ui=file("DFNative12BasicController.m")
  header=file("DFNative12BasicController.h")
  self.assertIn("map.automaticallyHidesNavigationBar=NO",app)
  self.assertIn("map.hidesButtonsWithNavigationBar=NO",app)
  self.assertIn("initWithTitle:command handler:",app)
  self.assertIn("leadingNavigationBarButtons",app)
  self.assertIn("trailingNavigationBarButtons",app)
  self.assertIn('@"App",@"Zoom",@"Style",@"Close"',app)
  self.assertIn("performCarPlayControl:command",app)
  self.assertIn('@"LEFT",@"RIGHT",@"SWAP"',app)
  self.assertIn("carplay-system-bar-command-confirmed",app)
  self.assertIn("carplay-system-map-command-confirmed",app)
  self.assertIn("performCarPlayControl:",header)
  self.assertIn("setPresetRatio:",header)
  self.assertIn("self.expanded=!self.expanded",ui)
  self.assertIn("self.ratio=MAX(1.0/3.0,MIN(2.0/3.0,ratio))",ui)
  self.assertNotIn("sendEvent:",app)
  self.assertNotIn("UIRootSceneWindow",app)
 def test_0_0_8_independent_touch_owner_probe_is_bounded_and_fail_closed(self):
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
  self.assertIn("110,40",probe)
  self.assertIn("window.frame=target",probe)
  self.assertIn("window-does-not-support-bounded-frame",probe)
  self.assertIn("timeout-30s",probe)
  self.assertIn("window-detached",probe)
  self.assertIn("real-button-action",probe)
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
  self.assertIn("0.0.8~touchowner1",build)
  self.assertIn("mobilesubstrate",file("control"))
 def test_separate_package_and_no_boot_scripts(self):
  c=file("control")
  self.assertIn("Package: com.duoface.carplay.nativescenehost",c)
  self.assertIn("Version: 0.0.8~touchowner1",c)
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
if __name__=="__main__":unittest.main(verbosity=2)
