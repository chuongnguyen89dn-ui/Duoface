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
  self.assertFalse(any(k.startswith("com.apple.developer.carplay") for k in plistlib.loads((R/"entitlements.plist").read_bytes())))
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
 def test_separate_package_and_no_boot_scripts(self):
  c=file("control")
  self.assertIn("Package: com.duoface.carplay.nativescenehost",c)
  self.assertIn("Version: 0.0.2~template1",c)
  self.assertNotIn("Conflicts:",c)
  self.assertNotIn("Replaces:",c)
  self.assertFalse((R/"postinst").exists())
  self.assertFalse((R/"prerm").exists())
if __name__=="__main__":unittest.main(verbosity=2)
