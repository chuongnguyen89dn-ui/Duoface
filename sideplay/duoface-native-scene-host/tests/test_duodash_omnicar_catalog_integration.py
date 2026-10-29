"""DuoDash/OmniCar independently composed management and real scene gate."""
import unittest
from pathlib import Path
R=Path(__file__).resolve().parents[1]
class AppManagerIntegrated(unittest.TestCase):
 def test_real_iphone_groups_search_and_native_map(self):
  s=(R/"DFNativeHostRootController.m").read_text()
  for name in ("DFCatalogRecordsFromProxies","UISearchBar","appsInGroup:","My Apps — Đã chọn",
   "Ứng dụng hệ thống","Tìm ứng dụng đã cài","showNativeMapPaneChoices","appSwitchToggled:",
   "showAppSettingsActions"):
   self.assertIn(name,s)
 def test_current_picker_rechecks_selected_allowed_bundle(self):
  p=(R/"DFAppPickerVC.m").read_text()
  self.assertIn("DFPickerAllowsApp(app.bundleID,DFConfiguredEnabledAppIDs())",p)
  self.assertIn("DFPickerAllowsApp(app.bundleID,enabled)",p)
  self.assertIn("[self refreshInstalledApps];",p)
 def test_original_inspired_catalog_only_no_vendor_code(self):
  c=(R/"DFAppCatalogPolicy.h").read_text()
  for term in ("isPlaceholder","isLaunchProhibited","appTags","applicationType","DFCatalogRecordsFromProxies"):
   self.assertIn(term,c)
  self.assertIn("DFCatalogRecordsFromProxies(proxies)",(R/"DFAppLibrary.m").read_text())
 def test_map_owner_and_protected_youtube_link(self):
  b=(R/"build.sh").read_text()
  self.assertIn("DFNativeMapPaneCoordinator.m",b)
  self.assertIn("DFYouTubeOrientationRelay.m",b)
if __name__=="__main__":unittest.main()
