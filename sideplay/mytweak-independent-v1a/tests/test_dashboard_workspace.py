#!/usr/bin/env python3
"""Proves ownership-routing code exists; NOT proof of dock runtime or Home."""
from pathlib import Path
import unittest
P=Path(__file__).resolve().parents[1]
def source(name):return (P/name).read_text(encoding="utf8")
class WorkspaceOwnerContract(unittest.TestCase):
    def test_native_dashboard_instance_owner(self):
        c=source("MTDashboardWorkspace.m")
        for value in ("DBWorkspace","DBDashboardWorkspaceOwner","initWithOwner:",
                      "MTOriginalWorkspaceInit(self,_cmd,owner)","MTObserveWorkspace(result,owner)",
                      "gDashboardWorkspace", "objc_addLoadImageFunc",
                      "class_addMethod", "method_setImplementation","WorkspaceCaptured"):
            self.assertIn(value,c)
        self.assertIn('[owner isKindOfClass:cls]',c)
        self.assertIn("static __weak id gDashboardWorkspace",c)
        self.assertNotIn("requestStateChange:",c)
        self.assertNotIn("activateApplication:",c)
    def test_early_placement(self):
        e=source("V1ATweak.x")
        self.assertIn('[MTDashboardWorkspace installEarlyObserver]',e)
        self.assertIn('[MTDashboardContext startIfCarPlayUIProcess]',e)
        self.assertLess(e.index('[MTDashboardWorkspace installEarlyObserver]'),
                        e.index('[MTDashboardContext startIfCarPlayUIProcess]'))
    def test_snapshot_to_existing_log(self):
        c=source("MTDashboardContext.m")
        self.assertIn('[record addEntriesFromDictionary:[MTDashboardWorkspace snapshot]]',c)
        w=source("MTDashboardWorkspace.m")
        self.assertIn('WorkspaceOwnerClassPresent',w)
        self.assertIn('WorkspaceHasActiveApp',w)
        self.assertNotIn('data[@"ActiveBundleIdentifier"]',w)
    def test_no_fake_dock(self):
        mk=source("Makefile")
        self.assertIn("MTDashboardWorkspace.m",mk)
        self.assertNotIn("MTNativeDockProbe.m",mk)
        self.assertNotIn("MTDockLayout.m",mk)
        c=source("control")
        self.assertIn("0.2.5~shell1",c)
        self.assertIn("native Home request",c)
if __name__=="__main__":unittest.main(verbosity=2)
