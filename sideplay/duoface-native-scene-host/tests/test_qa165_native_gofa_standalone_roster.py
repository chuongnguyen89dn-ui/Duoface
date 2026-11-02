"""QA165 read-only CarPlay Home roster / actual GOFA location callback pilot.
No device permission, CarPlay Home icon, or GPS numeric value is claimed by these tests.
"""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
PACK=(ROOT.parent/"jb-embedded-appbridge/package_integrated.py").read_text()
class TestNativeGofaAndHome165(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.tap=(ROOT/"DFGofaNativeLocationTap165.m").read_text()
  cls.old=(ROOT/"DFGofaSpeedSource162.m").read_text()
  cls.hud=(ROOT/"DFHomeStandalone144.m").read_text()
  cls.native=(ROOT/"DFSpeedNativeOverlay163.mm").read_text()
  cls.home=(ROOT/"DFHomePublisher136Core.m").read_text()
  cls.build=(ROOT/"build.sh").read_text()
 def test_single_signed_duoface_package_and_conservative_data_origin(self):
  self.assertIn('VERSION="0.0.173~touchlog1"',PACK)
  self.assertIn("0.1.173~touchlog1",self.build)
  self.assertNotIn("-DDF165_PASSIVE_GOFA_ONLY=1",self.build)
  self.assertIn("DFGofaNativeLocationTap165.m",self.build)
  self.assertIn("DFGofaSpeedSource162.m",self.build)
  self.assertIn("DFGofaSpeedSource162.m DFGofaNativeLocationTap165.m DFGofaTrafficNavProbe166.m",self.build)
  self.assertNotIn("CPSActivation",self.tap)
  self.assertIn("com.lumi.GOFA",self.tap)
  self.assertIn("DFSpeedHUDPublish(DFSpeedAppSourceGOFA,kmh,YES,0,NO)",self.tap)
  self.assertIn("method_setImplementation",self.tap)
  self.assertIn("DF165OriginalDidUpdate(receiver,cmd,manager,locations)",self.tap)
  self.assertIn("QA165 GOFA native location CALLBACK",self.tap)
  self.assertIn("DF165LastNativeGPSPublishUptime()",self.old)
  self.assertIn("fallbackEligible",self.old)
  self.assertIn("startUpdatingLocation",self.old)
 def test_HUD_appears_in_springboard_owned_native_home_standalone(self):
  self.assertIn("self.speedWindow=bubble;self.speedHUD=speed",self.hud)
  self.assertIn("speed.floatingWindowMode=YES",self.hud)
  self.assertIn("speed.floatingDragBounds=content",self.hud)
  self.assertIn("self.speedWindow.hidden=YES",self.hud)
  self.assertIn('record[@"HUDOwnerVisible"]=@YES',self.hud)
  self.assertIn("DF165StandaloneLease",self.native)
  self.assertIn('standalone[@"HUDOwnerVisible"]',self.native)
  self.assertIn("age>=0 && age<2.0",self.native)
 def test_native_carplay_home_selected_app_result_logged_not_fabricated(self):
  self.assertIn("NATIVE_DECLARATION_EXISTS_OS_HOME_ICON_NOT_MANAGED_BY_DUOFACE",self.home)
  self.assertIn("BRIDGE_DECLARATION_SENT_TO_FBS_ICON_NOT_YET_VERIFIED",self.home)
  self.assertIn("NOT_INSTALLED_OR_DIFFERENT_BUNDLE_ID",self.home)
  self.assertIn("DuoFaceHomeRoster165.log",self.home)
  self.assertIn("DFHome141InfoHasDeclaration(already)",self.home)
  self.assertNotIn("setVisible:",self.home)
if __name__=="__main__": unittest.main()
