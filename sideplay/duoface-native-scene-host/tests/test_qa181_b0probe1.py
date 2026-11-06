"""QA181 B0 instrumentation contract. Static checks; physical Q1-Q3 remain unverified."""
import pathlib
import re
import subprocess
import unittest

ROOT=pathlib.Path(__file__).resolve().parents[1]
REPO=ROOT.parents[1]
BASE="aa7f009b26f18c2e711de06693fb14760c8f8883"
def read(name):
    return (ROOT/name).read_text()

class QA181B0Probe(unittest.TestCase):
    def test_bounded_marker_and_filter(self):
        s=read("DF181B0Probe.h")
        for marker in ("qa181-b0", "DFDeepTrace", "com.google.Maps", "com.waze.iphone",
                       "native-carplay", "1.5", "last.count>96", "path=%@ bundle=%@ event=%@ sceneID=%@ owner=%@ size=%@"):
            self.assertIn(marker,s)
        self.assertNotIn("setForeground:",s)
        self.assertNotIn("BKSDisplayServicesSetScreenBlanked(",s)

    def test_both_paths_scene_identity(self):
        for file in ("DFSceneHost.m", "DFNative12Chrome.m"):
            self.assertIn("DF181B0Record",read(file))
        self.assertIn('@"picker-selection"',read("DFNative12Chrome.m"))
        for event in ("activate-request","poll-scene-present","poll-scene-absent","deactivate-request"):
            self.assertIn(event,read("DFSceneHost.m"))
        stock=(REPO/"sideplay/native-carplay-scene-v1/DFCarPlayLiveOwnerSnapshot.m").read_text()
        for key in ("DBApplicationSceneViewController","hostedSceneIdentifier",
                    "hostedBundleIdentifier", "nativeSceneProcessBundleIdentifier",
                    "native-controller-not-observed", 'DF181B0Record(@"stock"'):
            self.assertIn(key,stock)
        dock=read("DFCarPlayDockOwner.m")
        self.assertIn("DFIntegratedCarPlayCaptureLiveOwnerSnapshot",dock)
        self.assertIn("1.5*NSEC_PER_SEC",dock)

    def test_Q3_original_branches_untouched(self):
        self.assertIn('@"underlock-observed"',read("DFSceneLifecycle.m"))
        self.assertIn('@"bks-blank-observed"',read("DFTouchOwnerProbe.m"))
        changes=subprocess.check_output(
            ["git","diff","--name-only",BASE,"HEAD"],cwd=REPO,text=True).splitlines()
        frozen=("DFAppTouch177.h","DFH1Wake188.m")
        self.assertFalse([p for p in changes if p.endswith(frozen)])

    def test_changed_files_scoped(self):
        changed=set(subprocess.check_output(
            ["git","diff","--name-only",BASE,"HEAD"],cwd=REPO,text=True).splitlines())
        allowed={
          ".github/workflows/duoface-181-b0probe1-signed.yml",
          "sideplay/duoface-native-scene-host/DF181B0Probe.h",
          "sideplay/duoface-native-scene-host/DFCarPlayDockOwner.m",
          "sideplay/duoface-native-scene-host/DFDeepTrace.h",
          "sideplay/duoface-native-scene-host/DFNative12Chrome.m",
          "sideplay/duoface-native-scene-host/DFSceneHost.m",
          "sideplay/duoface-native-scene-host/DFSceneLifecycle.m",
          "sideplay/duoface-native-scene-host/DFTouchOwnerProbe.m",
          "sideplay/duoface-native-scene-host/Info.plist",
          "sideplay/duoface-native-scene-host/build.sh",
          "sideplay/duoface-native-scene-host/control",
          "sideplay/duoface-native-scene-host/tests/test_qa179_h1wake2.py",
          "sideplay/duoface-native-scene-host/tests/test_qa180_h1wake3.py",
          "sideplay/duoface-native-scene-host/tests/test_qa188_h1wake1.py",
          "sideplay/duoface-native-scene-host/tests/test_qa181_b0probe1.py",
          "sideplay/jb-embedded-appbridge/package_integrated.py",
          "sideplay/jb-embedded-appbridge/tests/test_integrated_package_144.py",
          "sideplay/native-carplay-scene-v1/DFCarPlayLiveOwnerSnapshot.m",
          "sideplay/tiep tuc du an.md"
        }
        self.assertEqual(changed-allowed,set())
        for protected in ("DFAppTouch177.h","DFH1Wake188.m"):
            self.assertNotIn(protected," ".join(changed))

    def test_version_181(self):
        self.assertIn('VERSION="0.0.181~b0probe1"',(REPO/"sideplay/jb-embedded-appbridge/package_integrated.py").read_text())
        self.assertIn("0.1.181~b0probe1",read("control"))
        self.assertIn("<key>CFBundleVersion</key><string>181</string>",read("Info.plist"))

if __name__=="__main__":
    unittest.main()
