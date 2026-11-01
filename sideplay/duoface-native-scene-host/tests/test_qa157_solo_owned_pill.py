"""QA157 staged first-party SOLO ellipsis and picker owner boundary.
Only static/source contract; no simulated pixels, native CarPlay or device PASS.
"""
from pathlib import Path
import unittest

R=Path(__file__).resolve().parents[1]
SOLO=(R/"DFHomeStandalone144.m").read_text()
PILL=(R/"DFSoloPill157.h").read_text()
BROKER=(R/"DFSoloPickerCarPlay157.h").read_text()
BUILD=(R/"build.sh").read_text()
HOME=(R/"DFCarPlayOwnerObserver.h").read_text()

class SoloOwnedMenu157(unittest.TestCase):
 def test_real_original_observation_yields_one_scene_owner(self):
  self.assertIn('#import "DFSoloPill157.h"',SOLO)
  self.assertIn('#import "DFSoloPickerCarPlay157.h"',SOLO)
  self.assertEqual(SOLO.count("[[DFSceneHost sharedHost] hostViewForBundleID:self.bundle error:&err]"),1)
  self.assertNotIn("[self df157InstallSoloMenuWithUsableRect:usable]",SOLO)
  self.assertNotIn("self.soloPill.hidden=NO",SOLO)
  self.assertIn("setSplitMode:NO",SOLO)
  self.assertNotIn("hostViewForBundleID:",PILL)
  self.assertNotIn("UIRootSceneWindow",PILL)
  self.assertNotIn("DFNative12Chrome",PILL)
 def test_picker_delegates_to_current_bridge_not_direct_springboard(self):
  self.assertIn("DFAppPickerVC",SOLO)
  self.assertIn("self.soloPicker.delegate",SOLO.replace("[self.soloPicker setDelegate:nil]","self.soloPicker.delegate=nil"))
  self.assertIn("DF144PickerRequest atomically:YES",PILL)  # legacy inactive path
  self.assertIn("notify_post(DF144PickerNotify)",PILL)
  self.assertNotIn("DF144BeginSelectedBridge",PILL)
  self.assertNotIn("requestStateChange:",PILL)
  self.assertIn("DF147Life.active && !DF147Life.pending",BROKER)
  self.assertIn("[p[@\"RequestID\"] isEqual:DF147RequestID]",BROKER)
  self.assertIn("[p[@\"CarDisplayID\"] isEqual:DF147Session]",BROKER)
  self.assertIn("DF144BeginSelectedBridge(bundle,home?:dock",BROKER)
  self.assertIn('@"CarPlayDockStandalone144"',BROKER)
 def test_native_dock_no_guest_app_stolen_and_home_unchanged(self):
  self.assertIn("DFOwnerDBHomeOriginal(object,sel,event);",HOME)
  self.assertIn('notify_post("com.duoface.nativehost.standalone144.stop")',HOME)
  self.assertNotIn("DF157RegisterSoloPickerReceiver();",SOLO)
  self.assertIn("if(self.window)self.window.hidden=YES",SOLO)
  self.assertIn("[self.soloPicker setDelegate:nil]",SOLO)
  self.assertIn("DFAppPickerVC.m",BUILD)
  self.assertIn("DFHomeStandalone144.m",BUILD)

if __name__=="__main__": unittest.main()
