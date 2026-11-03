"""QA163: prove source-vs-display separation and preserve old DuoFace/CarPlay ownership boundaries.
These structural tests cannot certify actual foreground UIWindow visibility on a physical CarPlay display.
"""
from pathlib import Path
import plistlib
import unittest

ROOT=Path(__file__).resolve().parents[1]
PACK=(ROOT.parent/"jb-embedded-appbridge/package_integrated.py").read_text()

class GlobalSpeedHUD163(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.build=(ROOT/"build.sh").read_text()
        cls.chrome=(ROOT/"DFNative12Chrome.m").read_text()
        cls.native=(ROOT/"DFSpeedNativeOverlay163.mm").read_text()
        cls.renderer=(ROOT/"speed8/DFNative8SpeedHUDView.mm").read_text()
        cls.source=(ROOT/"DFGofaSpeedSource162.m").read_text()

    def test_only_one_integrated_duoface_package_and_full_compilation(self):
        self.assertIn('VERSION="0.0.179~kbfit1"',PACK)
        self.assertIn('0.1.179~kbfit1',self.build)
        self.assertIn("DFSpeedNativeOverlay163.mm speed8/DFNative8SpeedHUDView.mm speed8/DFSpeedTransport.mm",self.build)
        self.assertIn("DFNative12Chrome.m",self.build)
        self.assertIn("DFGofaSpeedSource162.m",self.build)
        self.assertIn("DFGofaSpeedSource162.plist",self.build)
        self.assertNotIn("com.carplaypro.speed",self.build)

    def test_duoface_native_pane_not_gofa_gated(self):
        self.assertIn("refreshGlobalSpeedHUD164",self.chrome)
        self.assertNotIn("refreshGOFASpeedHUD162",self.chrome)
        self.assertNotIn('[bundle isEqualToString:@"com.lumi.GOFA"]',self.chrome)
        self.assertIn("self.speedHUDWindow=hudWindow",self.chrome)
        self.assertIn("self.gofaSpeedHUD.floatingWindowMode=YES",self.chrome)
        self.assertIn("[self.gofaSpeedHUD removeFromSuperview]",self.chrome)
        self.assertIn("w.screen!=UIScreen.mainScreen",self.chrome)

    def test_native_carplay_dashboard_existing_filter(self):
        filters=plistlib.loads((ROOT/"DFCarPlayDockOwner.plist").read_bytes())["Filter"]
        self.assertIn("com.apple.CarPlayApp",filters["Bundles"])
        self.assertIn("com.apple.dashboard",filters["Bundles"])
        self.assertIn("CarPlayApp",filters["Executables"])
        self.assertIn("dashboard",filters["Executables"])
        self.assertIn("DFOwnerAcceptPulse(pulse)",self.native)
        self.assertIn("visibleExternalOwner",self.native)
        self.assertIn("UIWindowDidBecomeVisibleNotification",self.native)
        self.assertIn("UISceneDidActivateNotification",self.native)
        self.assertIn("w.screen==UIScreen.mainScreen",self.native)
        self.assertIn("w.rootViewController.viewIfLoaded",self.native)
        # QA177: detach is funnelled through detachWithReason: so
        # every detach leaves a file-log line + record update.
        self.assertIn("[self detachWithReason:",self.native)
        self.assertIn("[root addSubview:view]",self.native)
        self.assertNotIn("alloc] initWithWindow",self.native)
        self.assertNotIn("initWithDisplayConfiguration:",self.native)
        self.assertNotIn("w.rootViewController=",self.native)

    def test_real_location_source_is_separate_and_no_fake_limits(self):
        self.assertIn("location.speed*3.6",self.source)
        self.assertIn("DFSpeedHUDReadBest(&sample)",self.renderer)
        self.assertIn('self.limit.text=@"—"',self.renderer)
        self.assertIn("DFSpeedHUDPublish(DFSpeedAppSourceGOFA",self.source)
        self.assertNotIn("speedLimitAdapter",self.source)
        self.assertNotIn("CPSActivation",self.source)
        self.assertNotIn("SecKeyVerifySignature",self.source)

if __name__=="__main__":
    unittest.main()
