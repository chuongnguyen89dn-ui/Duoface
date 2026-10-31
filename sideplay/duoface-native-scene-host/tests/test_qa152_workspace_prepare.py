"""QA152 source safety/ordering tests; CI cannot replace real iPhone runtime."""
import unittest
from pathlib import Path
import hashlib
R=Path(__file__).resolve().parents[1]
BRIDGE=(R/"DFHomeStandalone144.m").read_text()
PREP=(R/"DF152NativeWorkspacePrepare.h").read_text()
ONCE=(R/"DFNativePrepOnce152.h").read_text()
HOST=(R/"DFSceneHost.m").read_bytes()

class WorkspaceNativePreparation152(unittest.TestCase):
 def test_native_preparation_precedes_remote_scene_and_retains_original_home(self):
  launch=BRIDGE.split("static void DF144Launch(",1)[1].split("static void DF144Install(",1)[0]
  self.assertLess(launch.index("DF147Prepare(p)"),launch.index("DF152PrepareThenContinue(rid,bundle,display,self,^"))
  self.assertLess(launch.index("DF152PrepareThenContinue(rid,bundle,display,self,^"),launch.index("notify_post(DF144RequestNotify)"))
  self.assertIn('[still[@"RequestID"] isEqualToString:rid]',launch)
  self.assertIn('[still[@"BundleID"] isEqualToString:bundle]',launch)
  self.assertIn('[still[@"CarDisplayID"] isEqualToString:display]',launch)
  self.assertIn("DF147Life.pending",launch)
  self.assertIn("DF144LiveReceiver()",launch)
  self.assertIn("DF144UniqueNativeContentWindow(",launch)
  self.assertIn('DF144Original(self,cmd,manager,icon);return;',launch)
  self.assertIn("DF152RevokeNativePreparation();",BRIDGE)
  self.assertIn("notify_post(DF144StopNotify)",BRIDGE)
 def test_no_unverified_owner_app_or_foreground_deactivation(self):
  for x in ("DF151DashboardWorkspace","DF151DashboardOwner",
    "DF151IsDashboardOwner(owner)","homeWorkspace==workspace",
    "DF152ShowNativeApp(home,&showing)",
    'DF151SafeObjectGetter(workspace,"state"',
    'DF151SafeObjectGetter(state,"activeBundleIdentifier"',
    "[activeBundle isEqualToString:selectedBundle]",
    'DF152ExactClassMethod(controllerClass,"sharedInstance","@16@0:8")',
    'DF152ExactInstance(workspace,"requestStateChange:","v24@0:8@16")',
    'strcmp(method_getTypeEncoding(deactivate),"v24@0:8@16")',
    'strcmp(callbackType,"v24@0:8@?16")',
    'DF152ExactInstance(controller,"applicationWithBundleIdentifier:","@24@0:8@16")',
    'DF151SafeObjectGetter(officialApp,"bundleIdentifier",&actualBundle)',
    '[actualBundle isEqualToString:activeBundle]'):
   self.assertIn(x,PREP)
  self.assertNotIn("SBMainWorkspace",PREP)  # phone app eviction NOT guessed
  self.assertNotIn("setActiveBundleIdentifier:",PREP)  # Dock separate
 def test_once_completion_fallback_generation_and_home_revocation(self):
  self.assertIn("DF152Begin(&DF152Prep)",PREP)
  self.assertIn("DF152FinishOnce(&DF152Prep,generation)",PREP)
  self.assertIn("DF152Revoke(&DF152Prep)",PREP)
  self.assertIn("0.25*NSEC_PER_SEC",PREP)
  self.assertIn("workspace-completion",PREP)
  self.assertIn("native-workspace-fallback-250ms",PREP)
  self.assertIn("DF152CurrentRID",PREP)
  self.assertIn("DF152ResumeNative",PREP)
  self.assertIn("DF152FinishOnce",ONCE)
  self.assertIn("qa152-workspace-exception",PREP)
  self.assertIn("qa152-prep-stale-or-duplicate",PREP)
 def test_frozen_original_host_and_no_fabricated_readiness(self):
  blob=hashlib.sha1(b"blob "+str(len(HOST)).encode()+b"\0"+HOST).hexdigest()
  self.assertEqual(blob,"ec2924c145be4edaaa27b7320bb869b18de12c6b")
  self.assertIn("scene-hosted-render-and-touch-unverified",BRIDGE)
  self.assertNotIn("scene-ready-and-play-verified",BRIDGE)
  self.assertNotIn("setRequestedMode:",PREP)
if __name__=="__main__":
 unittest.main()
