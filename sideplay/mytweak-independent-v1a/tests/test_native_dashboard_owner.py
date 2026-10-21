#!/usr/bin/env python3
"""Independent CarPlay scene-owner safety checks, not a device-level Dock PASS."""
import unittest
from pathlib import Path
P=Path(__file__).resolve().parents[1]
def read(s): return (P/"prototype"/s).read_text()

class NativeOwner(unittest.TestCase):
    def test_normal_geometry_uses_visible_bar_not_guess(self):
        src=read("MTCPNativeChromeLayout.m")
        self.assertIn("CGRectIntersection(screen,bar)",src)
        self.assertIn("MTCPDockEdgeLeft",src)
        self.assertIn("MTCPDockEdgeRight",src)
        self.assertIn("MTCPDockEdgeTop",src)
        self.assertIn("MTCPDockEdgeBottom",src)
        for wrong in ["UIWindowLevelAlert", "insets.left=64", "insets.left=45",
                      "setHidden:", "setWindowLevel:", "setFrame:"]:
            self.assertNotIn(wrong,src)
    def test_only_existing_dashboard_scene_host(self):
        src=read("MTCPDashboardOwner.m")
        for required in ["DBDashboardRootViewController", "w.rootViewController!=root",
                         "root.view addSubview:host", "MTCPNativeBarContent",
                         "MTCPNativeUsableBounds", "MTCPBridgeReadSurface(nil)",
                         "connectWithOwnedContentView:host",
                         "self.receiver disconnect", "MTCPBridgeExplicitOptIn()"]:
            self.assertIn(required,src)
        for danger in ["UIRootSceneWindow", "FBSDisplayConfiguration",
                       "LSBundleProxy", "objc_addLoadImageFunc",
                       "initWithWindowScene:", "setWindowLevel:",
                       "DBStatusBarWindow.hidden", "window.hidden=NO",
                       "requestStateChange:", "SpringBoard"]:
            self.assertNotIn(danger,src)
    def test_zero_native_safearea_narrowly_allowed(self):
        src=read("MTCPRemoteLayer.m")
        self.assertIn("MTCPVerifiedNativeOwner(owner)",src)
        self.assertIn("owner.superview!=root.view",src)
        self.assertIn('isEqualToString:@"DBDashboardRootViewController"',src)
        self.assertIn('duoface.native.content.host',src)
        self.assertNotIn("UIRootSceneWindow",src)
    def test_source_is_not_auto_packaged_or_replacing_stable(self):
        maker=(P/"Makefile").read_text()
        c=(P/"control").read_text()
        self.assertNotIn("MTCPDashboardOwner.m",maker)
        self.assertNotIn("MTCPNativeChromeLayout.m",maker)
        self.assertIn("Version: 0.2.1~divider1",c)
        self.assertIn("SpringBoard",maker)
        self.assertNotIn("CarPlayApp",maker)
        self.assertNotIn("com.duoface.carplay.ownerprobe",maker)

if __name__=="__main__":unittest.main(verbosity=2)
