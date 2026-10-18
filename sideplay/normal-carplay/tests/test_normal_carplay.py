#!/usr/bin/env python3
"""Static regression checks for the SidePlay dock-on normal mode preset."""
import importlib.util
import plistlib
import tempfile
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).resolve().parents[1] / "tools/prepare_normal_mode.py"
spec = importlib.util.spec_from_file_location("prepare_normal_mode", MODULE_PATH)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


class NormalCarPlayDockTests(unittest.TestCase):
    def test_only_change_is_existing_car_dock_default(self):
        evidence = mod.verify_candidate()
        self.assertFalse(evidence["original_default"])
        self.assertTrue(evidence["candidate_default"])
        self.assertTrue(evidence["other_preference_rows_unchanged"])

    def test_existing_user_preferences_preserved(self):
        with tempfile.TemporaryDirectory() as t:
            root = Path(t)
            original = root / "com.sideplay-original.plist"
            candidate = root / "com.sideplay-normal.plist"
            values = {"carDock": False, "restoreLast": False,
                      "carZoom": 93.5, "autoHideBar": False, "autoOpen": False}
            with original.open("wb") as f:
                plistlib.dump(values, f)
            mod.build_prefs(original, candidate)
            result = mod.load(candidate)
            self.assertEqual(result, {**values, "carDock": True})
            self.assertEqual(mod.load(original), values)

    def test_cannot_write_over_input(self):
        with tempfile.TemporaryDirectory() as t:
            p = Path(t) / "com.sideplay.plist"
            with p.open("wb") as f:
                plistlib.dump({"carDock": False}, f)
            with self.assertRaises(ValueError):
                mod.build_prefs(p, p)

    def test_stock_panel_data_kept_byte_unmodified_in_repo(self):
        stock = mod.load(mod.STOCK)
        self.assertEqual(mod.row_by_key(stock, "carDock")["label"], "Thanh dock CarPlay")
        self.assertTrue(mod.row_by_key(stock, "autoFitCar")["default"])


if __name__ == "__main__":
    unittest.main()
