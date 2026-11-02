"""QA161 contract only: no physical first-pixel or touch-readiness claim."""
from pathlib import Path
import unittest,hashlib
ROOT=Path(__file__).resolve().parents[1]
HOST=(ROOT/"DFSceneHost.m").read_bytes()
SOLO=(ROOT/"DFHomeStandalone144.m").read_text()
BUILD=(ROOT/"build.sh").read_text()
PACK=(ROOT.parents[0]/"jb-embedded-appbridge"/"package_integrated.py").read_text()

class QA161SoloInitialReference(unittest.TestCase):
 def test_reviewed_source_only(self):
  actual=hashlib.sha1(b"blob "+str(len(HOST)).encode()+b"\0"+HOST).hexdigest()
  self.assertEqual(actual,"2686c4531e480831af3db445fe5f3d7e9d7ded5d")  # QA173-reviewed source supersedes the QA161 pin
  host=HOST.decode("utf-8")
  self.assertIn("quickSoloInitialGeometry=self.fastInitialPolling &&",host)
  self.assertIn("CGSizeEqualToSize(self.committedReferenceSize,CGSizeZero)",host)
  self.assertIn("![self.bundleID isEqual:DFYTBundle]",host)
  self.assertIn('![self.bundleID isEqual:@"com.lumi.GOFA"]',host)
  self.assertNotIn("geometryWait",host)  # QA173: no deferred geometry timer
  self.assertIn("qa173-solo-first-reference-immediate",host)
  self.assertIn("qa173-geometry-commit-immediate",host)
  self.assertIn("[self commitSceneGeometry:nil]",host)
  self.assertIn("if (self.stopped || self.committingSceneGeometry || !self.window || !self.appController ||",host)
  self.assertIn("!self.ready) return;",host)
  self.assertIn("if (!self.scene || observedScene!=self.scene || !hosting || !attached)",host)
 def test_solo_opt_in_only_and_distinct_package(self):
  self.assertIn("setFastInitialPolling:YES forHostedView:",SOLO)
  self.assertIn("0.1.174~auditfix1",BUILD)
  self.assertIn('VERSION="0.0.174~auditfix1"',PACK)
 def test_read_only_home_and_nonmedia_regressions(self):
  self.assertIn("qa160-native-home-page-snapshot-not-pixel",SOLO)
  self.assertIn("qa160-native-grid-icon-pressed",SOLO)
  self.assertNotIn("setDisplayState:1",SOLO)

if __name__=="__main__":unittest.main()
