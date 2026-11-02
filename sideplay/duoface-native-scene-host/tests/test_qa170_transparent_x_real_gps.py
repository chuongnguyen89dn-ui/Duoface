"""QA170 source/ownership regressions; these do NOT substitute for parked-car QA."""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(name):
    return (ROOT/name).read_text()
class TestQA170(unittest.TestCase):
    def test_red_x_is_a_transparent_clipped_circle_not_black_square(self):
        hud=read("speed8/DFNative8SpeedHUDView.mm")
        block=hud.split("UILabel *DF169MakeBubbleDismissSymbol(void)",1)[1].split("static CGRect DFAllowedArea",1)[0]
        self.assertIn("target.backgroundColor=UIColor.clearColor",block)
        self.assertIn("target.opaque=NO",block)
        self.assertIn("target.layer.masksToBounds=YES",block)
        self.assertIn("target.clipsToBounds=YES",block)
        self.assertIn("target.layer.borderWidth=1.3",block)
        self.assertIn("target.layer.borderColor=[UIColor colorWithRed:",block)
        self.assertIn("target.textColor=[UIColor colorWithRed:",block)
        self.assertNotIn("target.backgroundColor=[UIColor colorWithWhite:0.10 alpha:0.72]",block)
    def test_two_floating_owners_are_nopaque_and_circular(self):
        for owner in ["DFNative12Chrome.m","DFHomeStandalone144.m"]:
            s=read(owner)
            self.assertIn("xRoot.view.opaque=NO",s)
            self.assertIn("xRoot.view.layer.masksToBounds=YES",s)
            self.assertIn("xRoot.view.layer.cornerRadius=22",s)
            self.assertIn("xWindow.layer.masksToBounds=YES",s)
            self.assertIn("xWindow.layer.cornerRadius=22",s)
            self.assertIn("xWindow.userInteractionEnabled=NO",s)
            self.assertIn("DF169MakeBubbleDismissSymbol()",s)
    def test_real_gofa_gps_fallback_is_authorized_and_never_prompts(self):
        source=read("DFGofaSpeedSource162.m")
        tap=read("DFGofaNativeLocationTap165.m")
        build=read("build.sh")
        self.assertNotIn("-DDF165_PASSIVE_GOFA_ONLY=1",build)
        self.assertIn("DFGofaSpeedSource162.m DFGofaNativeLocationTap165.m",build)
        self.assertIn("DF165LastNativeGPSPublishUptime()",source)
        self.assertIn("nativeHealthy",source)
        self.assertIn("fallbackEligible",source)
        self.assertIn("now-self.initializedAt>=10.0",source)
        self.assertIn("[self.manager startUpdatingLocation]",source)
        self.assertIn("[self.manager stopUpdatingLocation]",source)
        self.assertIn("AuthorizedWhenInUse",source)
        self.assertIn("AuthorizedAlways",source)
        self.assertIn("location.speed*3.6",source)
        self.assertIn("DFSpeedHUDPublish(DFSpeedAppSourceGOFA",source)
        self.assertIn("DF165OriginalDidUpdate(receiver,cmd,manager,locations)",tap)
        self.assertIn('isEqualToString:@"DFGofaSpeedSource162"',tap)
        self.assertIn("atomic_store_explicit",tap)
        self.assertIn("DF165LastNativeGPSPublishUptime",tap)
        self.assertNotIn("requestAlwaysAuthorization",source)
        self.assertNotIn("requestWhenInUseAuthorization",source)
        self.assertNotIn("limitKmh",source)
    def test_version_and_existing_transport(self):
        self.assertIn("0.1.173~touchlog1",read("build.sh"))
        pkg=(ROOT.parent/"jb-embedded-appbridge/package_integrated.py").read_text()
        self.assertIn('VERSION="0.0.173~touchlog1"',pkg)
        transport=read("speed8/DFSpeedTransport.mm")
        self.assertIn("DFSpeed::Decode",transport)
        self.assertIn("sample.limitValid = false",transport)
        self.assertIn("DFSpeed::NotifyName(DFSpeed::Source::GOFA)",transport)
if __name__=="__main__":unittest.main()
