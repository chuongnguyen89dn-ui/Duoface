#!/usr/bin/env python3
"""Emergency recovery integrity checks. Build evidence is not proof of device safety."""
from pathlib import Path
import unittest
P=Path(__file__).resolve().parents[1]
def src(f): return (P/f).read_text(encoding='utf8')
class EmergencyRecovery(unittest.TestCase):
    def test_compiled_sources_are_original_device_tested_v1bc(self):
        m=src('Makefile')
        self.assertIn('INSTALL_TARGET_PROCESSES = SpringBoard',m)
        self.assertNotIn('CarPlayApp',m)
        self.assertNotIn('SUBPROJECTS',m)
        self.assertNotIn('MTCarPlayAdmission',m)
        self.assertNotIn('MTDashboardActivation',m)
        self.assertNotIn('MTDashboardWorkspace',m)
        self.assertNotIn('shell/',m)
        self.assertIn('MTSceneHost.m',m)
        self.assertIn('MTBridgeRootViewController.m',m)
    def test_no_prelaunch_launchservices_hooks(self):
        e=src('V1ATweak.x')
        for forbidden in ('MTCarPlayAdmission','objc_addLoadImageFunc',
                          'LSBundleProxy','LSBundleInfoCachedValues',
                          'DBWorkspace','requestStateChange:',
                          'MTDashboardActivation'):
            self.assertNotIn(forbidden,e)
        self.assertIn('applicationDidFinishLaunching:',e)
        self.assertIn('[MTBridgeCoordinator sharedCoordinator] start',e)
        pl=src('DFV1APreflight.plist')
        self.assertIn('com.apple.springboard',pl)
        self.assertNotIn('CarPlayApp',pl)
    def test_rollback_upgrade_without_vendor_payload(self):
        c=src('control')
        self.assertIn('Package: com.duoface.mytweak.v1a.preflight',c)
        self.assertIn('Version: 0.2.6~recovery1',c)
        for term in ('Conflicts:','Replaces:','com.duonavi','com.sensetechlab'):
            self.assertNotIn(term,c)
    def test_filza_opt_in_and_preserve_split(self):
        c=src('MTBridgeCoordinator.m')
        self.assertIn('BOOL enabled=[[self class] trialEnabled]',c)
        self.assertIn('if (!enabled || !present)',c)
        self.assertIn('stopAllHosts',c)
        s=src('MTSplitContainerViewController.m')
        for term in ('dividerPanned:','dividerHeld:','swapSlots','toggleFullscreenForSlot'):
            self.assertIn(term,s)
if __name__=='__main__':unittest.main(verbosity=2)
