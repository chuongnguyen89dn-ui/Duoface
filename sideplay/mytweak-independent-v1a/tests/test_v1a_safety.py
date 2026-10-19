#!/usr/bin/env python3
"""v1a source contract, not an iPhone, Theos, or CarPlay test."""
from pathlib import Path
import unittest

P=Path(__file__).resolve().parents[1]

class V1ASafetyTest(unittest.TestCase):
    def test_diagnostic_is_default_and_never_launches(self):
        tweak=(P/"Tweak.x").read_text()
        self.assertIn("#define MT_V1A_PREFLIGHT_ONLY 1",tweak)
        self.assertIn("[MTPreflight startReadOnlyDiagnostics];",tweak)
        self.assertIn("#else\n        [[MTBridgeCoordinator sharedCoordinator] start];",tweak)
        pre=(P/"MTPreflight.m").read_text()
        for forbidden in ("setRequestedMode:", "addChildViewController:", "initWithDisplayConfiguration:", "window.rootViewController=", "makeKeyAndVisible", "loadApp:", "setWindowLevel:"):
            if forbidden == "setRequestedMode:":
                # Selector probe text is allowed, invocation is not.
                self.assertNotIn('MTV1ARead(controller,@"setRequestedMode:")',pre)
            elif forbidden == "initWithDisplayConfiguration:":
                self.assertNotIn('objc_msgSend)([rootWindow alloc]',pre)
            else:
                self.assertNotIn(forbidden,pre)
    def test_required_runtime_evidence(self):
        s=(P/"MTPreflight.m").read_text()
        for item in ("method_getTypeEncoding", "defaultEntityWithApplicationForMainDisplay:",
                     "screenIDs", "uniqueId", "UIApplication.sharedApplication.connectedScenes", "UIWindowScene.class",
                     "AppDock", "window.windowScene", "diagnostic-start",
                     "snapshot-end", "UIScreenDidDisconnectNotification"):
            self.assertIn(item,s)
        self.assertIn("MTPreflight.m",(P/"Makefile").read_text())
    def test_preserve_existing_recovery(self):
        self.assertTrue((P/"MTSceneHost.m").is_file())
        self.assertTrue((P/"MTBridgeCoordinator.m").is_file())
        self.assertIn("stopAllHosts",(P/"MTBridgeCoordinator.m").read_text())
        self.assertNotIn("com.sideplay",(P/"control").read_text())
if __name__=="__main__":unittest.main(verbosity=2)
