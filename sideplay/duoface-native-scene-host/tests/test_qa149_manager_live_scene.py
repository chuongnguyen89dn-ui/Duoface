"""QA149 static wiring and ownership boundaries, NOT physical CarPlay parity."""
from pathlib import Path
import unittest,hashlib

R=Path(__file__).resolve().parents[1]
solo=(R/"DFHomeStandalone144.m").read_text()
dock=(R/"DFNativeDockSync147.h").read_text()
fsm=(R/"DFManagerLifecycle149.h").read_text()
host=(R/"DFSceneHost.m").read_bytes()

class FirstPartyManagerLiveReceipt(unittest.TestCase):
 def test_manager_receipt_only_after_real_host_observation(self):
  body=solo.split("- (void)attemptOwnedReadyForView:",1)[1].split("- (void)sceneReady:",1)[0]
  self.assertLess(body.index("isLiveSceneForHostedView:v"),body.index('reply:@"manager-owned-live-scene-pixels-unverified"'))
  self.assertLess(body.index("bundleIDForHostedView:v"),body.index('reply:@"manager-owned-live-scene-pixels-unverified"'))
  self.assertLess(body.index('reply:@"manager-owned-live-scene-pixels-unverified"'),body.index("verifiedPIDForHostedView:v"))
  self.assertIn("if(!self.emittedManager)",body)
  self.assertIn("self.generation!=generation",body)
  self.assertIn("self.surface!=v",body)
  self.assertIn("self.emittedManager=NO",solo)
  self.assertIn("manager-live-scene-revoked",solo)
 def test_native_dock_receives_manager_and_pid_as_independent_facts(self):
  self.assertIn('#import "DFManagerLifecycle149.h"',dock)
  self.assertIn('managerLive=[outcome isEqual:@"manager-owned-live-scene-pixels-unverified"]',dock)
  self.assertIn("DF149Receive(&DF149Life,identity,fresh,",dock)
  self.assertIn("managerLive || (hosted&&pid),hosted&&pid,terminal",dock)
  self.assertIn("DF147ResultAction(&DF147Life,identity,fresh,hosted,terminal,pid)",dock)
  self.assertIn("if(managerAction==DF149ManagerActivate && action==DF147Ignore)",dock)
  self.assertIn("DF147Life.pending=false;DF147Life.active=true;",dock)
  self.assertIn("notify_post(DF148OwnerRevokeStopNotify);",dock)
  self.assertIn("DF149Revoke(&DF149Life)",dock)
  self.assertIn("pidObserved",fsm)
 def test_dock_tap_selected_manager_and_original_native_fallback(self):
  m=dock.split("static void DF149ObserveDockPressed",1)[1].split("static void DF147InstallNativeSwitchHook",1)[0]
  for mark in ("_dockButtonPressed:","method_getNumberOfArguments(m)!=3",
     "method_getReturnType(m,r,sizeof(r))","DF144Allowed(bid)",
     "DF144LiveReceiver()","DF147FindDock(session,&home)==receiver",
     'DF144BeginSelectedBridge(bid,receiver,@"CarPlayDockStandalone144")',
     "if(!handled)","DF149NativeDockPressedOriginal(receiver,sel,button)"):
   self.assertIn(mark,m)
  self.assertNotIn("notify_post(DF144RequestNotify)",m)
 def test_no_frozen_host_mutation_or_fake_pid_or_render_claim(self):
  h=hashlib.sha1(b"blob "+str(len(host)).encode()+b"\0"+host).hexdigest()
  self.assertIn(h, {"aeb6178654eebe3a052e358febcc0b2519c3ac54", "d1a71c03041d0d71f4a4ac6364ee14f84bf7f3de", "6a3c073f9d7502d588eb441d4ecb6c546c3f09f8", "2686c4531e480831af3db445fe5f3d7e9d7ded5d"}) # original and reviewed QA160 solo-only fast probe
  self.assertNotIn("scene-ready-and-play-verified",solo)
  self.assertIn('@"manager-owned-live-scene-pixels-unverified"',solo)
  self.assertIn("DF147DockABI",dock)

if __name__=="__main__": unittest.main()
