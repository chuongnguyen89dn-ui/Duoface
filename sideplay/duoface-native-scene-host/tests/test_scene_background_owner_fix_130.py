#!/usr/bin/env python3
"""QA130 source contract: do not rewrite Apple's background after owner loss.

This DOES NOT test physical CarPlay/YouTube touches. It checks that the
native-lease guard really executes ahead of FBScene foreground mutation and
that foreign or stale scenes retain the Apple original call contract.
"""
import pathlib
import unittest

BASE=pathlib.Path(__file__).resolve().parents[1]
LIFECYCLE=(BASE/"DFSceneLifecycle.m").read_text()
LEASE=(BASE/"DFCarPlayOwnerLease.h").read_text()
HOST=(BASE/"DFNativeHostAppDelegate.m").read_text()

class ForegroundVetoContract(unittest.TestCase):
    def test_mutation_only_inside_live_owned_gate(self):
        fn=LIFECYCLE.split("static void DFUpdateScene(",1)[1].split(
            "// Native12 original 0x2c8ca8",1)[0]
        gate="if(!DFIsOwnedHostedLockScene123(scene))"
        self.assertIn("DFOwnsScene(scene) && DFForeground(settings)==0",fn)
        self.assertIn(gate,fn)
        self.assertLess(fn.index(gate),fn.index("[settings mutableCopy]"))
        self.assertLess(fn.index("sUpdate(scene,selector,settings,context,completion)"),
                        fn.index("[settings mutableCopy]"))
        self.assertIn("return;",fn[fn.index(gate):fn.index("[settings mutableCopy]")])
        self.assertIn("sUpdate(scene,selector,forwarded,context,completion);",fn)
        self.assertNotIn("setDeactivationReasons:",fn)

    def test_same_identity_owner_and_attested_real_screen(self):
        fn=LIFECYCLE.split("static BOOL DFIsOwnedHostedLockScene123(id scene) {",1)[1].split(
            "static BOOL DFUnderLockBackground123",1)[0]
        for s in ("DFSessionOwnsLiveCarPlay123()",
                  "DFIsOwnedManualSceneObserver(controller,handle)",
                  'NSSelectorFromString(@"isHostingAnApp")',
                  "window.screen==UIScreen.mainScreen",
                  "current()!=scene"):
            self.assertIn(s,fn)

    def test_app_lease_home_revocation_not_removed(self):
        self.assertIn("DFOwnerRevokeMatches(revoke,session)",LEASE)
        self.assertIn("DFOwnerEvidenceMatches(owner,session,pulse",LEASE)
        self.assertIn("DFOwnerAcceptRecords",LEASE)
        self.assertIn('stopTouchOwnerWithReason:@"native-home-button"',HOST)
        self.assertIn('stopTouchOwnerWithReason:@"scene-disconnected"',HOST)

    def test_original_abi_and_observer_still_forward(self):
        self.assertIn("DFObjectUpdateABI(method)",LIFECYCLE)
        self.assertIn("DFObjectUpdateABI(observerMethod)",LIFECYCLE)
        self.assertIn("sPreviousSceneObserver(controller,selector,handle,diff,previousSettings);",LIFECYCLE)
        self.assertIn("sOriginalBackgroundUnderLock(manager,cmd,scene,settings)",LIFECYCLE)
        self.assertIn("sOriginalPostLockIntercept(manager,cmd,scene,settings);",LIFECYCLE)

    def test_no_screen_dim_or_bypass_added(self):
        for disallowed in ("BKSDisplayServicesSetScreenBlanked",
                           "SBBacklightController",
                           "setScreenBlankEnabled:",
                           "systemService:isPasscodeLockedOrBlockedWithResult:"):
            self.assertNotIn(disallowed,LIFECYCLE)

if __name__=="__main__":
    unittest.main()
