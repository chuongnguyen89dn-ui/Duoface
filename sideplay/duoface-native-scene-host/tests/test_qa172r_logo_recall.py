"""QA172R contract: the QA171 build plus ONLY the QA177 H1 controls
recall (app-side touch sender + SpringBoard receiver). Everything else
from QA172-QA185 stays out; this is not keyboard/HUD/device acceptance.
"""
import pathlib,unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
INT=ROOT.parent/"jb-embedded-appbridge/package_integrated.py"
class QA172RLogoRecall(unittest.TestCase):
 def test_sender_header_contract(self):
  h=(ROOT/"DFAppTouch177.h").read_text()
  for token in ('com.duoface.apptouch177.wake','com.duoface.ipc.v177.apptouch',
                'AppTouchRecall177','DF177InstallAppTouchHook','DF177AppTouchNoteBegan'):
   self.assertIn(token,h)
 def test_relays_install_sender(self):
  relay=(ROOT/"DF154GeneralAppStateRelay.m").read_text()
  self.assertIn('#define DF177_APP_SIDE_SENDER 1',relay)
  self.assertIn('DF177InstallAppTouchHook(bundle)',relay)
  yt=(ROOT/"DFYouTubeOrientationRelay.m").read_text()
  self.assertIn('DF177InstallAppTouchHook(DFYTBundle)',yt)
 def test_chrome_receiver(self):
  chrome=(ROOT/"DFNative12Chrome.m").read_text()
  for token in ('notify_register_dispatch(DF177TouchWakeName','df177HandleAppTouch',
                'qa177-recall','notify_cancel(self.touchWake177Token)'):
   self.assertIn(token,chrome)
 def test_nothing_else_from_later_rounds(self):
  relay=(ROOT/"DF154GeneralAppStateRelay.m").read_text()
  yt=(ROOT/"DFYouTubeOrientationRelay.m").read_text()
  chrome=(ROOT/"DFNative12Chrome.m").read_text()
  for forbidden in ('DFKBDiag176','df176KeyboardShown'):
   self.assertNotIn(forbidden,relay); self.assertNotIn(forbidden,chrome)
  self.assertNotIn('DF175RelayGuardEnabled',yt)
  for forbidden in ('hudHandover177','DFDestSize185','SplitSuper186'):
   self.assertNotIn(forbidden,chrome)
 def test_version_coherence(self):
  self.assertIn('0.1.177~a1wake1',(ROOT/"build.sh").read_text())
  self.assertIn('VERSION="0.0.177~a1wake1"',INT.read_text())
  self.assertIn('Version: 0.1.177~a1wake1',(ROOT/"control").read_text())
  info=(ROOT/"Info.plist").read_text()
  self.assertIn('<key>CFBundleVersion</key><string>177</string>',info)
if __name__=="__main__":unittest.main()
