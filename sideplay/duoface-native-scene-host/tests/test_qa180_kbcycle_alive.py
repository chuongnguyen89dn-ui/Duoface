import pathlib, re, unittest
ROOT = pathlib.Path(__file__).resolve().parents[1]
REPO = ROOT.parents[1]
SRC = ROOT
RELAY = (SRC / "DF154GeneralAppStateRelay.m").read_text()
CHROME = (SRC / "DFNative12Chrome.m").read_text()
BUILD = (SRC / "build.sh").read_text()
WORKFLOW = (REPO / ".github" / "workflows" /
            "duoface-180-kbcycle-alive-signed-private.yml").read_text()

class QA180CycleAlive(unittest.TestCase):
    def test_versions(self):
        self.assertIn("0.1.180~kbcycle1", BUILD)
        pack = (ROOT.parent / "jb-embedded-appbridge" /
                "package_integrated.py").read_text()
        self.assertIn("0.0.180~kbcycle1", pack)
        self.assertIn("duoface-180-kbcycle-alive-signed-private", WORKFLOW)

    def test_forbidden_strings_stay_out_of_relay(self):
        for forbidden in ("setKeyplaneName", "setKeyboardName",
                          "setKeyboardWidth"):
            self.assertNotIn(forbidden, RELAY)
        for forbidden in ("setInterfaceOrientation:",
                          "UIWindowLevelAlert", "SBMainWorkspace"):
            self.assertNotIn(forbidden, RELAY)

    def test_cycle_flag_default_on_live_read(self):
        self.assertIn("DF180KeyboardCycleEnabled", RELAY)
        self.assertIn('p[@"KeyboardCycle180"]', RELAY)
        # flag read goes through the shared qa176 prefs path
        self.assertIn("DF176KBDiagPrefsPath", RELAY)

    def test_cycle_machinery(self):
        self.assertIn("DF180CycleBegin", RELAY)
        self.assertIn("DF180CycleFinish", RELAY)
        # event-driven evaluation inside the cycle
        self.assertIn("UIWindowDidBecomeVisibleNotification", RELAY)
        # bounded retry beats +0.6/+1.2 on top of the QA178 +0.3
        self.assertIn("{0.3,0.6,1.2}", RELAY)
        # cycle outcomes incl. exhaustion and cancellation
        for token in ("exhausted", "cancelled", "did-hide",
                      "foundAt="):
            self.assertIn(token, RELAY)
        # summaries ride their own segment key to Chrome
        self.assertIn("cyc180", RELAY)
        self.assertIn("qa180-cycle", CHROME)

    def test_cycle_only_in_fit_scope_and_flag_off_is_legacy(self):
        # cycle mode requires the fit scope guard
        self.assertIn("DF180KeyboardCycleEnabled() && DF179FitScope(self.bundle)",
                      RELAY)
        # legacy QA178 late capture remains for the flag-off path
        self.assertIn("kDF178KBDelayedCaptureSeconds", RELAY)

    def test_alive_markers(self):
        self.assertIn("DF180WriteAliveRecord", RELAY)
        self.assertIn("stage=R1", RELAY)
        # R2 names each guard plus the listen outcome
        self.assertIn("guards=b%d,p%d,e%d,s%d,i%d listen=-1 reg=0", RELAY)
        self.assertIn("guards=ok listen=0 reg=0", RELAY)
        self.assertIn("guards=ok listen=1 reg=1", RELAY)
        # markers bypass the pilot channel: direct mailbox init
        self.assertIn("DF180WriteSegmentRecord", RELAY)
        self.assertIn("qa180-relay-alive", CHROME)
        # R1 is written BEFORE the guard split in the constructor
        ctor = RELAY[RELAY.index("DF154StartAppSide"):]
        self.assertLess(ctor.index("stage=R1"),
                        ctor.index("BOOL gB="))

    def test_db_reference_size_readonly(self):
        self.assertIn("keyboardScreenReferenceSize", RELAY)
        self.assertIn("refSize=%@", RELAY)
        self.assertIn("refWhen=%@", RELAY)
        # read-only means: the selector is only ever responded-to
        # and messaged as a getter; no implementation replacement
        self.assertNotIn("method_setImplementation", RELAY)
        self.assertIn("respondsToSelector:rsSel", RELAY)

    def test_frozen_files_untouched(self):
        host = (SRC / "DFSceneHost.m").read_text()
        self.assertNotIn("QA180", host)
        self.assertNotIn("180~kbcycle1", host)
        hdr = (SRC / "DFHostedMapRenderSize.h").read_text()
        self.assertNotIn("QA180", hdr)

if __name__ == "__main__":
    unittest.main()
