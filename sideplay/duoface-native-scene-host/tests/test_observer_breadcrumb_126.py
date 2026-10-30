"""QA126 observer-forward instrumentation: no lifecycle policy changes.
Only the exact pre-Apple-callback boundary is measured and fsync'd.
This is a source contract test, not proof the iPhone crash is fixed.
"""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "DFSceneLifecycle.m"

class ObserverBreadcrumb126(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SRC.read_text()
        cls.callback = cls.source.split("static void DFManagedSceneObserver(", 1)[1].split(
            "// UIKit/FrontBoard object provenance", 1)[0]

    def test_breadcrumb_occurs_immediately_before_apple_forward(self):
        s = self.callback
        self.assertIn("if(DFIsOwnedManualSceneObserver(controller,handle))", s)
        self.assertIn("DFObserverForwardBreadcrumb126(controller,handle);", s)
        self.assertIn("sPreviousSceneObserver(controller,selector,handle,diff,previousSettings);", s)
        self.assertEqual(s.count("sPreviousSceneObserver(controller,selector,handle,diff,previousSettings);"), 1)
        self.assertLess(s.index("DFObserverForwardBreadcrumb126(controller,handle);"),
                        s.index("sPreviousSceneObserver(controller,selector,handle,diff,previousSettings);"))
        self.assertLess(s.index("owned-manual-observer-consumed"),
                        s.index("DFObserverForwardBreadcrumb126(controller,handle);"))

    def test_preserves_original_update_policy_and_scoping(self):
        s = self.source
        for invariant in ("DFOwnsScene(scene) && DFForeground(settings)==0",
                          "sUpdate(scene,selector,forwarded,context,completion);",
                          "DFIsOwnedHostedLockScene123(scene)",
                          "sOriginalBackgroundUnderLock(manager,cmd,scene,settings);",
                          "DFSceneLifecycleUnregister(self.appController)"):
            if invariant == "DFSceneLifecycleUnregister(self.appController)":
                # Called by DFSceneHost.m, not in this translation unit.
                self.assertIn(invariant, (ROOT / "DFSceneHost.m").read_text())
            else:
                self.assertIn(invariant, s)

    def test_bounded_fsync_no_global_swallow(self):
        s = self.source.split("static void DFObserverForwardBreadcrumb126(", 1)[1].split(
            "static void DFManagedSceneObserver(", 1)[0]
        for field in ("count=%u", "ownerKnown=%d", "handleMatch=%d",
                      "sceneMatch=%d", "manual=%d", "hosting=%d"):
            self.assertIn(field, s)
        self.assertIn("records>=96", s)
        self.assertIn("DuoFaceDeepTrace.log", s)
        self.assertIn("fsync(fd)", s)
        self.assertIn("O_WRONLY|O_CREAT|O_APPEND", s)
        for forbidden in ("sPreviousSceneObserver(", "sUpdate(", "setForeground:",
                          "setBackgrounded:", "setUnderLock:", "setUILocked:", "notify_post("):
            self.assertNotIn(forbidden, s)
        self.assertIn("} @catch(NSException *ignored) { (void)ignored; }", s)

if __name__ == "__main__":
    unittest.main()
