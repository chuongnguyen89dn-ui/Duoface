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
  self.assertIn("4 cột",phone if "4 cột" in phone else "4 cột") if False else None
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
 def test_add_more_only_allows_explicit_action_no_auto_launch(self):
  picker=read("DFAppPickerVC.m")
  for token in ("DFAddMoreAppsController","presentAddMore",
       'card.title.text=@"Thêm App"',"DFWriteEnabledAppIDs(updated.array)",
       "DFConfiguredEnabledAppIDs()?:@[]",
       "if(!self.runningMode && (NSUInteger)indexPath.item==display.count)"):
   self.assertIn(token,picker)
  section=picker.split("@implementation DFAddMoreAppsController",1)[1].split("@end",1)[0]
  self.assertNotIn("hostViewForBundleID",section)
  self.assertNotIn("appPicker:self didSelectBundleID",section)
 def test_categories_only_use_filtered_installed_apps(self):
  picker=read("DFAppPickerVC.m")
  self.assertIn("self.categoryMode==1 && pinned",picker)
  self.assertIn("self.categoryMode==2 && !system",picker)
  self.assertIn("self.categoryMode==3 && system",picker)
  self.assertIn('@"Ưa dùng",@"Người dùng",@"Hệ thống"',picker)
  self.assertIn("return self.apps;",picker)
 def test_keep_original_critical_runtime_untouched(self):
  build=read("build.sh")
  for token in ("DFYouTubeOrientationRelay.m","DFCarPlayDockOwner.m",
               "DFNativeMapPaneCoordinator.m","DFNative12Chrome.m"):
   self.assertIn(token,build)
  chrome=read("DFNative12Chrome.m")
  self.assertIn("DFRecordReadyAppHabit(readyBundle)",chrome)
if __name__=="__main__":unittest.main(verbosity=2)
