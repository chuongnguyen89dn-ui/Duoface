#!/usr/bin/env python3
"""Read-only CarPlay owner probe packaging and safety (source-only, not device proof)."""
from pathlib import Path
import plistlib
import re
import unittest

ROOT=Path(__file__).resolve().parents[1]
def read(name):return (ROOT/name).read_text(encoding="utf-8")

class OwnerProbeSafety(unittest.TestCase):
    def test_package_separate_and_boot_safe(self):
        c=read("control")
        self.assertIn("Package: com.duoface.carplay.ownerprobe",c)
        self.assertIn("Version: 0.0.1~ownerprobe1",c)
        for bad in ("Conflicts:", "Replaces:", "Breaks:", "com.duonavi.app", "Airaw.dylib"):
            self.assertNotIn(bad,c)
        m=read("Makefile")
        self.assertIn("rootless",m)
        self.assertIn("arm64 arm64e",m)
        self.assertIn("DFNativeDockOwnerProbe_FILES = Tweak.x",m)
        self.assertNotIn("SpringBoard",m)
    def test_carplay_only_filter(self):
        d=plistlib.loads((ROOT/"DFNativeDockOwnerProbe.plist").read_bytes())
        executable=d["Filter"]["Executables"]
        self.assertEqual(executable,["CarPlay","CarPlayApp"])
        self.assertNotIn("SpringBoard",executable)
    def test_runtime_readonly(self):
        c=read("Tweak.x")
        for term in ("processName", "CarPlayApp", "connectedScenes", "UIWindowScene",
                    "safeAreaInsets", "rootViewController", "DBWorkspace",
                    "DBDockWindow", "CAContext", "CALayerHost", "NSTimer",
                    "DFProbeCount>=40", "nativeDockVisible=UNVERIFIED",
                    "CarPlay/CarPlayApp"):
            self.assertIn(term,c)
        self.assertEqual(len(re.findall(r'%ctor',c)),1)
        self.assertNotIn("%hook",c)
        for banned in ("method_setImplementation", "class_replaceMethod", "objc_addLoadImageFunc",
                       "MTCarPlayAdmission", "UIRootSceneWindow", "initWithDisplayConfiguration:",
                       "SBApplicationController", "setFrame:", "setWindowLevel:",
                       "setHidden:", "LSBundleProxy", "killall", "respring"):
            self.assertNotIn(banned,c)
    def test_only_observation_and_bounded_lifecycle(self):
        c=read("Tweak.x")
        self.assertIn("dispatch_after",c)
        self.assertIn("(8*NSEC_PER_SEC)",c)
        self.assertIn("repeats:YES",c)
        self.assertIn("DFProbeFinished",c)
        self.assertIn("[timer invalidate]",c)
        self.assertIn("DuoFaceNativeDockOwnerProbe.log",c)

if __name__=="__main__":
    unittest.main(verbosity=2)
