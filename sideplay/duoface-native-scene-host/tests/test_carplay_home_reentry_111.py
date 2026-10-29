"""CarPlay Home scene lifecycle regression. Hardware still unverified."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def source(p):return (ROOT/p).read_text(encoding="utf-8")
class HomeReentry111(unittest.TestCase):
 def test_no_second_startup_splash_until_physical_disconnect(self):
  probe=source("DFTouchOwnerProbe.m")
  chrome=source("DFNative12Chrome.m")
  for token in ("sShownFirstSplashForPhysicalConnection",
      "if(!connected && sShownFirstSplashForPhysicalConnection)",
      "[sChrome skipStartupSplashForHomeReentry];"):
   self.assertIn(token,probe)
  self.assertIn("if(!self.homeReentrySkipsSplash){",chrome)
  self.assertIn("home-reentry-no-startup-splash-restore-saved-scenes",chrome)
 def test_hide_before_pid_inspection_or_host_stop(self):
  probe=source("DFTouchOwnerProbe.m")
  chrome=source("DFNative12Chrome.m")
  stop=probe.split("static void DFStopProbe(NSString *reason) {",1)[1].split("static BOOL DFSessionStillActive",1)[0]
  self.assertLess(stop.index("[sChrome hideAllExternalWindowsImmediately];"),
                  stop.index("DFDockZoomDetach(sChrome,sSession);"))
  self.assertLess(stop.index("[sChrome hideAllExternalWindowsImmediately];"),
                  stop.index("[old disconnectTerminationCandidates]"))
  self.assertLess(stop.index("[sChrome hideAllExternalWindowsImmediately];"),stop.index("[old stop];"))
  method=chrome.split("- (void)hideAllExternalWindowsImmediately {",1)[1].split("- (BOOL)start {",1)[0]
  self.assertIn("for(UIWindow *w in self.windows)w.hidden=YES;",method)
 def test_replacement_intent_saved_before_scene_ready(self):
  chrome=source("DFNative12Chrome.m")
  selected=chrome.split("- (void)appPicker:(DFAppPickerVC *)picker\n didSelectBundleID:",1)[1].split("- (void)sceneReady:",1)[0]
  self.assertIn("DFSavePhysicalBundle(physicalSlot,bundleID)",selected)
  self.assertNotIn("if(![active isKindOfClass:UIView.class]){",selected)
  self.assertLess(selected.index("DFSavePhysicalBundle(physicalSlot,bundleID)"),selected.index("self.appPickerVisible=NO;",selected.index("UIView *container=")))
 def test_one_retry_for_real_failed_saved_app_and_no_fabricated_ready(self):
  chrome=source("DFNative12Chrome.m")
  for token in ("restoreRetryCounts","if(retries>=1)return NO;",
    "owner.restoreGeneration!=generation","1.2*NSEC_PER_SEC",
    "workspace-restore-requeued-after-host-failure",
    "workspace-restore-skipped-allowlist-or-install",
    "workspace-restore-timeout-skipped-no-fake-ready",
    "DFPickerAllowsApp(bundle,DFConfiguredEnabledAppIDs())"):
   self.assertIn(token,chrome)
  self.assertNotIn("setForeground:",chrome)
 def test_synchronous_scene_ready_advances_to_second_pane(self):
  # didMoveToWindow -> start -> pollScene can notify inline in addSubview.
  # An earlier implementation set restorePending only AFTER addSubview.
  chrome=source("DFNative12Chrome.m")
  host=source("DFSceneHost.m")
  self.assertIn("if (self.window && !self.started && !self.stopped) [self start];",host)
  self.assertIn("[self pollScene:self.timer];",host)
  self.assertIn("postNotificationName:DFSceneHostDidBecomeReadyNotification",host)
  restore=chrome.split("- (void)restoreNextSavedWorkspaceApp {",1)[1].split(
    "// Shift physical scene WINDOWS",1)[0]
  setup=restore.split("[container addSubview:surface];",1)[0]
  for token in ("self.restorePending=YES;",
                "self.restoringPhysical=physical;",
                "self.pendingScenes[(NSUInteger)physical]=surface;"):
   self.assertIn(token,setup)
  self.assertLess(setup.index("self.restorePending=YES;"),
                  setup.index("self.pendingScenes[(NSUInteger)physical]=surface;"))
  self.assertIn("[container addSubview:surface];",restore)
  ready=chrome.split("- (void)sceneReady:",1)[1].split("- (void)sceneFailed:",1)[0]
  self.assertIn("if(self.restorePending && self.restoringPhysical==i)",ready)
  self.assertIn("[self restoreNextSavedWorkspaceApp];",ready)
  # Reentrant callback model: a ready scene in first pane must release
  # the queue gate before the next physical slot is attached.
  waiting=[0,1]
  pending=False
  completed=[]
  while waiting:
   slot=waiting.pop(0)
   pending=True          # This MUST occur before a possible inline callback.
   callback_sees=pending
   self.assertTrue(callback_sees)
   completed.append(slot)
   pending=False         # sceneReady clears the in-flight request.
  self.assertEqual(completed,[0,1])
 def test_restore_reads_current_workspace_before_first_host(self):
  chrome=source("DFNative12Chrome.m")
  begin=chrome.split("- (void)beginSavedWorkspaceRestore {",1)[1].split(
      "- (BOOL)scheduleFailedRestoreRetryForPhysical:",1)[0]
  self.assertLess(begin.index("self.workspace=DFCurrentWorkspace();"),
                  begin.index("DFRestorablePhysicalBundles(self.workspace,"))
  self.assertIn("workspace-restore-snapshot",begin)
if __name__=="__main__":unittest.main(verbosity=2)
