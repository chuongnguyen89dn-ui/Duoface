"""DuoFace #5 #6 #7: real-owned four app slots, 3/4 visual rotation, process metadata.
Source contract tests are separate from actual iOS SDK compilation and on-device QA.
"""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def src(name):return (ROOT/name).read_text(encoding="utf-8")
class Workspace098(unittest.TestCase):
 def test_remember_four_only_after_live_scene_ready_and_close(self):
  chrome=src("DFNative12Chrome.m")
  policy=src("DFSlotWorkspacePolicy.h")
  for token in ("PhysicalBundles","DFSavePhysicalBundleAtPath",
                "DFRestorablePhysicalBundles","DFRotateWorkspaceAtPath",
                "DFPhysicalForVisual","DFVisualForPhysical","RestoreOnReconnect"):
   self.assertIn(token,policy)
  self.assertIn("DFSavePhysicalBundle(i,bundle)",chrome)
  self.assertIn("DFSavePhysicalBundle(physicalSlot,@\"\")",chrome)
  ready=chrome.split("- (void)sceneReady:",1)[1].split("- (void)sceneFailed:",1)[0]
  self.assertLess(ready.index("self.sceneHandleReady[(NSUInteger)i]=@YES;"),
                  ready.index("DFSavePhysicalBundle(i,bundle)"))
  self.assertNotIn("setForeground:",policy)
 def test_connection_restore_is_bounded_and_approval_gated(self):
  chrome=src("DFNative12Chrome.m")
  self.assertIn("beginSavedWorkspaceRestore",chrome)
  self.assertIn("restoreNextSavedWorkspaceApp",chrome)
  self.assertIn("DFRestorablePhysicalBundles(self.workspace,",chrome)
  self.assertIn("DFPickerAllowsApp(bundle,DFConfiguredEnabledAppIDs())",chrome)
  self.assertIn("installedBundleIDsForRestore",chrome)
  self.assertIn("self.restorePending=YES;",chrome)
  self.assertIn("self.restoringPhysical=physical;",chrome)
  self.assertIn("self.restoreGeneration!=generation",chrome)
  self.assertIn("workspace-restore-timeout-skipped",chrome)
  self.assertIn("self.pendingScenes[(NSUInteger)physical]=surface;",chrome)
  self.assertIn("++self.restoreGeneration;",chrome)
 def test_cycle_scene_window_positions_never_reparent_existing_host(self):
  chrome=src("DFNative12Chrome.m")
  start=chrome.split("- (BOOL)rotateHostedAppsClockwise:",1)[1].split("- (UIWindow *)makeWindow:",1)[0]
  self.assertIn("DFRotateWorkspace(active,clockwise)",start)
  self.assertIn("surface.window!=self.appSceneWindows",start)
  self.assertIn("surface.superview!=self.appSceneContainers",start)
  self.assertNotIn("addSubview:",start)
  self.assertNotIn("releaseHostedView:",start)
  self.assertIn("physicalForVisual:",chrome)
  self.assertIn("visualForPhysical:",chrome)
 def test_scene_pid_is_real_and_absence_is_transparent(self):
  host=src("DFSceneHost.m")
  picker=src("DFAppPickerVC.m")
  chrome=src("DFNative12Chrome.m")
  self.assertIn("verifiedPIDForHostedView:",host)
  self.assertIn('DFCall1(registry,@"applicationWithBundleIdentifier:",surface.bundleID)',host)
  self.assertIn("kill(candidate,0)",host)
  self.assertIn("if(pid)detail[@\"PID\"]=pid",chrome)
  self.assertIn("PID chưa xác minh",picker)
  self.assertIn("Scene hiển thị",chrome)
  self.assertIn("Scene tạm ẩn",chrome)
  self.assertIn("appPicker:self closeRunningBundleID:",picker)
  self.assertIn("appPicker:self restartRunningBundleID:",picker)
  self.assertNotIn("kill(",chrome)
 def test_rotations_explicit_and_only_three_or_four_ready_apps(self):
  picker=src("DFAppPickerVC.m")
  chrome=src("DFNative12Chrome.m")
  self.assertIn("rotateRunningClockwise",picker)
  self.assertIn("self.runningRotateCapacity>=3",picker)
  self.assertIn("rotateHostedAppsClockwise:",chrome)
  self.assertIn("if(active<3 || active>4",chrome)
  self.assertIn("self.sceneHandleReady[(NSUInteger)i]",chrome)
 def test_logo_92_raw_contact_is_byte_pinned(self):
  chrome=src("DFNative12Chrome.m")
  golden=(ROOT/"tests/fixtures/logo92_contact_and_swap_baseline.txt").read_text()
  start=chrome.index("- (void)logoTouchDown:")
  end=chrome.index("// The divider window itself is re-framed",start)
  self.assertEqual(chrome[start:end],golden)
 def test_iphone_restore_enable_and_reset(self):
  phone=src("DFNativeHostRootController.m")
  self.assertIn("showWorkspaceRestoreMenu",phone)
  self.assertIn("DFSetRestoreOnReconnect(!enabled)",phone)
  self.assertIn("DFEmptyPhysicalBundles()",phone)
if __name__=="__main__":unittest.main(verbosity=2)
