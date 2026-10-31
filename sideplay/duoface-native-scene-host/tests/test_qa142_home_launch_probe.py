import pathlib
import unittest

ROOT=pathlib.Path(__file__).resolve().parents[1]
SRC=(ROOT/"DFHomeLaunchABI142.m").read_text()
BUILD=(ROOT/"build.sh").read_text()
CONTROL=(ROOT/"control").read_text()
PACKAGE=(ROOT.parent/"jb-embedded-appbridge"/"package_integrated.py").read_text()

class HomeLaunch142ABI(unittest.TestCase):
    def test_real_home_workspace_targeted(self):
        for marker in ("DBDashboardHomeViewController",
                       "DBApplicationController",
                       "DBMutableWorkspaceStateChangeRequest",
                       "DBWorkspace",
                       "requestStateChange:",
                       "iconManager:launchIcon:",
                       "iconManager:launchIconForIconView:",
                       "activateApplication:"):
            self.assertIn(marker,SRC)
    def test_no_unverified_home_or_scene_mutation(self):
        for bad in ("MSHookMessageEx", "method_setImplementation",
                    "class_replaceMethod", "setRequestedMode:",
                    "updateSettingsWithBlock:", "setForeground:",
                    "setBackgrounded:", "notify_post(",
                    "requestStateChange:)", "activateApplication:)",
                    "urlWithString", "openURL:"):
            self.assertNotIn(bad,SRC)
        self.assertIn("read-only-abi-report-complete no-launch-mutation",SRC)
        self.assertIn('processName isEqualToString:@"CarPlay"',SRC)
    def test_compiles_into_qa142_carplay_receiver_without_new_filter(self):
        self.assertIn("DFCarPlayDockOwner.m DFCarPlayHomeABIProbe.m",BUILD)
        self.assertIn("DFHomeAdmission141.m DFHomeLaunchABI142.m",BUILD)
        self.assertIn('0.1.142~homeabi1',BUILD)
        self.assertIn('Version: 0.1.142~homeabi1',CONTROL)
        self.assertIn('0.1.142~homeabi1',PACKAGE)
        self.assertIn('VERSION="0.0.142~homeabi1"',PACKAGE)
    def test_no_change_to_previous_qa141_executable_source(self):
        self.assertIn('DFGofaMapResize141.m',BUILD)
        self.assertIn('DFYouTubeOrientationRelay.m',BUILD)
        self.assertIn('DFTouchOwnerProbe.m',BUILD)

if __name__=="__main__":
    unittest.main()
