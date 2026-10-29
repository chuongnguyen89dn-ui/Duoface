"""DuoFace .114 passive full-pane wake regression against scanned original Native12
CBDividerView/CBWindow input owners. This is source-contract QA, not device QA.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT.parents[1]
SOURCE = (ROOT / "DFNative12Chrome.m").read_text()
SCENE = (ROOT / "DFSceneHost.m").read_text()
ORIGINAL_AUDIT = (
    PROJECT / "sideplay/audit/native12-vs-new-20261022/GESTURE_CALLSITE_CROSSWALK.md"
).read_text()

class PaneAnywhereWakeContract(unittest.TestCase):
    def test_original_binary_scan_not_invented(self):
        for selector in (
            "CBDividerView.pointInside:withEvent:",
            "CBDividerView.hitTest:withEvent:",
            "CBBridgedSplitApp.handleDividerPan:isVertical:state:",
        ):
            self.assertIn(selector, ORIGINAL_AUDIT)

    def test_all_real_physical_panes_have_passive_owner(self):
        section = SOURCE.split("// RESTORE .37's real scene owner:", 1)[1]
        section = section.split('DFCLog(@"media37-four-physical-scene-windows-restored");', 1)[0]
        self.assertIn("for(NSInteger i=0;i<4;i++)", section)
        self.assertIn("DFNativePanePassthroughView", section)
        self.assertIn(".touchBeganInPane=^(UIWindow *touchedWindow)", section)
        self.assertIn("[self.appSceneWindows addObject:slotWindow]", section)

    def test_touch_begin_not_captured_or_replayed(self):
        section = SOURCE.split("@implementation DFNativePanePassthroughView", 1)[1].split("@end",1)[0]
        self.assertIn("event.type==UIEventTypeTouches", section)
        self.assertIn("touch.phase==UITouchPhaseBegan", section)
        self.assertIn("touch.window==self.window", section)
        self.assertIn("self.touchBeganInPane(self.window)", section)
        self.assertIn("UIView *hit=[super hitTest:point withEvent:event]", section)
        self.assertIn("return hit==self?nil:hit;", section)
        self.assertNotIn("touchesBegan:", section)
        self.assertNotIn("sendEvent:", section)

    def test_wake_after_original_hit_test_and_external_scope_only(self):
        section = SOURCE.split("slotRoot.view.clipsToBounds=YES;",1)[1]
        section = section.split("UIWindow *slotWindow=[self makeWindow:",1)[0]
        self.assertIn("dispatch_async(dispatch_get_main_queue()", section)
        self.assertIn("[owner.appSceneWindows containsObject:touchedWindow]", section)
        self.assertIn("touchedWindow.hidden", section)
        self.assertIn("touchedWindow.screen==UIScreen.mainScreen", section)
        self.assertIn("owner.startupActive", section)
        self.assertIn("owner.appPickerVisible", section)
        self.assertIn("[owner noteUserActivity];", section)

    def test_four_second_auto_hide_unmodified(self):
        activity = SOURCE.split("- (void)noteUserActivity {",1)[1].split("- (void)realAppTouched:",1)[0]
        self.assertIn("self.controlsUntil=NSDate.date.timeIntervalSince1970+4.0",activity)
        self.assertIn("[self layoutControls];",activity)
        layout = SOURCE.split("BOOL controlsVisible=self.panActive",1)[1].split("// The 32pt ratio",1)[0]
        self.assertIn("self.dividerLogo.alpha=controlsVisible?1.0:0.02",layout)
        self.assertIn("show=show && (!allReady || controlsVisible)",layout)

    def test_existing_app_and_logo_gestures_not_removed(self):
        for marker in (
            "[window addGestureRecognizer:observer]",
            "[self observeActivityInWindow:slotWindow]",
            "DFSceneHostDidObserveTouchNotification",
            "logo.touchBegan=^(UIButton *sender)",
            "[self.dividerTrack addGestureRecognizer:trackPan]",
        ):
            self.assertIn(marker,SOURCE)
        self.assertIn("postNotificationName:DFSceneHostDidObserveTouchNotification",SCENE)

if __name__=="__main__":
    unittest.main()
