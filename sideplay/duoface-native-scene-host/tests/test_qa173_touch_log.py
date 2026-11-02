"""QA173: log reduction + same-pass scene geometry + root touch pass-through.
The QA172 GOFA decoder stays in shadow mode; bubble speed stays GPS."""
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parents[1]
class TestQA173(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.scene=(ROOT/"DFSceneHost.m").read_text()
        cls.chrome=(ROOT/"DFNative12Chrome.m").read_text()
        cls.probe=(ROOT/"DFTouchOwnerProbe.m").read_text()
        cls.trace=(ROOT/"DFDeepTrace.h").read_text()
        cls.guard=(ROOT/"DFLogGuard173.h").read_text()
        cls.exporter=(ROOT/"DFNativeDiagnostics.m").read_text()
        cls.glue=(ROOT/"DFGofaBoardSource172.m").read_text()
        cls.decoder=(ROOT/"DFGofaPayloadDecoder172.swift").read_text()
        cls.build=(ROOT/"build.sh").read_text()
        cls.workflow=(REPO/".github/workflows/duoface-175-touch-reliability-signed-private.yml").read_text()
    def test_versions_bumped(self):
        self.assertIn("0.1.175~touchfix1", self.build)
    def test_log_reduction_guards(self):
        self.assertIn("DFLogWriteCapped173", self.guard)
        self.assertIn("256 * 1024", self.guard)
        self.assertIn("DFLogWriteCapped173", self.scene)
        self.assertIn("DFLogWriteCapped173", self.chrome)
        self.assertIn("DFLogWriteCapped173", self.probe)
        self.assertIn("256*1024", self.trace)
        self.assertIn("lastKey", self.trace)
        self.assertIn("lastLoggedResizeSize", self.scene)
    def test_export_diagnostics_kept(self):
        self.assertIn("DF172_GOFA_NOTIFY_NAME", self.exporter)
        self.assertIn("QA172 decoder shadow event=", self.exporter)
        self.assertIn("DuoFaceTrafficNav166.log", self.exporter)
    def test_geometry_commits_trailing_edge_qa175(self):
        # QA175 supersedes the QA173 same-pass commit (drag jank,
        # one-shot skips): trailing-edge scheduling with retry.
        self.assertIn("scheduleGeometryCommit", self.scene)
        self.assertIn("kDF175GeometryDebounceSeconds", self.scene)
        self.assertNotIn("qa173-geometry-commit-immediate", self.scene)
        self.assertNotIn("[self commitSceneGeometry:nil]", self.scene)
        self.assertNotIn("geometryWait", self.scene)
    def test_root_touch_passthrough_flagged(self):
        self.assertIn("RootTouchPassThrough", self.chrome)
        self.assertIn("com.duoface.nativehost.qa173.plist", self.chrome)
        self.assertIn("DF173InstallWindowPassThrough", self.chrome)
        self.assertIn("qa173-root-touch-passthrough installed", self.chrome)
    def test_decoder_still_shadow_only(self):
        self.assertIn("pushSpeedBoard", self.decoder)
        self.assertIn("decodeSpeedBoardWithUserInfo", self.glue)
        self.assertNotIn("DFSpeedHUDPublish", self.glue)
    def test_ci_runs_qa173_regression(self):
        self.assertIn("test_qa174_audit_fix.py", self.workflow)
        self.assertIn("GOFA_REAL_ROAD_ALERTS_CONNECTED=false", self.workflow)
        self.assertIn("GOFA_REAL_NAVIGATION_TURNS_CONNECTED=false", self.workflow)
        self.assertIn("GOFA_RUNTIME_PROBE_VERIFIED=false", self.workflow)
if __name__=="__main__":
    unittest.main()
