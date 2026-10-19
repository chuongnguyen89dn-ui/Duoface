#!/usr/bin/env python3
"""Branch-only source safety and protocol checks; NEVER device-level evidence."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
P = ROOT / "prototype"

def source(name):
    return (P / name).read_text(encoding="utf-8")

class NativeCarPlayPrototype(unittest.TestCase):
    def test_isolated_from_installed_v1bc(self):
        # Must not change the known-working package or inject into CarPlay.
        m = (ROOT/"Makefile").read_text()
        control = (ROOT/"control").read_text()
        filt = (ROOT/"DFV1APreflight.plist").read_text()
        self.assertIn("Version: 0.2.0~v1bc1", control)
        self.assertIn("INSTALL_TARGET_PROCESSES = SpringBoard", m)
        self.assertNotIn("MTCPBridge", m)
        self.assertNotIn("MTCPRemote", m)
        self.assertNotIn("CarPlayApp", filt)
        self.assertNotIn("MTCarPlayAdmission", (ROOT/"V1ATweak.x").read_text())

    def test_double_explicit_opt_in_and_no_boot_hook(self):
        body=source("MTCPBridgeContract.m")
        self.assertIn('com.duoface.mytweak.v1bc.plist', body)
        self.assertIn('com.duoface.mytweak.carplay-bridge.plist', body)
        self.assertIn('MTCPBoolFlag(kEngineConfig,@"Enabled") &&', body)
        self.assertIn('MTCPBoolFlag(kBridgeConfig,@"Enabled")', body)
        for fname in ["MTCPBridgeContract.m","MTCPRemoteLayer.m","MTCPCommandRelay.m"]:
            s=source(fname)
            for bad in ["%ctor","objc_addLoadImageFunc", "method_setImplementation",
                        "LSBundleProxy", "LSBundleInfoCachedValues", "DBDockWindow",
                        "MTCarPlayAdmission", "setEntitlements:"]:
                self.assertNotIn(bad,s, (fname,bad))

    def test_envelope_validation_and_replay(self):
        s=source("MTCPBridgeContract.m")
        for requirement in ['MTCPValidSession', 'initWithUUIDString', 'kMaxAge=2.0',
                            'age>=0', 'age<=kMaxAge', '"ContextID"',
                            'UINT32_MAX', '"Sequence"',
                            'lastSequence', 'MTCPValidSession(session)',
                            '"Timestamp"', '"pointer"', '"begin"',
                            '"move"', '"end"', '"cancel"', 'x+w<=1.0001',
                            'writeToFile:kSurface atomically:YES',
                            'writeToFile:kCommand atomically:YES',
                            'record[@"Session"] isEqualToString:session']:
            self.assertIn(requirement,s)
        for action in ['@"home"', '@"close"', '@"swap"', '@"split"', '@"zoom"']:
            self.assertIn(action,s)
        self.assertNotIn('bundleIdentifier',s)
        self.assertNotIn('requestStateChange:',s)

    def test_system_owned_host_contract(self):
        s=source("MTCPRemoteLayer.m")
        for requirement in ['remoteContextWithOptions:', 'CALayerHost', 'setContextId:',
                            'connectWithOwnedContentView:', 'owner.window.windowScene',
                            'duoface.native.content.host', 'owner.window.screen==UIScreen.mainScreen',
                            'UIEdgeInsetsInsetRect', 'MTCPBridgeReadSurface(nil)',
                            'MTCPBridgeExplicitOptIn()', 'removeFromSuperlayer',
                            'touchesBegan:', 'touchesMoved:', 'touchesEnded:',
                            'touchesCancelled:', 'notify_post']:
            self.assertIn(requirement,s)
        self.assertNotIn('UIRootSceneWindow',s)
        self.assertNotIn('FBSDisplayConfiguration',s)
        self.assertNotIn('initWithDisplayConfiguration:',s)
        self.assertNotIn('windowLevel',s)
        self.assertNotIn('CARCapableApp',s)
        self.assertNotIn('UIWindowSceneSessionRoleCarPlay',s)

    def test_opt_in_command_relay_no_synthetic_touch(self):
        s=source("MTCPCommandRelay.m")
        for requirement in ['notify_register_dispatch','notify_cancel',
                            'MTCPBridgeReadCommand(strongSelf.session,strongSelf.lastSequence)',
                            'MTCPBridgeExplicitOptIn()', 'dispatch_get_main_queue()']:
            self.assertIn(requirement,s)
        for bad in ['GSEvent', 'IOHIDEvent', 'privateTouch', 'SBApplicationController',
                    'SpringBoard _handle', 'objc_msgSend']:
            self.assertNotIn(bad,s)

    def test_safe_split_command_dispatch(self):
        s=source("MTCPHostCommandAdapter.m")
        for text in ['MTCPBridgeExplicitOptIn()', 'processName isEqualToString:@"SpringBoard"',
                     '[root swapApps]', '[root toggleSplit]', '[root toggleZoom]',
                     '[[MTBridgeCoordinator sharedCoordinator] stopAndDisable]',
                     'return NO;']:
            self.assertIn(text,s)
        for banned in ['setWindowLevel:', 'FBSDisplayConfiguration',
                       'initWithDisplayConfiguration:', 'LSBundleProxy', 'SBApplicationController',
                       'handleDockIconTap:', 'UIEvent', 'GSEvent']:
            self.assertNotIn(banned,s)

if __name__ == "__main__":
    unittest.main(verbosity=2)
