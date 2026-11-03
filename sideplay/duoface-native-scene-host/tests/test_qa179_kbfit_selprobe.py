import pathlib, re, unittest
ROOT = pathlib.Path(__file__).resolve().parents[1]
REPO = ROOT.parents[1]
SRC = ROOT
RELAY = (SRC / "DF154GeneralAppStateRelay.m").read_text()
CHROME = (SRC / "DFNative12Chrome.m").read_text()
BUILD = (SRC / "build.sh").read_text()
WORKFLOW = (REPO / ".github" / "workflows" /
            "duoface-179-kbfit-selprobe-signed-private.yml").read_text()

class QA179KeyboardFit(unittest.TestCase):
    def test_versions(self):
        self.assertIn("0.1.180~kbcycle1", BUILD)
        pack = (ROOT.parent / "jb-embedded-appbridge" /
                "package_integrated.py").read_text()
        self.assertIn("0.0.180~kbcycle1", pack)
        self.assertIn("duoface-179-kbfit-selprobe-signed-private", WORKFLOW)

    def test_forbidden_strings_stay_out_of_relay(self):
        # The QA176/QA177 contract: the relay never names the
        # keyboard-mutation selectors.
        for forbidden in ("setKeyplaneName", "setKeyboardName",
                          "setKeyboardWidth"):
            self.assertNotIn(forbidden, RELAY)
        for forbidden in ("setInterfaceOrientation:",
                          "UIWindowLevelAlert", "SBMainWorkspace"):
            self.assertNotIn(forbidden, RELAY)

    def test_fit_flag_default_on_live_read(self):
        self.assertIn("DF179KeyboardFitEnabled", RELAY)
        self.assertIn('p[@"KeyboardFit179"]', RELAY)
        # Same live-read pattern as DF176KBDiagEnabled: absent = ON.
        self.assertIn("return v?[v boolValue]:YES;", RELAY)
        self.assertIn("DF176KBDiagPrefsPath", RELAY)

    def test_fit_scope_is_maps_and_waze_only(self):
        self.assertIn("DF179FitScope", RELAY)
        self.assertIn('@"com.google.Maps"', RELAY)
        self.assertIn('@"com.waze.iphone"', RELAY)

    def test_fit_applies_at_didshow_with_guards(self):
        self.assertIn("DF179FitScope(self.bundle)", RELAY)
        self.assertIn("UIKeyboardDidShowNotification", RELAY)
        self.assertIn("gDF179KbFitApplied", RELAY)
        self.assertIn("gDF179KbSavedFrame", RELAY)
        self.assertIn("already-fit", RELAY)
        self.assertIn("not-hosted", RELAY)
        # The keyboard window frame is set from the key window frame.
        self.assertRegex(RELAY, r"kb\.frame=fitKey\.frame")

    def test_restore_paths_exist(self):
        self.assertIn("df179KeyboardHidden:", RELAY)
        self.assertIn("UIKeyboardDidHideNotification", RELAY)
        self.assertIn('reason=did-hide', RELAY)
        self.assertIn('@"flag-off"', RELAY)
        self.assertIn('@"not-hosted"', RELAY)
        self.assertIn("DF179WriteFitRecord", RELAY)

    def test_fit_measurement_segment(self):
        self.assertIn("qa179-kbfit", CHROME)
        for field in ("action=%@", "kbBefore=%@", "kbAfter=%@",
                      "subs=%@", "screen=%@", "key=%@"):
            self.assertIn(field, RELAY)
        self.assertIn("notifBegin", RELAY)
        self.assertIn("notifBegin", CHROME)

    def test_selprobe_is_read_only(self):
        self.assertIn("qa179-selprobe", CHROME)
        self.assertIn("selProbe179", RELAY)
        self.assertIn("instancesRespondToSelector", RELAY)
        self.assertIn("class_respondsToSelector", RELAY)
        for sel in ("keyboardWidthForScreen:withOrientation:",
                    "keyboardScreenReferenceSize"):
            self.assertIn(sel, RELAY)
        # The probe must not invoke the width selectors: inside the
        # probe region there is no performSelector / msgSend at all.
        region = RELAY.split("QA179 H3: read-only selector-ownership")[1] \
                      .split("QA179 H1/H2: keyboard fit evaluation")[0]
        self.assertNotIn("performSelector", region)
        self.assertNotIn("objc_msgSend", region)

    def test_frozen_files_untouched_markers(self):
        # DFSceneHost.m keeps its QA175-era content markers and the
        # render-size header is not part of this round.
        host = (SRC / "DFSceneHost.m").read_text()
        self.assertIn("layoutScene", host)

if __name__ == "__main__":
    unittest.main()
