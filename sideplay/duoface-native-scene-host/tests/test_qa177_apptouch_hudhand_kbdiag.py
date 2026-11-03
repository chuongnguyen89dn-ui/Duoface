"""QA177: app-side touch signal for controls recall (H1), speed-HUD
exit handover + overlay file logging (H2), keyboard diagnostics
round 2, log only (H3).
Step-0 findings: DF156 supports the app -> SpringBoard direction
(proven on device by QA176 kbdiag); the overlay can announce its HUD
through its own single-writer record; panes are a fixed logical-size
scene scaled by a non-uniform transform (DFSceneHost.layoutScene).
Decoder stays shadow; bubble speed stays GPS; DFSceneHost.m is NOT
touched by this round."""
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parents[1]
class TestQA177(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.chrome=(ROOT/"DFNative12Chrome.m").read_text()
        cls.overlay=(ROOT/"DFSpeedNativeOverlay163.mm").read_text()
        cls.relay=(ROOT/"DF154GeneralAppStateRelay.m").read_text()
        cls.yt=(ROOT/"DFYouTubeOrientationRelay.m").read_text()
        cls.touch=(ROOT/"DFAppTouch177.h").read_text()
        cls.lease=(ROOT/"DFSpeedHUDLease176.h").read_text()
        cls.scene=(ROOT/"DFSceneHost.m").read_text()
        cls.trace=(ROOT/"DFDeepTrace.h").read_text()
        cls.build=(ROOT/"build.sh").read_text()
        cls.control=(ROOT/"control").read_text()
        cls.pack=(ROOT.parent/"jb-embedded-appbridge/package_integrated.py").read_text()
        cls.workflow=(REPO/".github/workflows/duoface-179-kbfit-selprobe-signed-private.yml").read_text()
    def test_versions_bumped(self):
        self.assertIn("0.1.179~kbfit1", self.build)
        self.assertIn("0.1.179~kbfit1", self.control)
        self.assertIn('VERSION="0.0.179~kbfit1"', self.pack)
        self.assertIn("build=0.0.179~kbfit1", self.trace)
    def test_h1_sender_original_first_readonly(self):
        # original implementation runs FIRST, hook only reads Began
        hook=self.touch.index("DF177SendEventOriginal)(")
        began=self.touch.index("UITouchPhaseBegan")
        self.assertLess(hook, began)
        self.assertIn("kDF177TouchThrottleSeconds = 0.25", self.touch)
        self.assertIn("com.duoface.ipc.v177.apptouch", self.touch)
        self.assertIn("AppTouchRecall177", self.touch)
    def test_h1_sender_installed_in_both_relays(self):
        self.assertIn("DF177InstallAppTouchHook(bundle)", self.relay)
        self.assertIn("DF177InstallAppTouchHook(DFYTBundle)", self.yt)
        self.assertIn("#define DF177_APP_SIDE_SENDER 1", self.relay)
        self.assertIn("#define DF177_APP_SIDE_SENDER 1", self.yt)
    def test_h1_chrome_wake_and_recall(self):
        self.assertIn("notify_register_dispatch(DF177TouchWakeName", self.chrome)
        self.assertIn("- (void)df177HandleAppTouch", self.chrome)
        self.assertIn("qa177-app-touch bundle=%@ count=%llu", self.chrome)
        self.assertIn("qa177-recall source=app-touch bundle=%@", self.chrome)
        # recall goes through the single noteUserActivity path
        handler=self.chrome.index("- (void)df177HandleAppTouch")
        end=self.chrome.index("- (void)df177HUDHandoverTick")
        self.assertIn("[self noteUserActivity]", self.chrome[handler:end])
        # symmetric teardown of the wake token in stop
        self.assertIn("notify_cancel(self.touchWake177Token)", self.chrome)
    def test_h1_qa176_wiring_kept(self):
        # QA176 H1(a)/(b) stays in place per the work order
        self.assertIn("selector:@selector(realAppTouched:) name:DFSceneHostDidObserveTouchNotification", self.chrome)
        self.assertIn("[self observeActivityInWindow:w]", self.chrome)
    def test_h2_overlay_file_log_and_record(self):
        self.assertIn("DuoFaceDockOwner.log", self.overlay)
        self.assertIn("qa177-overlay attach reason=%@", self.overlay)
        self.assertIn("qa177-overlay detach reason=%@", self.overlay)
        self.assertIn("DF177OverlayPublish(YES)", self.overlay)
        self.assertIn("DF177OverlayPublish(NO)", self.overlay)
        self.assertIn("com.duoface.speedhud.overlay163.plist", self.lease)
    def test_h2_overlay_retiring_overrides_yield(self):
        self.assertIn("DF176ChromeLeaseRetiring()", self.overlay)
        self.assertIn("!chromeRetiring && [self duoFaceOwnsExternalChrome]", self.overlay)
        self.assertIn("chrome-handover", self.overlay)
    def test_h2_chrome_handover(self):
        self.assertIn("kDF177HUDHandoverMaxSeconds = 4.0", self.chrome)
        self.assertIn("DF176HUDLeasePublishChrome(YES,YES)", self.chrome)
        self.assertIn("qa177-hud-handover start max=4.0s", self.chrome)
        self.assertIn("qa177-hud-handover done=%@ waited=%.2fs", self.chrome)
        self.assertIn("DF177OverlayVisibleFresh(2.0)", self.chrome)
        self.assertIn("[self df177FinishHUDHandover:@\"superseded\"]", self.chrome)
        self.assertIn("@\"Retiring\"", self.lease)
    def test_h3_didshow_not_starved(self):
        self.assertIn("lastKbDid176", self.relay)
        self.assertIn("UIKeyboardDidShowNotification", self.relay)
        seg=self.relay.index("rate-limit PER notification name")
        self.assertIn("lastKbDid176<2.0", self.relay[seg:seg+800])
    def test_h3_new_fields(self):
        self.assertIn("@\"kbLevel\":kbLevel", self.relay)
        self.assertIn("@\"sceneBounds\":sceneBounds", self.relay)
        self.assertIn("hostViewForBundleID:kbBundle", self.chrome)
        self.assertIn("hostT=%.3f,%.3f,%.3f", self.chrome)
        self.assertIn("kbLevel=%@ scene=%@", self.chrome)
    def test_h3_still_log_only(self):
        # the relay must never steer the keyboard (QA176 contract kept)
        self.assertNotIn("setKeyplaneName", self.relay)
        self.assertNotIn("setKeyboardName", self.relay)
        self.assertNotIn("setKeyboardWidth", self.relay)
    def test_scenehost_untouched_by_round(self):
        # QA177 does not modify the frozen scene host: its QA175
        # trailing-edge machinery and logical-size scaling stay as-is
        self.assertIn("CGAffineTransformMakeScale(size.width/logical.width,size.height/logical.height)", self.scene)
        self.assertIn("kDF175GeometryDebounceSeconds", self.scene)
if __name__ == "__main__":
    unittest.main()
