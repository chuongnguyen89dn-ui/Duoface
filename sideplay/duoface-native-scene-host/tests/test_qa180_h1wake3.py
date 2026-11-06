"""QA180 h1wake3 contract: Darwin hidden/shown/query instead of unreadable controls plist.

Static only. Real on-car H1 and keyboard behavior requires a QA180 device log.
"""
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
HEADER = ROOT / "DFAppTouch177.h"
HOST = ROOT / "DFH1Wake188.m"
NAMES = ("com.duoface.controls188.hidden",
         "com.duoface.controls188.shown",
         "com.duoface.controls188.query")

class QA180H1Wake3(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.app = HEADER.read_text()
        cls.host = HOST.read_text()

    def test_three_notifications_both_sides_no_host_keyboard_dict(self):
        for name in NAMES:
            self.assertIn(name, self.app)
            self.assertIn(name, self.host)
        self.assertNotIn("KbByBundle188", self.app + self.host)

    def test_gate_never_reads_controls_plist(self):
        gate = self.app.split("static void DF177SendEventHook(", 1)[1].split(
            "// Installs the sendEvent:", 1)[0]
        self.assertNotIn("DF188RefreshControlsHidden", self.app)
        self.assertNotIn("dictionaryWithContentsOfFile:", gate)
        self.assertNotIn("DF177KbComputeVisible(", gate)
        self.assertRegex(gate, r"DF188ControlsHiddenKnown\s*&&\s*DF188ControlsHidden\s*&&\s*!DF188KbSessionVisible")
        self.assertIn("DF177AppTouchNoteBeganExWithGate(DF177TouchBundle, YES, gateAtDecision);",gate)
        self.assertIn("return; // consumed: the original never receives this event",gate)
        self.assertIn("DF177AppTouchNoteBeganExWithGate(DF177TouchBundle, NO, gateAtDecision);",gate)
        self.assertIn("if (hasBegan) gateAtDecision = DF188GateAtDecision();",gate)
        self.assertLess(gate.index("gateAtDecision = DF188GateAtDecision()"),
                        gate.index("DF177SendEventOriginal)("))

    def test_relay_receivers_and_initial_one_time_query(self):
        self.assertIn("static BOOL DF188ControlsHidden = NO;",self.app)
        self.assertIn("static BOOL DF188ControlsHiddenKnown = NO;",self.app)
        install=self.app.split("static inline void DF177InstallAppTouchHook(",1)[1]
        self.assertIn("notify_register_dispatch(DF188ControlsHiddenName",install)
        self.assertIn("notify_register_dispatch(DF188ControlsShownName",install)
        hidden=install.split("notify_register_dispatch(DF188ControlsHiddenName",1)[1].split(
            "notify_register_dispatch(DF188ControlsShownName",1)[0]
        shown=install.split("notify_register_dispatch(DF188ControlsShownName",1)[1].split(
            "notify_post(DF188ControlsQueryName)",1)[0]
        self.assertIn("DF188ControlsHidden = YES;",hidden)
        self.assertIn("DF188ControlsHiddenKnown = YES;",hidden)
        self.assertIn("DF188ControlsHidden = NO;",shown)
        self.assertIn("DF188ControlsHiddenKnown = YES;",shown)
        self.assertEqual(install.count("notify_post(DF188ControlsQueryName)"),1)
        self.assertLess(install.index("notify_register_dispatch(DF188ControlsShownName"),
                        install.index("notify_post(DF188ControlsQueryName)"))

    def test_host_legacy_plist_preserved_query_answers_current_state(self):
        publish=self.host.split("static void DF188PublishHidden(",1)[1].split(
            "static void DF188HandleAppTouch(",1)[0]
        self.assertIn("[p writeToFile:DF177TouchPrefsPath atomically:YES]",publish)
        self.assertIn("notify_post(DF188ControlsStateName)",publish)
        self.assertIn("notify_post(hidden ? DF188ControlsHiddenName : DF188ControlsShownName)",publish)
        self.assertIn("qa188-h1-controls-state hidden=%d",publish)
        start=self.host.split("static BOOL DF188Start(",1)[1].split(
            "static void (*DF188OrigStop)",1)[0]
        self.assertIn("notify_register_dispatch(DF188ControlsQueryName",start)
        self.assertIn("DF188PublishHidden(owner, YES)",start)
        self.assertIn("DF188PublishHidden(self, YES)",start)
        self.assertIn("notify_cancel(DF188QueryToken)",self.host)

    def test_normal_and_swallowed_records_include_gate_and_host_logs_it(self):
        sender=self.app.split("static inline void DF177AppTouchNoteBeganExWithGate(",1)[1].split(
            "static inline void DF177AppTouchNoteBeganEx(",1)[0]
        snap=self.app.split("static inline NSString *DF188GateAtDecision(",1)[1].split(
            "static inline void DF177AppTouchNoteBeganExWithGate(",1)[0]
        for name in ('@"known=%d hidden=%d kb=%d"',
                     '(int)DF188ControlsHiddenKnown','(int)DF188ControlsHidden',
                     '(int)DF188KbSessionVisible'):
            self.assertIn(name,snap)
        self.assertIn('@"gate": decisionGate ?: DF188GateAtDecision()',sender)
        self.assertIn('@"swallowed": @(swallowed)',sender)
        self.assertIn("DF177AppTouchNoteBeganEx(bundle, NO)",self.app)
        self.assertIn("DF177AppTouchNoteBeganExWithGate(DF177TouchBundle, YES, gateAtDecision)",self.app)
        self.assertIn("DF177AppTouchNoteBeganExWithGate(DF177TouchBundle, NO, gateAtDecision)",self.app)
        self.assertIn('rec[@"gate"]',self.host)
        self.assertIn("swallowed=%d gate=%@",self.host)

    def test_qa179_keyboard_and_df156_unmodified(self):
        self.assertIn("UIKeyboardWillShowNotification",self.app)
        self.assertIn("UIKeyboardWillHideNotification",self.app)
        self.assertIn("CGRectGetMinY(frame) > 0.0",self.app)
        self.assertIn("DF177KbSetVisible(DF177KbComputeVisible());",self.app)
        self.assertIn("notify_post(DF177KbWakeName)",self.app)
        self.assertNotIn("DF177KbWakeName",self.host)
        for name,install in (("DF154GeneralAppStateRelay.m","DF177InstallAppTouchHook(bundle)"),
                             ("DFYouTubeOrientationRelay.m","DF177InstallAppTouchHook(DFYTBundle)")):
            self.assertIn(install,(ROOT/name).read_text())

    def test_exact_qa180_versions(self):
        integrated=(ROOT.parent/"jb-embedded-appbridge/package_integrated.py").read_text()
        self.assertIn('VERSION="0.0.182~b1nativemaps1"',integrated)
        self.assertIn("0.1.182~b1nativemaps1",(ROOT/"build.sh").read_text())
        self.assertIn("Version: 0.1.182~b1nativemaps1",(ROOT/"control").read_text())
        self.assertIn("<key>CFBundleVersion</key><string>182</string>",(ROOT/"Info.plist").read_text())
        for name in ("DFDeepTrace.h","DFTouchOwnerProbe.m"):
            self.assertIn("0.0.182~b1nativemaps1",(ROOT/name).read_text())

if __name__=="__main__":
    unittest.main()
