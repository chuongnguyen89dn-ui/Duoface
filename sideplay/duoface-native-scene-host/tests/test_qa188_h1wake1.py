"""QA178 h1wake1 contract: QA171 base + QA177 H1 recall wiring
(relays + DFAppTouch177.h) + the app-side first-touch swallow while
controls are hidden. Host-side H1 registration lives in the
DFH1Wake188.m companion so DFNative12Chrome.m stays byte-identical
to the QA171 base. This is not device acceptance.
"""
import pathlib,unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
INT=ROOT.parent/"jb-embedded-appbridge/package_integrated.py"
class QA178H1Wake(unittest.TestCase):
 def test_sender_header_contract(self):
  h=(ROOT/"DFAppTouch177.h").read_text()
  for token in ('com.duoface.apptouch177.wake','com.duoface.ipc.v177.apptouch',
                'AppTouchRecall177','DF177InstallAppTouchHook','DF177AppTouchNoteBegan',
                'DF188ControlsHidden','DF188Swallowing','swallowed',
                'com.duoface.controls188.state'):
   self.assertIn(token,h)
 def test_relays_install_sender(self):
  relay=(ROOT/"DF154GeneralAppStateRelay.m").read_text()
  self.assertIn('#define DF177_APP_SIDE_SENDER 1',relay)
  self.assertIn('DF177InstallAppTouchHook(bundle)',relay)
  yt=(ROOT/"DFYouTubeOrientationRelay.m").read_text()
  self.assertIn('DF177InstallAppTouchHook(DFYTBundle)',yt)
 def test_host_companion(self):
  comp=(ROOT/"DFH1Wake188.m").read_text()
  for token in ('DF177TouchWakeName','noteUserActivity','layoutControls',
                'qa188-h1-app-touch-wake','qa188-h1-controls-state',
                'ControlsHidden188','notify_register_dispatch'):
   self.assertIn(token,comp)
  self.assertIn('DFH1Wake188.m',(ROOT/"build.sh").read_text())
 def test_chrome_untouched_by_h1(self):
  chrome=(ROOT/"DFNative12Chrome.m").read_text()
  self.assertNotIn('DFAppTouch177',chrome)
  self.assertNotIn('DFH1Wake188',chrome)
 def test_version_coherence(self):
  self.assertIn('0.1.179~h1wake2',(ROOT/"build.sh").read_text())
  self.assertIn('VERSION="0.0.179~h1wake2"',INT.read_text())
  self.assertIn('Version: 0.1.179~h1wake2',(ROOT/"control").read_text())
  info=(ROOT/"Info.plist").read_text()
  self.assertIn('<key>CFBundleVersion</key><string>178</string>',info)
if __name__=="__main__":unittest.main()
