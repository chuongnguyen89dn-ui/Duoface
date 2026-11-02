"""QA174: audit fix only - diagnostic build labels must name the real build.
Carries the QA173 contracts forward unchanged."""
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parents[1]
class TestQA174(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.trace=(ROOT/"DFDeepTrace.h").read_text()
        cls.probe=(ROOT/"DFTouchOwnerProbe.m").read_text()
        cls.scene=(ROOT/"DFSceneHost.m").read_text()
        cls.chrome=(ROOT/"DFNative12Chrome.m").read_text()
        cls.guard=(ROOT/"DFLogGuard173.h").read_text()
        cls.glue=(ROOT/"DFGofaBoardSource172.m").read_text()
        cls.build=(ROOT/"build.sh").read_text()
        cls.workflow=(REPO/".github/workflows/duoface-174-audit-fix-signed-private.yml").read_text()
    def test_versions_bumped(self):
        self.assertIn("0.1.174~auditfix1", self.build)
    def test_build_labels_current(self):
        self.assertIn("build=0.0.174~auditfix1", self.trace)
        self.assertIn("build=0.0.174~auditfix1", self.probe)
        self.assertNotIn("build=0.0.90~nativegetters1", self.trace)
        self.assertNotIn("build=0.0.86~nativeowner1", self.probe)
    def test_qa173_contracts_carried(self):
        self.assertIn("qa173-geometry-commit-immediate", self.scene)
        self.assertIn("[self commitSceneGeometry:nil]", self.scene)
        self.assertIn("RootTouchPassThrough", self.chrome)
        self.assertIn("DFLogWriteCapped173", self.guard)
        self.assertNotIn("DFSpeedHUDPublish", self.glue)
    def test_ci_runs_qa174_regression(self):
        self.assertIn("test_qa174_audit_fix.py", self.workflow)
        self.assertIn("GOFA_REAL_ROAD_ALERTS_CONNECTED=false", self.workflow)
        self.assertIn("GOFA_REAL_NAVIGATION_TURNS_CONNECTED=false", self.workflow)
        self.assertIn("GOFA_RUNTIME_PROBE_VERIFIED=false", self.workflow)
if __name__=="__main__":
    unittest.main()
