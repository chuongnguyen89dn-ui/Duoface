"""Native12 original iPhone Apps Manager vs one-app CarPlay picker contract.
Source-level unit regression only; physical CarPlay UI/scene remains unverified.
Original evidence: runs 40699487806 / 40700551205, not vendor source code.
"""
from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class PhoneAppManager(unittest.TestCase):
 def test_phone_enable_toggles_and_bulk_actions_only_on_iphone(self):
  s=(R/"DFNativeHostRootController.m").read_text()
  for x in ("appSwitchToggled:","showAppSettingsActions","Bật tất cả",
            "Bật ứng dụng người dùng","Tắt tất cả",
            "DFWriteEnabledAppIDs","DFConfiguredEnabledAppIDs"):
   self.assertIn(x,s)
  self.assertIn("indexPath.row==0)[self showAppSettingsActions]",s)
  self.assertIn("if(self.tabs.selectedSegmentIndex==1)",s)
 def test_exact_catalog_single_selection_and_explicit_empty(self):
  p=(R/"DFAppPickerVC.m").read_text()
  c=(R/"DFNative12Chrome.m").read_text()
  h=(R/"DFEnabledAppsPolicy.h").read_text()
  self.assertIn("NSArray<NSString *> *enabled=DFConfiguredEnabledAppIDs();",p)
  self.assertIn("DFPickerAllowsApp(app.bundleID,enabled)",p)
  self.assertIn("appPicker:self didSelectBundleID:app.bundleID",p)
  self.assertIn("NSInteger slot=self.selectedSlot;",c)
  self.assertIn('@"EnabledBundleIDs":valid.array',h)
  self.assertIn('return nil;',h) # absent config preserves legacy state
  self.assertIn("(!enabled || [enabled containsObject:bundleID])",h)
  self.assertNotIn("enableAllApps",p)
 def test_no_player_or_dock_or_vendor_change(self):
  s=(R/"DFNativeHostRootController.m").read_text()
  self.assertNotIn("CBAppsManagerViewController",s)
  self.assertNotIn("CBLicenseSyncManager",s)
  self.assertNotIn("sbreload",s)
if __name__=="__main__":unittest.main()
