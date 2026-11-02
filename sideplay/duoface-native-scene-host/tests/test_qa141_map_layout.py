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
  # QA173 (user-scoped, reviewed): normalize its three DFSceneHost
  # replacements back to the QA161/baseline bytes before comparing, and
  # drop its two pure insertions. Each span must occur exactly once.
  import base64 as _b64
  for _cur173,_target173 in (
    (_b64.b64decode("ICAgIC8vIE9uZSBzaG9ydCBhcHAtc2NvcGVkIGRpYWdub3N0aWMgZmlsZSBmb3IgaVBob25lIFggdGVzdGluZzsgbm8gc2VjcmV0cy4KICAgIC8vIFFBMTczOiBjYXBwZWQgKyBkZS1kdXBsaWNhdGVkIGFwcGVuZCAoc2VlIERGTG9nR3VhcmQxNzMuaCkuCiAgICBERkxvZ1dyaXRlQ2FwcGVkMTczKEAiL3Zhci9tb2JpbGUvTGlicmFyeS9Mb2dzL0R1b0ZhY2VTY2VuZUhvc3QubG9nIiwgbGluZSk7Cg=="),_b64.b64decode("ICAgIC8vIE9uZSBzaG9ydCBhcHAtc2NvcGVkIGRpYWdub3N0aWMgZmlsZSBmb3IgaVBob25lIFggdGVzdGluZzsgbm8gc2VjcmV0cy4KICAgIGludCBmZCA9IG9wZW4oIi92YXIvbW9iaWxlL0xpYnJhcnkvTG9ncy9EdW9GYWNlU2NlbmVIb3N0LmxvZyIsCiAgICAgICAgICAgICAgICAgIE9fV1JPTkxZIHwgT19BUFBFTkQgfCBPX0NSRUFULCAwNjQ0KTsKICAgIGlmIChmZCA+PSAwKSB7CiAgICAgICAgTlNEYXRhICpkYXRhID0gW1tsaW5lIHN0cmluZ0J5QXBwZW5kaW5nU3RyaW5nOkAiXG4iXSBkYXRhVXNpbmdFbmNvZGluZzpOU1VURjhTdHJpbmdFbmNvZGluZ107CiAgICAgICAgKHZvaWQpd3JpdGUoZmQsIGRhdGEuYnl0ZXMsIGRhdGEubGVuZ3RoKTsKICAgICAgICBjbG9zZShmZCk7CiAgICB9Cg==")),
    (_b64.b64decode("ICAgIC8vIFFBMTczOiBjb21taXQgdGhlIHJlbW90ZSBzY2VuZSBnZW9tZXRyeSBpbiB0aGUgU0FNRSBsYXlvdXQgcGFzcwogICAgLy8gaW5zdGVhZCBvZiBkZWZlcnJpbmcgMC4zMHMgKDAuMTJzIHNvbG8pIGJlaGluZCBhIG9uZS1zaG90IHRpbWVyLgogICAgLy8gQSB2aXNpYmxlIGZyYW1lIHdob3NlIHJlbW90ZSBpbnB1dCBnZW9tZXRyeSBsYWdzIGJlaGluZCBpdCBpcyB0aGUKICAgIC8vIGxlYWRpbmcgc3VzcGVjdCBmb3IgaG9zdGVkLWFwcCB0YXBzIGxhbmRpbmcgbm93aGVyZS4gVGhlIGNvbW1pdAogICAgLy8ga2VlcHMgaXRzIG93biBzdGFsZS1vd25lciwgc2l6ZS1lcXVhbGl0eSBhbmQgcmUtZW50cmFuY3kgZ3VhcmRzLgogICAgaWYocXVpY2tTb2xvSW5pdGlhbEdlb21ldHJ5KQogICAgICAgIERGU2NlbmVMb2coQCJxYTE3My1zb2xvLWZpcnN0LXJlZmVyZW5jZS1pbW1lZGlhdGUiLHNlbGYuYnVuZGxlSUQsCiAgICAgICAgICAgICAgICAgICBAInNjZW5lLXJlYWR5LW9ubHk7IHJlbmRlcmluZy1hbmQtdG91Y2gtdW52ZXJpZmllZCIpOwogICAgREZTY2VuZUxvZyhAInFhMTczLWdlb21ldHJ5LWNvbW1pdC1pbW1lZGlhdGUiLHNlbGYuYnVuZGxlSUQsCiAgICAgICAgICAgICAgIE5TU3RyaW5nRnJvbUNHU2l6ZShzaXplKSk7CiAgICBbc2VsZiBjb21taXRTY2VuZUdlb21ldHJ5Om5pbF07Cg=="),_b64.b64decode("ICAgIE5TVGltZUludGVydmFsIGdlb21ldHJ5V2FpdD1xdWlja1NvbG9Jbml0aWFsR2VvbWV0cnk/MC4xMjowLjMwOwogICAgaWYocXVpY2tTb2xvSW5pdGlhbEdlb21ldHJ5KQogICAgICAgIERGU2NlbmVMb2coQCJxYTE2MS1zb2xvLWZpcnN0LXJlZmVyZW5jZS0xMjBtcyIsc2VsZi5idW5kbGVJRCwKICAgICAgICAgICAgICAgICAgIEAic2NlbmUtcmVhZHktb25seTsgcmVuZGVyaW5nLWFuZC10b3VjaC11bnZlcmlmaWVkIik7CiAgICBzZWxmLmdlb21ldHJ5Q29tbWl0VGltZXI9W05TVGltZXIgc2NoZWR1bGVkVGltZXJXaXRoVGltZUludGVydmFsOmdlb21ldHJ5V2FpdAogICAgICAgIHRhcmdldDpzZWxmIHNlbGVjdG9yOkBzZWxlY3Rvcihjb21taXRTY2VuZUdlb21ldHJ5OikgdXNlckluZm86bmlsIHJlcGVhdHM6Tk9dOwo=")),
    (_b64.b64decode("ICAgIC8vIFFBMTczOiB0aGUgcmVzaXplIGxpbmUgaXMgc3RhdGUtY2hhbmdlLW9ubHkgbm93OyBpZGVudGljYWwgc2l6ZXMKICAgIC8vIGR1cmluZyBsYXlvdXQgc3Rvcm1zIG5vIGxvbmdlciByZWFjaCB0aGUgbG9nIGF0IGFsbC4KICAgIGlmICghQ0dTaXplRXF1YWxUb1NpemUoc2l6ZSwgc2VsZi5sYXN0TG9nZ2VkUmVzaXplU2l6ZSkpIHsKICAgICAgICBzZWxmLmxhc3RMb2dnZWRSZXNpemVTaXplID0gc2l6ZTsKICAgICAgICBERlNjZW5lTG9nKEAicmVzaXplIixzZWxmLmJ1bmRsZUlELE5TU3RyaW5nRnJvbUNHU2l6ZShzaXplKSk7CiAgICB9Cg=="),_b64.b64decode("ICAgIERGU2NlbmVMb2coQCJyZXNpemUiLHNlbGYuYnVuZGxlSUQsTlNTdHJpbmdGcm9tQ0dTaXplKHNpemUpKTsK")),
  ):
   self.assertEqual(normalized.count(_cur173),1,"QA173 span must stay exact")
   normalized=normalized.replace(_cur173,_target173,1)
  for _ins173 in (_b64.b64decode("QHByb3BlcnR5KG5vbmF0b21pYykgQ0dTaXplIGxhc3RMb2dnZWRSZXNpemVTaXplOwo="),_b64.b64decode("I2ltcG9ydCAiREZMb2dHdWFyZDE3My5oIgo=")):
   self.assertEqual(normalized.count(_ins173),1,"QA173 insertion must stay exact")
   normalized=normalized.replace(_ins173,b"",1)
  # QA161 contains exactly one reviewed SOLO-only first geometry timer
  # change. Replace that precise span with old frozen bytes before comparing.
  changed=b'''    // QA161: on the very first scene-ready frame of a single independent
    // app, the SOLO viewport has no moving divider to debounce. Preserve
    // the original 300ms wait for split, subsequent resizes, YouTube and GOFA.
    // Keep the SAME owned live scene/attachment checks in commitSceneGeometry:.
    BOOL quickSoloInitialGeometry=self.fastInitialPolling &&
        CGSizeEqualToSize(self.committedReferenceSize,CGSizeZero) &&
        ![self.bundleID isEqual:DFYTBundle] &&
        ![self.bundleID isEqual:@"com.lumi.GOFA"];
    NSTimeInterval geometryWait=quickSoloInitialGeometry?0.12:0.30;
    if(quickSoloInitialGeometry)
        DFSceneLog(@"qa161-solo-first-reference-120ms",self.bundleID,
                   @"scene-ready-only; rendering-and-touch-unverified");
    self.geometryCommitTimer=[NSTimer scheduledTimerWithTimeInterval:geometryWait
        target:self selector:@selector(commitSceneGeometry:) userInfo:nil repeats:NO];
'''
  original=b'''    self.geometryCommitTimer=[NSTimer scheduledTimerWithTimeInterval:0.30
        target:self selector:@selector(commitSceneGeometry:) userInfo:nil repeats:NO];
'''
  self.assertEqual(normalized.count(changed),1,"QA161 timer diff must stay exact")
  normalized=normalized.replace(changed,original,1)
  self.assertEqual(without_start(baseline),without_start(normalized))
  startup=current.split(marker1,1)[1].split(marker2,1)[0]
  self.assertLess(startup.index(b'setIgnoresOcclusions:'),startup.index(b'[self addSubview:appView]'))
  self.assertLess(startup.index(b'setRequestedMode:'),startup.index(b'[self addSubview:appView]'))
if __name__=='__main__':unittest.main()
