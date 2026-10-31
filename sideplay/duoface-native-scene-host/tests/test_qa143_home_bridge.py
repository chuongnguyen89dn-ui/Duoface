import pathlib, unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
CAR=(ROOT/"DFHomeLaunch143.m").read_text()
SB=(ROOT/"DFHomeRequestReceiver143.m").read_text()
BR=(ROOT/"DFHomeSceneBridge143.m").read_text()
TO=(ROOT/"DFTouchOwnerProbe.m").read_text()
CH=(ROOT/"DFNative12Chrome.h").read_text()
BUILD=(ROOT/"build.sh").read_text()
PACK=(ROOT.parent/"jb-embedded-appbridge"/"package_integrated.py").read_text()

class HomeBridge143Contracts(unittest.TestCase):
 def test_exact_observed_ios16_selector_and_once_fallback(self):
  self.assertIn('iconManager:launchIconForIconView:',CAR)
  self.assertIn('v32@0:8@16@24',CAR)
  self.assertIn('objc_getClass("DBDashboardHomeViewController")',CAR)
  self.assertIn("DF143Original(owner,selector,manager,iconView)",CAR)
  self.assertEqual(CAR.count("DF143Original(owner,selector,manager,iconView)"),3)
  self.assertEqual(CAR.count("DF143Original(owner,selector,manager,duofaceView)"),1)
  for missing in ('DBApplicationController','requestStateChange:',
                  'updateSettingsWithBlock:','setForeground:','UIApplication.sharedApplication openURL'):
   self.assertNotIn(missing,CAR)
 def test_selected_only_and_real_host_icon(self):
  for required in ('DFHome140Enabled()','DFPickerAllowsApp(bundle,DFConfiguredEnabledAppIDs())',
                   'DFIsRecommendedAppID(bundle)','DF143HostID',
                   'DF143FindHostInView','[root isKindOfClass:tappedClass]',
                   'host-icon-not-visible original-forwarded',
                   'CarPlayHomeTap143','O_CREAT|O_WRONLY|O_APPEND'):
   self.assertIn(required,CAR)
  self.assertNotIn('DF138',CAR)
  self.assertNotIn('class_replaceMethod',CAR)
 def test_request_replay_and_foreground_owner(self):
  for name in ('DFHome143ConsumeRequest(sChrome,sSession)',
               'if(!DFSessionStillActive())', '[sChrome start]'):
   self.assertIn(name,TO)
  for name in ('DF143LastConsumed','age>15.0','DFHome140Enabled()',
               'DFPickerAllowsApp(bundle,DFConfiguredEnabledAppIDs())',
               'removeItemAtPath:DF143RequestPath','scene-requested-not-yet-ready'):
   self.assertIn(name,SB)
  self.assertIn('openSelectedHomeBundleID143:',CH)
  self.assertIn('[self appPicker:picker didSelectBundleID:bundleID displayName:bundleID]',BR)
  self.assertNotIn('hostViewForBundleID:',BR) # use existing Chrome lifecycle
 def test_build_versions_and_unmodified_gofa_youtube_dock(self):
  for name in ('DFHomeSceneBridge143.m','DFHomeRequestReceiver143.m',
               'DFHomeLaunch143.m','DFHomeAdmission141.m',
               'DFGofaMapResize141.m','DFCarPlayDockOwner.m',
               'DFYouTubeOrientationRelay.m'):
   self.assertIn(name,BUILD)
  self.assertIn('0.1.143~homebridge1',BUILD)
  self.assertIn('VERSION="0.0.143~homebridge1"',PACK)
  self.assertIn('0.1.143~homebridge1',PACK)
  self.assertIn('Version: 0.1.143~homebridge1',(ROOT/"control").read_text())
  self.assertIn('<key>CFBundleVersion</key><string>143</string>',(ROOT/"Info.plist").read_text())
 def test_no_vendored_binary_and_no_auto_respring(self):
  self.assertNotIn('DuoNaviDashboard',BUILD)
  for command in ('killall SpringBoard','sbreload','ldrestart','uicache -a'):
   self.assertNotIn(command,BUILD+SB+CAR+BR)

if __name__=="__main__":unittest.main()
