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
 def test_separate_package_and_no_boot_scripts(self):
  c=file("control")
  self.assertIn("Package: com.duoface.carplay.nativescenehost",c)
  self.assertIn("Version: 0.0.4~template1",c)
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
