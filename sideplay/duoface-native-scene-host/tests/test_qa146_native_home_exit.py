"""QA146: QA145 real Log22 showed tap=1 home=0 and no independent stop.
This checks the existing native statusbar Home button unblocks the SOLO owner
without changing the original CarPlay Home forwarding or requiring DuoFace split.
No device runtime success is claimed.
"""
import pathlib, unittest
R=pathlib.Path(__file__).resolve().parents[1]
H=(R/"DFCarPlayOwnerObserver.h").read_text()
B=(R/"DFHomeStandalone144.m").read_text()
D=(R/"DFCarPlayDockOwner.m").read_text()
class NativeSoloHomeRelease(unittest.TestCase):
 def test_real_native_home_callback_and_original_preserved(self):
  self.assertIn('@"homeButtonUp:"',H)
  self.assertIn('DFOwnerInstallHome(NSClassFromString(@"DBRootStatusBarViewController")',H)
  self.assertIn('DFOwnerDBHomeOriginal(object,sel,event);',H)
  self.assertIn('DFOwnerCARHomeOriginal(object,sel,event);',H)
  self.assertIn('DFOwnerHomeReceived(object);',H)
  self.assertIn('DFOwnerHomeHooksReady=DFOwnerHomeCoverage();',H)
 def test_stop_is_before_old_duoface_only_pulse_gate(self):
  body=H.split("static void DFOwnerHomeReceived(id receiver) {",1)[1].split("static void DFOwnerDBHome(",1)[0]
  # This must be AFTER native UIViewController and real UIScreen checks,
  # yet BEFORE the old DuoFace CPTemplate session check.
  screen=body.index('if(!window.screen || window.screen.bounds.size.width<300)return;')
  stop=body.index('notify_post("com.duoface.nativehost.standalone144.stop")')
  gate=body.index('DFOwnerValidSession(session)')
  self.assertLess(screen,stop)
  self.assertLess(stop,gate)
  self.assertIn('qa146-native-home-standalone-stop-notified',body)
  self.assertEqual(body.count('notify_post("com.duoface.nativehost.standalone144.stop")'),1)
 def test_only_independent_owned_surface_is_released(self):
  self.assertIn('notify_register_dispatch(DF144StopNotify,',B)
  self.assertIn('[DF144Owner stop:@"native-Home-exit"];',B)
  self.assertIn('if(self.window)self.window.hidden=YES;',B)
  self.assertIn('releaseHostedView:view',B)
  self.assertNotIn('DFNative12Chrome',H)
  self.assertIn('#import "DFCarPlayOwnerObserver.h"',D)
 def test_selected_home_app_callback_and_native_dock_remain(self):
  self.assertIn('iconManager:launchIconForIconView:',B)
  self.assertIn('DF144Original(self,cmd,manager,icon);return;',B)
  self.assertIn('DBStatusBarWindow',B)
  self.assertIn('DBNotificationWindow',B)
if __name__=="__main__":unittest.main()
