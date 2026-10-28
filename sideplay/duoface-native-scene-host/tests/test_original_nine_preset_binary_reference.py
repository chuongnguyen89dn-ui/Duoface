"""Check the nine explicit original Native12 preview-image cases against
our first-party geometry. This is real Mach-O-derived evidence, not the
previous assistant-authored eight-choice substitute and NOT a device test.
"""
import json
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
RENDERER=ROOT/"sideplay/audit/native12-real-deb-cardcount-20261022/evidence/helper/ORIGINAL_PRESET_IMAGE_RENDERER_ARM64.json"
ENGINE=ROOT/"sideplay/duoface-native-scene-host/DFLayoutEngine.m"
CHROME=ROOT/"sideplay/duoface-native-scene-host/DFNative12Chrome.m"
PHONE=ROOT/"sideplay/duoface-native-scene-host/DFNativeHostRootController.m"
RECEIVER=ROOT/"sideplay/duoface-native-scene-host/DFNativeHostAppDelegate.m"
ORIGINAL_SHA="9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
CASES=[
 (0,0x9f290,1,"solo"),
 (1,0x9f2fc,2,"left-right"),
 (2,0x9f384,2,"top-bottom"),
 (3,0x9f408,3,"three-columns"),
 (4,0x9f4f4,3,"left-plus-two-right"),
 (5,0x9f5c4,3,"two-left-plus-right"),
 (6,0x9f690,3,"top-plus-two-bottom"),
 (7,0x9f760,3,"two-top-plus-bottom"),
 (8,0x9fdd4,4,"four-quadrants")
]
class OriginalBinaryNinePresetMapping(unittest.TestCase):
 def test_actual_nine_arm64_jump_entries_and_independent_source(self):
  renderer=json.loads(RENDERER.read_text())
  self.assertEqual(renderer["original_dashboard_sha256"],ORIGINAL_SHA)
  table=renderer["nine_case_jump_table"]
  self.assertEqual(table["table_vmaddr"],"0x310d3e")
  self.assertEqual(table["adr_base"],"0x9f290")
  cases=table["cases"]
  self.assertEqual(len(cases),9)
  engine=ENGINE.read_text();chrome=CHROME.read_text()
  phone=PHONE.read_text();receiver=RECEIVER.read_text()
  for preset,pc,slots,label in CASES:
   with self.subTest(preset=preset,visual_shape=label):
    self.assertEqual(cases[preset]["preset_tag"],preset)
    self.assertEqual(int(cases[preset]["renderer_case_pc"],16),pc)
    self.assertIn(f"case {preset}:",engine)
  self.assertIn("preset==8?4:3",engine)
  self.assertIn("for(NSInteger idx=0;idx<9;idx++)",chrome)
  self.assertIn('@"Bốn ô"',chrome)
  self.assertIn("selected>8",chrome)
  self.assertIn("self.tabs.selectedSegmentIndex==2?10:",phone)
  self.assertIn("active>4",receiver)
  self.assertTrue(renderer["all_nine_card_visual_shapes_verified"] is False)
  # Exact case targets and authored frame semantics are source-checked;
  # UIKit images, pixel colors, launch/touch/audio await real CarPlay test.
if __name__=="__main__": unittest.main()
