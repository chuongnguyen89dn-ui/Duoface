"""Regression: latest user removed 3-second grip hold. No UI timer is allowed."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class NoHoldGate(unittest.TestCase):
    def test_live_chrome_has_no_legacy_hold(self):
        src=(ROOT/"DFNative12Chrome.m").read_text()
        for forbidden in ("#import \"DFLogoHoldGate.h\"", "DFLogoHoldBegin(",
                          "DFLogoHoldAdvance(", "DFLogoHoldIsQuickTap(",
                          "logo-3s-hold-armed", "logo-hold-3s-unlocked"):
            self.assertNotIn(forbidden,src)
        self.assertIn('logo-ratio-drag-begin-no-hold',src)
        self.assertIn('[self beginDividerDragAt:point]',src)
        self.assertIn('[self updateDividerDragAt:point]',src)
    def test_only_one_ratio_geometry(self):
        src=(ROOT/"DFDividerDrag.h").read_text()
        self.assertNotIn("d->axis=DFDragLogo",src)
        self.assertNotIn("d->logo=DFDragClamp",src)
        self.assertIn("d->axis=DFDragRatio",src)
        chrome=(ROOT/"DFNative12Chrome.m").read_text()
        self.assertIn("self.dividerWindow.frame=tr;",chrome)
        self.assertIn("self.dividerLogo.frame=self.verticalDivider?",chrome)
if __name__=="__main__": unittest.main()
