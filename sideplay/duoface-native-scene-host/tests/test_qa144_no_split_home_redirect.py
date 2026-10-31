"""QA144 negative-control: Home external app MUST NOT redirect to DuoFace's split UI.

This test verifies only that the broken QA143 launch hook is no longer linked.
It does NOT claim the new standalone renderer has been implemented or tested.
"""
import pathlib,unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
BUILD=(ROOT/"build.sh").read_text()
SPLIT=(ROOT/"DFNative12Chrome.m").read_text()
SCENE=(ROOT/"DFSceneHost.m").read_text()
OLD=(ROOT/"DFHomeLaunch143.m").read_text()
class StandaloneHome144Guard(unittest.TestCase):
 def test_qa143_wrong_icon_substitution_not_linked(self):
  self.assertNotIn("DFHomeLaunch143.m",BUILD)
  self.assertIn('DF143Original(owner,selector,manager,duofaceView)',OLD)
  self.assertIn('DF143HostID=@"com.duoface.native.scenehost"',OLD)
 def test_split_scoped_to_original_duoface_ui_only(self):
  # Existing split functionality is retained for entering DuoFace by its own icon.
  self.assertIn("DFNative12Chrome.m",BUILD)
  self.assertIn("DFSceneHost.m",BUILD)
  self.assertIn("appPicker:(DFAppPickerVC *)picker",SPLIT)
  self.assertIn("hostViewForBundleID:",SCENE)
 def test_qa143_outdated_home_remains_not_the_future_signed_release(self):
  self.assertIn("0.1.143~homebridge1",BUILD)
  # No QA144 build can be considered valid until a distinct Home standalone
  # producer, scene consumer, lifecycle and new signed version are added.
  self.assertNotIn("DFHomeLaunch144.m",BUILD)
  self.assertNotIn("DFHomeStandalone144.m",BUILD)
if __name__=="__main__":unittest.main()
