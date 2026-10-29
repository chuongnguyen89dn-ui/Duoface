"""First-party native map physical-pane handoff: source ownership, not map tiles."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
HOST=ROOT.parent/"duoface-native-scene-host"
def read(path):return path.read_text(encoding="utf-8")
class NativeMap099(unittest.TestCase):
 def test_springboard_produces_actual_own_window_snapshot(self):
  chrome=read(HOST/"DFNative12Chrome.m")
  probe=read(HOST/"DFTouchOwnerProbe.m")
  self.assertIn("actualTwoPaneWindowReadback",chrome)
  self.assertIn('@"PhysicalWindowReadback":[self actualTwoPaneWindowReadback]',chrome)
  self.assertIn('@"HasLiveApp":@([self.sceneHandleReady[(NSUInteger)physical] boolValue])',chrome)
  self.assertIn("if(self.startupActive || DFSlotCountForPreset(self.preset)!=2",chrome)
  self.assertIn('@"Owner":@"SpringBoard"',probe)
  self.assertIn("DFSessionStillActive",probe)
  self.assertIn("physical-panes.v1.plist",probe)
 def test_carplay_native_uses_same_session_real_dock_and_physical_windows(self):
  binding=read(ROOT/"DFCarPlayPhysicalPaneBinding.h")
  coord=read(ROOT/"DFNativeMapPaneCoordinator.m")
  for token in ("physical-duoface-slot-not-verified",
   "target-duoface-slot-already-hosts-app",
   "native-dock-and-duoface-physical-geometry-disagree",
   "sample[@\"Session\"] isEqual:heartbeat[@\"Session\"]",
   "DFPhysicalMapNearRect"):
   self.assertIn(token,binding)
  self.assertIn("DFPhysicalMapVerifyPane(physical,heartbeat,plan",coord)
  self.assertIn('if(![binding[@"Verified"] isEqual:@YES])',coord)
  self.assertIn('CGRectFromString(binding[@"Target"])',coord)
  self.assertIn("native-owner-attached-physical-frame-observed-map-tiles-not-verified",coord)
  self.assertNotIn("CGAffineTransformMakeScale",coord)
 def test_scene_ownership_and_restoration_not_bypassed(self):
  coord=read(ROOT/"DFNativeMapPaneCoordinator.m")
  adapter=read(ROOT/"DFNativeMapPaneAdapter.m")
  self.assertIn("only-two-slot-native-map-supported",coord)
  self.assertIn("existing-lease-must-restore-first",coord)
  self.assertIn("restoreOriginalOwnerWithError",coord)
  self.assertIn("DFMapExactFBScene",adapter)
  self.assertIn("target-parent-different-carplay-window",adapter)
  self.assertIn("native-maps-scene-host-identity-unverified",adapter)
  self.assertIn("target-pane-overlaps-native-chrome",adapter)
if __name__=="__main__":unittest.main(verbosity=2)
