"""QA171 GOFA runtime diagnostic export: safe schema metadata only."""
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parents[1]
class TestQA171(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.probe=(ROOT/"DFGofaTrafficNavProbe166.m").read_text()
        cls.exporter=(ROOT/"DFNativeDiagnostics.m").read_text()
        cls.host_ui=(ROOT/"DFNativeHostRootController.m").read_text()
        cls.workflow=(REPO/".github/workflows/duoface-171-gofa-runtime-diagnostics-signed-private.yml").read_text()
    def test_probe_has_syslog_fallback_and_bounded_file_writer(self):
        self.assertIn('NSLog(@"[DuoFaceGOFAProbe QA171] %@",line)',self.probe)
        self.assertIn("attributesOfItemAtPath:DF166LogFile",self.probe)
        self.assertIn("attrs[NSFileSize]",self.probe)
        self.assertIn("@try",self.probe)
        self.assertIn("@finally",self.probe)
        self.assertIn("DuoFaceTrafficNav166.log",self.probe)
    def test_manual_export_includes_gofa_diagnostics_without_auto_upload(self):
        self.assertIn("DuoFaceTrafficNav166.log",self.exporter)
        self.assertIn("DF167GOFADecode(raw",self.exporter)
        self.assertIn("notify_get_state",self.exporter)
        self.assertIn("Xuất log / lỗi CarPlay",self.host_ui)
        self.assertIn("prepareShareFiles",self.host_ui)
        self.assertNotIn("URLSession",self.exporter)
        self.assertNotIn("uploadTask",self.exporter)
    def test_ci_runs_qa171_diagnostic_regression(self):
        self.assertIn("test_qa171_gofa_diagnostics_export.py",self.workflow)
        self.assertIn("GOFA_REAL_ROAD_ALERTS_CONNECTED=false",self.workflow)
        self.assertIn("GOFA_REAL_NAVIGATION_TURNS_CONNECTED=false",self.workflow)
        self.assertIn("GOFA_RUNTIME_PROBE_VERIFIED=false",self.workflow)
if __name__=="__main__":
    unittest.main()
