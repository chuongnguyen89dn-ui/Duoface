"""QA148 static ABI/ownership safeguards, not proof of iOS16 runtime support."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOLO = (ROOT / "DFHomeStandalone144.m").read_text()
DOCK = (ROOT / "DFNativeDockSync147.h").read_text()
HOST = (ROOT / "DFSceneHost.m").read_bytes()


class ProcessPIDAndNativeStopGuard(unittest.TestCase):
    def test_pid_must_belong_to_exact_live_host_and_bundle(self):
        body = SOLO.split("- (NSNumber *)verifiedProcessStatePIDForView:",1)[1].split("- (void)reply:",1)[0]
        self.assertIn("isLiveSceneForHostedView:view",body)
        self.assertIn("bundleIDForHostedView:view",body)
        self.assertIn("SBApplicationController",body)
        self.assertIn("applicationWithBundleIdentifier:",body)
        self.assertIn('strcmp(method_getTypeEncoding(appLookup),"@24@0:8@16")',body)
        self.assertIn("bundleIdentifier",body)
        self.assertIn("processState",body)
        self.assertIn('sel_registerName("pid")',body)
        self.assertIn("method_getReturnType(m,ret,sizeof(ret))",body)
        self.assertIn("candidate<=1 || candidate>INT_MAX || candidate==getpid()",body)
        self.assertIn("kill((pid_t)candidate,0)",body)
        self.assertIn("errno!=EPERM",body)
        self.assertIn("@catch(NSException *e)",body)
        self.assertNotIn("arc4random",body)
    def test_observation_pid_cannot_be_silently_dropped_from_result(self):
        self.assertIn("reason:(NSString *)reason verifiedPID:(NSNumber *)verifiedPID",SOLO)
        self.assertIn("NSNumber *pid=verifiedPID?:",SOLO)
        self.assertIn("if(!pid)pid=[self verifiedProcessStatePIDForView:v];",SOLO)
        self.assertIn('reason:[NSString stringWithFormat:@"verifiedPID=%@",pid] verifiedPID:pid',SOLO)
        self.assertIn("if(!pid ||",DOCK) if "if(!pid ||" in DOCK else self.assertIn("terminal,pid",DOCK)
        self.assertIn("DF147ResultAction(&DF147Life,identity,fresh,hosted,terminal,pid)",DOCK)
    def test_nonhome_reasons_never_reuse_true_home_stop(self):
        for name in ("DF148WatchdogStopNotify","DF148NativeSwitchStopNotify","DF148OwnerRevokeStopNotify"):
            self.assertIn(name,SOLO)
            self.assertIn("notify_post("+name+")",DOCK)
        self.assertIn('[DF144Owner stop:@"native-Home-exit"]',SOLO)
        self.assertIn('[DF144Owner stop:@"native-pending-watchdog-expiry"]',SOLO)
        self.assertIn('[DF144Owner stop:@"native-app-switch"]',SOLO)
        self.assertIn('[DF144Owner stop:@"native-owner-or-consent-revoked"]',SOLO)
        self.assertEqual(DOCK.count("notify_post(DF144StopNotify)"),0)
    def test_frozen_scene_host_and_app_specific_filters_preserved(self):
        import hashlib
        digest=hashlib.sha1(b"blob "+str(len(HOST)).encode()+b"\\0"+HOST).hexdigest()
        self.assertEqual(digest,"ec2924c145be4edaaa27b7320bb869b18de12c6b")
        self.assertIn("DFGofaMapResize141.m",(ROOT/"build.sh").read_text())
        self.assertIn("DFYouTubeOrientationRelay.m",(ROOT/"build.sh").read_text())


if __name__=="__main__":
    unittest.main()
