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
  # QA175 (user-scoped, reviewed): normalize the QA175 touch-
  # reliability scene-host changes (trailing-edge geometry
  # commits with retry, one-shot surface observers, YouTube
  # state throttle) back to the reviewed QA161 revision.
  import base64 as _b64_175
  def _d175(s): return _b64_175.b64decode(s)  # bytes: current/baseline are bytes
  for _old,_new in [
      (_d175("c3RhdGljIHZvaWQgREZTY2VuZUxvZyhOU1N0cmluZyAqZXZlbnQsIE5TU3RyaW5nICpidW5kbGVJRCwgTlNTdHJpbmcgKmRldGFpbCkgewogICAgTlNTdHJpbmcgKmxpbmUgPSBbTlNTdHJpbmcgc3RyaW5nV2l0aEZvcm1hdDpAIltEdW9GYWNlU2NlbmVdIGV2ZW50PSVAIGJ1bmRsZT0lQCAlQCIsCiAgICAgICAgICAgICAgICAgICAgICBldmVudCA/OiBAInVua25vd24iLCBidW5kbGVJRCA/OiBAIi0iLCBkZXRhaWwgPzogQCIiXTsKICAgIERGRGVlcFRyYWNlKEAic2NlbmUiLGxpbmUpOwogICAgTlNMb2coQCIlQCIsIGxpbmUpOwogICAgLy8gT25lIHNob3J0IGFwcC1zY29wZWQgZGlhZ25vc3RpYyBmaWxlIGZvciBpUGhvbmUgWCB0ZXN0aW5nOyBubyBzZWNyZXRzLgogICAgLy8gUUExNzM6IGNhcHBlZCArIGRlLWR1cGxpY2F0ZWQgYXBwZW5kIChzZWUgREZMb2dHdWFyZDE3My5oKS4KICAgIERGTG9nV3JpdGVDYXBwZWQxNzMoQCIvdmFyL21vYmlsZS9MaWJyYXJ5L0xvZ3MvRHVvRmFjZVNjZW5lSG9zdC5sb2ciLCBsaW5lKTsKfQo="),_d175("c3RhdGljIHZvaWQgREZTY2VuZUxvZyhOU1N0cmluZyAqZXZlbnQsIE5TU3RyaW5nICpidW5kbGVJRCwgTlNTdHJpbmcgKmRldGFpbCkgewogICAgTlNTdHJpbmcgKmxpbmUgPSBbTlNTdHJpbmcgc3RyaW5nV2l0aEZvcm1hdDpAIltEdW9GYWNlU2NlbmVdIGV2ZW50PSVAIGJ1bmRsZT0lQCAlQCIsCiAgICAgICAgICAgICAgICAgICAgICBldmVudCA/OiBAInVua25vd24iLCBidW5kbGVJRCA/OiBAIi0iLCBkZXRhaWwgPzogQCIiXTsKICAgIERGRGVlcFRyYWNlKEAic2NlbmUiLGxpbmUpOwogICAgTlNMb2coQCIlQCIsIGxpbmUpOwogICAgLy8gT25lIHNob3J0IGFwcC1zY29wZWQgZGlhZ25vc3RpYyBmaWxlIGZvciBpUGhvbmUgWCB0ZXN0aW5nOyBubyBzZWNyZXRzLgogICAgaW50IGZkID0gb3BlbigiL3Zhci9tb2JpbGUvTGlicmFyeS9Mb2dzL0R1b0ZhY2VTY2VuZUhvc3QubG9nIiwKICAgICAgICAgICAgICAgICAgT19XUk9OTFkgfCBPX0FQUEVORCB8IE9fQ1JFQVQsIDA2NDQpOwogICAgaWYgKGZkID49IDApIHsKICAgICAgICBOU0RhdGEgKmRhdGEgPSBbW2xpbmUgc3RyaW5nQnlBcHBlbmRpbmdTdHJpbmc6QCJcbiJdIGRhdGFVc2luZ0VuY29kaW5nOk5TVVRGOFN0cmluZ0VuY29kaW5nXTsKICAgICAgICAodm9pZCl3cml0ZShmZCwgZGF0YS5ieXRlcywgZGF0YS5sZW5ndGgpOwogICAgICAgIGNsb3NlKGZkKTsKICAgIH0KfQo=")),
      (_d175("ICAgIGlmKG5vdy1zZWxmLnlvdXR1YmVMYXN0UHVibGlzaDwoREYxNzVZVFJlbGF5R3VhcmRFbmFibGVkKCk/a0RGMTc1WVRTdGF0ZVRocm90dGxlU2Vjb25kczowLjc1KSlyZXR1cm47Cg=="),_d175("ICAgIGlmKG5vdy1zZWxmLnlvdXR1YmVMYXN0UHVibGlzaDwwLjc1KXJldHVybjsK")),
      (_d175("ICAgIGlmICghc2VsZi5yZWFkeSkgcmV0dXJuOwogICAgLy8gUUExNzUgKFQyKTogdHJhaWxpbmctZWRnZSBnZW9tZXRyeSBjb21taXQuIEEgbGF5b3V0IHBhc3Mgbm93IG9ubHkKICAgIC8vIHJlY29yZHMgdGhlIHBlbmRpbmcgc2l6ZSBhbmQgKHJlKWFybXMgYSBzaG9ydCBkZWJvdW5jZSB0aW1lcjsgdGhlCiAgICAvLyByZW1vdGUgRkJTY2VuZSBjb21taXQgcnVucyBvbmNlIHRoZSBzaXplIGhhcyBzZXR0bGVkIGZvcgogICAgLy8ga0RGMTc1R2VvbWV0cnlEZWJvdW5jZVNlY29uZHMsIHdoaWNoIGlzIGFsc28gZXhhY3RseSBvbmNlIGFmdGVyIGEKICAgIC8vIGRpdmlkZXIgZHJhZyBpcyByZWxlYXNlZC4gUUExNzMgY29tbWl0dGVkIHN5bmNocm9ub3VzbHkgb24gZXZlcnkKICAgIC8vIHBhc3MgKGRyYWcgamFuayArIGEgc2V0dGluZ3MgdHJhbnNhY3Rpb24gcGVyIGludGVybWVkaWF0ZSBzaXplKQogICAgLy8gYW5kIGEgc2tpcHBlZCBjb21taXQgd2FzIG5ldmVyIHJldHJpZWQ7IGNvbW1pdFNjZW5lR2VvbWV0cnk6IG5vdwogICAgLy8gcmUtYXJtcyB2aWEgZGYxNzVOb3RlR2VvbWV0cnlTa2lwIGFuZCBwb2xsU2NlbmU6IHJlLWFybXMgd2hpbGUgYQogICAgLy8gcGVuZGluZyBzaXplIHN0YXlzIHVuY29tbWl0dGVkLiBUaGUgcmVzaXplIGxpbmUgaXMgbG9nZ2VkIG9uY2UKICAgIC8vIHBlciBzZXR0bGVkIGNvbW1pdCwgbm90IHBlciBsYXlvdXQgcGFzcy4gVGhpcyBzdXBlcnNlZGVzIHRoZQogICAgLy8gUUExNjEgMTIwbXMvMzAwbXMgc3BsaXQgYW5kIHRoZSBRQTE3MyBzYW1lLXBhc3MgY29tbWl0LgogICAgc2VsZi5wZW5kaW5nUmVmZXJlbmNlU2l6ZT1zaXplOwogICAgW3NlbGYgc2NoZWR1bGVHZW9tZXRyeUNvbW1pdF07Cg=="),_d175("ICAgIERGU2NlbmVMb2coQCJyZXNpemUiLHNlbGYuYnVuZGxlSUQsTlNTdHJpbmdGcm9tQ0dTaXplKHNpemUpKTsKICAgIGlmICghc2VsZi5yZWFkeSkgcmV0dXJuOwogICAgc2VsZi5wZW5kaW5nUmVmZXJlbmNlU2l6ZT1zaXplOwogICAgW3NlbGYuZ2VvbWV0cnlDb21taXRUaW1lciBpbnZhbGlkYXRlXTsKICAgIC8vIFFBMTYxOiBvbiB0aGUgdmVyeSBmaXJzdCBzY2VuZS1yZWFkeSBmcmFtZSBvZiBhIHNpbmdsZSBpbmRlcGVuZGVudAogICAgLy8gYXBwLCB0aGUgU09MTyB2aWV3cG9ydCBoYXMgbm8gbW92aW5nIGRpdmlkZXIgdG8gZGVib3VuY2UuIFByZXNlcnZlCiAgICAvLyB0aGUgb3JpZ2luYWwgMzAwbXMgd2FpdCBmb3Igc3BsaXQsIHN1YnNlcXVlbnQgcmVzaXplcywgWW91VHViZSBhbmQgR09GQS4KICAgIC8vIEtlZXAgdGhlIFNBTUUgb3duZWQgbGl2ZSBzY2VuZS9hdHRhY2htZW50IGNoZWNrcyBpbiBjb21taXRTY2VuZUdlb21ldHJ5Oi4KICAgIEJPT0wgcXVpY2tTb2xvSW5pdGlhbEdlb21ldHJ5PXNlbGYuZmFzdEluaXRpYWxQb2xsaW5nICYmCiAgICAgICAgQ0dTaXplRXF1YWxUb1NpemUoc2VsZi5jb21taXR0ZWRSZWZlcmVuY2VTaXplLENHU2l6ZVplcm8pICYmCiAgICAgICAgIVtzZWxmLmJ1bmRsZUlEIGlzRXF1YWw6REZZVEJ1bmRsZV0gJiYKICAgICAgICAhW3NlbGYuYnVuZGxlSUQgaXNFcXVhbDpAImNvbS5sdW1pLkdPRkEiXTsKICAgIE5TVGltZUludGVydmFsIGdlb21ldHJ5V2FpdD1xdWlja1NvbG9Jbml0aWFsR2VvbWV0cnk/MC4xMjowLjMwOwogICAgaWYocXVpY2tTb2xvSW5pdGlhbEdlb21ldHJ5KQogICAgICAgIERGU2NlbmVMb2coQCJxYTE2MS1zb2xvLWZpcnN0LXJlZmVyZW5jZS0xMjBtcyIsc2VsZi5idW5kbGVJRCwKICAgICAgICAgICAgICAgICAgIEAic2NlbmUtcmVhZHktb25seTsgcmVuZGVyaW5nLWFuZC10b3VjaC11bnZlcmlmaWVkIik7CiAgICBzZWxmLmdlb21ldHJ5Q29tbWl0VGltZXI9W05TVGltZXIgc2NoZWR1bGVkVGltZXJXaXRoVGltZUludGVydmFsOmdlb21ldHJ5V2FpdAogICAgICAgIHRhcmdldDpzZWxmIHNlbGVjdG9yOkBzZWxlY3Rvcihjb21taXRTY2VuZUdlb21ldHJ5OikgdXNlckluZm86bmlsIHJlcGVhdHM6Tk9dOwo=")),
      (_d175("ICAgIGlmIChzZWxmLnN0b3BwZWQgfHwgc2VsZi5jb21taXR0aW5nU2NlbmVHZW9tZXRyeSB8fCAhc2VsZi53aW5kb3cgfHwgIXNlbGYuYXBwQ29udHJvbGxlciB8fAogICAgICAgICFzZWxmLnJlYWR5KSB7IFtzZWxmIGRmMTc1Tm90ZUdlb21ldHJ5U2tpcF07IHJldHVybjsgfQogICAgQ0dTaXplIHNpemU9c2VsZi5wZW5kaW5nUmVmZXJlbmNlU2l6ZTsKICAgIGlmIChDR1NpemVFcXVhbFRvU2l6ZShzaXplLHNlbGYuY29tbWl0dGVkUmVmZXJlbmNlU2l6ZSkpIHJldHVybjsKICAgIGlmICghQ0dTaXplRXF1YWxUb1NpemUoc2l6ZSxzZWxmLmJvdW5kcy5zaXplKSB8fAogICAgICAgIHNpemUud2lkdGg8PTAgfHwgc2l6ZS5oZWlnaHQ8PTApIHsgW3NlbGYgZGYxNzVOb3RlR2VvbWV0cnlTa2lwXTsgcmV0dXJuOyB9Cg=="),_d175("ICAgIGlmIChzZWxmLnN0b3BwZWQgfHwgc2VsZi5jb21taXR0aW5nU2NlbmVHZW9tZXRyeSB8fCAhc2VsZi53aW5kb3cgfHwgIXNlbGYuYXBwQ29udHJvbGxlciB8fAogICAgICAgICFzZWxmLnJlYWR5KSByZXR1cm47CiAgICBDR1NpemUgc2l6ZT1zZWxmLnBlbmRpbmdSZWZlcmVuY2VTaXplOwogICAgaWYgKENHU2l6ZUVxdWFsVG9TaXplKHNpemUsc2VsZi5jb21taXR0ZWRSZWZlcmVuY2VTaXplKSB8fAogICAgICAgICFDR1NpemVFcXVhbFRvU2l6ZShzaXplLHNlbGYuYm91bmRzLnNpemUpIHx8CiAgICAgICAgc2l6ZS53aWR0aDw9MCB8fCBzaXplLmhlaWdodDw9MCkgcmV0dXJuOwo=")),
      (_d175("ICAgICAgICAgICAgREZTY2VuZUxvZyhAInNjZW5lLWdlb21ldHJ5LXN0YWxlLW93bmVyLXNraXAiLHNlbGYuYnVuZGxlSUQsCiAgICAgICAgICAgICAgICBbTlNTdHJpbmcgc3RyaW5nV2l0aEZvcm1hdDpAInNjZW5lU2FtZT0lZCBob3N0aW5nPSVkIGF0dGFjaGVkPSVkIiwKICAgICAgICAgICAgICAgICAgICBvYnNlcnZlZFNjZW5lIT1uaWwgJiYgb2JzZXJ2ZWRTY2VuZT09c2VsZi5zY2VuZSxob3N0aW5nLGF0dGFjaGVkXSk7CiAgICAgICAgICAgIFtzZWxmIGRmMTc1Tm90ZUdlb21ldHJ5U2tpcF07CiAgICAgICAgICAgIHJldHVybjsK"),_d175("ICAgICAgICAgICAgREZTY2VuZUxvZyhAInNjZW5lLWdlb21ldHJ5LXN0YWxlLW93bmVyLXNraXAiLHNlbGYuYnVuZGxlSUQsCiAgICAgICAgICAgICAgICBbTlNTdHJpbmcgc3RyaW5nV2l0aEZvcm1hdDpAInNjZW5lU2FtZT0lZCBob3N0aW5nPSVkIGF0dGFjaGVkPSVkIiwKICAgICAgICAgICAgICAgICAgICBvYnNlcnZlZFNjZW5lIT1uaWwgJiYgb2JzZXJ2ZWRTY2VuZT09c2VsZi5zY2VuZSxob3N0aW5nLGF0dGFjaGVkXSk7CiAgICAgICAgICAgIHJldHVybjsK")),
      (_d175("ICAgICAgICBpZiAoYXBwbGllZCkgewogICAgICAgICAgICBzZWxmLmdlb21ldHJ5Q29tbWl0QXR0ZW1wdHM9MDsKICAgICAgICAgICAgaWYgKCFDR1NpemVFcXVhbFRvU2l6ZShzaXplLCBzZWxmLmxhc3RMb2dnZWRSZXNpemVTaXplKSkgewogICAgICAgICAgICAgICAgc2VsZi5sYXN0TG9nZ2VkUmVzaXplU2l6ZSA9IHNpemU7CiAgICAgICAgICAgICAgICBERlNjZW5lTG9nKEAicmVzaXplIixzZWxmLmJ1bmRsZUlELE5TU3RyaW5nRnJvbUNHU2l6ZShzaXplKSk7CiAgICAgICAgICAgIH0KICAgICAgICAgICAgc2VsZi5jb21taXR0ZWRSZWZlcmVuY2VTaXplPXNpemU7Cg=="),_d175("ICAgICAgICBpZiAoYXBwbGllZCkgewogICAgICAgICAgICBzZWxmLmNvbW1pdHRlZFJlZmVyZW5jZVNpemU9c2l6ZTsK")),
  ]:
      assert current.count(_old)==1
      current=current.replace(_old,_new)
  for _strip in [
      _d175("Ly8gUUExNzUgdHVuYWJsZXM6IHRyYWlsaW5nLWVkZ2UgZ2VvbWV0cnkgZGVib3VuY2UgYW5kIHRoZSBZb3VUdWJlCi8vIGhvc3Qtc3RhdGUgcmVwdWJsaXNoIHRocm90dGxlIChwZXJpb2RpYyBwYXRoKS4gQm90aCBhcmUgbmFtZWQgc28gYQovLyBmdXR1cmUgUUEgY2FuIHJldHVuZSB3aXRob3V0IGh1bnRpbmcgbGl0ZXJhbHMuCnN0YXRpYyBjb25zdCBOU1RpbWVJbnRlcnZhbCBrREYxNzVHZW9tZXRyeURlYm91bmNlU2Vjb25kcyA9IDAuMDk7CnN0YXRpYyBjb25zdCBOU1RpbWVJbnRlcnZhbCBrREYxNzVZVFN0YXRlVGhyb3R0bGVTZWNvbmRzID0gMC4zMDsKLy8gUUExNzUga2lsbCBzd2l0Y2ggZm9yIHRoZSByZWxheSBndWFyZCBiZWhhdmlvdXIgKHNtYWxsZXIgcmVwdWJsaXNoCi8vIHRocm90dGxlIGhvc3Qtc2lkZSArIG5vIHNpbGVudC1leHBpcnkgc25hcHNob3QgcmVzdG9yZSByZWxheS1zaWRlKS4KLy8gL3Zhci9tb2JpbGUvTGlicmFyeS9QcmVmZXJlbmNlcy9jb20uZHVvZmFjZS5uYXRpdmVob3N0LnFhMTc1LnBsaXN0Ci8vIGtleSBZVFJlbGF5R3VhcmQgKGFic2VudCA9IGVuYWJsZWQ7IHNldCAwICsgcmVzcHJpbmcgPSBRQTE3NCBiZWhhdmlvdXIpLgpzdGF0aWMgQk9PTCBERjE3NVlUUmVsYXlHdWFyZEVuYWJsZWQodm9pZCkgewogICAgc3RhdGljIEJPT0wgY2FjaGVkOyBzdGF0aWMgQk9PTCBsb2FkZWQ7CiAgICBpZiAoIWxvYWRlZCkgewogICAgICAgIGxvYWRlZCA9IFlFUzsgY2FjaGVkID0gWUVTOwogICAgICAgIE5TRGljdGlvbmFyeSAqcHJlZnMgPSBbTlNEaWN0aW9uYXJ5IGRpY3Rpb25hcnlXaXRoQ29udGVudHNPZkZpbGU6CiAgICAgICAgICAgIEAiL3Zhci9tb2JpbGUvTGlicmFyeS9QcmVmZXJlbmNlcy9jb20uZHVvZmFjZS5uYXRpdmVob3N0LnFhMTc1LnBsaXN0Il07CiAgICAgICAgaWQgdiA9IHByZWZzW0AiWVRSZWxheUd1YXJkIl07CiAgICAgICAgaWYgKFt2IHJlc3BvbmRzVG9TZWxlY3RvcjpAc2VsZWN0b3IoYm9vbFZhbHVlKV0pIGNhY2hlZCA9IFt2IGJvb2xWYWx1ZV07CiAgICB9CiAgICByZXR1cm4gY2FjaGVkOwp9Cgo="),
      _d175("QHByb3BlcnR5KG5vbmF0b21pYykgTlNVSW50ZWdlciBnZW9tZXRyeUNvbW1pdEF0dGVtcHRzOwpAcHJvcGVydHkobm9uYXRvbWljKSBCT09MIG9ic2VydmVyc1JlZ2lzdGVyZWQxNzU7Cg=="),
      _d175("LSAodm9pZClzY2hlZHVsZUdlb21ldHJ5Q29tbWl0IHsKICAgIGlmIChzZWxmLnN0b3BwZWQpIHJldHVybjsKICAgIFtzZWxmLmdlb21ldHJ5Q29tbWl0VGltZXIgaW52YWxpZGF0ZV07CiAgICBzZWxmLmdlb21ldHJ5Q29tbWl0VGltZXI9W05TVGltZXIgc2NoZWR1bGVkVGltZXJXaXRoVGltZUludGVydmFsOmtERjE3NUdlb21ldHJ5RGVib3VuY2VTZWNvbmRzCiAgICAgICAgdGFyZ2V0OnNlbGYgc2VsZWN0b3I6QHNlbGVjdG9yKGNvbW1pdFNjZW5lR2VvbWV0cnk6KSB1c2VySW5mbzpuaWwgcmVwZWF0czpOT107Cn0KLSAodm9pZClkZjE3NU5vdGVHZW9tZXRyeVNraXAgewogICAgaWYgKHNlbGYuc3RvcHBlZCB8fCBzZWxmLmNvbW1pdHRpbmdTY2VuZUdlb21ldHJ5KSByZXR1cm47CiAgICBpZiAoQ0dTaXplRXF1YWxUb1NpemUoc2VsZi5wZW5kaW5nUmVmZXJlbmNlU2l6ZSxzZWxmLmNvbW1pdHRlZFJlZmVyZW5jZVNpemUpKSByZXR1cm47CiAgICBpZiAoc2VsZi5nZW9tZXRyeUNvbW1pdEF0dGVtcHRzPj00KSByZXR1cm47CiAgICBzZWxmLmdlb21ldHJ5Q29tbWl0QXR0ZW1wdHMrKzsKICAgIFtzZWxmIHNjaGVkdWxlR2VvbWV0cnlDb21taXRdOwp9Cg=="),
      _d175("ICAgICAgICAgICAgaWYgKHNlbGYucmVhZHkgJiYKICAgICAgICAgICAgICAgICFDR1NpemVFcXVhbFRvU2l6ZShzZWxmLnBlbmRpbmdSZWZlcmVuY2VTaXplLHNlbGYuY29tbWl0dGVkUmVmZXJlbmNlU2l6ZSkgJiYKICAgICAgICAgICAgICAgICFzZWxmLmdlb21ldHJ5Q29tbWl0VGltZXIpCiAgICAgICAgICAgICAgICBbc2VsZiBzY2hlZHVsZUdlb21ldHJ5Q29tbWl0XTsK"),
      _d175("I2ltcG9ydCAiREZMb2dHdWFyZDE3My5oIgo="),
      _d175("QHByb3BlcnR5KG5vbmF0b21pYykgQ0dTaXplIGxhc3RMb2dnZWRSZXNpemVTaXplOwo="),
  ]:
      assert current.count(_strip)==1
      current=current.replace(_strip,b"")
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
