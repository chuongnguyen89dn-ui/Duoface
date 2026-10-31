"""QA155 contract: actual merged receiver with exact offline runtime scope.
This is not device orientation, Home, Dock or touch acceptance.
"""
import pathlib,plistlib,hashlib,re,unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
INT=ROOT.parent/"jb-embedded-appbridge/package_integrated.py"
class QA155AppReceiver(unittest.TestCase):
 def test_exact_two_app_substrate_filter(self):
  doc=plistlib.loads((ROOT/"DF155GeneralAppStateRelay.plist").read_bytes())
  self.assertEqual(doc,{"Filter":{"Bundles":["com.apple.mobilesafari","org.videolan.vlc-ios"]}})
  scope=(ROOT/"DF155PilotAppScope.h").read_text()
  for item in doc["Filter"]["Bundles"]:self.assertIn(item,scope)
  for blocked in ("com.google.ios.youtube","com.lumi.GOFA","com.apple.CarPlay","com.apple.springboard"):
   self.assertNotIn('<string>'+blocked+'</string>',(ROOT/"DF155GeneralAppStateRelay.plist").read_text())
  self.assertIn("DFPickerAllowsApp(bundle,DFConfiguredEnabledAppIDs())",scope)
 def test_real_build_and_merge_enforced(self):
  sh=(ROOT/"build.sh").read_text()
  self.assertRegex(sh,r'-o "\$APP_STATE_DYLIB" DF154GeneralAppStateRelay.m')
  self.assertIn('cp DF155GeneralAppStateRelay.plist "$TMP/',sh)
  self.assertIn('ldid -S "$APP_STATE_DYLIB"',sh)
  packaging=INT.read_text()
  self.assertIn('generic.with_suffix(".dylib").is_file()',packaging)
  self.assertIn('exact_filter!={"Filter":{"Bundles":["com.apple.mobilesafari","org.videolan.vlc-ios"]}}',packaging)
  self.assertIn('"qa155_app_receiver_device_accepted":False',packaging)
 def test_owner_revocation_and_noninterference(self):
  relay=(ROOT/"DF154GeneralAppStateRelay.m").read_text()
  for token in ('DF155EnabledPilotApp(self.bundle)','owner-terminal','lease-expired',
                'allowlist-revoked','allowlist-disabled','window.windowScene!=target',
                'window.frame=original.frame','transport-unavailable'):
   self.assertIn(token,relay)
  for forbidden in ('setInterfaceOrientation:','sendEvent:','UIWindowLevelAlert','SBMainWorkspace'):
   self.assertNotIn(forbidden,relay)
  self.assertIn('DF154Valid(self.state,NSDate.date.timeIntervalSince1970)',relay)
  native=(ROOT/"DFSceneHost.m").read_bytes()
  self.assertEqual(hashlib.sha1(b"blob "+str(len(native)).encode()+b"\0"+native).hexdigest(),
                   "ec2924c145be4edaaa27b7320bb869b18de12c6b")
 def test_no_legacy_relay_filter_broadening(self):
  for name,bundle in (("DFYouTubeOrientationRelay.plist","com.google.ios.youtube"),
                       ("DFGofaMapResize141.plist","com.lumi.GOFA")):
   self.assertEqual(plistlib.loads((ROOT/name).read_bytes()),{"Filter":{"Bundles":[bundle]}})
if __name__=="__main__":unittest.main()
