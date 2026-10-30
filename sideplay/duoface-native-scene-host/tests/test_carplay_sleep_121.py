"""QA121: independent, session-bound *system* idle assertion contract.

No bypass of iPhone passcode/screen lock, no forced display brightness, no
global app hooks, no proof of device Play behavior from source tests.
"""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class CarPlaySleepAssertion121(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.src=(ROOT/'DFTouchOwnerProbe.m').read_text()
    def test_true_native_session_only(self):
        src=self.src
        self.assertIn('static void DFCarPlayPreventIdleSystemSleep121(void)',src)
        self.assertIn('!sChrome || !sActivated || !sSession || !DFSessionStillActive()',src)
        self.assertIn('!DFConnectedCarDisplay()',src)
        self.assertIn('if([sSession isEqualToString:sDFCarPlaySystemSleepSession121])return',src)
    def test_original_verified_public_api_not_vendor(self):
        src=self.src
        self.assertIn('IOPMAssertionCreateWithName',src)
        self.assertIn('IOPMAssertionRelease',src)
        self.assertIn('CFSTR("PreventUserIdleSystemSleep"),255',src)
        self.assertIn('CFSTR("DuoFace active CarPlay session")',src)
        self.assertNotIn('DuoNaviDashboard.dylib',src)
        # QA132 adds independent BKS handling: unlike the older QA121
        # assertion it is scoped to a live app scene, locked protected data
        # and an exact current CarPlay session; never blindly wake.
        self.assertIn('BKSDisplayServicesSetScreenBlanked',src)
        self.assertIn('DFActiveHostedLockedPane132()',src)
        self.assertIn('DFReleaseScopedBlankPolicy132();',src)
        self.assertNotIn('setIdleTimerDisabled:',src)
    def test_release_before_scene_detach_and_watchdog(self):
        src=self.src
        stop=src.index('static void DFStopProbe(NSString *reason) {')
        release=src.index('DFCarPlayReleaseIdleSystem121();',stop)
        detach=src.index('[sChrome hideAllExternalWindowsImmediately]',stop)
        self.assertLess(stop,release)
        self.assertLess(release,detach)
        self.assertIn('DFStopProbe(@"inactive-or-stale-heartbeat")',src)
        self.assertIn('DFStopProbe(@"nativehost-disconnected")',src)
        self.assertIn('DFCarPlayPreventIdleSystemSleep121();',src[src.index('static void DFStartProbe(void) {'):])
    def test_never_prevent_display_sleep_or_override_iphone_lock(self):
        src=self.src
        self.assertNotIn('CFSTR("PreventUserIdleDisplaySleep")',src)
        self.assertNotIn('CFSTR("NoDisplaySleepAssertion")',src)
        self.assertNotIn('UIScreen.mainScreen.brightness=',src)
        self.assertNotIn('setBrightness:',src)
        self.assertNotIn('setUILocked:',src)
if __name__=='__main__':unittest.main()
