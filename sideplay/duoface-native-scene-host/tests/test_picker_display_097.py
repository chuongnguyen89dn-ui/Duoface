"""DuoFace strict iPhone allowlist and configurable CarPlay App picker regression."""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(name):return (ROOT/name).read_text(encoding="utf-8")
class AppPicker097(unittest.TestCase):
 def test_only_iphone_approved_apps_visible(self):
  policy=read("DFEnabledAppsPolicy.h")
  phone=read("DFNativeHostRootController.m")
  picker=read("DFAppPickerVC.m")
  self.assertIn("(enabled && [enabled containsObject:bundleID])",policy)
  self.assertIn("BOOL selected=enabled && [enabled containsObject:bid];",phone)
  self.assertIn("existing?:@[]",phone)
  self.assertIn("DFPickerAllowsApp(app.bundleID,enabled)",picker)
  self.assertIn("DFPickerAllowsApp(app.bundleID,DFConfiguredEnabledAppIDs())",picker)
 def test_grid_and_names_are_iPhone_preference_not_scene_geometry(self):
  display=read("DFAppPickerDisplayPolicy.h")
  phone=read("DFNativeHostRootController.m")
  picker=read("DFAppPickerVC.m")
  for token in ("GridColumns","GridRows","ShowAppNames","DFPickerCapacity",
                "DFSavePickerDisplay","DFPickerDisplayChanged"):
   self.assertIn(token,display)
  self.assertIn("showPickerDisplaySettings",phone)
  self.assertIn("count<=6",phone)
  self.assertIn("count<=3",phone)
  self.assertIn("Ẩn tên App",phone)
  self.assertIn("MAX(1,columns)",picker)
  self.assertIn("MAX(1,rows)",picker)
  self.assertIn("card.showsAppName=self.showAppNames;",picker)
  self.assertIn("self.runningMode?4:self.gridColumns",picker)
  self.assertIn("self.runningMode?1:self.gridRows",picker)
  self.assertIn("notify_cancel(self.displayNotifyToken)",picker)
  self.assertNotIn("DFPickerDisplayPath",read("DFSceneHost.m"))
 def test_iphone_is_sole_app_permission_owner(self):
  picker=read("DFAppPickerVC.m")
  phone=read("DFNativeHostRootController.m")
  self.assertIn("DFPickerAllowsApp(app.bundleID,enabled)",picker)
  self.assertIn("DFPickerAllowsApp(app.bundleID,DFConfiguredEnabledAppIDs())",picker)
  self.assertIn("if((NSUInteger)indexPath.item>=display.count)return;",picker)
  self.assertIn("return [self pageCount]*MAX(1,self.cardsPerPage);",picker)
  self.assertIn("NSInteger count=(NSInteger)self.visibleApps.count;",picker)
  for forbidden in ("DFAddMoreAppsController", "presentAddMore", "showCategoryMenu",
                    "categoryButton", "categoryMode",
                    "UIAlertController", "UINavigationController",
                    "DFWriteEnabledAppIDs(", "plus.circle.fill"):
   self.assertNotIn(forbidden,picker)
  self.assertIn("My Apps — Đã chọn",phone)
  self.assertIn("DFWriteEnabledAppIDs",phone)
  self.assertIn("Bật đề xuất",phone)
  self.assertIn("Bật tất cả",phone)
  self.assertIn("Tắt tất cả",phone)
 def test_carplay_filter_is_not_a_popup_and_only_displays_iphone_selection(self):
  picker=read("DFAppPickerVC.m")
  self.assertIn("return self.apps;",picker)
  self.assertIn("DFRankAppIDsByHabits(",picker)
  self.assertIn("self.pageControl.frame=CGRectMake(8,",picker)
  self.assertIn("self.runningMode?4:self.gridColumns",picker)
  self.assertIn("self.runningMode?1:self.gridRows",picker)
  self.assertNotIn("DFAddMoreRow",picker)
  self.assertNotIn("Phân loại ứng dụng",picker)
 def test_keep_original_critical_runtime_untouched(self):
  build=read("build.sh")
  for token in ("DFYouTubeOrientationRelay.m","DFCarPlayDockOwner.m",
               "DFNativeMapPaneCoordinator.m","DFNative12Chrome.m"):
   self.assertIn(token,build)
  self.assertIn("DFRecordReadyAppHabit(self.bundleID)",read("DFSceneHost.m"))
  chrome=read("DFNative12Chrome.m")
  self.assertNotIn("DFRecordReadyAppHabit",chrome)
if __name__=="__main__":unittest.main(verbosity=2)
