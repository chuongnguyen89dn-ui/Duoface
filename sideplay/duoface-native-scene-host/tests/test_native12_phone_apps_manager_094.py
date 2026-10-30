"""Phone Apps Manager original evidence and first-party cross-process regression.
Original Native12 runs: 40699487806 and 40700551205. Not a device result.
"""
from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
def read(name):return (R/name).read_text()
class PhoneAppManager094(unittest.TestCase):
 def test_phone_ui_handlers_with_real_toggle_and_actions(self):
  s=read("DFNativeHostRootController.m")
  for text in ("appSwitchToggled:", "showAppSettingsActions",
               'actionWithTitle:@"Bật đề xuất"',
               'actionWithTitle:@"Bật tất cả"',
               'actionWithTitle:@"Tắt tất cả"',
               "DFWriteEnabledAppIDs", "DFConfiguredEnabledAppIDs",
               "DFIsRecommendedAppID", "cell.accessoryView=toggle"):
   self.assertIn(text,s)
  self.assertIn("[self appSwitchToggled:toggle]",s)
  self.assertNotIn("CBAppsManagerViewController",s)
  self.assertNotIn("CBLicenseSyncManager",s)
 def test_carplay_catalog_gated_but_app_tap_is_single(self):
  picker=read("DFAppPickerVC.m")
  policy=read("DFEnabledAppsPolicy.h")
  chrome=read("DFNative12Chrome.m")
  for text in ("DFConfiguredEnabledAppIDs()", "DFCarPlaySelectedInstalledBundleIDs(",
               "notify_register_dispatch", "notify_cancel",
               "appPicker:self didSelectBundleID:app.bundleID"):
   self.assertIn(text,picker)
  self.assertIn("NSInteger slot=self.selectedSlot;",chrome)
  self.assertIn("notify_post(DFEnabledAppsChangedNotification)",policy)
  self.assertIn("readback && [readback isEqualToArray:ids.array]",policy)
  self.assertIn("return nil;",policy)
  self.assertIn("return @[];",policy)
 def test_recommended_replaces_state_not_union(self):
  phone=read("DFNativeHostRootController.m")
  part=phone.split('actionWithTitle:@"Bật đề xuất"',1)[1].split('actionWithTitle:@"Tắt tất cả"',1)[0]
  self.assertIn("DFWriteEnabledAppIDs(recommended)",part)
  self.assertNotIn("DFConfiguredEnabledAppIDs()",part)
  self.assertNotIn("killall",phone)
  self.assertNotIn("sbreload",phone)
 def test_player_dock_maps_preserved_in_build(self):
  build=read("build.sh")
  self.assertIn("DFYouTubeOrientationRelay.m",build)
  self.assertIn("DFCarPlayDockOwner.m",build)
  self.assertIn("DFNativeMapPaneCoordinator.m",build)
if __name__=="__main__":unittest.main()
