"""QA166 source-evidence gates. This is NOT a GOFA route/alert integration test.
No notification payload, alerts or route correctness is inferred by these checks.
"""
from pathlib import Path
import unittest
import os

ROOT=Path(__file__).resolve().parents[1]
REPO=ROOT.parents[1]
PROBE=ROOT / "DFGofaTrafficNavProbe166.m"
EXPORTER=ROOT / "DFNativeDiagnostics.m"
ORIGINAL=Path(os.environ["DF166_ORIGINAL_SYMBOL_FILE"]) if "DF166_ORIGINAL_SYMBOL_FILE" in os.environ else (REPO / "sideplay/audit/carplaypro-0.9.97/macho/007-SpeedAlerts.dylib-arm64.section-strings.json")
import json

class TestTrafficNavEvidence166(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.probe=PROBE.read_text()
        cls.exporter=EXPORTER.read_text()
        cls.original=json.loads(ORIGINAL.read_text())
        cls.all_original=set(cls.original["__cstring"]+cls.original["__objc_methname"])

    def test_probe_only_uses_observed_original_identifiers(self):
        for symbol in ("notificationSpeedBoard","notificationNextBoard",
                       "notificationOtherBoard","pushOtherBoardToCarplay",
                       "currentAllowSpeed","flutterDirection",
                       "GOFA.SpeedBoardModel","GOFA.DatapointModel"):
            self.assertIn(symbol,self.all_original)
        for sym in ("notificationSpeedBoard","notificationNextBoard",
                    "notificationOtherBoard","currentAllowSpeed",
                    "flutterDirection"):
            self.assertIn(sym,self.probe)

    def test_no_unverified_payload_decoding_or_unwanted_mutation(self):
        self.assertIn("com.lumi.GOFA",self.probe)
        self.assertIn("objc_copyClassList",self.probe)
        self.assertIn("method_getTypeEncoding",self.probe)
        self.assertIn("addObserverForName:name",self.probe)
        self.assertNotIn("method_setImplementation(",self.probe)
        self.assertNotIn("class_replaceMethod(",self.probe)
        self.assertNotIn("performSelector:",self.probe)
        self.assertNotIn("requestWhenInUseAuthorization",self.probe)
        self.assertNotIn("CLLocationManager new",self.probe)
        self.assertNotIn("DFSpeedHUDPublish(",self.probe)
        self.assertNotIn("navigationSample=",self.probe)

    def test_manual_export_without_private_coordinates(self):
        self.assertIn("DuoFaceTrafficNav166.log",self.exporter)
        self.assertIn("DuoFaceTrafficNav166.log",self.probe)
        self.assertIn("payloadKeys=%lu",self.probe)
        self.assertNotIn("note.userInfo description",self.probe)
        self.assertNotIn("location.coordinate",self.probe)

if __name__=="__main__":
    unittest.main()
