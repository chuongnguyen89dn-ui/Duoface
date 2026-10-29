"""DuoFace 117 native Dock and hidden-logo wake regression source contracts.

These tests are intentionally static: physical CarPlay touch delivery, device
safeArea accuracy and remotely-hosted YouTube are not simulated here.
"""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
probe=(ROOT/"DFTouchOwnerProbe.m").read_text()
chrome=(ROOT/"DFNative12Chrome.m").read_text()
trace=(ROOT/"DFPaneInputTrace116.h").read_text()
delegate=(ROOT/"DFNativeHostAppDelegate.m").read_text()

class NativeDockRectContract(unittest.TestCase):
    def test_native_safe_area_is_forwarded_without_double_left_margin(self):
        self.assertIn("safe=w.safeAreaLayoutGuide.layoutFrame",delegate)
        self.assertIn('launch[@"ContentRect"]',probe)
        self.assertIn("contentRect:region command:",probe)
        self.assertIn("CGRectContainsRect(CGRectInset(screen,-1,-1),region)",probe)
        self.assertIn('native-content-bounds-rejected',probe)
        self.assertIn('native-content-bounds-accepted',probe)
        self.assertIn('DFStopProbe(@"native-safe-area-unavailable")',probe)
        self.assertNotIn("MAX(42,screen.size.width*.082)",probe)
        self.assertNotIn("CGFloat x=MAX(region.origin.x,safeLeft)",probe)
        self.assertNotIn("region=CGRectMake(safeLeft",probe)
        self.assertIn('CGRect slotRect=CGRectMake(cr.origin.x,cr.origin.y',chrome)

class PassiveRootWindowWakeContract(unittest.TestCase):
    def test_original_uikit_dispatch_unmodified(self):
        self.assertEqual(trace.count("objc_msgSendSuper)"),3)
        self.assertIn('DFPane117SetWake',trace)
        self.assertIn('DFPane117SignalWake(w);',trace)
        self.assertIn('if(touch && target)DFPane117SignalWake((UIWindow *)self);',trace)
        self.assertIn('return target;',trace)
        self.assertIn('return accepts;',trace)
        self.assertNotIn('IOHIDEventSystemClientDispatchEvent',trace)
        self.assertNotIn('addGestureRecognizer:',trace)
    def test_wake_only_existing_external_app_pane_after_dispatch(self):
        self.assertIn('physicalPane?DFPane116TraceClass(_externalWindowClass):Nil',chrome)
        self.assertIn('if(physicalPane && traced)',chrome)
        self.assertIn('DFPane117SetWake(w,^(UIWindow *touchedWindow)',chrome)
        self.assertIn('[owner.appSceneWindows containsObject:touchedWindow]',chrome)
        self.assertIn('touchedWindow.hidden',chrome)
        self.assertIn('touchedWindow.screen==UIScreen.mainScreen',chrome)
        self.assertIn('[owner noteUserActivity];',chrome)
        self.assertIn('pane117-root-window-woke-hidden-logo-and-controls',chrome)
        self.assertIn('dispatch_async(dispatch_get_main_queue()',chrome)
        self.assertIn('self.controlsUntil=NSDate.date.timeIntervalSince1970+4.0;',chrome)
        self.assertIn('self.dividerLogo.alpha=controlsVisible?1.0:0.02;',chrome)

if __name__=="__main__":
    unittest.main()
