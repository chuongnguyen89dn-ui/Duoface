import pathlib, unittest
ROOT = pathlib.Path(__file__).resolve().parents[1]
CHROME = (ROOT / "DFNative12Chrome.m").read_text()
TRACE = (ROOT / "DFDeepTrace.h").read_text()
CTRL = (ROOT / "control").read_text()
PKG = (ROOT.parent / "jb-embedded-appbridge" / "package_integrated.py").read_text()

class QA172Wakefix2(unittest.TestCase):
 def test_version_coherence(self):
  for text in (TRACE, CTRL, PKG):
   self.assertIn("wakefix2", text)
   self.assertNotIn("wakefix2map1", text)
  self.assertNotIn("wakefix1", TRACE)
  self.assertNotIn("wakefix1", PKG)
  self.assertIn("Version: 0.1.172~wakefix2", CTRL)

 def test_shield_window_gone(self):
  for token in ("DFNativeWakeShieldView","wakeShieldViews",
                "syncWakeShields","source=shield-touch"):
   self.assertNotIn(token, CHROME)

 def test_permanent_gate_present(self):
  for token in ("DFNativeWakeGateView","ensureWakeGates","wakeGateViews",
                "source=gate-touch"):
   self.assertIn(token, CHROME)

 def test_gate_hittest_contract(self):
  gate = CHROME.split("@implementation DFNativeWakeGateView")[1].split("@end")[0]
  self.assertIn("hitTest:", gate)
  self.assertIn("shouldConsume", gate)
  self.assertIn("return nil", gate)
  self.assertIn("touchesBegan", gate)

 def test_gate_respects_keyboard(self):
  self.assertIn("kbVisible177", CHROME)
  relay = (ROOT / "DFAppTouch177.h").read_text()
  self.assertIn("com.duoface.ipc.v177.kbstate", relay)

 def test_app_touch_stays_timers_only(self):
  body = CHROME.split("df177HandleAppTouch")[1].split("}")[0]
  self.assertNotIn("layoutControls", body)

if __name__ == "__main__":
 unittest.main()
