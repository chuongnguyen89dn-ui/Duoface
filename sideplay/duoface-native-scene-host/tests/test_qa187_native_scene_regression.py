"""QA187 source-only safety checks, not proof of on-car pixels/touch."""
from pathlib import Path
import unittest

R=Path(__file__).resolve().parents[3]
MAPS=R/"sideplay/native-carplay-scene-v1/DF182NativeMaps.m"
CHROME=R/"sideplay/duoface-native-scene-host/DFNative12Chrome.m"

class NativeMapsRegression(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.maps=MAPS.read_text()
  cls.chrome=CHROME.read_text()

 def test_system_scene_frame_returns_unmodified_original(self):
  frame=self.maps.split("static CGRect DF182Frame(",1)[1].split("static void DF182Present(",1)[0]
  self.assertIn("CGRect r=DF182OriginalFrame(obj,sel,info,proxy);",frame)
  self.assertIn("return r;",frame)
  self.assertIn("targetForWindow:DF182Owner.window",frame)
  self.assertIn("scene-frame-original-preserved",frame)
  for bad in ("r.size=", "r.origin=", "r=target", "updateSettingsWithBlock:"):
   self.assertNotIn(bad,frame)

 def test_saved_maps_cannot_autostart_native_or_phone_fallback(self):
  restore=self.chrome.split("- (void)restoreNextSavedWorkspaceApp {",1)[1].split("// Shift physical scene WINDOWS",1)[0]
  self.assertIn("native-maps-restore-deferred-explicit-picker-required",restore)
  self.assertNotIn('assignNativeMaps182:physical origin:@"workspace-restore"',restore)
  self.assertIn("continue; // No native launch and no phone-scene fallback.",restore)
  self.assertLess(restore.index('if([bundle isEqual:@"com.google.Maps"])'),
                  restore.index("hostViewForBundleID:bundle"))
  manual=self.chrome.split("- (void)appPicker:(DFAppPickerVC *)picker\n didSelectBundleID:",1)[1]
  self.assertIn("[self assignNativeMaps182:physicalSlot]",manual)

 def test_only_committed_owner_hides_existing_phone_pane(self):
  layout=self.chrome.split("- (void)layoutControls {",1)[1].split("- (void)refreshGlobalSpeedHUD164",1)[0]
  self.assertIn('member[@"Stage"] isEqual:@"COMMITTED"',layout)
  self.assertIn("DF184MapMembershipAccepted(DF182Pulse()",layout)
  self.assertIn("appWindow.hidden=(self.startupActive || focusedElsewhere || nativeReserved);",layout)
  reconcile=self.chrome.split("- (void)reconcileNativeMaps184 {",1)[1].split("- (BOOL)assignNativeMaps182:",1)[0]
  self.assertIn('if(valid && [receipt[@"Stage"] isEqual:@"COMMITTED"])',reconcile)
  self.assertIn("lastCommitted=key;",reconcile)
  self.assertIn("[self layoutControls];",reconcile)
  self.assertIn("qa184-maps-handoff-released-layout-rollback",reconcile)

 def test_owner_loss_home_revoke_still_fail_closed(self):
  self.assertIn('reason:@"committed-native-pane-attestation-lost-STOP"',self.maps)
  self.assertIn('DF182Revoke(reason?:@"native-pane-admission-failed")',self.maps)
  owner=(R/"sideplay/duoface-native-scene-host/DFTouchOwnerProbe.m").read_text()
  watchdog=owner.split("static void DFWatchdog(NSUInteger generation) {",1)[1].split("static void DFStartProbe",1)[0]
  self.assertIn('DFStopProbe(@"inactive-or-stale-heartbeat")',watchdog)
  self.assertIn("[sChrome reconcileNativeMaps184];",watchdog)

if __name__=="__main__":
 unittest.main()
