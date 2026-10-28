"""Native12 SHA-pinned two-pass YouTube UIKit reflow regression (static source gate).

Original original binary: sideplay/audit/native12-083-rotation-20261028/
NATIVE12_ORIGINAL_APP_ORIENTATION_HELPER_RUN_40648090838.json
ARM64 0x2aa2e4 UIWindow class-side internal enumeration.
No hardware equivalence is claimed.
"""
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def source(name):
    return (ROOT/name).read_text(encoding="utf-8")

class YoutubeInternalWindowReflow088(unittest.TestCase):
    def test_original_class_method_not_wrong_application_instance(self):
        helper=source("DFYouTubeHostState.h")
        self.assertIn("class_getClassMethod(cls,sel)",helper)
        self.assertIn("Class cls=UIWindow.class",helper)
        self.assertIn("allWindowsIncludingInternalWindows:onlyVisibleWindows:",helper)
        self.assertIn("_allWindowsIncludingInternalWindows:onlyVisibleWindows:",helper)
        self.assertIn("(cls,sel,YES,NO)",helper)
        self.assertNotIn("DFYTVisibleInternalWindows(id application)",helper)
        self.assertIn("method_getNumberOfArguments(method)!=4",helper)
        self.assertIn("result[0]!='@'",helper)
    def test_two_pass_exact_scene_ownership_and_dedup(self):
        src=source("DFYouTubeOrientationRelay.m")
        self.assertIn("NSMutableOrderedSet<UIWindow *> *candidates",src)
        self.assertIn("for(UIWindow *window in owned.windows)",src)
        self.assertIn("NSArray *internal=DFYTVisibleInternalWindows()",src)
        self.assertIn("((UIWindow *)object).windowScene==owned",src)
        self.assertIn("[candidates addObject:(UIWindow *)object]",src)
        self.assertIn("window.windowScene!=owned || window.hidden",src)
        self.assertIn("window.windowLevel!=UIWindowLevelNormal",src)
        self.assertIn("DFYTRotationABI(window)",src)
        self.assertIn("DFYTRotate(window,UIInterfaceOrientationPortrait)",src)
        self.assertIn("self.snapshots",src)
        self.assertIn("scene-id-unmatched",src)
        self.assertNotIn("UIApplication.sharedApplication.windows",src)
        self.assertNotIn("DFYTUpdateWindowLayout(window.rootViewController)",src)
    def test_runtime_instrumentation_and_frozen_maps_video_baseline(self):
        app=source("DFYouTubeOrientationRelay.m")
        host=source("DFSceneHost.m")
        self.assertIn('@"internalWindowCount":@(windowsFromInternal)',app)
        self.assertIn('@"layoutRefreshes":@(layoutRefreshes)',app)
        self.assertIn('ack[@"internalWindowCount"]',host)
        self.assertIn('ack[@"layoutRefreshes"]',host)
        self.assertNotIn("AVPlayer",app)
        self.assertNotIn("UIDevice.currentDevice",app)
        self.assertIn("DFYTBundle",app)
        self.assertIn("DFYTValidState(self.state",app)
        assert source("DFYouTubeOrientationRelay.plist").count("<string>com.google.ios.youtube</string>")==1
        self.assertEqual("0.50",source("DFHostedMapRenderSize.h").split("return (CGFloat)")[1].split(";")[0])
        self.assertIn("DFSceneLifecycle.m",source("build.sh"))

if __name__=="__main__":
    unittest.main()
