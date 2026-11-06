"""QA180 owner-scoped in-path wake plus preserved legacy keyboard relays.
The first hidden contact wakes only; app-side injection remains allowlisted.
These source assertions do not establish device touch delivery.
"""
import pathlib,unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
INT=ROOT.parent/"jb-embedded-appbridge/package_integrated.py"
class QA172Wakefix(unittest.TestCase):
 def test_kb_state_sender(self):
  h=(ROOT/"DFAppTouch177.h").read_text()+(ROOT/"DFKeyboardState177.h").read_text()
  for token in ('com.duoface.kbstate177.wake','com.duoface.ipc.v177.kbstate',
                'DF177KbSetVisible','DF177KbRefreshFromScan',
                'UIRemoteKeyboardWindow','UIWindowDidBecomeVisibleNotification',
                'UIWindowDidBecomeHiddenNotification'):
   self.assertIn(token,h)
 def test_chrome_shield_and_receivers(self):
  chrome=(ROOT/"DFNative12Chrome.m").read_text()
  for token in ('ensureWakeGates','DFOwnedWakeSurface180','df177HandleKbState',
                'notify_register_dispatch(DF177KbWakeName',
                'notify_cancel(self.kbWake177Token)',
                'qa180-wake-contact','qa177-kb-state',
                'DF177CurrentTouchOwner','kbVisible177'):
   self.assertIn(token,chrome)
  self.assertIn('!DF155PilotAppID(bundle)',(ROOT/'DF154GeneralAppStateRelay.m').read_text())
 def test_app_touch_never_recalls_directly(self):
  chrome=(ROOT/"DFNative12Chrome.m").read_text()
  start=chrome.index('- (void)df177HandleAppTouch')
  end=chrome.index('- (void)realAppTouched:')
  body=chrome[start:end]
  self.assertNotIn('[self noteUserActivity]',body)
  self.assertIn('touch177RecheckGeneration',body)
  self.assertIn('qa177-extend-while-hidden',body)
 def test_version_coherence(self):
  self.assertIn('0.1.176~appwake1',(ROOT/"build.sh").read_text())
  self.assertIn('VERSION="0.0.176~appwake1"',INT.read_text())
  self.assertIn('Version: 0.1.176~appwake1',(ROOT/"control").read_text())
  self.assertIn('build=0.0.176~appwake1',(ROOT/"DFDeepTrace.h").read_text())
if __name__=="__main__":unittest.main()
