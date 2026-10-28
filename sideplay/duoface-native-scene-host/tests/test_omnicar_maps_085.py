import pathlib,unittest
R=pathlib.Path(__file__).resolve().parents[1]
def src(s):return (R/s).read_text()
class OriginalOmniMap85(unittest.TestCase):
 def test_map_zoom_guess_removed_until_native_carplay_owner_is_proven(self):
  p=src("DFHostedMapRenderSize.h")
  for key in ('@"com.apple.Maps"','@"com.google.Maps"','@"com.waze.iphone"','@"vn.vietmap.live"'):
   self.assertIn(key,p)
  self.assertNotIn('DFIsMapNavigationBundle(bundleID)?0.80:0.50',p)
  self.assertIn('return (CGFloat)0.50;',p)
  self.assertIn('round(pane.width*2.0),round(pane.height*2.0)',p)
  self.assertIn('native CarPlay map compositor',p)
 def test_host_lifecycle_and_active_owned_scene_only(self):
  h=src("DFSceneHost.m")
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
 def test_no_entitlement_spoof_or_fabricated_native_map(self):
  p=src("DFHostedMapRenderSize.h")
  host=src("DFSceneHost.m")
  self.assertNotIn('CPMapTemplate',p)
  self.assertNotIn('CPWindow',p)
  self.assertNotIn('setInterfaceOrientation:',host)
  self.assertNotIn('requestGeometryUpdate',host)
 def test_known_good_083_lifecycle_unchanged(self):
  a=src("DFSceneLifecycle.m")
  self.assertIn('DFIsOwnedManualSceneObserver',a)
  self.assertIn('sPreviousSceneObserver(controller,selector,handle,diff,previousSettings)',a)
  self.assertIn('!((BOOL(*)(id,SEL))objc_msgSend)(controller,autoSel)',a)
if __name__=="__main__":unittest.main(verbosity=2)
