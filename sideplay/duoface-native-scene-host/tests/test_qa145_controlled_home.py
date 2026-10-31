"""QA145 static safety contract for the single controlled parked-car validation.
Passing does not mean an actual iPhone or CarPlay display was tested.
"""
import pathlib,unittest
R=pathlib.Path(__file__).resolve().parents[1]
bridge=(R/"DFHomeStandalone144.m").read_text()
ui=(R/"DFNativeHostRootController.m").read_text()
consent=(R/"DFHome145Consent.h").read_text()
trace=(R/"DFNativeDiagnostics.m").read_text()
build=(R/"build.sh").read_text()
class Home145OptInRegression(unittest.TestCase):
 def test_default_off_and_parent_policy_distinct(self):
  self.assertIn("DFHome145EnabledAt",consent)
  self.assertIn('p[@"StandaloneHomeDirect"] isEqual:@YES',consent)
  self.assertIn("DFHome140Enabled()",consent)
  self.assertIn("if(enable && !DFHome140Enabled())return NO;",consent)
  self.assertIn("writeToFile:DFHome145ConsentPath atomically:YES",consent)
  self.assertIn("DFHome145Enabled()",bridge)
 def test_phone_ui_has_separate_consent_and_safe_cancel(self):
  self.assertIn("Mở trực tiếp App từ CarPlay Home",ui)
  self.assertIn("home145SwitchChanged:",ui)
  self.assertIn('DFHome145Write(NO)',ui)
  self.assertIn('DFHome145Write(YES)',ui)
  self.assertIn("DFConfiguredEnabledAppIDs().count",ui)
  self.assertIn("Chỉ dùng khi xe đang đỗ",ui)
  self.assertIn("standalone144.stop",ui)
  self.assertIn("return section==0?10:",ui)
  self.assertIn("row==9",ui)
 def test_native_home_forwards_if_no_live_receiver(self):
  self.assertIn("DF144LiveReceiver()",bridge)
  self.assertIn("standalone144-sb-lease.plist",bridge)
  self.assertIn("age<=2.0",bridge)
  self.assertIn("DF144Original(self,cmd,manager,icon);return;",bridge)
  self.assertIn("DF144LeaseHeartbeat",bridge)
  self.assertIn("SpringBoard-Standalone144",bridge)
  self.assertIn("owner-revoked-consent-or-external-display",bridge)
  self.assertIn("previous-live-scene-no-longer-hosted",bridge)
 def test_manual_diagnostics_does_not_assume_render(self):
  self.assertIn("DuoFaceStandalone144.log",trace)
  self.assertIn("standalone144-result.plist",trace)
  self.assertIn("receiverAge",trace) if "receiverAge" in trace else self.assertIn("age=%.2fs",trace)
  self.assertIn("UNVERIFIED",trace)
  self.assertNotIn("scene-ready-and-play-verified",bridge)
 def test_qa145_distinct_signed_artifact_no_old_home_to_split(self):
  self.assertIn("0.1.145~standalone-controlled1",build)
  self.assertIn("DFHomeStandalone144.m",build)
  for old in ("DFHomeLaunch143.m","DFHomeSceneBridge143.m","DFHomeRequestReceiver143.m"):
   self.assertNotIn(old,build)
if __name__=="__main__":unittest.main()
