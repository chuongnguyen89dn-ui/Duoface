from pathlib import Path
import plistlib, unittest
ROOT=Path(__file__).resolve().parents[1]
class Map141Contract(unittest.TestCase):
 def test_scoped_receiver_and_signed_build(self):
  p=plistlib.loads((ROOT/'DFGofaMapResize141.plist').read_bytes())
  self.assertEqual(p,{"Filter":{"Bundles":["com.lumi.GOFA"]}})
  s=(ROOT/'DFGofaMapResize141.m').read_text()
  for text in ('GOFA.GofaMapView','MapboxMaps.MapView','DFGofa141MayResize', 'parentBounds','beforeFrame','afterFrame','restoreMasks','phase":@"resize141'):
   self.assertIn(text,s)
  for forbidden in ('metalView.frame=','window.frame=','root.frame=','method_setImplementation','DFYTRotate('):
   self.assertNotIn(forbidden,s)
  build=(ROOT/'build.sh').read_text()
  self.assertIn('DFGofaMapResize141.m',build)
  self.assertIn('DFHomeAdmission141.m',build)
  self.assertNotIn('DFHomeAdmission138.m',build)
 def test_host_geometry_remains_baseline(self):
  import subprocess
  path='sideplay/duoface-native-scene-host/DFSceneHost.m'
  baseline=subprocess.check_output(['git','show','a25adbfeb1782e39ca96f78b42ce638ccf7ca860:'+path],cwd=ROOT.parents[1])
  self.assertEqual(baseline,(ROOT/'DFSceneHost.m').read_bytes())
if __name__=='__main__':unittest.main()
