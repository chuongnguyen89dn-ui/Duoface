"""Historical .92 divider ratio geometry; newest logo drag supersedes .92 hold."""
from pathlib import Path
import json
import unittest
BASE=Path(__file__).resolve().parents[1]
class DividerGeometryHistoricalPin(unittest.TestCase):
 def test_ratio_geometry_still_pinned_to_092(self):
  src=(BASE/"DFNative12Chrome.m").read_text()
  fixture=json.loads((BASE/"tests/fixtures/divider92_exact_source.json").read_text())
  # Old .92 grip setup is superseded; keep the actual ratio, coordinate and
  # window geometry reference, not its obsolete three-second touch path.
  for name in ("divider_touch_exclusion","divider_window_layout","divider_pan_machine","divider_pan_coordinates"):
   part=fixture["parts"][name]
   actual=src[src.index(part["start"]):src.index(part["end"],src.index(part["start"]))]
   original=part["text"]
   if name=="divider_pan_machine":
    actual=actual.split("// The user's latest contract supersedes",1)[0]
    original=original.split("// User-approved 3s logo hold",1)[0]
   self.assertEqual(actual,original,name)
 def test_no_three_second_logo_gate_in_active_source(self):
  src=(BASE/"DFNative12Chrome.m").read_text()
  for forbidden in ("DFLogoHoldBegin(", "DFLogoHoldAdvance(", "DFLogoHoldIsQuickTap("):
   self.assertNotIn(forbidden,src)
  self.assertIn('[self beginDividerDragAt:point]',src)
  self.assertIn('[self updateDividerDragAt:point]',src)
if __name__=="__main__": unittest.main()
