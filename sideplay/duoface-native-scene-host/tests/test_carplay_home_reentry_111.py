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
if __name__=="__main__":unittest.main(verbosity=2)
