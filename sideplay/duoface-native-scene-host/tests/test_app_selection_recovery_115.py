"""Source-contract regressions for manual selection after reconnect / scene loss.

These checks do NOT simulate real SpringBoard, Youtube or CarPlay touch input.
They guard the proven source-level failure paths fixed in 0.0.115.
"""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
def read(name):return (ROOT/name).read_text(encoding="utf-8")

class AppSelectionRecovery115(unittest.TestCase):
 def test_cached_ready_is_not_current_live_scene(self):
  src=read("DFNative12Chrome.m")
  owner=src.split("- (void)appPicker:(DFAppPickerVC *)picker\n didSelectBundleID:",1)[1].split("- (void)sceneReady:",1)[0]
  self.assertIn("[owner isLiveSceneForHostedView:active]",owner)
  self.assertIn("app-selection-released-stale-scene",owner)
  self.assertIn("self.hostedScenes[(NSUInteger)physicalSlot]=NSNull.null;",owner)
  self.assertIn("self.sceneHandleReady[(NSUInteger)physicalSlot]=@NO;",owner)
  self.assertLess(owner.index("!activeIsLive"),owner.index("if(activeIsLive && [activeID isEqualToString:bundleID])"))
  self.assertIn("replace-same-live-app-noop",owner)
  self.assertNotIn("replace-same-app-noop",owner)
 def test_manual_user_selection_unblocks_serial_restore(self):
  src=read("DFNative12Chrome.m")
  method=src.split("- (void)appPicker:(DFAppPickerVC *)picker\n didSelectBundleID:",1)[1].split("- (void)sceneReady:",1)[0]
  for t in ('BOOL interruptedRestore=self.restorePending', 'self.restoringPhysical==physicalSlot',
            'self.restorePending=NO;', 'self.restoringPhysical=-1;',
            '[self.restoreQueue removeObject:@(physicalSlot)];',
            'workspace-restore-interrupted-by-manual-selection',
            'workspace-restore-queue-waits-for-manual-scene-ready',
            '[self restoreNextSavedWorkspaceApp];'):
   self.assertIn(t,method)
  self.assertLess(method.index("self.pendingScenes[(NSUInteger)physicalSlot]=host;"),
                  method.index("[container addSubview:host];"))
 def test_picker_checkmark_requires_real_live_owner_and_pending_has_clock(self):
  chrome=read("DFNative12Chrome.m")
  start=chrome.split("- (void)openAppPickerForSlot:",1)[1].split("- (void)openRunningAppManager",1)[0] if "- (void)openRunningAppManager" in chrome.split("- (void)openAppPickerForSlot:",1)[1] else chrome.split("- (void)openAppPickerForSlot:",1)[1][:2500]
  self.assertIn("[hostOwner isLiveSceneForHostedView:surface]",start)
  self.assertIn("self.appPickerController.pendingSlotBundleID=pendingBundle",start)
  self.assertIn("app-picker-live-vs-pending",start)
  header=read("DFAppPickerVC.h")
  picker=read("DFAppPickerVC.m")
  self.assertIn("pendingSlotBundleID;",header)
  self.assertIn('pendingApp?@"clock.fill"',picker)
  self.assertIn('selectedApp?@"checkmark.circle.fill"',picker)
  self.assertIn("card.appBadgeKind=selectedApp?1:(pendingApp?3:",picker)
 def test_no_fake_ready_and_no_unrelated_orientation_touch_mutation(self):
  chrome=read("DFNative12Chrome.m")
  host=read("DFSceneHost.m")
  selection=chrome.split("- (void)appPicker:(DFAppPickerVC *)picker\n didSelectBundleID:",1)[1].split("- (void)sceneReady:",1)[0]
  self.assertIn("host.userInteractionEnabled=NO",selection)
  self.assertNotIn("self.sceneHandleReady[(NSUInteger)physicalSlot]=@YES;",selection)
  self.assertIn("postNotificationName:DFSceneHostDidBecomeReadyNotification",host)
  self.assertIn("DFSavePhysicalBundle(physicalSlot,bundleID)",selection)
  self.assertIn("DFSavePhysicalBundle(i,bundle)",chrome)

if __name__=="__main__":unittest.main(verbosity=2)
