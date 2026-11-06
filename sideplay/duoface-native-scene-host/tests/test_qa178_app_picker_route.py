"""App picker must not send a known native map down phone-main-display scene host."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
CAT=(ROOT/"DFCarPlayAppRoute178.h").read_text()
LIB=(ROOT/"DFAppLibrary.m").read_text()
PICKER=(ROOT/"DFAppPickerVC.m").read_text()
CHROME=(ROOT/"DFNative12Chrome.m").read_text()
class AppRoster178(unittest.TestCase):
 def test_native_map_route_is_separate(self):
  self.assertIn("DFNativeMapAllowedBundle(bundle)",CAT)
  self.assertIn("DF178NativeMapUnverified",CAT)
  self.assertIn("DF178PhoneAppBridge",CAT)
  self.assertIn("DF178RouteForSelectedBundle",PICKER)
  self.assertIn("appPicker:self didSelectNativeMapBundleID:",PICKER)
 def test_picker_live_selected_inventory(self):
  self.assertIn("selectedAppFallbackForBundleIDs",LIB)
  self.assertIn("DFCarPlaySelectedInstalledBundleIDs",PICKER)
  self.assertIn("DFNativeMapCatalogBundles",PICKER)
  self.assertIn("DFPickerAllowsApp",PICKER)
 def test_no_native_owner_bypass_or_synthetic_home(self):
  for forbidden in ("MSHookMessageEx", "setIconState:forVehicleID:", "CPMapTemplate alloc"):
   self.assertNotIn(forbidden,CAT)
  self.assertIn("DFNativeMapAllowedBundle",CHROME)
  self.assertIn("DFNativeMapAckReadState",CHROME)
  self.assertIn("DFNativeMapFreshExplicitCommand",CHROME)
  self.assertIn("native-map-picker-ack-applied",CHROME)
if __name__=="__main__":unittest.main()
