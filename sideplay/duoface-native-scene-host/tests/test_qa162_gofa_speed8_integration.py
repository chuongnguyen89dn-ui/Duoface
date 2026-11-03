"""QA162: verify GOFA Speed8 is integrated into ONE native DuoFace DEB.
Static checks do not prove actual GPS permission or on-road behavior.
"""
from pathlib import Path
import plistlib
import unittest

ROOT=Path(__file__).resolve().parents[1]
PACK=ROOT.parent/"jb-embedded-appbridge"/"package_integrated.py"

class QA162GofaSpeed8(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.build=(ROOT/"build.sh").read_text()
        cls.chrome=(ROOT/"DFNative12Chrome.m").read_text()
        cls.speed=(ROOT/"speed8/DFNative8SpeedHUDView.mm").read_text()
        cls.transport=(ROOT/"speed8/DFSpeedTransport.mm").read_text()
        cls.publisher=(ROOT/"DFGofaSpeedSource162.m").read_text()
        cls.pack=PACK.read_text()

    def test_single_package_identity_and_version(self):
        self.assertIn('NAME="com.duoface.jb.embedded"',self.pack)
        self.assertIn('VERSION="0.0.177~apptouch1"',self.pack)
        self.assertIn("0.1.177~apptouch1",self.build)
        self.assertIn("DFGofaSpeedSource162.dylib",self.build)
        self.assertIn("speed8/DFNative8SpeedHUDView.mm",self.build)
        self.assertIn("speed8/DFSpeedTransport.mm",self.build)

    def test_gofa_bundle_only_and_no_permissions_prompt(self):
        plist=plistlib.loads((ROOT/"DFGofaSpeedSource162.plist").read_bytes())
        self.assertEqual(plist,{"Filter":{"Bundles":["com.lumi.GOFA"]}})
        self.assertIn("CLLocationManagerDelegate",self.publisher)
        self.assertIn("DFSpeedHUDPublish(DFSpeedAppSourceGOFA",self.publisher)
        self.assertIn("age<=8.0",self.publisher)
        for forbidden in ("requestAlwaysAuthorization","requestWhenInUseAuthorization",
                          "licenseValid","offlineLicense","CPSActivation",
                          "com.carplaypro.speed"):
            self.assertNotIn(forbidden,self.publisher)

    def test_verified_scene_owner_and_tap_boundary(self):
        self.assertIn("refreshGlobalSpeedHUD164",self.chrome)
        self.assertNotIn('[bundle isEqualToString:@"com.lumi.GOFA"]',self.chrome)
        self.assertIn("self.speedHUDWindow=hudWindow",self.chrome)
        self.assertIn("[self.gofaSpeedHUD removeFromSuperview]",self.chrome)
        self.assertIn("self.gofaSpeedHUD.ownerWindow=nil",self.chrome)
        self.assertIn("DFSpeedHUDReadBest(&sample)",self.speed)
        self.assertIn('self.limit.text=@"—"',self.speed)
        self.assertIn("self.selectedSource=4",self.speed)
        self.assertIn("Ẩn tạm",self.speed)

    def test_ttl_and_no_fabricated_speed_limit(self):
        self.assertIn("DFSpeed::Decode",self.transport)
        self.assertIn("DFSpeed::Encode",self.transport)
        self.assertIn("notify_set_state",self.transport)
        self.assertIn("notify_get_state",self.transport)
        self.assertIn("sample.limitValid = false",self.transport)
        self.assertIn("hasLimit = sample.limitValid",self.transport)
        self.assertIn("kMaxAgeSeconds=5", (ROOT/"speed8/DFSpeedProtocol.hpp").read_text())

if __name__=="__main__":
    unittest.main()
