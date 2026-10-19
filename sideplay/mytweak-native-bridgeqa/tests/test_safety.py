#!/usr/bin/env python3
import unittest
from pathlib import Path
import plistlib
ROOT=Path(__file__).resolve().parents[1]
def read(name):return (ROOT/name).read_text()
class Safety(unittest.TestCase):
    def test_standalone_and_disabled_by_default(self):
        c=read("control")
        self.assertIn("Package: com.duoface.carplay.nativebridgeqa",c)
        self.assertIn("Version: 0.0.2~sidebartest1",c)
        self.assertIn("com.duoface.mytweak.v1a.preflight",c)
        for s in ("Conflicts:","Replaces:","Breaks:"):self.assertNotIn(s,c)
        code=read("DFCPNativeBridgeQA.m")
        self.assertIn("MTCPBridgeExplicitOptIn()",code)
        self.assertIn("if(!MTCPBridgeExplicitOptIn())",code)
        self.assertIn("[self.publisher invalidate]",code)
        self.assertIn("[self.owner detach]",code)
    def test_process_filter_and_no_boot_injection(self):
        f=plistlib.loads((ROOT/"DFNativeDashboardBridgeQA.plist").read_bytes())
        self.assertEqual(f["Filter"]["Executables"],["SpringBoard","CarPlay","CarPlayApp"])
        c=read("Tweak.x")
        self.assertNotIn("%hook",c)
        self.assertIn("(10*NSEC_PER_SEC)",c)
        self.assertEqual(c.count("%ctor"),1)
        for p in ("Tweak.x","DFCPNativeBridgeQA.m"):
            c=read(p)
            for illegal in ("LSBundleProxy","objc_addLoadImageFunc","method_setImplementation","FBSDisplayConfiguration","UIRootSceneWindow","setEntitlements:","setWindowLevel:","DBStatusBarWindow.hidden=NO"):
                self.assertNotIn(illegal,c)
    def test_no_live_original_layer_reparented(self):
        c=read("DFCPNativeBridgeQA.m")
        self.assertIn("drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO",c)
        self.assertIn("self.mirrorLayer.contents=",c)
        self.assertIn("publishLayer:self.mirrorLayer",c)
        self.assertNotIn("publishLayer:root.view.layer",c)
        self.assertNotIn("addSublayer:view.layer",c)
        self.assertIn("remote producer", (ROOT/"../mytweak-independent-v1a/prototype/MTCPRemoteLayer.m").read_text().lower())
    def test_menu_only_pointer_no_iphone_app_gesture_spoof(self):
        c=read("DFCPNativeBridgeQA.m")
        for needed in ('@"App"', '@"Split 2"', '@"Single"', '@"Swap"', '@"Zoom"', '@"Close"', "sendActionsForControlEvents:UIControlEventTouchUpInside", "self.pointerDown=NO", "hypot("):
            self.assertIn(needed,c)
        for wrong in ("UIEvent *fabricated","GSEvent","IOHIDEvent","setPressed","touchesWithEvent"):
            self.assertNotIn(wrong,c)
    def test_package_contents(self):
        m=read("Makefile")
        self.assertIn("THEOS_PACKAGE_SCHEME = rootless",m)
        self.assertIn("arm64 arm64e",m)
        self.assertIn("INSTALL_TARGET_PROCESSES =",m)
        self.assertIn("MTCPDashboardOwner.m",m)
        self.assertIn("MTCPNativeChromeLayout.m",m)
        self.assertIn("MTCPCommandRelay.m",m)
        self.assertNotIn("MTBridgeCoordinator.m",m)
        self.assertIn("DFNativeSidebarTrial.m",m)
    def test_temporary_real_sidebar_third_optin_and_reversible(self):
        s=read("DFNativeSidebarTrial.m")
        for x in ['cfg[@"NativeSidebarTrial"]','cfg[@"Enabled"]','@"DBStatusBarWindow"','@"DBRootStatusBarViewController"','NSDate.date.timeIntervalSince1970-self.beganAt>45','w.frame=self.originalFrame','DFClose(f.origin.x,-f.size.width)','self.exhaustedSession']:
            self.assertIn(x,s)
        for bad in ("w.hidden=NO","UIWindowLevel","LSBundleProxy"):
            self.assertNotIn(bad,s)
if __name__=="__main__":unittest.main(verbosity=2)
