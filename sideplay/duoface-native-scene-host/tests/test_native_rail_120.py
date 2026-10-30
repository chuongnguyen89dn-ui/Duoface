"""QA120 source contract: measured native CarPlay rail and passive YouTube Play tap trace.

Mac signed build validates the Objective-C; these checks guard against
unconditional x=0 fullscreen and reintroduction of global hit-test hooks.
No test here claims a physical vehicle test or successful YouTube playback.
"""
from pathlib import Path
import unittest

HERE=Path(__file__).resolve().parents[1]
INTEGRATED=HERE.parent / 'jb-embedded-appbridge' / 'package_integrated.py'


class QA120NativeGeometry(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dock=(HERE/'DFCarPlayDockOwner.m').read_text()
        cls.owner=(HERE/'DFTouchOwnerProbe.m').read_text()
        cls.chrome=(HERE/'DFNative12Chrome.m').read_text()
        cls.host=(HERE/'DFSceneHost.m').read_text()

    def test_real_native_dock_view_not_fake_full_height_rail(self):
        for required in ('DFZVerifiedRailForPulse', 'DBRootStatusBarViewController',
                         'DBAppDockViewController', 'DBNotificationWindow',
                         'DFZFindNativeRailDockController', 'dockRect',
                         'matchingContent!=1', 'accepted.count==1',
                         'qa120-native-rail-owner'):
            self.assertIn(required,self.dock)
        # A 45x111 real AppDock from QA119 is less than 48% of the
        # measured 360pt display: the new resolver must not apply the old
        # overly strict Dock Zoom occupancy test to this native subtree.
        resolver=self.dock.split('static NSDictionary *DFZVerifiedRailForPulse',1)[1].split(
            '// Diagnostics only;',1)[0]
        self.assertNotIn('r.size.height>=height*.48',resolver)
        self.assertIn('isDescendantOfView:railWindow',resolver)
        self.assertIn('DFGFresh',resolver)  # stale session not admitted

    def test_one_measured_native_edge_or_emergency_fallback(self):
        self.assertIn('verified-native-rail',self.owner)
        self.assertIn('DFVerifiedNativeContent120',self.owner)
        self.assertIn('rail[@"Session"] isEqualToString:session',self.owner)
        self.assertIn('rail[@"ScreenScale"]',self.owner)
        self.assertIn('fabs(CGRectGetMaxX(dockRail)-CGRectGetMinX(content))',self.owner)
        self.assertIn('safeLeft=CGRectGetMinX(verifiedNativeContent)',self.owner)
        self.assertIn('MAX(42,screen.size.width*.082)',self.owner)  # safety rollback
        self.assertIn('qa120-safe-dock-fallback',self.owner)
        self.assertIn('sNativeRail120WaitCount<5',self.owner)
        self.assertNotIn('safeLeft=0;',self.owner)

    def test_original_size_formula_without_guessed_edge(self):
        # Measured same-session QA119 values; not a new width heuristic.
        rail=(0,45)
        native_content=(45,595)
        full_width=640
        legacy=max(42,full_width*.082)
        assert native_content[0]==rail[1]
        assert native_content[0]+native_content[1]==full_width
        self.assertAlmostEqual(legacy-native_content[0],7.48)

    def test_passive_per_tap_not_global_touch_replacement(self):
        self.assertIn('qa120-pane-tap',self.chrome)
        self.assertIn('qa120-hosted-touch-hit',self.host)
        self.assertIn('return hit==self?nil:hit;',self.chrome)
        self.assertIn('return target;',self.host)
        self.assertNotIn('IOHIDEventCreateDigitizerEvent',self.chrome)
        self.assertNotIn('DFPane116TraceClass(',self.chrome)
        # Native app-process YouTube .90 orientation source stays untouched.

    def test_unique_rootless_versions(self):
        import plistlib
        info=plistlib.loads((HERE/'Info.plist').read_bytes())
        self.assertEqual(info['CFBundleVersion'],'130')
        self.assertEqual(info['CFBundleShortVersionString'],'0.1.130')
        self.assertIn('0.1.130~sceneowner1',(HERE/'build.sh').read_text())
        self.assertIn('Version: 0.1.130~sceneowner1',(HERE/'control').read_text())
        integration=INTEGRATED.read_text()
        self.assertIn('VERSION="0.0.130~sceneowner1"',integration)
        self.assertIn('com.duoface.carplay.nativescenehost_0.1.130~sceneowner1',integration)


if __name__=='__main__':
    unittest.main()
