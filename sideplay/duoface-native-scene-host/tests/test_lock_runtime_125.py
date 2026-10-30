"""QA125 iOS16.7.16 physical runtime ABI/source guard and Home safety."""
import unittest
from pathlib import Path
R=Path(__file__).resolve().parents[1]
class RuntimeABI125(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.s=(R/"DFSceneLifecycle.m").read_text()
  cls.host=(R/"DFNativeHostAppDelegate.m").read_text()
 def test_one_existing_exact_signature_only(self):
  s=self.s
  self.assertIn('_shouldBeBackgroundUnderLockForScene:withSettings:',s)
  self.assertIn('DFLockABI(bg,4)',s)
  self.assertIn('method_getImplementation(bg)',s)
  self.assertIn('shouldBeUnderLockForScene:',s)  # observed absence, diagnostic only
  self.assertNotIn('DFLockABI(ul,3)',s)
  self.assertNotIn('hook(cls,underlock,',s)
  self.assertNotIn('sOriginalShouldUnderLock',s)
  self.assertIn('scoped-existing-background-hook-installed',s)
 def test_owner_scope_and_no_global_lock_bypass(self):
  s=self.s
  self.assertIn('DFIsOwnedHostedLockScene123(scene)',s)
  self.assertIn('DFIsOwnedManualSceneObserver(controller,handle)',s)
  self.assertIn('sOriginalBackgroundUnderLock(manager,cmd,scene,settings)',s)
  self.assertIn('window.screen==UIScreen.mainScreen',s)
  self.assertIn('DFOwnerAcceptPulse(pulse)',s)
  for term in ('SBMainWorkspace','setUILocked:', 'isPasscodeLockedOrBlockedWithResult:',
               'canActivateApplication:withResult:', 'BKSDisplayServicesSetScreenBlanked'):
   self.assertNotIn(term,s)
 def test_home_and_lock_not_unconditionally_equated(self):
  s=self.host
  self.assertIn('qa125-background-boundary',s)
  self.assertIn('protected-data=',s)
  self.assertIn('external-window=',s)
  self.assertIn('stopTouchOwnerWithReason:@"scene-background"',s)
  self.assertIn('stopTouchOwnerWithReason:@"scene-disconnected"',s)
  self.assertNotIn('retain-even-when-scene-background',s)
 def test_version_wiring(self):
  root=R.parents[0]
  self.assertIn('0.1.131~clockprobe1',(R/'build.sh').read_text())
  self.assertIn('0.1.131~clockprobe1',(R/'control').read_text())
  self.assertIn('VERSION="0.0.131~clockprobe1"',(root/'jb-embedded-appbridge/package_integrated.py').read_text())
if __name__=="__main__":unittest.main()
