"""QA159 native Home destination based on physical Log26 (source-only tests)."""
from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
SOLO=(R/"DFHomeStandalone144.m").read_text()
PILL=(R/"DFSoloPill157.h").read_text()
HOME=(R/"DFCarPlayOwnerObserver.h").read_text()
DOCK=(R/"DFNativeDockSync147.h").read_text()

class NativeCarPlayHome159(unittest.TestCase):
 def test_native_home_does_not_leave_first_party_picker(self):
  body=SOLO.split("notify_register_dispatch(DF144StopNotify,&stopToken",1)[1].split("notify_register_dispatch(DF148WatchdogStopNotify",1)[0]
  self.assertIn('[DF144Owner stop:@"native-Home-exit"]',body)
  self.assertIn('DF153PhoneRevoke();',body)
  self.assertIn('qa159-native-home-stop-no-chooser',body)
  self.assertNotIn("df157ReturnHomeToPicker",body)
  self.assertNotIn('self.homeChooser=YES',body)
 def test_no_custom_chooser_created_during_independent_launch(self):
  begin=SOLO.split("- (BOOL)begin:(NSDictionary *)p {",1)[1].split("- (void)attemptOwnedReadyForView:",1)[0]
  self.assertNotIn("[self df157InstallSoloMenuWithUsableRect:usable]",begin)
  self.assertIn("hostViewForBundleID:self.bundle error:&err",begin)
  self.assertIn("setSplitMode:NO forHostedView:v",begin)
  self.assertNotIn("DF157RegisterSoloPickerReceiver();",SOLO)
  self.assertNotIn('#import "DFSoloPickerCarPlay157.h"',SOLO)
  self.assertIn("- (BOOL)df157ReturnHomeToPicker {return NO;}",PILL)
 def test_statusbar_native_apple_home_callback_unmodified(self):
  self.assertIn('DF157NativeHomeCallbackObserved();',HOME)
  self.assertIn('notify_post("com.duoface.nativehost.standalone144.stop")',HOME)
  self.assertIn("DFOwnerDBHomeOriginal(object,sel,event);",HOME)
  self.assertIn("DFOwnerCARHomeOriginal(object,sel,event);",HOME)
  self.assertIn('DF144ChooserSession=nil; // QA159',SOLO)
  self.assertIn('DF147Reset(@"native-home-stop")',SOLO)
  self.assertIn('DF147RestoreDock(terminalReason)',DOCK)
if __name__=="__main__":unittest.main()
