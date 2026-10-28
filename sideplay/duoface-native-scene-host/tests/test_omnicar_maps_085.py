import pathlib,unittest
R=pathlib.Path(__file__).resolve().parents[1]
def src(s):return (R/s).read_text()
class OriginalOmniMap85(unittest.TestCase):
 def test_original_omnicar_shared_zoom_range_and_explicit_map_only_profile(self):
  p=src("DFHostedMapRenderSize.h")
  self.assertIn('@"com.apple.Maps"',p)
  self.assertIn('@"com.google.Maps"',p)
  self.assertIn('@"com.waze.iphone"',p)
  self.assertIn('@"vn.vietmap.live"',p)
  self.assertIn('DFIsMapNavigationBundle(bundleID)?0.80:0.50',p)
  self.assertIn('round(pane.width/z),round(pane.height/z)',p)
  self.assertIn('z<0.50||z>1.0',p)
 def test_host_lifecycle_and_active_owned_scene_only(self):
  h=src("DFSceneHost.m")
  self.assertIn('DFHostedLogicalSizeForBundle(size,self.bundleID);',h)
  self.assertEqual(h.count('CGSize logical=DFHostedLogicalSizeForBundle(size,self.bundleID);'),2)
  self.assertIn('DFHostedLogicalSizeForBundle(surface.bounds.size,surface.bundleID)',h)
  self.assertLess(h.index('(void)DFSceneOrientationPolicyInstall();'),h.index('DFHostInt(self.appController, @"setRequestedMode:", 2);'))
  ready=h.split('if (!self.ready) {',1)[1].split('[[NSNotificationCenter defaultCenter]',1)[0]
  self.assertLess(ready.index('[self registerOwnedOrientationForDeviceController:nil]'),
                  ready.index('[self layoutScene]'))
  self.assertIn('surface.sceneGeneration!=generation',h)
  self.assertIn('surface.owner.live[surface.bundleID]!=surface',h)
  self.assertIn('[self revokeOrientationPolicy];',h)
  self.assertIn('DFSceneLifecycleUnregister(self.appController);',h)
 def test_native_carplay_app_scene_is_not_faked_by_map_zoom(self):
  h=src("DFHostedMapRenderSize.h")
  srcHost=src("DFSceneHost.m")
  self.assertNotIn('CPMapTemplate',h)
  self.assertNotIn('CPWindow',h)
  self.assertNotIn('setInterfaceOrientation:',srcHost)
  self.assertNotIn('requestGeometryUpdate',srcHost)
 def test_known_good_083_scoped_manual_scene_observer_kept(self):
  a=src("DFSceneLifecycle.m")
  self.assertIn('DFIsOwnedManualSceneObserver',a)
  self.assertIn('sPreviousSceneObserver(controller,selector,handle,diff,previousSettings)',a)
  self.assertIn('!((BOOL(*)(id,SEL))objc_msgSend)(controller,autoSel)',a)
if __name__=="__main__":unittest.main(verbosity=2)
