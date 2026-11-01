"""QA158 independent Home-only app acceptance contract (static, no phone proof)."""
from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
SOLO=(R/"DFHomeStandalone144.m").read_text()
PICKER=(R/"DFSoloPill157.h").read_text()
HOME=(R/"DFCarPlayOwnerObserver.h").read_text()
BROKER=(R/"DFSoloPickerCarPlay157.h").read_text()
class HomeOnly158(unittest.TestCase):
 def test_no_three_dot_on_running_app(self):
  builder=PICKER.split("- (void)df157InstallSoloMenuWithUsableRect:",1)[1]
  self.assertNotIn("UIButton *pill=",builder)
  self.assertNotIn('setTitle:@"•••"',builder)
  self.assertNotIn("df157SoloPillPressed:",PICKER)
  self.assertIn("self.soloPill=nil;",builder)
  self.assertIn("picker.view.hidden=YES;",builder)
  self.assertNotIn("self.soloPill.hidden=NO",SOLO)
  self.assertIn("setSplitMode:NO forHostedView:v",SOLO)
 def test_home_route_not_gated_by_dying_remote_scene(self):
  body=PICKER.split("- (BOOL)df157ReturnHomeToPicker {",1)[1].split("- (void)appPickerDidCancel:",1)[0]
  gate=body.split(" BOOL outgoingSceneLive=",1)[0]
  self.assertIn("!self.emittedManager",gate)
  self.assertIn("self.window.rootViewController!=self.root",gate)
  self.assertIn("![self currentCarDisplayWithID:self.carDisplayID]",gate)
  self.assertNotIn("isLiveSceneForHostedView:",gate)
  self.assertIn("self.homeChooser=YES;",body)
  self.assertIn("self.soloPicker.view.hidden=NO;",body)
  self.assertIn('reply:@"stopped" reason:@"native-Home-exit"',body)
  self.assertIn('notify_post("com.duoface.nativehost.standalone144.stop")',HOME)
  self.assertIn("DFOwnerDBHomeOriginal(object,sel,event);",HOME)
 def test_only_home_chooser_selects_next_app_and_preserves_native_owner(self):
  b=PICKER.split("didSelectBundleID:(NSString *)bundle displayName:",1)[1].split("- (void)appPickerDidRequestLayout:",1)[0]
  self.assertIn("!self.homeChooser",b)
  self.assertIn("DF144PickerRequest atomically:YES",b)
  self.assertIn("notify_post(DF144PickerNotify)",b)
  self.assertIn("DF144BeginSelectedBridge(bundle,home?:dock",BROKER)
  self.assertIn("DF147Life.active && !DF147Life.pending",BROKER)
  self.assertIn("DF144LastRequest=[uuid copy];",SOLO)
if __name__=="__main__":unittest.main()
