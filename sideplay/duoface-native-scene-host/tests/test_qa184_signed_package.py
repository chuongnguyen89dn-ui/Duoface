"""QA184 single signed integrated test package: source/manifest contracts only.
Physical CarPlay, pixels, touch, Home, stock Customize OFF remain on-car gates.
"""
import pathlib
import plistlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
REPO = ROOT.parents[1]
VERSION = "0.0.185~admission1"
NATIVE = "0.1.185~admission1"

class QA184Package(unittest.TestCase):
    def test_exact_versions_are_coordinated(self):
        build = (ROOT / "build.sh").read_text()
        control = (ROOT / "control").read_text()
        info = plistlib.loads((ROOT / "Info.plist").read_bytes())
        pack = (REPO / "sideplay/jb-embedded-appbridge/package_integrated.py").read_text()
        self.assertIn(NATIVE, build)
        self.assertIn("Version: " + NATIVE, control)
        self.assertEqual(info["CFBundleVersion"], "185")
        self.assertEqual(info["CFBundleShortVersionString"], "0.1.185")
        self.assertIn('VERSION="' + VERSION + '"', pack)
        self.assertIn(NATIVE, pack)
        self.assertNotIn("0.1.182~b1nativemaps1", build)
        self.assertNotIn("0.0.182~b1nativemaps1", pack)
    def test_signed_single_package_and_no_vendor_dependency(self):
        pack = (REPO / "sideplay/jb-embedded-appbridge/package_integrated.py").read_text()
        build = (ROOT / "build.sh").read_text()
        self.assertIn('NAME="com.duoface.jb.embedded"', pack)
        self.assertIn('EXCLUDED=(', pack)
        self.assertIn('DFNativeMapPaneCoordinator.m', build)
        self.assertIn('DF182NativeMaps.m', build)
        self.assertIn('DFTouchOwnerProbe.m', build)
        self.assertIn('DFNativeHostAppDelegate.m', build)
        self.assertIn('DF155GeneralAppStateRelay.dylib', build)
        self.assertIn("ldid -S", build)
        self.assertIn("ldid -Sentitlements.plist", build)
    def test_source_protects_original_home_and_watchdog(self):
        src = (ROOT / "DFCarPlayOwnerLease.h").read_text()
        maps = (REPO / "sideplay/native-carplay-scene-v1/DF182NativeMaps.m").read_text()
        chrome = (ROOT / "DFNative12Chrome.m").read_text()
        self.assertIn("DF184MapMembershipAccepted(", src)
        self.assertIn("DF182OriginalPresent(root,sel,base,animated,source,completion)", maps)
        self.assertIn('publishMembershipStage:@"PRESENTED"', maps)
        self.assertIn('publishMembershipStage:@"COMMITTED"', maps)
        self.assertIn('DF182Revoke(@"Chrome-Home-or-disconnect")', chrome)
        self.assertIn("reconcileNativeMaps184", chrome)
        self.assertNotIn("hostViewForBundleID:@\"com.google.Maps\"", chrome)
    def test_once_only_ci_and_no_sileo_publishing(self):
        workflow = (REPO / ".github/workflows/duoface-184-nativeowner-signed-once.yml").read_text()
        self.assertIn("sideplay/audit/qa184-native-maps-owner-20261107/BUILD_REQUEST_ONCE_20261107.md", workflow)
        self.assertIn("actions/upload-artifact@v4", workflow)
        self.assertIn("SILEO_PUBLISHED=false", workflow)
        self.assertNotIn("carplaydsp", workflow)
        self.assertNotIn("gh release create", workflow)
        self.assertNotIn("apt-ftparchive", workflow)

if __name__ == "__main__":
    unittest.main()
