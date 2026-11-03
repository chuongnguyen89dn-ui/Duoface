"""QA169 source contracts: actual owner coverage, not an iPhone/CarPlay test."""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(name):
    return (ROOT/name).read_text()
class TestBubbleVisibility169(unittest.TestCase):
    def test_shared_visibility_is_persistent_and_no_per_object_dismiss(self):
        impl=read("DFSpeedVisibility169.m")
        hud=read("speed8/DFNative8SpeedHUDView.mm")
        for part in ('com.duoface.speedhud.visibility.v1.plist',
          'writeToFile:DF169VisibilityPath atomically:YES',
          'DF169SpeedBubbleEnabled','DF169SetSpeedBubbleEnabled',
          'notify_post(DF169VisibilityNotify)'):
            self.assertIn(part,impl)
        self.assertIn('DF169SetSpeedBubbleEnabled(NO)',hud)
        self.assertIn('windowHiddenForDisable',hud)
        self.assertNotIn('dismissedForSession',hud)
    def test_x_in_duoface_standalone_and_normal(self):
        chrome=read("DFNative12Chrome.m")
        standalone=read("DFHomeStandalone144.m")
        hud=read("speed8/DFNative8SpeedHUDView.mm")
        for s in (chrome,standalone):
            self.assertIn('DF169MakeBubbleDismissSymbol()',s)
            self.assertIn('.dismissWindow=',s)
            self.assertIn('userInteractionEnabled=NO',s)
        self.assertIn('DF169MakeBubbleDismissSymbol()',hud)
        self.assertIn('CGSizeMake(30,30)',hud)
        self.assertIn('CGRectInset(self.dismissWindow.frame,-20,-20)',hud)
        self.assertIn('DF169SetSpeedBubbleEnabled(NO)',hud)
        self.assertNotIn('!self.floatingWindowMode && !CGRectIsEmpty(drop)',hud)
        self.assertNotIn('CGRectMake(0,0,62,62)',hud)
    def test_phone_control_and_native_carplay_gate(self):
        phone=read("DFNativeHostRootController.m")
        native=read("DFSpeedNativeOverlay163.mm")
        chrome=read("DFNative12Chrome.m")
        stand=read("DFHomeStandalone144.m")
        self.assertIn('@selector(toggleSpeedBubble:)',phone)
        self.assertIn('DF169SetSpeedBubbleEnabled(requested)',phone)
        self.assertIn('DF169SpeedBubbleEnabled()',native)
        self.assertIn('DF169SpeedBubbleEnabled()',chrome)
        self.assertIn('refreshVisibility169',stand)
        self.assertIn('refreshVisibility169',chrome)
    def test_one_integrated_rootless_build(self):
        build=read("build.sh")
        pkg=(ROOT.parent/"jb-embedded-appbridge/package_integrated.py").read_text()
        self.assertEqual(build.count("DFSpeedVisibility169.m"),4)
        self.assertIn("0.1.179~kbfit1",build)
        self.assertIn('VERSION="0.0.179~kbfit1"',pkg)
if __name__=="__main__":unittest.main()
