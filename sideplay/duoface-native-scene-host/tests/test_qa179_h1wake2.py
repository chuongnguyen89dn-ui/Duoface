"""QA179 h1wake2 app-process keyboard-session swallow contract, static only.

The legacy DF156 keyboard reports remain untouched and are not the H1 gate.
Physical CarPlay/keyboard acceptance is not established by this test.
"""
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
HEADER = ROOT / "DFAppTouch177.h"

class QA179H1Wake2(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.h = HEADER.read_text()

    def test_gate_consumes_only_app_session_state_not_keyboard_window_scan(self):
        gate = self.h.split("static void DF177SendEventHook(", 1)[1].split(
            "// Installs the sendEvent:", 1)[0]
        self.assertNotIn("DF177KbComputeVisible(", gate)
        self.assertRegex(gate, r"DF188ControlsHiddenKnown\s*&&\s*DF188ControlsHidden\s*&&\s*!DF188KbSessionVisible")
        self.assertNotIn("DF188RefreshControlsHidden();", gate)
        self.assertIn("DF177AppTouchNoteBeganExWithGate(DF177TouchBundle, YES, gateAtDecision);", gate)
        self.assertIn("return; // consumed: the original never receives this event", gate)

    def test_keyboard_session_show_and_hide_notifications(self):
        install = self.h.split("static inline void DF177InstallAppTouchHook(", 1)[1]
        self.assertIn("addObserverForName:UIKeyboardWillShowNotification", install)
        self.assertIn("addObserverForName:UIKeyboardWillHideNotification", install)
        self.assertRegex(install, r"UIKeyboardWillShowNotification[\s\S]*?DF188KbSessionVisible\s*=\s*YES")
        self.assertRegex(install, r"UIKeyboardWillHideNotification[\s\S]*?DF188KbSessionVisible\s*=\s*NO")
        self.assertIn("DF188KbSessionVisible = DF188InitialKeyboardSessionVisible();", install)

    def test_initial_keyboard_scan_rejects_parked_full_screen(self):
        scan = self.h.split("static inline BOOL DF188KeyboardWindowHasActiveFrame(", 1)[1].split(
            "static inline BOOL DF188InitialKeyboardSessionVisible(", 1)[0]
        self.assertIn("DF177IsKeyboardWindow(window)", scan)
        self.assertIn("window.hidden", scan)
        self.assertIn("CGRectGetMinY(frame) > 0.0", scan)
        self.assertIn("CGRectGetHeight(frame) > 0.0", scan)
        self.assertIn("CGRectGetMaxY(frame) - CGRectGetMaxY(screen)", scan)
        self.assertIn("<= 2.0", scan)
        for x, y, width, height, screen_bottom, expected in (
            (0, 0, 382, 480, 480, False),
            (0, 0, 414, 736, 736, False),
            (0, 476, 414, 260, 736, True),
            (0, 470, 414, 260, 736, False),
        ):
            with self.subTest(frame=(x, y, width, height)):
                self.assertEqual(y > 0 and height > 0 and abs(y + height - screen_bottom) <= 2.0, expected)
        self.assertIn("UIApplication.sharedApplication.connectedScenes", self.h)
        self.assertIn("UIApplication.sharedApplication.windows", self.h)

    def test_original_df156_keyboard_reporting_is_still_separate(self):
        report = self.h.split("static inline void DF177KbSetVisible(", 1)[1].split(
            "// QA178 h1wake1 swallow state:", 1)[0]
        self.assertIn("DF156Write(", report)
        self.assertIn("notify_post(DF177KbWakeName)", report)
        self.assertIn("DF177KbSetVisible(DF177KbComputeVisible());", report)
        host = (ROOT / "DFH1Wake188.m").read_text()
        self.assertIn("qa188-h1-controls-state", host)
        self.assertIn("qa188-h1-app-touch-wake", host)
        self.assertNotIn("KbByBundle188", host)
        self.assertNotIn("DF177KbWakeName", host)

    def test_two_app_relays_keep_original_h1(self):
        for filename, selector in (
            ("DF154GeneralAppStateRelay.m", "DF177InstallAppTouchHook(bundle)"),
            ("DFYouTubeOrientationRelay.m", "DF177InstallAppTouchHook(DFYTBundle)"),
        ):
            self.assertIn(selector, (ROOT / filename).read_text())
        self.assertIn("DFH1Wake188.m", (ROOT / "build.sh").read_text())

    def test_package_and_log_version_180(self):
        integrated = (ROOT.parent / "jb-embedded-appbridge" / "package_integrated.py").read_text()
        self.assertIn('VERSION="0.0.185~admission1"', integrated)
        self.assertIn("0.1.185~admission1", (ROOT / "build.sh").read_text())
        self.assertIn("Version: 0.1.185~admission1", (ROOT / "control").read_text())
        self.assertIn("<key>CFBundleVersion</key><string>185</string>", (ROOT / "Info.plist").read_text())
        for path in (ROOT / "DFDeepTrace.h", ROOT / "DFTouchOwnerProbe.m"):
            self.assertIn("0.0.185~admission1", path.read_text())

if __name__ == "__main__":
    unittest.main()
