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
 def test_unverified_native_map_tap_reaches_native_coordinator(self):
  # OmniCar original distinguishes selected native CarPlay apps and phone bridge.
  # The absence of a snapshot cannot consume an explicit native map selection.
  start=PICKER.index("- (void)collectionView:(UICollectionView *)collectionView")
  end=PICKER.index("- (NSString *)verifiedRunningIDForIndex:",start)
  tap=PICKER[start:end]
  self.assertIn("DFPickerAllowsApp(app.bundleID,DFConfiguredEnabledAppIDs())",tap)
  self.assertIn("app.carPlayRoute178==DF178NativeMapReady ||",tap)
  self.assertIn("app.carPlayRoute178==DF178NativeMapUnverified){",tap)
  self.assertIn("[self.delegate appPicker:self didSelectNativeMapBundleID:app.bundleID",tap)
  self.assertNotIn('showAppPickerStatus:@"Bản đồ native chưa sẵn sàng"',tap)
  self.assertLess(tap.index("didSelectNativeMapBundleID:app.bundleID"),
                  tap.index("if(app.carPlayRoute178==DF178PhoneAppBridge)"))

 def test_native_attach_requires_actual_carplay_owner_ack(self):
  # Source contract only: genuine scene pixels and input require parked-car QA.
  coordinator=(ROOT.parent/"native-carplay-scene-v1"/"DFNativeMapPaneCoordinator.m").read_text()
  runtime=(ROOT.parent/"native-carplay-scene-v1"/"DFNativeMapLaunchRuntime.m").read_text()
  self.assertIn('@"Operation":@"Attach"',CHROME)
  self.assertIn('notify_post("com.duoface.nativehost.map-pane.command.v1")',CHROME)
  self.assertIn("DFNativeMapAckReadState",CHROME)
  self.assertIn("if(state==DFNativeMapAckApplied)",CHROME)
  self.assertIn("DFNativeMapSelectAttachAction(",coordinator)
  self.assertIn("DFNativeMapDispatchLaunchGuarded(",coordinator)
  self.assertIn("native-owner-attached-physical-frame-observed-map-tiles-not-verified",coordinator)
  self.assertIn("native-launch-carplay-declaration-unverified",runtime)
  self.assertIn('sel_registerName("handleEvent:")',runtime)
if __name__=="__main__":unittest.main()
