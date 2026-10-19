#!/usr/bin/env python3
"""Contract tests for actual CarPlay DBDockWindow source and safe fail-closed layout.
Passing is NOT proof that iOS draws the native Dock; that needs a device run.
"""
import re
import unittest
from pathlib import Path
P=Path(__file__).resolve().parents[1]
def src(n):return (P/n).read_text(encoding="utf-8")
class NativeDockContract(unittest.TestCase):
    def test_real_dock_process_only_no_mock(self):
        plist=src("DFV1APreflight.plist")
        self.assertIn("<string>SpringBoard</string>",plist)
        self.assertIn("<string>CarPlay</string>",plist)
        entry=src("V1ATweak.x")
        self.assertIn("%group MTSpringBoardHook",entry)
        self.assertIn("%init(MTSpringBoardHook)",entry)
        self.assertNotIn("startForCarPlayProcess",entry)
        p=src("MTNativeDockProbe.m")
        for x in ('@"DBDockWindow"', '"CarPlay"', '"real-DBDockWindow"',
                  'MTOriginalDockLayout(window,cmd)','class_addMethod',
                  'isSubclassOfClass:UIWindow.class', 'MTDockEdge',
                  'native-window', 'native-layout'):
            self.assertIn(x,p)
        self.assertIn('NSProcessInfo.processInfo.processName',p)
        self.assertIn('if (!enabled) return;',p)
        self.assertIn('com.duoface.mytweak.v1bc.plist',p)
        for needle in ('dock-probe-state','prefsReadable','dock-window-inventory','dockClassWindows'):
            self.assertIn(needle,p)
        self.assertNotIn('NSClassFromString(@"CB',p)
        for x in ('addSubview:','insertSubview:','makeKeyAndVisible','setWindowLevel:'):
            self.assertNotIn(x,p)
    def test_native_geometry_without_guessing(self):
        l=src("MTDockLayout.m")
        for x in ('Producer','CarPlay','real-DBDockWindow',
                  'MTDockContentRect','age>9.0',
                  'full.size.width','full.size.height',
                  '@"left"', '@"right"', '@"top"', '@"bottom"'):
            self.assertIn(x,l)
        self.assertNotIn('64.0',l)
        self.assertNotIn('48.0',l)
        c=src("MTBridgeCoordinator.m")
        self.assertIn('refreshDashboardContentGeometry',c)
        self.assertIn('mtUnobstructedFrame',c)
        self.assertIn('MTNativeShellUsableRect(full,shell,&desired)',c)
        self.assertIn('native-shell-frame-rejected',c)
        self.assertIn('w.frame=desired',c)
        self.assertIn('if (!enabled || !present)',c)
        self.assertNotIn('MTDockContentRect(full,data,&desired)',c)
    def test_preserve_existing_host_modes(self):
        root=src("MTBridgeRootViewController.m")
        for x in ('@"App"','@"Split 2"','@"Swap"','@"Zoom"','@"Close"','mtWantsNativeDock'):
            self.assertIn(x,root)
        split=src("MTSplitContainerViewController.m")
        for x in ('singlePaneMode=YES','dividerPanned:','dividerHeld:',
                  'swapSlots','toggleFullscreenForSlot','mtFullscreen'):
            self.assertIn(x,split)
        self.assertIn('stopAllHosts',src("MTBridgeCoordinator.m"))
    def test_pkg_release_not_vendor_or_system_spoof(self):
        c=src("control")
        self.assertIn("Version: 0.2.5~shell1",c)
        self.assertIn("Package: com.duoface.mytweak.v1a.preflight",c)
        self.assertNotIn("Conflicts:",c)
        self.assertNotIn("Replaces:",c)
        mk=src("Makefile")
        self.assertNotIn("MTNativeDockProbe.m",mk)
        self.assertNotIn("MTDockLayout.m",mk)
        self.assertIn("THEOS_PACKAGE_SCHEME = rootless",mk)
        self.assertNotIn("Airaw.dylib",mk)
        self.assertNotIn("CarSurf.dylib",mk)
if __name__=="__main__":unittest.main(verbosity=2)
