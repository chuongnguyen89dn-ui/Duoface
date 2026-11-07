"""QA185 transaction contracts; real pixels/touch require vehicle testing."""
import pathlib, unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
REPO=ROOT.parents[1]
class Admission185(unittest.TestCase):
 def test_identity_before_visibility(self):
  s=(REPO/'sideplay/native-carplay-scene-v1/DF182NativeMaps.m').read_text()
  method=s.split('@implementation DF182MapsOwner',1)[1].split('- (BOOL)publishMembershipStage:',1)[1].split('- (BOOL)ownsOrPresenting:',1)[0]
  self.assertIn('DF185LaunchIdentityMatches(self.launchAssignment,choiceRead,nativeBundle)',method)
  self.assertNotIn('DF182Pulse()',method)
  self.assertNotIn('DF182AssignmentFromRecords',method)
  self.assertIn('if(committed) {\n  DF185_REQUIRE(DF185PostAdmissionVisible',method)
  self.assertIn('if(committed)\n  DF185_REQUIRE([self targetForWindow',method)
  self.assertIn('@"Session":self.launchAssignment[@"Session"]',method)
 def test_launch_is_captured_and_cancelled(self):
  s=(REPO/'sideplay/native-carplay-scene-v1/DF182NativeMaps.m').read_text()
  self.assertLess(s.index('self.launchAssignment=[launchRecord copy]'),s.index('NSDictionary *result=launch(self.assignment)'))
  self.assertIn('self.assignment=current;self.launchAssignment=nil;',s)
  self.assertIn('post-admission-visible-view-timeout-STOP',s)
  self.assertNotIn('v.hidden=NO',s)
  self.assertNotIn('viewIfLoaded.hidden=NO',s)
  self.assertIn('DF184Fresh(NSDate.date.timeIntervalSince1970,@(self.presentedAt),0.85)',s)
 def test_source_route_is_explicit(self):
  c=(ROOT/'DFNative12Chrome.m').read_text()
  # QA188: restored native-only saved Maps intent is an EXPLICIT request,
  # not native launch acceptance or a phone-scene fallback.
  restore=c.split('- (void)restoreNextSavedWorkspaceApp {',1)[1].split('// Shift physical scene WINDOWS',1)[0]
  self.assertIn('DFPickerAllowsApp(bundle,DFConfiguredEnabledAppIDs())',restore)
  self.assertIn('assignNativeMaps182:physical origin:@"workspace-restore"',restore)
  self.assertIn('scene=UNVERIFIED',restore)
  self.assertIn('continue; // Native scene only; no phone-scene fallback on failure.',restore)
  self.assertIn('origin:@"picker"',c)
  self.assertIn('DF182AssignForOrigin(physical,visual,origin)',c)
if __name__=='__main__': unittest.main()
