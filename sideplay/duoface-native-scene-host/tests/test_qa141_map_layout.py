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
  current=(ROOT/'DFSceneHost.m').read_bytes()
  # QA141 geometry outside the independently audited host-startup function
  # stays byte-for-byte identical. The function itself now follows original
  # DuoNavi flags -> mode2 -> child mount order.
  marker1=b"- (void)start {"
  marker2=b"- (void)layoutSubviews {"
  def without_start(content):
   a=content.index(marker1)
   b=content.index(marker2,a)
   return content[:a]+content[b:]
  # Preserve exact pre-QA160 audited geometry outside only the named,
  # source-reviewed SOLO readiness instrumentation additions.
  additions=[
   b"@property(nonatomic) BOOL fastInitialPolling;\n",
   b'''                 // Revert to the previous low-rate heartbeat after the first true ready.
                 // Scene liveness and ownership gates remain unchanged.
                 if(self.fastInitialPolling && self.timer && self.timer.timeInterval<0.34) {
                     [self.timer invalidate];
                     self.timer=[NSTimer scheduledTimerWithTimeInterval:0.35 target:self
                                  selector:@selector(pollScene:) userInfo:nil repeats:YES];
                     DFSceneLog(@"qa160-fast-initial-probe-complete",self.bundleID,@"0.10s-to-0.35s");
                 }
''',
   b'''- (void)setFastInitialPolling:(BOOL)fast forHostedView:(UIView *)view {
    if(!NSThread.isMainThread || !view)return;
    DFSceneSurface *surface=(DFSceneSurface *)view;
    if(![surface isKindOfClass:DFSceneSurface.class] || surface.started || surface.stopped ||
       surface.window || self.live[surface.bundleID]!=surface)return;
    surface.fastInitialPolling=fast;
}
'''
  ]
  normalized=current
  for addition in additions:
   self.assertEqual(normalized.count(addition),1,"Only reviewed QA160 additions allowed")
   normalized=normalized.replace(addition,b"",1)
  self.assertEqual(without_start(baseline),without_start(normalized))
  startup=current.split(marker1,1)[1].split(marker2,1)[0]
  self.assertLess(startup.index(b'setIgnoresOcclusions:'),startup.index(b'[self addSubview:appView]'))
  self.assertLess(startup.index(b'setRequestedMode:'),startup.index(b'[self addSubview:appView]'))
if __name__=='__main__':unittest.main()
