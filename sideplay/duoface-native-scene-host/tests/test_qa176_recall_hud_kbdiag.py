"""QA176: controls recall rewiring (H1), speed-HUD single-owner lease
priority (H2), hosted-app keyboard diagnostics, log only (H3).
Step-0 census: exactly three HUD presenters, all on the CarPlay
display (Chrome + DF144-SB anchor identically). Decoder stays shadow;
bubble speed stays GPS; DFSceneHost.m is NOT touched by this round."""
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parents[1]
class TestQA176(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.chrome=(ROOT/"DFNative12Chrome.m").read_text()
        cls.df144=(ROOT/"DFHomeStandalone144.m").read_text()
        cls.overlay=(ROOT/"DFSpeedNativeOverlay163.mm").read_text()
        cls.relay=(ROOT/"DF154GeneralAppStateRelay.m").read_text()
        cls.lease=(ROOT/"DFSpeedHUDLease176.h").read_text()
        cls.kbdiag=(ROOT/"DFKBDiag176.h").read_text()
        cls.trace=(ROOT/"DFDeepTrace.h").read_text()
        cls.build=(ROOT/"build.sh").read_text()
        cls.control=(ROOT/"control").read_text()
        cls.pack=(ROOT.parent/"jb-embedded-appbridge/package_integrated.py").read_text()
        cls.workflow=(REPO/".github/workflows/duoface-176-recall-hud-kbdiag-signed-private.yml").read_text()
    def test_versions_bumped(self):
        self.assertIn("0.1.177~apptouch1", self.build)
        self.assertIn("0.1.177~apptouch1", self.control)
        self.assertIn('VERSION="0.0.177~apptouch1"', self.pack)
        self.assertIn("build=0.0.177~apptouch1", self.trace)
    def test_h1_touch_subscription_connected(self):
        # (a) the scene-touch notification finally has a subscriber
        self.assertIn("selector:@selector(realAppTouched:) name:DFSceneHostDidObserveTouchNotification", self.chrome)
        self.assertIn("- (void)realAppTouched:(NSNotification *)note", self.chrome)
    def test_h1_activity_observer_on_chrome_windows(self):
        # (b) makeWindow attaches the passive observer to every window
        self.assertIn("[self observeActivityInWindow:w]", self.chrome)
        start=self.chrome.index("- (UIWindow *)makeWindow:")
        end=self.chrome.index("- (UIViewController *)emptyRoot:")
        self.assertIn("observeActivityInWindow:w", self.chrome[start:end])
    def test_h1_constants_and_antistorm(self):
        self.assertIn("kDF176ControlsVisibleSeconds = 4.0", self.chrome)
        self.assertIn("kDF176ControlsBorderSeconds = 2.0", self.chrome)
        self.assertIn("kDF176ActivityThrottleSeconds = 0.25", self.chrome)
        start=self.chrome.index("- (void)noteUserActivity")
        end=self.chrome.index("- (void)realAppTouched:")
        body=self.chrome[start:end]
        # deadlines always move; only the relayout is throttled
        self.assertIn("self.controlsUntil=now+kDF176ControlsVisibleSeconds", body)
        self.assertIn("lastActivityLayoutAt176<kDF176ActivityThrottleSeconds", body)
        self.assertNotIn("+4.0", self.chrome)
    def test_h2_lease_priority_wiring(self):
        self.assertIn("kDF176HUDLeaseFreshSeconds = 2.0", self.lease)
        # Chrome publishes only while visible, retracts in stop
        self.assertIn("DF176HUDLeasePublish(DF176HUDLeaseChromePath,@\"Chrome\")", self.chrome)
        self.assertIn("DF176HUDLeaseRetract(DF176HUDLeaseChromePath)", self.chrome)
        # DF144-SB yields to Chrome and resumes, one line per transition
        self.assertIn("DF144ApplyHUDYield176", self.df144)
        self.assertIn("yield=DF144-SB winner=Chrome", self.df144)
        self.assertIn("resume=DF144-SB", self.df144)
        # overlay163 gains the HUD-scoped Chrome lease on top of its
        # existing DF144 lease + session-pulse suppression
        self.assertIn("yield=Overlay163 winner=Chrome", self.overlay)
        self.assertIn("QA165 native HUD suppressed for standalone owner", self.overlay)
        # no presenter was removed
        self.assertIn("gofaSpeedHUD", self.chrome)
        self.assertIn("speedHUD", self.df144)
    def test_h3_keyboard_diagnostics_log_only(self):
        self.assertIn("KeyboardDiag176", self.kbdiag)
        self.assertIn("DF176KBDiagWakeName", self.kbdiag)
        # app side: observes, records the discriminating facts, ships
        self.assertIn("df176KeyboardShown:", self.relay)
        self.assertIn("UIKeyboardWillShowNotification", self.relay)
        self.assertIn("UIKeyboardDidShowNotification", self.relay)
        self.assertIn("UIKeyboardLayoutStar", self.relay)
        self.assertIn("GSEventIsHardwareKeyboardAttached", self.relay)
        self.assertIn("DF176KBDiagMailboxName", self.relay)
        # app side must not mutate the keyboard in any way
        self.assertNotIn("setKeyplaneName", self.relay)
        self.assertNotIn("setKeyboardName", self.relay)
        self.assertNotIn("setKeyboardWidth", self.relay)
        # SpringBoard side: wake listener + combined log line
        self.assertIn("df176LogKeyboardContext", self.chrome)
        self.assertIn("qa176-kbdiag", self.chrome)
        self.assertIn("notify_register_dispatch(DF176KBDiagWakeName", self.chrome)
    def test_ci_runs_qa176_regression(self):
        self.assertIn("test_qa176_recall_hud_kbdiag.py", self.workflow)
if __name__ == "__main__":
    unittest.main()
