# QA178 contracts: keyboard diagnostics round 3 (private all-window
# capture + 300ms late capture, record fields, no behaviour hooks) and
# the HUD exit hold (gate-state logging at both teardown points,
# hideAll exclusion, pre-hide snapshot handover decision).
import pathlib, re, unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
RELAY = (ROOT / "DF154GeneralAppStateRelay.m").read_text()
CHROME = (ROOT / "DFNative12Chrome.m").read_text()
HEADER = (ROOT / "DFNative12Chrome.h").read_text()
PROBE = (ROOT / "DFTouchOwnerProbe.m").read_text()
CONTROL = (ROOT / "control").read_text()
INFO = (ROOT / "Info.plist").read_text()
BUILD = (ROOT / "build.sh").read_text()
TRACE = (ROOT / "DFDeepTrace.h").read_text()


class QA178KBDiag(unittest.TestCase):
    def test_private_all_windows_enumeration_guarded(self):
        self.assertIn("allWindowsIncludingInternalWindows:onlyVisibleWindows:",
                      RELAY)
        self.assertIn("[UIWindow respondsToSelector:allSel]", RELAY)

    def test_delayed_capture_300ms(self):
        self.assertIn("kDF178KBDelayedCaptureSeconds = 0.3", RELAY)
        self.assertIn("df178CaptureKeyboard:held late:YES", RELAY)
        self.assertIn("df178CaptureKeyboard:note late:NO", RELAY)

    def test_keyplane_independent_of_window(self):
        self.assertIn('NSClassFromString(@"UIKeyboardImpl")', RELAY)
        self.assertIn('@"activeInstance"', RELAY)
        self.assertIn('@"layoutStar"', RELAY)

    def test_record_fields(self):
        for key in ('@"late"', '@"kbScreenFrame"', '@"kbTransform"',
                    '@"appSelf"', '@"winDump"'):
            self.assertIn(key, RELAY)
        self.assertIn("convertRect:kb.bounds", RELAY)
        self.assertIn("substringToIndex:880", RELAY)  # mailbox budget cap

    def test_versions(self):
        self.assertIn('Version: 0.1.178~kbhud1', CONTROL)
        self.assertIn('0.1.178~kbhud1_iphoneos-arm64.deb', BUILD)
        self.assertIn('<string>178</string>', INFO)
        self.assertIn('build=0.0.178~kbhud1', TRACE)
        self.assertIn('build=0.0.178~kbhud1', PROBE)


class QA178HUDHold(unittest.TestCase):
    def test_gate_log_points(self):
        self.assertIn('df178LogHUDGate:@"deactivate"', PROBE)
        self.assertIn('df178LogHUDGate:@"stop"', CHROME)
        self.assertIn("qa178-hud-gate point=%@", CHROME)
        self.assertIn("- (void)df178LogHUDGate:(NSString *)point;", HEADER)

    def test_snapshot_constants_and_stamp(self):
        self.assertIn("kDF178HUDSnapshotFreshSeconds = 2.0", CHROME)
        self.assertIn("owner.hudWasVisibleAt176=NSDate.date.timeIntervalSince1970",
                      CHROME)
        self.assertIn("df178HUDSnapshotUp", CHROME)

    def test_hideall_excludes_hud_window(self):
        i = CHROME.index("- (void)hideAllExternalWindowsImmediately")
        seg = CHROME[i:i + 1400]
        self.assertIn("if(holdHUD178 && w==self.speedHUDWindow)continue;", seg)

    def test_stop_gate_uses_snapshot_not_hidden_flag(self):
        i = CHROME.index("if([self df178HUDSnapshotUp]){")
        seg = CHROME[i:i + 1500]
        self.assertIn("self.handover177Window.hidden=NO;", seg)
        self.assertIn("DF176HUDLeasePublishChrome(YES,YES);", seg)
        self.assertIn("qa177-hud-handover start max=4.0s pub=%d snapshotAge=%.2f",
                      seg)

    def test_frozen_files_untouched_markers(self):
        # QA178 must not need DFSceneHost changes: the kbdiag host
        # fallback reads Chrome's own surfaces instead.
        self.assertIn("bundleIDForHostedView:surface", CHROME)
        self.assertIn('@"qa178-kbdiag2 bundle=%@', CHROME)


if __name__ == "__main__":
    unittest.main()
