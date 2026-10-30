"""QA123 first-party owned hosted-scene under-lock policy source regression.

Only registered LIVE CarPlay/external scene may be exempted from background
decisions; no device passcode, SBMainWorkspace or arbitrary app hook.
"""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class UnderLockOwner123(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.code=(ROOT/'DFSceneLifecycle.m').read_text()
        cls.host=(ROOT/'DFNativeHostAppDelegate.m').read_text()
        cls.touch=(ROOT/'DFTouchOwnerProbe.m').read_text()
    def test_exact_two_decision_selectors_only(self):
        s=self.code
        self.assertIn('SBSuspendedUnderLockManager',s)
        self.assertIn('_shouldBeBackgroundUnderLockForScene:withSettings:',s)
        self.assertIn('shouldBeUnderLockForScene:',s)
        self.assertIn('DFLockABI(bg,4)',s)
        self.assertIn('DFLockABI(ul,3)',s)
        self.assertNotIn('interceptUpdateForScene:withNewSettings:',s)
    def test_foreign_scene_uses_original_system_method(self):
        s=self.code
        self.assertIn('return sOriginalBackgroundUnderLock(manager,cmd,scene,settings);',s)
        self.assertIn('return sOriginalShouldUnderLock(manager,cmd,scene);',s)
        self.assertIn('if(DFIsOwnedHostedLockScene123(scene))',s)
        self.assertIn('DFIsOwnedManualSceneObserver(controller,handle)',s)
        self.assertIn('sOwners.keyEnumerator.allObjects',s)
    def test_true_physical_carplay_and_fresh_session(self):
        s=self.code
        self.assertIn('com.duoface.nativehost.touchowner.session.plist',s)
        self.assertIn('age>2.5',s)
        self.assertIn('pulse[@"Active"]',s)
        self.assertIn('UIScreen.mainScreen',s)
        self.assertIn('window.hidden',s)
        self.assertIn('view.alpha<=0.0',s)
        self.assertIn('isHostingAnApp',s)
        self.assertNotIn('SBSuspendedUnderLockManager sharedInstance',s)
    def test_no_passcode_hook_or_foreign_global_policy(self):
        s=self.code
        self.assertNotIn('NSClassFromString(@"SBMainWorkspace")',s)
        self.assertNotIn('isPasscodeLockedOrBlockedWithResult:',s)
        self.assertNotIn('canActivateApplication:withResult:',s)
        self.assertNotIn('CBDuoNaviHosted',s)
        self.assertNotIn('CBCarBridgeHosted',s)
        self.assertNotIn('BKSDisplayServicesSetScreenBlanked',s)
    def test_preserve_old_host_home_teardown_and_geometry(self):
        self.assertIn('qa124-scene-resign-retained-await-background',self.host)
        self.assertIn('scene-background',self.host)
        self.assertIn('DFVerifiedNativeContent120',self.touch)
        self.assertIn('hideAllExternalWindowsImmediately',self.touch)
        self.assertIn('DFCarPlayPreventIdleSystemSleep121',self.touch)
if __name__=='__main__':unittest.main()
