#!/usr/bin/env python3
"""Regression: Native12-discovered iOS16 destroy scene, independent safe adapter."""
import json
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[3]
SRC=ROOT/"sideplay/duoface-native-scene-host"
BODY=(SRC/"DFSceneLifecycle.m").read_text()
ORIGINAL=json.loads((ROOT/"sideplay/audit/lock-native-duonavi-fullscan-20261030"/
                      "NATIVE12_11_HOOKS_LOCK_ARM64.json").read_text())

class DestroyContract(unittest.TestCase):
    def test_exact_original_registration(self):
        h=ORIGINAL["hooks"]["manual_scene_destroy"]
        self.assertEqual(h["start"],"0x2c8ef8")
        self.assertEqual(ORIGINAL["exact_registered_hook_count"],11)

    def test_existing_selector_exact_runtime_abi_only(self):
        part=BODY.split("static void DFInstallSceneDestroyObserver(",1)[1].split(
            "// UIKit/FrontBoard object provenance",1)[0]
        self.assertIn('@"sceneHandle:didDestroyScene:"',part)
        self.assertIn("method_getNumberOfArguments(m)!=4",part)
        self.assertIn('strcmp(type,"v")',part)
        self.assertIn("if(type[0]!='@')return",part)
        self.assertIn("method_getImplementation(m)",part)
        self.assertIn("sPreviousSceneDestroy!=NULL",part)

    def test_tombstone_current_owned_only_and_apple_original(self):
        part=BODY.split("static void DFManagedSceneDestroy(",1)[1].split(
            "static void DFInstallSceneDestroyObserver",1)[0]
        for expected in ("[sOwners objectForKey:controller]",
                         "current==handle && owned && owned()==scene",
                         "[sDestroyedOwnedScenes addObject:scene]",
                         "sPreviousSceneDestroy(controller,selector,handle,scene);"):
            self.assertIn(expected,part)
        self.assertLess(part.index("[sDestroyedOwnedScenes addObject:scene]"),
                        part.index("sPreviousSceneDestroy(controller,selector,handle,scene);"))
        self.assertNotIn("terminate",part)
        self.assertNotIn("invalidate",part)
        self.assertNotIn("setForeground:",part)

    def test_both_foreground_and_lock_guard_reject_destroyed_identity(self):
        self.assertIn("[sDestroyedOwnedScenes containsObject:scene])return NO;",BODY)
        self.assertIn("[sDestroyedOwnedScenes containsObject:scene] ||",BODY)
        self.assertIn("DFInstallSceneDestroyObserver(host,hook);",BODY)
        self.assertIn("if(!DFIsOwnedHostedLockScene123(scene))",BODY)

    def test_owner_revoke_and_unregistration_still_present(self):
        self.assertIn("void DFSceneLifecycleUnregister(id controller)",BODY)
        self.assertIn("sPreviousSceneObserver(controller,selector,handle,diff,previousSettings);",BODY)
        self.assertIn("sOriginalPostLockIntercept(manager,cmd,scene,settings);",BODY)
        for unsafe in ("BKSDisplayServicesSetScreenBlanked",
                       "systemService:isPasscodeLockedOrBlockedWithResult:",
                       "setScreenBlankEnabled:"):
            self.assertNotIn(unsafe,BODY)

if __name__=="__main__":
    unittest.main()
