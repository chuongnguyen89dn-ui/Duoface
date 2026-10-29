"""Source contracts for safe subset of DuoFace expanded phone settings."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[2]/"duoface-native-scene-host"
def read(name):return (ROOT/name).read_text(encoding="utf-8")
class ExtendedSettings099(unittest.TestCase):
 def test_monitor_is_explicit_on_demand_read_only(self):
  phone=read("DFNativeHostRootController.m")
  start=phone.split("- (void)showDockMonitor:",1)[1].split("- (void)shareCarPlayDiagnostics:",1)[0]
  self.assertIn("touchowner.session.plist",start)
  self.assertIn("dockzoom.ack.plist",start)
  self.assertIn("dock[@\"Session\"] isEqualToString:session[@\"Session\"]",start)
  self.assertIn('dock[@"DockOwnerVerified"] isEqual:@YES',start)
  self.assertIn("ackAge<=3.0",start)
  self.assertIn("Dock: chưa có ACK hợp lệ",start)
  self.assertNotIn("notify_post(",start)
  self.assertNotIn("kill(",start)
  self.assertNotIn("setDockHidden:",start)
 def test_reset_only_safe_preferences(self):
  phone=read("DFNativeHostRootController.m")
  start=phone.split("- (void)showResetOptions {",1)[1].split("- (void)showWorkspaceRestoreMenu",1)[0]
  self.assertIn('DFSaveAppChoices(@"",@[])',start)
  self.assertIn("DFSavePickerDisplay(4,2,YES)",start)
  for forbidden in ("removeItemAtPath", "DFDockZoomToggle", "terminate", "DFWriteEnabledAppIDs", "closeHostedSlot"):
   self.assertNotIn(forbidden,start)
  self.assertIn("showResetOptions",phone)
 def test_hide_app_names_and_restore_are_real_existing_policies(self):
  policy=read("DFAppPickerDisplayPolicy.h")
  phone=read("DFNativeHostRootController.m")
  self.assertIn("ShowAppNames",policy)
  self.assertIn("DFSavePickerDisplay(columns,rows,!names)",phone)
  self.assertIn("DFSetRestoreOnReconnect(!enabled)",phone)
if __name__=="__main__":unittest.main(verbosity=2)
