"""QA175: touch reliability — pane-only fall-through, trailing-edge
geometry commits with retry, single-source divider visibility, surface
observer registration after guards, GOFA decoder on a serial queue.
Decoder stays shadow; bubble speed stays GPS."""
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parents[1]
class TestQA175(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.scene=(ROOT/"DFSceneHost.m").read_text()
        cls.chrome=(ROOT/"DFNative12Chrome.m").read_text()
        cls.relay=(ROOT/"DFYouTubeOrientationRelay.m").read_text()
        cls.glue=(ROOT/"DFGofaBoardSource172.m").read_text()
        cls.probe=(ROOT/"DFGofaTrafficNavProbe166.m").read_text()
        cls.trace=(ROOT/"DFDeepTrace.h").read_text()
        cls.build=(ROOT/"build.sh").read_text()
        cls.workflow=(REPO/".github/workflows/duoface-175-touch-reliability-signed-private.yml").read_text()
    def test_versions_bumped(self):
        self.assertIn("0.1.177~apptouch1", self.build)
    def test_t6_build_labels_current(self):
        self.assertIn("build=0.0.177~apptouch1", self.trace)
    def test_t1_passthrough_only_pane_windows(self):
        # the mark is set exactly once: at the pane (slot) creation site
        self.assertEqual(self.chrome.count("objc_setAssociatedObject(slotWindow, kDF173WindowMarkKey"), 1)
        self.assertNotIn("objc_setAssociatedObject(w, kDF173WindowMarkKey", self.chrome)
        self.assertIn("DF173InstallWindowPassThrough", self.chrome)
        self.assertIn("RootTouchPassThrough", self.chrome)
    def test_t2_trailing_edge_commit_with_retry(self):
        self.assertIn("kDF175GeometryDebounceSeconds", self.scene)
        self.assertIn("scheduleGeometryCommit", self.scene)
        self.assertIn("df175NoteGeometrySkip", self.scene)
        self.assertNotIn("qa173-geometry-commit-immediate", self.scene)
        self.assertNotIn("[self commitSceneGeometry:nil]", self.scene)
        self.assertIn("kDF175YTStateThrottleSeconds", self.scene)
        self.assertIn("YTRelayGuard", self.scene)
        self.assertIn("YTRelayGuard", self.relay)
        self.assertIn("df175ResetRestoringSnapshots", self.relay)
    def test_t3_single_divider_visibility(self):
        self.assertIn("df175RefreshDividerVisibility", self.chrome)
        self.assertIn("qa175-divider-visibility", self.chrome)
        self.assertEqual(self.chrome.count("dividerWindow.hidden="), 1)
        self.assertEqual(self.chrome.count("secondaryDividerWindow.hidden="), 1)
    def test_t4_observers_after_guards(self):
        start=self.scene.split("- (void)start {",1)[1].split("- (void)layoutSubviews",1)[0]
        self.assertIn("observersRegistered175", start)
        self.assertLess(start.index("if (!self.window"), start.index("observersRegistered175"))
    def test_t5_decoder_serial_queue(self):
        self.assertIn("com.duoface.gofa.decoder172", self.glue)
        self.assertIn("DF172ObserverTokens", self.glue)
        self.assertIn("com.duoface.gofa.probe166", self.probe)
        self.assertNotIn("DFSpeedHUDPublish", self.glue)
    def test_ci_runs_qa175_regression(self):
        self.assertIn("test_qa175_touch_reliability.py", self.workflow)
        self.assertIn("GOFA_REAL_ROAD_ALERTS_CONNECTED=false", self.workflow)
        self.assertIn("GOFA_REAL_NAVIGATION_TURNS_CONNECTED=false", self.workflow)
        self.assertIn("GOFA_RUNTIME_PROBE_VERIFIED=false", self.workflow)
if __name__=="__main__":
    unittest.main()
