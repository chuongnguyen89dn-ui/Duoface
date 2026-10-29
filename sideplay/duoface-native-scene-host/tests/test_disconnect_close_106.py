"""Source contracts for original DuoDash 12s-like independent 10s safety pipeline.
CarPlay hardware and private RunningBoard termination need separate QA evidence."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def f(name):return (ROOT/name).read_text()
class Disconnect106(unittest.TestCase):
 def test_policy_default_off_and_user_approved_ten_seconds(self):
  src=f("DFDisconnectClosePolicy.h")
  self.assertIn("DFDisconnectCloseGrace=10.0",src)
  self.assertIn("CFBooleanGetTypeID()",src)
  self.assertIn("DFDisconnectCloseSetEnabled(BOOL on)",src)
  self.assertIn("expectedGeneration==currentGeneration",src)
  self.assertIn("disconnected && enabled",src)
  self.assertNotIn("12.0",src)
 def test_real_physical_disconnect_is_not_carplay_home(self):
  p=f("DFTouchOwnerProbe.m")
  self.assertIn("DFConnectedCarDisplay()!=nil",p)
  self.assertIn("UIScreenDidDisconnectNotification",p)
  self.assertIn("CarPlayIsConnectedDidChange",p)
  self.assertIn("DFDisconnectClosePhysicalObserved",p)
  self.assertIn("DFDisconnectCloseNewActiveSession",p)
  self.assertIn("DFDisconnectCloseCapture",p)
  self.assertIn("[old disconnectTerminationCandidates]",p)
  self.assertIn("previousSession",p)
  self.assertIn("DFEnsureDisconnectMonitor()",p)
  self.assertNotIn("DFDisconnectCloseCapture([self stored",p)
 def test_scope_newly_owned_verified_live_process_only(self):
  scene=f("DFSceneHost.m")
  chrome=f("DFNative12Chrome.m")
  self.assertIn("processDidNotExistBeforeHost",scene)
  self.assertIn("preexistingProcess",scene)
  self.assertIn("kill(before,0)",scene)
  self.assertIn("wasProcessAbsentBeforeHostedView",scene)
  self.assertIn("[host isLiveSceneForHostedView:surface]",chrome)
  self.assertIn("[host wasProcessAbsentBeforeHostedView:surface]",chrome)
  self.assertIn("[host verifiedPIDForHostedView:surface]",chrome)
  self.assertIn('@"BundleID":bundle,@"PID":pid',chrome)
 def test_abort_reconnect_disable_stale_pid_and_foreground(self):
  src=f("DFDisconnectCloseCoordinator.m")
  for token in ("DFDisconnectCloseGrace*NSEC_PER_SEC",
   "DFDisconnectCloseMayExecute", "DFDisconnectCloseEnabled()",
   "gProbe && !gProbe()", "DFDiscVerifiedCurrentPID",
   "DFDiscPhoneForegroundIsSafeForClose",
   "DFDiscCancel", "gGeneration",
   "RBSProcessPredicate","RBSTerminateRequest",
   "terminate-requested", "verified-process-exited",
   "skipped-foreground-unverified","skipped-pid-changed",
   "gCandidates=nil;gSession=nil"):
    self.assertIn(token,src)
  self.assertNotIn("kill(pid,SIGTERM)",src)
  self.assertNotIn("killall",src)
  self.assertNotIn("terminateAllBridgedApplications",src)
 def test_iphone_switch_and_deb_packaged(self):
  phone=f("DFNativeHostRootController.m")
  for token in ("Đóng app khi ngắt CarPlay","DFDisconnectCloseSetEnabled",
                "10 giây", "UIAlertController", "disconnectCloseSwitchChanged:"):
    self.assertIn(token,phone)
  build=f("build.sh")
  self.assertIn("DFDisconnectCloseCoordinator.m",build)
  self.assertIn("0.1.108~ratio-disconnect-restore1",build)
  self.assertIn("0.1.108~ratio-disconnect-restore1",f("control"))
 def test_manual_diagnostics_records_disconnect_actual_pid_outcome(self):
  source=f("DFNativeDiagnostics.m")
  self.assertIn("DuoFaceDisconnectClose.log",source)
  self.assertIn("disconnect-close.ack.v1.plist",source)
  self.assertIn('closeState[@"VerifiedExited"]',source)
 def test_worker_revalidates_new_session_before_termination(self):
  source=f("DFDisconnectCloseCoordinator.m")
  for marker in ("dispatch_sync(dispatch_get_main_queue()", "stillEligible=(generation==gGeneration",
                 "[DFDiscVerifiedCurrentPID(ownedBundle) isEqual:before]",
                 "DFDiscPhoneForegroundIsSafeForClose(ownedBundle)",
                 "worker-stale-reconnected-or-pid-changed",
                 "worker-response-ignored-after-reconnect",
                 "termination-workers-dispatched-not-yet-confirmed"):
   self.assertIn(marker,source)
 def test_legacy_chrome_video_and_logo_unchanged(self):
  chrome=f("DFNative12Chrome.m")
  self.assertIn("- (void)logoTouchChanged:",chrome)
  self.assertIn("DFYT",f("DFSceneHost.m"))
  self.assertIn("stopAllHosts",chrome)
if __name__=="__main__":unittest.main(verbosity=2)
