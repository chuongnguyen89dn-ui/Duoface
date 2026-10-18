#!/usr/bin/env python3
"""Static integrity checks only; not an iOS compilation or CarPlay run."""
from pathlib import Path
import re
import zipfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
class TestSceneHostContract(unittest.TestCase):
    def get(self,name):return (ROOT/name).read_text(encoding='utf-8')
    def test_original_project_files_preserved(self):
        make=self.get('Makefile')
        files=' '.join(line.strip().rstrip('\\') for line in make.splitlines() if line.startswith('MyTweak_FILES') or line.startswith('\t'))
        found=re.findall(r'\b[A-Za-z_]+\.(?:m|x)\b',files)
        self.assertEqual(len(found),10)
        for name in found:self.assertTrue((ROOT/name).is_file(),name)
    def test_no_stub_and_correct_springboard_classes(self):
        s=self.get('MTSceneHost.m')
        for sym in ('SBApplicationController','SBDeviceApplicationSceneEntity','SBAppViewController',
                    'initWithIdentifier:andApplicationSceneEntity:', 'setRequestedMode:',
                    'sceneHandle','sceneIfExists','updateSettings:withTransitionContext:completion:',
                    'invalidate','MTSceneHostDidFailNotification'):
            self.assertIn(sym,s)
        self.assertNotIn('NOT IMPLEMENTED',s)
        self.assertNotIn('code:1001',s)
        executable = '\n'.join(line for line in s.splitlines() if not line.lstrip().startswith('//'))
        for forbidden in ('CBBridgeManager','CBLicenseSyncManager','CBWindow','com.duonavi','DuoFaceDashboard'):
            self.assertNotIn(forbidden,executable)
    def test_single_owner_window_and_no_alert(self):
        s=self.get('MTBridgeCoordinator.m')
        self.assertIn('UIRootSceneWindow',s)
        self.assertIn('FBSDisplayConfiguration',s)
        self.assertIn('currentCarPlayExternalDevice',s)
        self.assertIn('screenIDs',s)
        self.assertIn('if (self.bridgeWindow) return;',s)
        self.assertIn('stopAllHosts',s)
        self.assertIn('#define MT_SHOW_LOAD_ALERT 0',self.get('Tweak.x'))
    def test_slot_cleanup_and_error_surface(self):
        s=self.get('MTAppSlotViewController.m')
        self.assertIn('releaseHostedView:sub',s)
        self.assertIn('sceneHostDidFail:',s)
        self.assertIn('MTSceneHostDidFailNotification',s)
    def test_rootless_injection(self):
        m=self.get('MyTweak.plist')
        self.assertIn('com.apple.springboard',m)
        self.assertIn('THEOS_PACKAGE_SCHEME = rootless',self.get('Makefile'))
    def test_no_vendor_libraries_in_project_code(self):
        joined='\n'.join(line for p in ROOT.glob('*.m') for line in p.read_text(encoding='utf8').splitlines() if not line.lstrip().startswith('//'))
        for bad in ('CBBridgeManager','CBLicenseSyncManager','CBBridgedSplitApp','com.duonavi','licenseWatchdog'):
            self.assertNotIn(bad,joined)
if __name__=='__main__': unittest.main(verbosity=2)
