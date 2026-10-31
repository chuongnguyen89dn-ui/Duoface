"""QA146 regression: real iPhone Log22 native Home button must release
only independent standalone window, without requiring DuoFace CPTemplate.
Static source assertions are not a device-success claim.
"""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
owner=(ROOT/"DFCarPlayOwnerObserver.h").read_text()
solo=(ROOT/"DFHomeStandalone144.m").read_text()
build=(ROOT/"build.sh").read_text()

class StandaloneHomeExit(unittest.TestCase):
    def test_real_existing_native_home_callback_signals_independent_owner_first(self):
        body=owner.split("static void DFOwnerHomeReceived(id receiver) {",1)[1].split(
            "\nstatic void DFOwnerDBHome(",1)[0]
        self.assertIn("DBRootStatusBarViewController",body)
        self.assertIn('com.duoface.nativehost.standalone144.stop',body)
        self.assertIn('DFHome145Enabled()',body)
        self.assertIn('window.screen!=UIScreen.mainScreen',body)
        self.assertIn('UIWindowSceneSessionRoleCarPlay',body)
        self.assertLess(body.index('standalone144.stop'),body.index('DFOwnerValidSession(session)'),
                        "Solo Home/Back must not depend on DuoFace split session")
        self.assertIn('native-home-standalone-stop qa146',body)
    def test_original_system_home_still_forwarded_exactly_once(self):
        for name in ("DB","CAR"):
            body=owner.split("static void DFOwner%sHome(id object,SEL sel,id event) {"%name,1)[1].split("\n}",1)[0]
            self.assertEqual(body.count("DFOwner%sHomeOriginal(object,sel,event);"%name),1)
            self.assertLess(body.index("DFOwnerHomeReceived(object)"),body.index("DFOwner%sHomeOriginal"%name))
    def test_exact_standalone_owner_stop_not_split_ui(self):
        self.assertIn('DF144StopNotify="com.duoface.nativehost.standalone144.stop"',solo)
        self.assertIn('[DF144Owner stop:@"native-Home-exit"]',solo)
        self.assertIn('self.window.hidden=YES',solo)
        self.assertIn('releaseHostedView:view',solo)
        for forbidden in ('DFNative12Chrome', 'setSelectedSlot:0','DFHomeLaunch143.m'):
            self.assertNotIn(forbidden,owner)
    def test_preserve_existing_native_dock_and_home_handlers(self):
        self.assertIn('DFCarPlayDockOwner.m DFHomeStandalone144.m',build)
        self.assertIn('DFOwnerHomeCoverage()',owner)
        self.assertIn('DFOwnerRevokedSession=[session copy]',owner)
        self.assertIn('DFZRestore();',owner)

if __name__=="__main__":
    unittest.main()
