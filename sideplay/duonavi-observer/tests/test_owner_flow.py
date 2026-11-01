import importlib.util
import json
import unittest
from pathlib import Path

source = Path(__file__).resolve().parents[1] / "analyze_owner_flow.py"
spec = importlib.util.spec_from_file_location("owner", source)
owner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(owner)


class OwnerEvidenceTests(unittest.TestCase):
    def test_no_old_or_invalid_record_qualifies(self):
        for txt in ("", '{"observer_version":"0.0.3~homeflow1"}',
                    "=== header ===\n{garbled}"):
            r = owner.analyze(txt)
            self.assertEqual(r["records"], 0)
            self.assertTrue(all(r["missing"].values()))

    def test_rotated_order_and_real_factory_result(self):
        rows = [
            {"event":"home_flow_call","observer_version":owner.VERSION,
             "process":"SpringBoard","pid":13,"run":"A","call":8,"utc":11.0,
             "selector":"appForBundleIdentifier:frame:","phase":"factory-return",
             "factoryResult":"CBBridgedUIApp:0x123"},
            {"event":"home_flow_call","observer_version":owner.VERSION,
             "process":"SpringBoard","pid":13,"run":"A","call":8,"utc":10.0,
             "selector":"appForBundleIdentifier:frame:","phase":"enter",
             "argument":{"string":"com.google.ios.youtube"},"frame":"{{0,0},{640,320}}"},
            {"event":"home_flow_call","observer_version":owner.VERSION,
             "process":"SpringBoard","pid":13,"run":"A","call":20,"utc":11.1,
             "selector":"notifyStateUpdated","phase":"enter",
             "snapshot":{"bridge_owner":{"status":"runtime-manager-getters",
                          "manager":"CBBridgeManager:0x55",
                          "currentApp":"CBBridgedUIApp:0x123",
                          "bridgeWindow":"CBWindow:0x33"}}},
            {"event":"home_flow_call","observer_version":owner.VERSION,
             "process":"SpringBoard","pid":13,"run":"A","call":21,"utc":11.3,
             "selector":"showAppPickerForSlot:","phase":"enter","slotIndex":-1},
            {"event":"home_flow_call","observer_version":owner.VERSION,
             "process":"CarPlay","pid":14,"run":"B","call":45,"utc":14.0,
             "selector":"homeButtonUp:","phase":"return"},
            {"event":"home_flow_call","observer_version":owner.VERSION,
             "process":"CarPlay","pid":14,"run":"B","call":45,"utc":13.9,
             "selector":"homeButtonUp:","phase":"enter",
             "snapshot":{"activeBundle":"com.apple.CarPlay.dashboard"}},
            {"event":"manual_mark","stage":"RESULT_APP_CHOOSER","utc":14.7},
        ]
        report = owner.analyze("\n".join(json.dumps(x) for x in rows))
        self.assertEqual(report["observed_factory_return_classes"], {"CBBridgedUIApp":1})
        self.assertFalse(any(report["missing"].values()))
        self.assertEqual(report["home_enter_return_pairs"][0]["enter_line"], 6)
        self.assertEqual(report["home_enter_return_pairs"][0]["return_line"], 5)
        self.assertEqual(report["method_events"][0]["phase"], "enter")
        self.assertEqual(report["method_events"][1]["phase"], "factory-return")
        self.assertEqual(report["manual_outcome_markers"][0]["stage"], "RESULT_APP_CHOOSER")

    def test_unknown_destination_remains_unknown(self):
        r = owner.analyze(json.dumps({"event":"home_flow_call",
             "observer_version":owner.VERSION,"selector":"showAppPickerForSlot:",
             "phase":"enter","slotIndex":0,"utc":1.0}))
        self.assertFalse(r["missing"]["picker_method_invocation"])
        self.assertTrue(r["missing"]["visual_home_destination_marker"])
        self.assertTrue(r["missing"]["original_factory_return_class"])


if __name__ == "__main__":
    unittest.main()
