"""DuoDash source comparison contracts and user-reported real-device regressions.
Source-only tests: do NOT certify iPhone/CarPlay process exit or native map tiles.
"""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
MAP=ROOT.parent/"native-carplay-scene-v1"/"DFNativeMapPaneCoordinator.m"
def f(name):return (ROOT/name).read_text(encoding="utf-8")
class DuoDashManagedReconnect110(unittest.TestCase):
 def test_opt_in_unplug_has_physical_display_probe_and_managed_scope(self):
  probe=f("DFTouchOwnerProbe.m")
  disc=f("DFDisconnectCloseCoordinator.m")
  policy=f("DFDisconnectClosePolicy.h")
  self.assertIn("AVExternalDevice",probe)
  self.assertIn("screenIDs",probe)
  self.assertIn("CADisplay",probe)
  self.assertIn("DFDisconnectClosePhysicalObserved",probe)
  self.assertIn("DFDisconnectCloseGrace=10.0",policy)
  self.assertIn("CloseOnPhysicalDisconnect",policy)
  self.assertIn('gProbe && !gProbe()',disc)
  self.assertIn("generation==gGeneration",disc)
  self.assertIn("DFDiscPhoneForegroundIsSafeForClose",disc)
  self.assertIn("DFDiscVerifiedCurrentPID",disc)
  self.assertIn("RBSTerminateRequest",disc)
  self.assertIn("kill(original,0)",disc) # read-only PID exit check
  self.assertNotIn("kill(pid,SIGTERM)",disc)
  self.assertIn("capture-empty",disc) # explicit evidence when no managed app
 def test_old_only_new_process_filter_is_replaced_with_duodash_managed_scope(self):
  chrome=f("DFNative12Chrome.m")
  block=chrome.split("- (NSArray<NSDictionary *> *)disconnectTerminationCandidates {")[1].split(
    "- (NSArray<NSDictionary *> *)actualTwoPaneWindowReadback",1)[0]
  self.assertIn("[host isLiveSceneForHostedView:surface]",block)
  self.assertIn("[host verifiedPIDForHostedView:surface]",block)
  self.assertNotIn("&& ![host wasProcessAbsentBeforeHostedView:surface]",block)
  self.assertIn('"NewlyStarted":@([host wasProcessAbsentBeforeHostedView:surface])',block)
  self.assertIn("sceneHandleReady[physical]",block)
  self.assertNotIn("terminate",block)
 def test_pending_second_pane_is_remembered_without_fabricated_ready(self):
  chrome=f("DFNative12Chrome.m")
  selected=chrome.split("- (void)appPicker:(DFAppPickerVC *)picker\n  didSelectBundleID:",1)[1].split("- (void)sceneReady:",1)[0]
  self.assertLess(selected.index("hostViewForBundleID:bundleID"),
    selected.index("DFSavePhysicalBundle(physicalSlot,bundleID)"))
  self.assertIn("if(![active isKindOfClass:UIView.class])",selected)
  self.assertIn("self.workspace=DFCurrentWorkspace();",selected)
  self.assertIn("workspace-intent-saved-pending",selected)
  restore=chrome.split("- (void)restoreNextSavedWorkspaceApp {",1)[1].split(
    "// Shift physical scene WINDOWS",1)[0]
  self.assertIn("owner.restoreGeneration!=generation",restore)
  self.assertIn("DFPickerAllowsApp(bundle,DFConfiguredEnabledAppIDs())",restore)
 def test_native_map_has_separate_verified_session_lease_and_explicit_choice(self):
  native=MAP.read_text(encoding="utf-8")
  disc=f("DFDisconnectCloseCoordinator.m")
  header=f("DFNativeMapLeasePolicy.h")
  for marker in ("DFNativeMapRememberedChoice", "DFNativeMapSaveChoice(self.slot)",
        "DFNativeMapWriteLease(self.boundSession,bundle,self.slot)",
        "DFPhysicalMapVerifyPane", "DFMapVerifiedBundle(self.owner)",
        "autoRestoreAfterReconnectIfVerified","self.lastAutoSession=[session copy]",
        'DFMapFindVC(root,0,[NSMutableSet new],owners)',
        "DFNativeMapForgetChoice()", "DFNativeMapFreshLease"):
    self.assertIn(marker,native+disc+header,marker)
  self.assertIn('"com.google.Maps"',header)
  self.assertIn('"com.waze.iphone"',header)
  self.assertIn('"com.apple.Maps"',header)
  self.assertIn('@"Session":session',header)
  self.assertIn('age>=0&&age<=5.0',header)
  self.assertIn("DFDiscVerifiedCurrentPID(native)",disc)
  self.assertIn("if(![workspace[@\"RestoreOnReconnect\"] isEqual:@YES])return;",native)
  self.assertNotIn("setForeground:",native)
 def test_export_report_is_read_only_and_explains_actual_user_case(self):
  diag=f("DFNativeDiagnostics.m")
  self.assertIn("Remembered app slot",diag)
  self.assertIn("Native map chosen physical slot",diag)
  self.assertIn("Physical unplug app close enabled:",diag)
  self.assertIn("DuoFaceDisconnectClose.log",diag)
  self.assertIn("VerifiedExited",diag)
if __name__=="__main__":unittest.main(verbosity=2)
