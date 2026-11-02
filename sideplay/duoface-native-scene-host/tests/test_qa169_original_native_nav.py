"""QA169: real original CarPlayPro Speed 0.9.97 exact native navigation method selectors.
Static match against ORIGINAL Mach-O authenticated selref bytes; runtime untested.
"""
import json
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
AUDIT=ROOT.parent/"audit/carplaypro-0.9.97/qa169-original-gofa-literals"
HOOK=ROOT/"DFGofaOriginalCarPlayNavHook169.m"
class TestQA169(unittest.TestCase):
    def test_original_method_selectors_not_guessed(self):
        original=json.loads((AUDIT/"ORIGINAL_CP_NAV_SELECTOR_POINTERS.json").read_text())
        pairs={x["selref"]:x["selector"] for x in original["selectors"]}
        self.assertEqual(pairs["0x6b000"],"setUpcomingManeuvers:")
        self.assertEqual(pairs["0x6b008"],"updateTravelEstimates:forManeuver:")
        self.assertEqual(original["original_CPNav_hook_calls"]["0x2fae4"],"0x6b000")
        self.assertEqual(original["original_CPNav_hook_calls"]["0x2fb00"],"0x6b008")
        source=HOOK.read_text()
        for selector in (pairs["0x6b000"],pairs["0x6b008"]):
            self.assertIn(selector,source)
    def test_original_first_real_source_scoped_to_gofa(self):
        s=HOOK.read_text()
        self.assertIn('com.lumi.GOFA',s)
        self.assertIn('DF169OriginalSet(owner,cmd,maneuvers);',s)
        self.assertIn('DF169OriginalUpdate(owner,cmd,estimates,maneuver);',s)
        self.assertIn('DF168PublishNativeCarPlayManeuver',s)
        self.assertIn("method_getNumberOfArguments",s)
        self.assertIn("CPNavigationSession",s)
        self.assertNotIn("requestWhenInUseAuthorization",s)
        self.assertNotIn("traffic_sign_id",s) # native maneuver != original GOFA Swift alert
        self.assertNotIn("cameraUpcoming",s)
    def test_integrated_one_package(self):
        build=(ROOT/"build.sh").read_text()
        control=(ROOT/"control").read_text()
        self.assertIn("DFGofaOriginalCarPlayNavHook169.m",build)
        self.assertIn("0.1.169~originalhooks1",build)
        self.assertIn("0.1.169~originalhooks1",control)
        pkg=(ROOT.parent/"jb-embedded-appbridge/package_integrated.py").read_text()
        self.assertIn('VERSION="0.0.169~originalhooks1"',pkg)
if __name__=="__main__":unittest.main()
