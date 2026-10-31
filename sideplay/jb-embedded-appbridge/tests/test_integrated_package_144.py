"""QA144 integrated candidate must preserve original split, native Dock,
YouTube/GOFA helpers, and the standalone Home producer/consumer. Offline only."""
import pathlib,unittest
ROOT=pathlib.Path(__file__).resolve().parents[2]
PACK=(ROOT/"jb-embedded-appbridge/package_integrated.py").read_text()
NATIVE=(ROOT/"duoface-native-scene-host/build.sh").read_text()
BRIDGE=(ROOT/"duoface-native-scene-host/DFHomeStandalone144.m").read_text()
class Q144PackageContract(unittest.TestCase):
 def test_new_unique_candidate_both_versions(self):
  self.assertIn('VERSION="0.0.145~standalone-controlled1"',PACK)
  self.assertIn("0.1.145~standalone-controlled1",PACK)
  self.assertIn("0.1.145~standalone-controlled1",NATIVE)
  self.assertNotIn("0.1.143~homebridge1",NATIVE)
 def test_broker_is_native_and_springboard_not_split(self):
  self.assertIn("DF144_CARPLAY=1",NATIVE)
  self.assertIn("DF144_SPRINGBOARD=1",NATIVE)
  self.assertEqual(NATIVE.count("DFHomeStandalone144.m"),2)
  for old in ("DFHomeLaunch143.m","DFHomeRequestReceiver143.m","DFHomeSceneBridge143.m"):
   self.assertNotIn(old,NATIVE)
 def test_explicit_default_off_and_no_success_shortcut(self):
  self.assertIn("DFHome145Enabled()",BRIDGE)
  self.assertIn("DF144LiveReceiver()",BRIDGE)
  self.assertIn("scene-hosted-render-and-touch-unverified",BRIDGE)
  self.assertIn("pending-scene",BRIDGE)
  self.assertIn("DFSceneHostDidBecomeReadyNotification",BRIDGE)
  self.assertIn("DF144Original(self,cmd,manager,icon)",BRIDGE)
  self.assertNotIn("DF143Original",BRIDGE)
 def test_preserve_regressions_native_maps_gofa_youtube_split(self):
  for name in ("DFNative12Chrome.m","DFCarPlayDockOwner.m","DFNativeMapPaneCoordinator.m",
               "DFGofaMapResize141.m","DFYouTubeOrientationRelay.m"):
   self.assertIn(name,NATIVE)
  self.assertIn("DFNativeMapPaneCoordinator",PACK)
  self.assertIn("DFGofaMapResize141",PACK)
  self.assertIn("DFYouTubeOrientationRelay",PACK)
  self.assertIn("EXCLUDED=",PACK)
if __name__=="__main__":unittest.main()
