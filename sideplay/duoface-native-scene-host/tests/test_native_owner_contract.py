"""Integration gates around native owner acquisition, Home, and consumer wiring.
Behavioral policy/record checks run as C and Foundation executables in SDK CI.
"""
from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class NativeOwnerContract(unittest.TestCase):
    def test_home_forwards_both_originals_once_and_checks_abi(self):
        s=(R/'DFCarPlayOwnerObserver.h').read_text()
        for name in ('DB','CAR'):
            body=s.split(f'static void DFOwner{name}Home(id object,SEL sel,id event) {{',1)[1].split('\n}',1)[0]
            self.assertEqual(body.count(f'DFOwner{name}HomeOriginal(object,sel,event);'),1)
            self.assertLess(body.index('DFOwnerHomeReceived(object)'),body.index(f'DFOwner{name}HomeOriginal'))
        for gate in ('method_getNumberOfArguments(m)!=3','strcmp(type,"v")',"type[0]!='@'",'MSHookMessageEx','DFOwnerHomeCoverage()'):
            self.assertIn(gate,s)
        for forbidden in ('setUILocked:', 'setBrightness:', 'sendEvent:', 'BKSDisplayServicesSetScreenBlanked'):
            self.assertNotIn(forbidden,s)

    def test_background_cannot_acquire_native_owner(self):
        s=(R/'DFCarPlayOwnerObserver.h').read_text()
        bind=s.split('if(!sameSession) {',1)[1].split('    BOOL active=',1)[0]
        for term in ('DFOwnerFreshTime(', '![pulse[@"HostBackground"] isEqual:@YES]', 'DFOwnerHomeHooksReady', 'DFOwnerBoundNativeScene=', 'DFOwnerBoundController='):
            self.assertIn(term,bind)
        for term in ('found.count==1', 'candidate[@"Controller"]==DFOwnerBoundController', 'DFOwnerVisibleController(vc)', '@"isForeground"', 'native-owner-state'):
            self.assertIn(term,s)

    def test_background_retention_and_all_core_readers_share_validator(self):
        native=(R/'DFNativeHostAppDelegate.m').read_text()
        self.assertIn('DFOwnerNativeEvidence(self.touchSession,scene.session.persistentIdentifier)',native)
        self.assertIn('DFOwnerMayRenew(',native)
        self.assertIn('DFOwnerSessionRevoked(weakOwner.touchSession)',native)
        for name in ('DFTouchOwnerProbe.m','DFSceneLifecycle.m','DFCarPlayDockOwner.m'):
            self.assertIn('DFOwnerAcceptPulse(pulse)',(R/name).read_text())
        probe=(R/'DFTouchOwnerProbe.m').read_text()
        self.assertIn('if(!DFSessionStillActive())DFStopProbe',probe)
        self.assertIn('if(sSession && DFOwnerSessionRevoked(sSession))',probe)
        self.assertIn('DFStopProbe(@"native-home-button")',probe)
        self.assertIn('stopTouchOwnerWithReason:@"scene-disconnected"',native)

if __name__=='__main__':unittest.main()
