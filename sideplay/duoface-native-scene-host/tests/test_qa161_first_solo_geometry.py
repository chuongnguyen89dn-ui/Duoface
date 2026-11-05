"""QA161 contract only: no physical first-pixel or touch-readiness claim."""
from pathlib import Path
import unittest,hashlib
from native_map_host_guard import without_native_map_guard
ROOT=Path(__file__).resolve().parents[1]
HOST=without_native_map_guard((ROOT/"DFSceneHost.m").read_bytes())
SOLO=(ROOT/"DFHomeStandalone144.m").read_text()
BUILD=(ROOT/"build.sh").read_text()
PACK=(ROOT.parents[0]/"jb-embedded-appbridge"/"package_integrated.py").read_text()

class QA161SoloInitialReference(unittest.TestCase):
 def test_reviewed_source_only(self):
  actual=hashlib.sha1(b"blob "+str(len(HOST)).encode()+b"\0"+HOST).hexdigest()
  self.assertEqual(actual,"6a3c073f9d7502d588eb441d4ecb6c546c3f09f8")
  host=HOST.decode("utf-8")
  self.assertIn("quickSoloInitialGeometry=self.fastInitialPolling &&",host)
  self.assertIn("CGSizeEqualToSize(self.committedReferenceSize,CGSizeZero)",host)
  self.assertIn("![self.bundleID isEqual:DFYTBundle]",host)
  self.assertIn('![self.bundleID isEqual:@"com.lumi.GOFA"]',host)
  self.assertIn("geometryWait=quickSoloInitialGeometry?0.12:0.30",host)
  self.assertIn("qa161-solo-first-reference-120ms",host)
  self.assertIn("if (self.stopped || self.committingSceneGeometry || !self.window || !self.appController ||",host)
  self.assertIn("!self.ready) return;",host)
  self.assertIn("if (!self.scene || observedScene!=self.scene || !hosting || !attached)",host)
 def test_solo_opt_in_only_and_distinct_package(self):
  self.assertIn("setFastInitialPolling:YES forHostedView:",SOLO)
  self.assertIn("0.1.172~wakefix3",BUILD)
  self.assertIn('VERSION="0.0.172~wakefix3"',PACK)
 def test_read_only_home_and_nonmedia_regressions(self):
  self.assertIn("qa160-native-home-page-snapshot-not-pixel",SOLO)
  self.assertIn("qa160-native-grid-icon-pressed",SOLO)
  self.assertNotIn("setDisplayState:1",SOLO)

if __name__=="__main__":unittest.main()
