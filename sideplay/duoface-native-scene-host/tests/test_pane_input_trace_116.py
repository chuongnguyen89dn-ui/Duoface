"""Static contract tests for nonintrusive .116 pane diagnostics."""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
chrome=(ROOT/"DFNative12Chrome.m").read_text()
trace=(ROOT/"DFPaneInputTrace116.h").read_text()

class TestPaneTrace(unittest.TestCase):
    def test_physical_window_only(self):
        self.assertIn("physicalPane?DFPane116TraceClass(_externalWindowClass):Nil",chrome)
        self.assertIn("[root.view isKindOfClass:DFNativePanePassthroughView.class]",chrome)
        self.assertIn("Class factory=traced?:_externalWindowClass;",chrome)

    def test_super_forwarding_unchanged(self):
        self.assertEqual(trace.count("objc_msgSendSuper)"),3)
        self.assertIn("return target;",trace)
        self.assertIn("return accepts;",trace)

    def test_touch_only_with_external_screen(self):
        self.assertIn("event.type!=UIEventTypeTouches",trace)
        self.assertIn("t.phase==UITouchPhaseBegan",trace)
        self.assertIn("w.screen==UIScreen.mainScreen",trace)
        self.assertIn("fractionY=",trace)

    def test_existing_gestures_unchanged(self):
        self.assertIn("[self.dividerTrack addGestureRecognizer:trackPan]",chrome)
        self.assertIn("self.controlsUntil=NSDate.date.timeIntervalSince1970+4.0;",chrome)
        self.assertIn("[self.appSceneWindows addObject:slotWindow]",chrome)

if __name__=="__main__":
    unittest.main()
