"""QA184 static contracts. These cannot prove display pixels or vehicle touch."""
import pathlib, unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
REPO=ROOT.parents[1]
def source(p): return (REPO/p).read_text()
class QA184NativeOwner(unittest.TestCase):
 def test_real_present_gate_before_owner_lease(self):
  s=source('sideplay/native-carplay-scene-v1/DF182NativeMaps.m')
  gate=s.split('static void DF182Present(',1)[1].split('static void DF182Deactivate',1)[0]
  self.assertLess(gate.index('DF182OriginalPresent('),gate.index('publishMembershipStage:@"PRESENTED"'))
  self.assertIn('presentBaseViewController:animated:launchSource:completion:',s)
  self.assertIn('DF182Method(root,',s)
  self.assertIn('DF182OriginalPresent(root,sel,base,animated,source,completion);',s)
  self.assertIn('publishMembershipStage:@"COMMITTED" controller:vc',s)
  self.assertIn('publishMembershipStage:@"COMMITTED" controller:self.owner',s)
  self.assertIn('[self clearMembership];',s)
  self.assertIn('@"REVOKED"',s)
  self.assertIn('DF182Revoke(reason?:@"native-pane-admission-failed")',s)
  self.assertIn('DF184Fresh(NSDate.date.timeIntervalSince1970,receipt[@"Timestamp"],0.85)',s)
 def test_shared_authority_and_strict_springboard(self):
  m=source('sideplay/duoface-native-scene-host/DF184NativeMapMembership.h')
  lease=source('sideplay/duoface-native-scene-host/DFCarPlayOwnerLease.h')
  app=source('sideplay/duoface-native-scene-host/DFNativeHostAppDelegate.m')
  sb=source('sideplay/duoface-native-scene-host/DFTouchOwnerProbe.m')
  for name in ('AssignmentID','Session','NativeSceneID','PhysicalSlot','HostSceneID','SceneClass',
               'ControllerClass','WindowRole','SceneHostAttached','HomeHookReady',
               'PresentedAt','PRESENTED','COMMITTED','REVOKED'):
   self.assertIn(name,m)
  self.assertIn('DF184Fresh(now,member[@"PresentedAt"],0.85)',m)
  self.assertIn('DF184Fresh(now,member[@"Timestamp"],1.25)',m)
  self.assertIn('DFOwnerAcceptRecords(pulse,owner,revoke,now)',lease)
  self.assertIn('DF184MapMembershipAccepted(pulse,owner,',lease)
  self.assertIn('DFOwnerNativeMapsEvidence(self.touchSession,hostID)',app)
  self.assertIn('DFOwnerAcceptPulse(pulse)',sb)
  self.assertIn('DFStopProbe(@"inactive-or-stale-heartbeat")',sb)
  self.assertNotIn('watchdogDisabled',sb)
 def test_other_pane_preserved_and_rollback(self):
  chrome=source('sideplay/duoface-native-scene-host/DFNative12Chrome.m')
  s=source('sideplay/native-carplay-scene-v1/DF182NativeMaps.m')
  segment=chrome.split('- (BOOL)assignNativeMaps182:(NSInteger)physical {',1)[1].split('- (void)appPicker:',1)[0]
  self.assertNotIn('releaseHostedView:',segment)
  self.assertNotIn('self.hostedScenes[(NSUInteger)i]=NSNull.null;',segment)
  self.assertIn('self.lastNativeAssignment184=assignment[@"AssignmentID"];',segment)
  self.assertIn('reconcileNativeMaps184',chrome)
  self.assertIn('qa184-maps-handoff-released-layout-rollback',chrome)
  self.assertIn('app-replaced-in-native-slot',chrome)
  self.assertNotIn('![e[@"HasLiveApp"] isEqual:@NO]',s)
  self.assertNotIn('hostViewForBundleID:',s)
 def test_h1_previous_user_routes_unmodified(self):
  # Existing QA182 and H1 freeze tests run separately in macOS CI.
  s=source('sideplay/duoface-native-scene-host/DFNative12Chrome.m')
  self.assertIn('DF182Revoke(@"Chrome-Home-or-disconnect")',s)
  self.assertIn('DF182Revoke(@"app-replaced-in-native-slot")',s)
if __name__=='__main__': unittest.main()
