"""QA172 GOFA payload decoder shadow: decode in-process, publish nothing."""
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parents[1]
class TestQA172(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.probe=(ROOT/"DFGofaTrafficNavProbe166.m").read_text()
        cls.exporter=(ROOT/"DFNativeDiagnostics.m").read_text()
        cls.host_ui=(ROOT/"DFNativeHostRootController.m").read_text()
        cls.glue=(ROOT/"DFGofaBoardSource172.m").read_text()
        cls.decoder=(ROOT/"DFGofaPayloadDecoder172.swift").read_text()
        cls.build=(ROOT/"build.sh").read_text()
        cls.workflow=(REPO/".github/workflows/duoface-172-gofa-payload-decoder-shadow-signed-private.yml").read_text()
    def test_probe_unchanged_baseline(self):
        self.assertIn('NSLog(@"[DuoFaceGOFAProbe QA171] %@",line)',self.probe)
        self.assertIn("DuoFaceTrafficNav166.log",self.probe)
    def test_manual_export_includes_v1_and_v2_diagnostics(self):
        self.assertIn("DuoFaceTrafficNav166.log",self.exporter)
        self.assertIn("DF167GOFADecode(raw",self.exporter)
        self.assertIn("notify_get_state",self.exporter)
        self.assertIn("DF172_GOFA_NOTIFY_NAME",self.exporter)
        self.assertIn("DF172GOFADecode(raw172",self.exporter)
        self.assertIn("QA172 decoder shadow event=",self.exporter)
        self.assertIn("Xuất log / lỗi CarPlay",self.host_ui)
        self.assertIn("prepareShareFiles",self.host_ui)
        self.assertNotIn("URLSession",self.exporter)
        self.assertNotIn("uploadTask",self.exporter)
    def test_decoder_is_shadow_only_and_build_wires_it(self):
        self.assertIn("pushSpeedBoard",self.decoder)
        self.assertIn("pushNextBoard",self.decoder)
        self.assertIn("pushOtherBoardToCarplay",self.decoder)
        self.assertIn("Mirror",self.decoder)
        self.assertIn("decodeSpeedBoardWithUserInfo",self.glue)
        self.assertIn("DF172_GOFA_NOTIFY_NAME",self.glue)
        self.assertNotIn("DFSpeedHUDPublish",self.glue)
        self.assertIn("swiftc -emit-object",self.build)
        self.assertIn("DFGofaBoardSource172.m",self.build)
        self.assertIn("0.1.172~gofadecoder1",self.build)
    def test_ci_runs_qa172_decoder_regression(self):
        self.assertIn("test_qa172_gofa_decoder_shadow.py",self.workflow)
        self.assertIn("GOFA_REAL_ROAD_ALERTS_CONNECTED=false",self.workflow)
        self.assertIn("GOFA_REAL_NAVIGATION_TURNS_CONNECTED=false",self.workflow)
        self.assertIn("GOFA_RUNTIME_PROBE_VERIFIED=false",self.workflow)
if __name__=="__main__":
    unittest.main()
