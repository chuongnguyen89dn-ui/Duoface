"""Read-only/source guard for own visual-only logo expiration.
Run from repository via Python unittest; hardware CarPlay still required.
"""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
CHROME=(ROOT/"DFNative12Chrome.m").read_text()
HEADER=(ROOT/"DFChromeVisual178.h").read_text()

def method(name,next_name):
    return CHROME[CHROME.index(name):CHROME.index(next_name,CHROME.index(name))]

class QA178LogoVisibility(unittest.TestCase):
    def test_timer_does_not_mutate_hosted_geometry_or_keyboard(self):
        body=method("- (void)df178RefreshChromeArtwork {","- (void)df178ScheduleChromeExpiry {")
        self.assertIn("self.dividerLogo.alpha=visible?1.0:0.02;",body)
        self.assertIn("[self updateGripBlinkForVisibleSession:visible];",body)
        for forbidden in ("layoutControls","kbVisible177","kbStateKnown177","hostViewForBundleID",
                          "window.frame","sceneHandle", "setSplitMode"):
            self.assertNotIn(forbidden,body)
    def test_single_timer_guarded_by_active_session_and_generation(self):
        body=method("- (void)df178ScheduleChromeExpiry {","- (void)noteUserActivity {")
        for token in ("[self.chromeVisualTimer178 invalidate]", "chromeVisualGeneration178",
                      "DF178ChromeExpiryGenerationCurrent", "DF177AppTouchSessionMatches",
                      "NSRunLoopCommonModes", "[owner df178RefreshChromeArtwork]"):
            self.assertIn(token,body)
        self.assertNotIn("layoutControls",body)
    def test_start_activity_app_touch_and_stop_cover_all_expiries(self):
        start=method("- (BOOL)start {","// The grip owns its own touch stream")
        note=method("- (void)noteUserActivity {","- (BOOL)df177RefreshKeyboardState {")
        app=method("- (void)df177HandleAppTouch {","- (void)realAppTouched:")
        stop=CHROME[CHROME.index("- (void)stop {"):]
        for chunk in (start,note,app):
            self.assertIn("[self df178ScheduleChromeExpiry];",chunk)
        self.assertIn("[self.chromeVisualTimer178 invalidate];self.chromeVisualTimer178=nil;",stop)
        self.assertIn("++self.chromeVisualGeneration178",stop)
        self.assertNotIn("[self layoutControls];",app.split("dispatch_after(",1)[0])
        self.assertIn("if(owner.kbStateKnown177 && !owner.kbVisible177)",app)
        self.assertIn("if(owner.kbStateKnown177 && !owner.kbVisible177)",note)
    def test_visual_logo_recall_cannot_reactivate_red_border(self):
        recall=method("- (void)df178RecallChromeVisualOnly {",
                      "- (void)df178ScheduleChromeExpiry {")
        self.assertIn("[self df178RefreshChromeArtwork];",recall)
        for forbidden in ("borderUntil", "layoutControls", "kbVisible177",
                          "window.frame", "appSceneContainers"):
            self.assertNotIn(forbidden,recall)
        layout=method("- (void)layoutControls {",
                      "- (void)refreshGlobalSpeedHUD164 {")
        self.assertIn("BOOL touched=(splitVisible && controlsVisible &&",layout)
        self.assertIn("self.borderUntil",layout)

    def test_drag_and_deadline_behavior(self):
        self.assertIn("DF178ChromeVisible",CHROME)
        self.assertIn("isDragging || logoTouchPending",HEADER)
        self.assertIn("now<=controlsUntil",HEADER)
        self.assertIn("return captured!=0 && captured==current",HEADER)

if __name__=="__main__":unittest.main()
