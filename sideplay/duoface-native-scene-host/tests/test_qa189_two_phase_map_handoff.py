"""Source-only QA189 handoff contracts; not on-car pixel, touch or logo PASS."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
REPO=ROOT.parents[1]
def read(p): return (REPO/p).read_text()
class BoundedNativeMapHandoff(unittest.TestCase):
 def setUp(self):
  self.m=read("sideplay/native-carplay-scene-v1/DF182NativeMaps.m")
  self.c=read("sideplay/duoface-native-scene-host/DFNative12Chrome.m")
  self.h=read("sideplay/duoface-native-scene-host/DF184NativeMapMembership.h")
  self.p=read("sideplay/duoface-native-scene-host/DFTouchOwnerProbe.m")
 def test_prelaunch_visible_presentation_hidden(self):
  region=self.m.split("- (BOOL)targetForWindow:",1)[1].split("- (BOOL)layoutOwnedPane",1)[0]
  self.assertIn("BOOL requiresHidden=self.presentedAt>0 || self.placed;",region)
  self.assertIn("requiresHidden?@NO:@YES",region)
  self.assertIn("PRELAUNCH-target-visible",region)
  self.assertIn("PRESENTED-or-COMMITTED-target-hidden",region)
  self.assertIn("presented-target-yield-expired-before-COMMITTED-STOP",self.m)
 def test_target_only_yield_after_real_membership(self):
  pane=self.c.split("- (void)layoutControls {",1)[1].split("- (void)refreshGlobalSpeedHUD164",1)[0]
  self.assertIn('BOOL nativeStage=[member[@"Stage"] isEqual:@"PRESENTED"]',pane)
  self.assertIn("nativeReserved=nativeStage &&",pane)
  self.assertIn("DF184MapMembershipAccepted(DF182Pulse()",pane)
  self.assertIn("appWindow.hidden=(self.startupActive || focusedElsewhere || nativeReserved);",pane)
  self.assertNotIn("releaseHostedView:",pane)
 def test_notification_carries_no_owner_authority(self):
  self.assertIn("DF184MapMembershipChanged",self.h)
  self.assertIn("if(saved)notify_post(DF184MapMembershipChanged);",self.m)
  self.assertIn("notify_post(DF184MapMembershipChanged); // Revoke",self.m)
  recv=self.p.split("int member=notify_register_dispatch(",1)[1].split("int ack=notify_register_dispatch(",1)[0]
  self.assertIn("DFSessionStillActive()",recv)
  self.assertIn("[sChrome reconcileNativeMaps184];",recv)
  self.assertIn("DFPublishPhysicalPaneSnapshot();",recv)
  self.assertNotIn("DFStopProbe(",recv)
 def test_rollback_is_non_destructive(self):
  recon=self.c.split("- (void)reconcileNativeMaps184 {",1)[1].split("- (BOOL)assignNativeMaps182:",1)[0]
  self.assertIn('self.lastNativeStage184=nil;',recon)
  self.assertIn('stage?:@"RELEASED"',recon)
  self.assertIn("qa184-maps-handoff-released-layout-rollback",recon)
  self.assertNotIn("stopAllHosts",recon)
  self.assertNotIn("releaseHostedView:",recon)
 def test_h1_recall_independent_of_optional_scene_state_channel(self):
  relay=read("sideplay/duoface-native-scene-host/DF154GeneralAppStateRelay.m")
  self.assertIn("DF155PilotAppID(bundle)",relay)
  self.assertIn("DF177InstallAppTouchHook(bundle);",relay)
  self.assertLess(relay.index("DF177InstallAppTouchHook(bundle);"),
                  relay.index("if(!DF156Listen(bundle,NO"))
  self.assertEqual(relay.count("DF177InstallAppTouchHook(bundle);"),1)
 def test_home_h1_keyboard_and_system_frame_are_not_bypassed(self):
  self.assertIn('DFStopProbe(@"inactive-or-stale-heartbeat")',self.p)
  self.assertIn('DFStopProbe(@"native-home-button")',self.p)
  self.assertIn('DF182Revoke(@"Chrome-Home-or-disconnect")',self.c)
  self.assertIn("[chrome noteUserActivity]",(ROOT/"DFH1Wake188.m").read_text())
  self.assertIn("return r;",self.m.split("static CGRect DF182Frame(",1)[1].split("static void DF182Present(",1)[0])
if __name__=="__main__": unittest.main()
