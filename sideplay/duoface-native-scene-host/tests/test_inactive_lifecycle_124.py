"""QA124 conservative lifecycle simplification: no device PASS claims.

The transition willResignActive can be caused by a temporary interruption
rather than CarPlay Home. Only background and disconnect revoke the session.
The actual decision on a physical locked iPhone still needs a same-session log.
"""
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

def method_body(source,signature):
    """A contiguous method region until the next ObjC instance method."""
    return source.split(signature,1)[1].split('\n- (void)',1)[0]

class InactiveCarPlayLifecycle124(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.native=(ROOT/'DFNativeHostAppDelegate.m').read_text()
        cls.owner=(ROOT/'DFTouchOwnerProbe.m').read_text()
        cls.lock=(ROOT/'DFSceneLifecycle.m').read_text()
        cls.chrome=(ROOT/'DFNative12Chrome.m').read_text()
        cls.dock=(ROOT/'DFCarPlayDockOwner.m').read_text()

    def test_resign_does_not_infer_home(self):
        source=self.native.split('@implementation DFNativeHostTemplateSceneDelegate',1)[1]
        resign=method_body(source,'- (void)sceneWillResignActive:(UIScene *)scene {')
        self.assertIn('qa124-scene-resign-retained-await-background',resign)
        self.assertNotIn('stopTouchOwnerWithReason',resign)
        self.assertNotIn('touchSession=nil',resign)

    def test_real_home_and_disconnect_still_revoke(self):
        source=self.native.split('@implementation DFNativeHostTemplateSceneDelegate',1)[1]
        background=method_body(source,'- (void)sceneDidEnterBackground:(UIScene *)scene {')
        disconnect=method_body(source,'- (void)sceneDidDisconnect:(UIScene *)scene {')
        self.assertIn('stopTouchOwnerWithReason:@"scene-background"',background)
        self.assertIn('stopTouchOwnerWithReason:@"scene-disconnected"',disconnect)
        self.assertIn('@"Active":@NO',source)
        self.assertIn('com.duoface.nativehost.touchowner.stop.v1',source)

    def test_foreground_inactive_heartbeat_without_infinite_lease(self):
        source=self.native.split('@implementation DFNativeHostTemplateSceneDelegate',1)[1]
        heartbeat=method_body(source,'- (void)renewTouchOwnerHeartbeat:(NSTimer *)timer {')
        self.assertIn('UISceneActivationStateForegroundActive',heartbeat)
        self.assertIn('UISceneActivationStateForegroundInactive',heartbeat)
        self.assertIn('!mayRenew',heartbeat)
        self.assertIn('scene-background-or-external-window-lost',heartbeat)
        self.assertIn('self.carWindow.screen==UIScreen.mainScreen',heartbeat)
        self.assertNotIn('not-active-or-home',heartbeat)
        self.assertIn('stopTouchOwnerWithReason:@"heartbeat-write-failed"',heartbeat)

    def test_cross_process_watchdog_has_unchanged_release(self):
        self.assertIn('age>2.5',self.owner)
        self.assertIn('DFStopProbe(@"inactive-or-stale-heartbeat")',self.owner)
        self.assertIn('hideAllExternalWindowsImmediately',self.owner)
        self.assertIn('DFCarPlayReleaseIdleSystem121();',self.owner)
        self.assertIn('DFVerifiedNativeContent120',self.owner)

    def test_underlock_only_current_owned_external_scene(self):
        self.assertIn('if(!isfinite(age) || age<0 || age>2.5)return NO;',self.lock)
        self.assertIn('pulse[@"Active"] boolValue',self.lock)
        self.assertIn('DFIsOwnedManualSceneObserver(controller,handle)',self.lock)
        self.assertIn('window.screen==UIScreen.mainScreen',self.lock)
        self.assertIn('return sOriginalBackgroundUnderLock(manager,cmd,scene,settings);',self.lock)
        self.assertIn('scoped-existing-background-hook-installed',self.lock)
        for dangerous in ('isPasscodeLockedOrBlockedWithResult:',
                          'BKSDisplayServicesSetScreenBlanked',
                          'setUILocked:'):
            self.assertNotIn(dangerous,self.lock)

    def test_dock_orientation_and_divider_unchanged(self):
        self.assertIn('qa120-native-rail-owner',self.dock)
        self.assertIn('hideAllExternalWindowsImmediately',self.chrome)
        self.assertIn('completeWholeHostZoomRequest:',self.owner)

if __name__=='__main__':
    unittest.main()
