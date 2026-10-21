from pathlib import Path
import re
import unittest
P=Path(__file__).resolve().parents[1]
def src(n):return (P/n).read_text(encoding='utf8')
class CombinedContract(unittest.TestCase):
    def test_v1bc_package(self):
        c=src('control')
        self.assertIn('Package: com.duoface.mytweak.v1a.preflight',c)
        self.assertIn('Version: 0.2.1~divider1',c)
        self.assertNotIn('Conflicts:',c)
        self.assertNotIn('Replaces:',c)
        m=re.search(r'^DFV1APreflight_FILES = (.*)$',src('Makefile'),re.M)
        self.assertIsNotNone(m)
        files=m.group(1).split()
        self.assertEqual(len(files),11)
        for name in files:self.assertTrue((P/name).is_file(),name)
        self.assertIn('MTSceneHost.m',files)
        self.assertIn('MTBridgeCoordinator.m',files)
    def test_filza_kill_switch(self):
        coord=src('MTBridgeCoordinator.m')
        for x in ('setTrialEnabled:NO','BOOL enabled=[[self class] trialEnabled]',
                  'if (!enabled || !present)','attemptedForThisConnection=YES',
                  'stopAndDisable','stopAllHosts','MTCarPlayDisplay',
                  'UIRootSceneWindow','FBSDisplayConfiguration'):
            self.assertIn(x,coord)
        self.assertNotIn('UIScreenDidConnectNotification',coord)
        self.assertIn('com.duoface.mytweak.v1bc.plist',src('MTTrialLog.m'))
        self.assertIn('[MTPreflight startReadOnlyDiagnostics]',src('V1ATweak.x'))
    def test_single_dual_ratio_swap_zoom(self):
        r=src('MTBridgeRootViewController.m')
        for x in ('@"App"', '@"Split 2"', '@"Swap"', '@"Zoom"', '@"Close"',
                  'stopAndDisable','launchAppWithBundleID'):
            self.assertIn(x,r)
        s=src('MTSplitContainerViewController.m')
        for x in ('singlePaneMode=YES','dividerPanned:','dividerHeld:','swapSlots',
                  'toggleFullscreenForSlot','0.25','0.75','previousLeft=self.leftSlot'):
            self.assertIn(x,s)
        t=src('MTAppSlotViewController.m')
        self.assertIn('doubleTap.cancelsTouchesInView=NO',t)
        self.assertIn('MTV1BCSlotClose',t)
    def test_remote_divider_in_native_content_coordinates(self):
        root=src("MTBridgeRootViewController.m")
        split=src("MTSplitContainerViewController.m")
        for key in ("remoteDividerPhase:","normalizedPoint:","convertPoint:rootPoint fromView:self.view",
                    "self.presentedViewController"):
            self.assertIn(key,root)
        for key in ("fabs(point.x-CGRectGetMidX(self.dividerView.frame))>24.0",
                    "_remoteDividerActive","_remoteDividerDragged",
                    "self.singlePaneMode || self.fullscreenSlot",
                    "[phase isEqualToString:@\"cancel\"]",
                    "self.leftRatio=_remoteDividerRatio",
                    "fmax(0.25,fmin(0.75",
                    "held>=0.30","[self swapSlots]"):
            self.assertIn(key,split)
        for bad in ("UITouch alloc", "GSEventCreate", "IOHIDEvent", "sendEvent:"):
            self.assertNotIn(bad,split)
    def test_host_logs_and_teardown(self):
        h=src('MTSceneHost.m')
        for x in ('SBAppViewController','SBDeviceApplicationSceneEntity',
                  'MTTrialLog(event','stopAllHosts','scene-ready','close-no-private-settings-restore'):
            self.assertIn(x,h)
        self.assertIn('MyTweakV1BC.log',src('MTTrialLog.m'))
        self.assertNotIn('NOT IMPLEMENTED',h)
if __name__=='__main__':unittest.main(verbosity=2)
