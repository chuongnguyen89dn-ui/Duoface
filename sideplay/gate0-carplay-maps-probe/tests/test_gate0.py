"""Gate0 offline policy and non-mutating instrumentation contract."""
from __future__ import annotations

import importlib.util
import json
import pathlib
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("gate0_analyze", ROOT / "analyze_gate0.py")
mod = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(mod)


def row(mode="UNKNOWN", status="UNVERIFIED", event="native.scene.snapshot", t=1000, **overrides):
    payload = {
        "version": 1, "bundle": "com.google.Maps", "run": "test-run",
        "event": event, "seq": int(t), "wall": float(t),
        "stockSettings": mode, "stockSourceStatus": status,
        "stockSource": "IOS16.7.16:VERIFIED_RUNTIME_READER",
        "stockProfileDigest": "abcdef1234567890", "stockProfileMatch": True,
        "stockSampleWall": t - .1, "stockAgeMs": 100,
        "scenes": [{
            "controller": "DBApplicationSceneViewController",
            "sceneClass": "FBScene",
            "sceneID": "Car[2-3]:com.apple.CarPlayTemplateUIHost:com.google.Maps",
            "windowRole": "UIWindowSceneSessionRoleCarPlay",
            "external": True,
        }],
    }
    payload.update(overrides)
    return payload


