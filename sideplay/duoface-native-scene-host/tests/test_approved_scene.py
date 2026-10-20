import pathlib
import plistlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]

class ApprovedSceneContract(unittest.TestCase):
    def test_independent_phone_and_carplay_scenes(self):
        manifest = plistlib.loads((ROOT / "Info.plist").read_bytes())
        roles = manifest["UIApplicationSceneManifest"]["UISceneConfigurations"]
        self.assertIn("UIWindowSceneSessionRoleApplication", roles)
        self.assertIn("UIWindowSceneSessionRoleCarPlay", roles)
        template = roles["CPTemplateApplicationSceneSessionRoleApplication"][0]
        self.assertEqual(template["UISceneClassName"], "CPTemplateApplicationScene")
        self.assertEqual(template["UISceneDelegateClassName"], "DFNativeHostTemplateSceneDelegate")

    def test_no_entitlement_claim_without_apple_approval(self):
        entitlements = plistlib.loads((ROOT / "entitlements.plist").read_bytes())
        self.assertFalse(any(k.startswith("com.apple.developer.carplay-") for k in entitlements))
        s = (ROOT / "DFNativeHostAppDelegate.m").read_text()
        for key in ("#import <CarPlay/CarPlay.h>",
                    "didConnectInterfaceController:",
                    "setRootTemplate:root animated:NO completion:nil",
                    "config.sceneClass=CPTemplateApplicationScene.class"):
            self.assertIn(key, s)
        for forbidden in ("MSHookMessageEx", "method_setImplementation", "sbreload"):
            self.assertNotIn(forbidden, s)

    def test_build_is_rootless_and_no_restart(self):
        s = (ROOT / "build.sh").read_text()
        self.assertIn("-framework CarPlay", s)
        self.assertIn("0.0.2~template1_iphoneos-arm64.deb", s)
        self.assertNotIn("sbreload", s)
        self.assertNotIn("killall", s)
        self.assertNotIn("launchctl", s)

if __name__ == "__main__":
    unittest.main(verbosity=2)
