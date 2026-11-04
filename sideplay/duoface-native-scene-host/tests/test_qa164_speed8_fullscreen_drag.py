"""QA164 source-level contract: compact window spans DuoFace content via movement,
not a full-screen touch interception window. Not a physical CarPlay test.
"""
from pathlib import Path
import unittest
import plistlib
ROOT=Path(__file__).resolve().parents[1]
PACK=(ROOT.parent/"jb-embedded-appbridge/package_integrated.py").read_text()

class Speed8FullContent164(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.chrome=(ROOT/"DFNative12Chrome.m").read_text()
        cls.hud=(ROOT/"speed8/DFNative8SpeedHUDView.mm").read_text()
        cls.header=(ROOT/"speed8/DFNative8SpeedHUDView.h").read_text()
        cls.source=(ROOT/"DFGofaSpeedSource162.m").read_text()
        cls.build=(ROOT/"build.sh").read_text()

    def test_one_integrated_duoface_package(self):
        self.assertIn('VERSION="0.0.172~wakefix1"',PACK)
        self.assertIn("0.1.172~wakefix1",self.build)
        self.assertIn("speed8/DFNative8SpeedHUDView.mm",self.build)
        self.assertIn("DFSpeedNativeOverlay163.mm",self.build)
        self.assertNotIn("com.carplaypro.speed",self.build)

    def test_not_locked_inside_a_single_app_scene(self):
        self.assertIn("self.speedHUDWindow=hudWindow",self.chrome)
        self.assertIn("[self makeWindow:hudFrame root:hudRoot level:2.5]",self.chrome)
        self.assertIn("self.gofaSpeedHUD.floatingWindowMode=YES",self.chrome)
        self.assertIn("self.gofaSpeedHUD.floatingDragBounds=cr",self.chrome)
        self.assertIn("[self refreshGlobalSpeedHUD164]",self.chrome)
        self.assertIn("w.hidden=!valid",self.chrome)
        self.assertIn("self.speedHUDWindow=nil",self.chrome)
        self.assertNotIn("refreshGlobalSpeedHUD163",self.chrome)
        self.assertNotIn('[bundle isEqualToString:@"com.lumi.GOFA"]',self.chrome)

    def test_drag_moves_only_bubble_window_across_full_content(self):
        self.assertIn("CGRectInset(bubble.floatingDragBounds,3,3)",self.hud)
        self.assertIn("CGRect frame=self.ownerWindow.frame",self.hud)
        self.assertIn("self.ownerWindow.frame=frame",self.hud)
        self.assertIn("CGPoint prior=[self dfDisplayCenter]",self.hud)
        self.assertIn("dfSetDisplayCenter:DFClampCenter",self.hud)
        self.assertIn("if(self.floatingWindowMode)",self.hud)
        self.assertIn("self.dismissWindow",self.hud)
        self.assertIn("floatingDragBounds",self.header)
        self.assertIn("floatingWindowMode",self.header)

    def test_settings_popup_expands_only_while_open(self):
        self.assertIn("dfExpandFloatingSettings",self.hud)
        self.assertIn("dfCollapseFloatingSettings",self.hud)
        self.assertIn("MIN(221,area.size.height)",self.hud)

    def test_missing_gofa_gps_is_diagnosed_not_invented(self):
        self.assertIn("GOFA GPS source status auth=",self.source)
        self.assertIn("GOFA GPS sample REJECTED",self.source)
        self.assertIn("GOFA GPS IPC publication FAILED",self.source)
        self.assertIn("viewer NO_FRESH_SAMPLE source=GOFA ttl=5s",self.hud)
        self.assertIn("DFSpeedHUDReadBest(&sample)",self.hud)
        self.assertIn('self.current.text=@"—"',self.hud)
        self.assertIn('self.limit.text=@"—"',self.hud)
        self.assertIn("location.speed*3.6",self.source)
        filt=plistlib.loads((ROOT/"DFGofaSpeedSource162.plist").read_bytes())
        self.assertEqual(filt,{"Filter":{"Bundles":["com.lumi.GOFA"]}})

if __name__=="__main__":
    unittest.main()