class Gate0Tests(unittest.TestCase):
    def test_unknown_gate_always_fails_closed(self):
        records = [row(), row(event="presentBase.original-returned")]
        result = mod.analyze(records)
        self.assertEqual(result["gate0Status"], "MEASUREMENT_BLOCKED")
        self.assertEqual(result["eligibleRecords"], 0)
        self.assertFalse(result["hardwareNativeMapsInDuoFaceAccepted"])

    def test_fake_manual_label_cannot_verify(self):
        r = row("OFF", "UNVERIFIED", stockCalibrated=True, stockCalibrationSource="manual")
        self.assertFalse(mod.eligible(r))
        self.assertFalse(mod.calibration_verified([r]))

    def test_stale_wrong_vehicle_conflicting_and_guessed_source_rejected(self):
        base = row("OFF", "VERIFIED")
        self.assertTrue(mod.eligible(base))
        for overrides in (
            {"stockAgeMs": 2001},
            {"stockSourceStatus": "STALE"},
            {"stockSourceStatus": "CONFLICT"},
            {"stockProfileMatch": False},
            {"stockSource": "UNVALIDATED_CARPLAY_ICONSTATE_CANDIDATES"},
            {"stockSource": ""},
            {"stockProfileDigest": None},
            {"stockSampleWall": 1001},
            {"stockSampleWall": 997},
            {"stockAgeMs": -1},
            {"stockSettings": "unknown"},
            {"bundle": "com.waze.iphone"},
        ):
            with self.subTest(overrides=overrides):
                self.assertFalse(mod.eligible({**base, **overrides}))

    def test_on_off_on_must_be_calibrated_same_source_same_car(self):
        calibration = [
            row(mode, "VERIFIED", event="stock.calibration",
                t=1000 + index, stockCalibrated=True,
                stockCalibrationSource="iOS-Customize-UI+OS-reader")
            for index, mode in enumerate(("ON", "OFF", "ON"))
        ]
        self.assertTrue(mod.calibration_verified(calibration))
        wrong = [dict(r) for r in calibration]
        wrong[1]["stockProfileDigest"] = "different-car-id-digest"
        self.assertFalse(mod.calibration_verified(wrong))
        wrong = [dict(r) for r in calibration]
        wrong[2]["stockSource"] = "DIFFERENT_OS_READER"
        self.assertFalse(mod.calibration_verified(wrong))
        wrong = [dict(r) for r in calibration]
        wrong[0]["stockCalibrationSource"] = "human-only"
        self.assertFalse(mod.calibration_verified(wrong))

    def test_scene_observation_does_not_use_phone_scene(self):
        valid = row("OFF", "VERIFIED")
        self.assertTrue(mod.native_scene_in_record(valid))
        invalid = dict(valid)
        invalid["scenes"] = [{**valid["scenes"][0], "sceneID": "sceneID:com.google.Maps-default",
                              "windowRole": "UIWindowSceneSessionRoleApplication"}]
        self.assertFalse(mod.native_scene_in_record(invalid))
        invalid = dict(valid)
        invalid["scenes"] = [{**valid["scenes"][0], "external": False}]
        self.assertFalse(mod.native_scene_in_record(invalid))

    def test_calibrated_on_off_proves_only_scene_observation(self):
        r = [row(mode, "VERIFIED", event="stock.calibration", t=1000 + i,
                 stockCalibrated=True, stockCalibrationSource="iOS-Customize-UI+OS-reader")
             for i, mode in enumerate(("ON", "OFF", "ON"))]
        r += [row("ON", "VERIFIED", t=1005), row("OFF", "VERIFIED", t=1006)]
        result = mod.analyze(r)
        self.assertEqual(result["gate0Status"], "CALIBRATED_ON_OFF_NATIVE_SCENE_OBSERVATIONS_AVAILABLE")
        self.assertTrue(result["perSourceAndVehicleRuns"][0]["offNativeSceneObserved"])
        self.assertFalse(result["hardwareNativeMapsInDuoFaceAccepted"])

    def test_absent_native_scene_is_not_proof_native_scene_impossible(self):
        r = [row(mode, "VERIFIED", event="stock.calibration", t=1000 + i,
                 stockCalibrated=True, stockCalibrationSource="iOS-Customize-UI+OS-reader")
             for i, mode in enumerate(("ON", "OFF", "ON"))]
        r.extend([row("ON", "VERIFIED", t=1005),
                  row("OFF", "VERIFIED", t=1006, scenes=[])])
        result = mod.analyze(r)
        self.assertEqual(result["gate0Status"], "CALIBRATED_ON_OFF_NATIVE_SCENE_OBSERVATIONS_AVAILABLE")
        self.assertFalse(result["perSourceAndVehicleRuns"][0]["offNativeSceneObserved"])
        self.assertIn("NOT_OBSERVED_IS_NOT_PROOF", result["perSourceAndVehicleRuns"][0]["modes"]["OFF"]["absenceInterpretation"])

    def test_corrupted_jsonl_is_reported_not_accepted(self):
        with tempfile.TemporaryDirectory() as d:
            path = pathlib.Path(d) / "gate0.jsonl"
            path.write_text(json.dumps(row()) + "\n{not-json}\n", encoding="utf-8")
            values, errors = mod.read_jsonl([str(path)])
            self.assertEqual(len(values), 1)
            self.assertEqual(len(errors), 1)
            self.assertEqual(mod.analyze(values, errors)["gate0Status"], "MEASUREMENT_BLOCKED")

    def test_gate0_audit_mirror_and_window_provenance_regression(self):
        src = (ROOT / "DFGate0CarPlayProbe.m").read_text()
        build = (ROOT / "build_private_probe.sh").read_text()
        flow = (ROOT.parents[1] / ".github/workflows/duoface-gate0-onoff-readonly-signed.yml").read_text()
        # Compiled Objective-C newline escape must be ONE slash, not a literal "\\n".
        self.assertIn(r'area=gate0 %@\n",', src)
        self.assertNotIn(r'area=gate0 %@\\n",', src)
        self.assertIn("auditMirrorWrite", src)
        self.assertIn("O_WRONLY|O_CREAT|O_APPEND|O_CLOEXEC", src)
        self.assertIn("DFG0CandidateSnapshot=DFG0ReadCandidates();", src)
        emitter = src.split("static void DFG0Emit(", 1)[1].split("static void DFG0ABI(", 1)[0]
        self.assertNotIn("DFG0ReadCandidates()", emitter)
        self.assertIn('@"candidateSampleWall"', emitter)
        self.assertIn('@"stockSampleWall":@0', emitter)
        self.assertIn("DFG0LastNativeMapsVC=vc;", src)
        self.assertIn("DFG0VCReadback(DFG0LastNativeMapsVC)", src)
        self.assertNotIn("if(ws.screen==UIScreen.mainScreen)continue;", src)
        self.assertIn('@"carplayRoleWindowCount"', src)
        self.assertIn('@"screenExternalByComparison"', src)
        self.assertIn("0.0.2~gate0audit2", build)
        self.assertIn("0.0.2~gate0audit2", flow)
        self.assertIn("0.0.2~gate0audit2", src)

    def test_first_party_probe_is_diagnostic_only(self):
        src = (ROOT / "DFGate0CarPlayProbe.m").read_text()
        inject = (ROOT / "DFGate0CarPlayProbe.plist").read_text()
        self.assertIn('@"stockSettings":@"UNKNOWN"', src)
        self.assertIn('@"stockSourceStatus":@"UNVERIFIED"', src)
        self.assertIn('DFG0OriginalPresent(owner,cmd,vc,animated,source,completion);', src)
        self.assertIn('objc_copyClassList', src)
        self.assertIn('objc_getClass("DBDashboardRootViewController")', src)
        self.assertIn('CarPlayApp', inject)
        self.assertIn('Preferences', inject)
        self.assertNotIn('SpringBoard', inject)
        pack = (ROOT / "build_private_probe.sh").read_text()
        self.assertIn('chmod 0755 "$STAGING"', pack)
        self.assertIn('Depends: firmware (>= 16.0), mobilesubstrate', pack)
        for forbidden in (
            "setCarPlayDeclaration:", "setFrame:", "setSceneSize:",
            "hostViewForBundleID:", "requestStateChange:", "setLaunchAsCarApplication:",
            "CFPreferencesSetAppValue", "setHiddenBundleIdentifiers:",
            "MSHookFunction", "BKSDisplayServicesSetScreenBlanked",
        ):
            self.assertNotIn(forbidden, src)


if __name__ == "__main__":
    unittest.main()
