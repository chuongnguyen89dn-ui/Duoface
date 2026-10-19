#!/usr/bin/env python3
"""V1A DEB contract is deliberately more restrictive than v1a source trial."""
from pathlib import Path
import unittest
import re
ROOT=Path(__file__).resolve().parents[1]
class PackageIsolation(unittest.TestCase):
    def test_unique_package(self):
        c=(ROOT/'control').read_text()
        self.assertIn('Package: com.duoface.mytweak.v1a.preflight',c)
        self.assertIn('Version: 0.2.1~dock1',c)
        self.assertIn('Architecture: iphoneos-arm64',c)
        self.assertNotIn('com.sideplay',c)
        self.assertNotIn('Conflicts:',c)
    def test_compiled_binary_contains_only_preflight(self):
        mk=(ROOT/'Makefile').read_text()
        m=re.search(r'^DFV1APreflight_FILES = (.+)$',mk,re.MULTILINE)
        self.assertIsNotNone(m)
        self.assertEqual(m.group(1).split(),['V1ATweak.x','MTPreflight.m','MTTrialLog.m','MTBridgeCoordinator.m','MTBridgeRootViewController.m','MTSplitContainerViewController.m','MTAppSlotViewController.m','MTAppPickerViewController.m','MTAppLibrary.m','MTAppLauncher.m','MTSceneHost.m','MTDockLayout.m','MTNativeDockProbe.m'])
        self.assertIn('THEOS_PACKAGE_SCHEME = rootless',mk)
        self.assertIn('INSTALL_TARGET_PROCESSES = SpringBoard CarPlay',mk)
        self.assertIn('arm64 arm64e',mk)
        entry=(ROOT/'V1ATweak.x').read_text()
        self.assertIn('[MTPreflight startReadOnlyDiagnostics]',entry)
        for bad in ('initWithDisplayConfiguration:',
                    'setRequestedMode:', 'makeKeyAndVisible','loadApp:','CBBridgeManager'):
            self.assertNotIn(bad,entry)
        self.assertIn('<string>SpringBoard</string>',(ROOT/'DFV1APreflight.plist').read_text())
        self.assertIn('<string>CarPlay</string>',(ROOT/'DFV1APreflight.plist').read_text())
    def test_preserve_host_source_for_later(self):
        for name in ('MTSceneHost.m','MTBridgeCoordinator.m','Tweak.x'):
            self.assertTrue((ROOT/name).exists())
if __name__=='__main__':unittest.main(verbosity=2)
