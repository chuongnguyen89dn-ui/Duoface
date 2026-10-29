"""QA118 safety regression: Dock-visible .116 frame contract and NO automatic pane wake.

This static test cannot assert physical Apple Dock or YouTube event delivery.
The Sileo .117 user reports both regressions; nothing may claim device PASS.
"""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
chrome=(ROOT/"DFNative12Chrome.m").read_text()
probe=(ROOT/"DFTouchOwnerProbe.m").read_text()
delegate=(ROOT/"DFNativeHostAppDelegate.m").read_text()

class Emergency118(unittest.TestCase):
    def test_dock_known_visible_116_rollback_exact(self):
        self.assertIn("MAX(42,screen.size.width*.082)",probe)
        self.assertIn("CGFloat x=MAX(region.origin.x,safeLeft);",probe)
        self.assertIn("region=CGRectMake(safeLeft,screen.origin.y",probe)
        self.assertIn('launch[@"ContentRect"]',probe)
        self.assertIn("safe=w.safeAreaLayoutGuide.layoutFrame",delegate)
        self.assertNotIn('native-content-bounds-accepted',probe)
        self.assertIn("contentRect:region command:",probe)
    def test_no_input_root_subclass_and_no_app_pane_wake_registration(self):
        self.assertNotIn('#import "DFPaneInputTrace116.h"',chrome)
        self.assertNotIn("DFPane116TraceClass(",chrome)
        self.assertNotIn("DFPane117SetWake(",chrome)
        self.assertIn("[_externalWindowClass alloc],windowSelector,config",chrome)
        self.assertNotIn("[self observeActivityInWindow:slotWindow]",chrome)
        self.assertNotIn("self.dividerWindow];\n    [self observeActivityInWindow:",chrome)
        self.assertNotIn("name:DFSceneHostDidObserveTouchNotification object:nil",chrome)
        self.assertNotIn(").touchBeganInPane=^",chrome)
        self.assertIn("[self.appSceneWindows addObject:slotWindow];",chrome)
        self.assertIn("self.dividerLogo.alpha=controlsVisible?1.0:0.02;",chrome)
        self.assertIn("self.controlsUntil=NSDate.date.timeIntervalSince1970+4.0;",chrome)
    def test_preserve_per_pane_and_original_scene(self):
        self.assertIn("media37-four-physical-scene-windows-restored",chrome)
        self.assertIn("self.dividerWindow.userInteractionEnabled=YES;",chrome)
        self.assertIn("CGPoint p=[touch locationInView:self.dividerTrack];",chrome)
        self.assertIn("for(NSInteger i=0;i<4;i++){",chrome)
        self.assertIn("appWindow.frame=target;",chrome)

if __name__=="__main__":
    unittest.main()
