"""QA138 package contract; historical QA137 diagnostic remains read-only."""
from pathlib import Path
import plistlib
import unittest
ROOT=Path(__file__).resolve().parents[1]
REPO=ROOT.parents[1]
class Home138PackageContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.probe=(ROOT/"DFHomeAdmission137Probe.m").read_text()
        cls.entry=(ROOT/"DFHomePublisher136Entry.m").read_text()
        cls.core=(ROOT/"DFHomePublisher136Core.m").read_text()
        cls.host=(ROOT/"build.sh").read_text()
        cls.diag=(ROOT/"DFNativeDiagnostics.m").read_text()
        cls.package=(REPO/"sideplay/jb-embedded-appbridge/package_integrated.py").read_text()
    def test_probe_bounded_and_observe_only(self):
        for token in ("DF137InScope", "DF137MethodABI", "DF137ObserveExistingAppInfo",
                      "FBSApplicationLibrary", "DBApplicationInfo",
                      "entitlementValueForKey:ofClass:valuesOfClass:",
                      "CARApplication", "DBApplicationController",
                      "_setupIconModel", "iconManager:launchIcon:",
                      "DuoFaceHomeAdmission137.log",
                      "@3, @12, @30", "DF137InfoSamples >= 32"):
            self.assertIn(token,self.probe)
        for dangerous in ("MSHookMessageEx","method_setImplementation",
                          "class_replaceMethod","setIconState:forVehicleID:",
                          "setCarPlaySupported:","addApplicationProxy:",
                          "entitlementValueForKey3(",
                          "killall SpringBoard","sbreload"):
            self.assertNotIn(dangerous,self.probe)
    def test_existing_publisher_has_guarded_admission(self):
        self.assertIn("DFHome136ReconcileVerifiedLibrary(id library)",self.core)
        self.assertIn("DF137ObserveExistingAppInfo(already",self.core)
        self.assertIn("DF137ObserveExistingAppInfo(info",self.core)
        self.assertIn("isEqualToString:@\"CarPlay\"",self.core)
        self.assertIn("user Home switch OFF or kill switch",self.entry)
    def test_one_sileo_package_both_process_probes(self):
        self.assertEqual(self.host.count("DFHomeAdmission137Probe.m"),2)
        self.assertIn("0.1.138~selectedlayout1",self.host)
        self.assertIn("DuoFaceHomeAdmission137.log",self.diag)
        self.assertIn("0.1.138~selectedlayout1",self.package)
        self.assertIn('VERSION="0.0.138~selectedlayout1"',self.package)
        self.assertIn('"device_carplay_icon_tested":False',self.package)
        info=plistlib.loads((ROOT/"Info.plist").read_bytes())
        self.assertEqual(info["CFBundleVersion"],"138")
        self.assertEqual(info["CFBundleShortVersionString"],"0.1.138")
        self.assertIn("Version: 0.1.138~selectedlayout1",(ROOT/"control").read_text())
        with (ROOT/"DFCarPlayDockOwner.plist").open("rb") as f:
            filters=plistlib.load(f)["Filter"]
        self.assertIn("com.apple.dashboard",filters["Bundles"])
        with (ROOT/"DFTouchOwnerProbe.plist").open("rb") as f:
            filters=plistlib.load(f)["Filter"]
        self.assertEqual(filters,{"Bundles":["com.apple.springboard"],"Executables":["SpringBoard"]})
    def test_qa135_goaf_and_qa136_switch_remain(self):
        self.assertIn("DFHome136Enabled()",self.core)
        self.assertIn("DFHome136Enabled()",self.entry)
        self.assertIn("DFHome136Changed",self.entry)
        self.assertNotIn("setLaunchUsingTemplateUI:",self.probe)
if __name__=="__main__":unittest.main()
