"""QA167 GOFA type-only schema probe: requires original CarPlayPro static proof.
These gates cannot establish whether real GOFA notifications fire on iPhone.
"""
import json
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
REPO=ROOT.parents[1]
PROBE=ROOT/"DFGofaTrafficNavProbe166.m"
EXPORTER=ROOT/"DFNativeDiagnostics.m"
PROTOCOL=ROOT/"DF167GOFAEventProtocol.h"
ORIGINAL=REPO/"sideplay/audit/carplaypro-0.9.97/qa166-gofa-dataflow/ORIGINAL_GOFA_NOTIFICATION_NAMES.json"

class TestQA167(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.p=PROBE.read_text()
        cls.e=EXPORTER.read_text()
        cls.h=PROTOCOL.read_text()
        cls.original=json.loads(ORIGINAL.read_text())

    def test_three_original_notifications_proven_not_guessed(self):
        self.assertEqual([v["cfstring"]["text"] for v in self.original["array_members"]],
                          ["notificationNextBoard","notificationOtherBoard"])
        self.assertEqual(self.original["static_additional_notification"]["text"],
                          "notificationSpeedBoard")
        for name in ("notificationNextBoard","notificationOtherBoard",
                     "notificationSpeedBoard"):
            self.assertIn(name,self.p)
        self.assertIn("addObserverForName:name",self.p)

    def test_no_payload_or_unverified_goFA_methods_or_values(self):
        self.assertIn('com.lumi.GOFA',self.p)
        self.assertIn("objectClass=%@ payloadKeys=%lu",self.p)
        self.assertIn("keysAndTypes=%@",self.p)
        self.assertIn("property_getName",self.p)
        self.assertIn("DF167SafeKey",self.p)
        self.assertIn('@"latitude"',self.p)
        self.assertNotIn("DFSpeedHUDPublish(",self.p)
        self.assertNotIn("class_replaceMethod(",self.p)
        self.assertNotIn("method_setImplementation(",self.p)
        self.assertNotIn("requestWhenInUseAuthorization",self.p)
        self.assertNotIn("CLLocationManager new",self.p)
        self.assertNotIn("location.coordinate",self.p)
        self.assertNotIn("userInfo description",self.p)
        self.assertNotIn("object description",self.p)
        self.assertNotIn("routeName:",self.p)

    def test_transport_only_event_count_kind_age_no_private_values(self):
        self.assertIn("DF167GOFAEncode(e,&encoded)",self.p)
        self.assertIn("notify_set_state(DF167NotifyToken,encoded)",self.p)
        self.assertIn("notify_post(DF167_GOFA_NOTIFY_NAME)",self.p)
        self.assertIn("DF167GOFADecode(raw",self.e)
        self.assertIn("notify_get_state(df167Token,&raw)",self.e)
        self.assertIn("GOFA original notification received id=",self.e)
        self.assertIn("DuoFaceTrafficNav166.log",self.e)
        self.assertIn("DF167_GOFA_NOTIFY_NAME",self.h)
        self.assertIn("DF167_GOFA_MAGIC",self.h)
        self.assertIn("DF167_GOFA_VERSION",self.h)
        self.assertNotIn("latitude",self.h)
        self.assertNotIn("longitude",self.h)
        self.assertNotIn("camera",self.h)
        self.assertNotIn("direction",self.h)

if __name__=="__main__":unittest.main()
