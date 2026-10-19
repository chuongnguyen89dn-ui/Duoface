#!/usr/bin/env python3
"""Dashboard context contract tests: static checks, not an in-car Dock proof."""
from pathlib import Path
import re
import unittest
P=Path(__file__).resolve().parents[1]
def source(name):return (P/name).read_text(encoding="utf-8")
class DashboardContextContract(unittest.TestCase):
    def test_carplay_process_owner_and_launch(self):
        c=source("MTDashboardContext.m")
        for x in ("CarPlayApp","CarPlay","DBWorkspace","DBDashboardWorkspaceOwner",
                  "UIApplication.sharedApplication","connectedScenes","UIWindowScene",
                  "screen.bounds","safeAreaInsets","root-window","observer-start"):
            self.assertIn(x,c)
        entry=source("V1ATweak.x")
        self.assertIn("startIfCarPlayUIProcess",entry)
        self.assertIn("%group MTSpringBoardHook",entry)
        self.assertIn("%init(MTSpringBoardHook)",entry)
        plist=source("DFV1APreflight.plist")
        for app in ("SpringBoard","CarPlay","CarPlayApp"):
            self.assertIn("<string>"+app+"</string>",plist)
    def test_read_only_carplay_window_capture(self):
        c=source("MTDashboardContext.m")
        for bad in ("makeKeyAndVisible","setWindowLevel:","requestStateChange:",
                    "setHidden:", "applicationDidBecomeActive:", "CBBridgeManager",
                    "Airaw.dylib","SidePlay.dylib"):
            self.assertNotIn(bad,c)
        self.assertIn("UIEdgeInsetsInsetRect",c)
        self.assertIn("UIWindow *best=nil",c)
        self.assertIn("CGRectContainsRect",c)
        self.assertIn("HasNonzeroInsets",c)
        self.assertIn("UsableValid",c)
        self.assertIn("context-write-failed",c)
        self.assertNotIn("48.0",c)
        self.assertNotIn("64.0",c)
    def test_geometry_never_guesses_fallback(self):
        g=source("MTDashboardUsableRect.m")
        for x in ("CarPlayRootWindowSafeArea","HasNonzeroInsets",
                  "UsableValid", "age>5.0", "DisplayAspect",
                  "CGRectMake", "if (out)*out=usable"):
            self.assertIn(x,g)
        self.assertNotIn("DockWidth",g)
        self.assertNotIn("48.0",g)
        self.assertNotIn("64.0",g)
        b=source("MTBridgeCoordinator.m")
        self.assertIn("MTDashboardUsableRect(full,context,&desired)",b)
        self.assertIn("MTDashboardContextPath()",b)
        self.assertIn('@"dashboard-layout"',b)
        self.assertIn('@"dashboard-context-missing-preserve-existing"',b)
        self.assertIn('CGRect desired=full;',b)
        self.assertNotIn('MTDockContentRect(full,data,&desired)',b)
    def test_preserve_host_and_one_springboard_owner(self):
        c=source("MTBridgeCoordinator.m")
        self.assertIn("stopAllHosts",c)
        self.assertIn("UIRootSceneWindow",c)
        self.assertIn("if (self.bridgeWindow) return;",c)
        split=source("MTSplitContainerViewController.m")
        for x in ("singlePaneMode=YES","swapSlots","dividerPanned:","dividerHeld:",
                  "toggleFullscreenForSlot"):
            self.assertIn(x,split)
        self.assertIn("setTrialEnabled:NO",c)
    def test_distinct_sandbox_and_version(self):
        control=source("control")
        self.assertIn("Version: 0.2.3~workspace1",control)
        self.assertIn("Package: com.duoface.mytweak.v1a.preflight",control)
        for forbidden in ("Conflicts:","Replaces:","DuoNaviDashboard.dylib"):
            self.assertNotIn(forbidden,control)
        make=source("Makefile")
        self.assertIn("MTDashboardContext.m",make)
        self.assertIn("MTDashboardUsableRect.m",make)
        self.assertIn("MTDashboardWorkspace.m",make)
        self.assertIn("THEOS_PACKAGE_SCHEME = rootless",make)
        self.assertIn("ARCHS = arm64 arm64e",make)
        self.assertNotIn("Airaw.dylib",make)
if __name__=="__main__":unittest.main(verbosity=2)
