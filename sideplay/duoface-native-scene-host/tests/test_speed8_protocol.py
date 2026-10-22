"""Exercise the user's prior first-party Speed8 wire protocol exactly.
Static C++ numeric tests only; no SpringBoard, GPS, GMapHUD or speed display
runtime is simulated. Old CBWindow-bound renderer is NOT linked to new project.
Historical origin: project commit 1286a3ef868cf7e29804bcddf7e20b2eae707ce1.
"""
import pathlib, shutil, subprocess, tempfile, unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
class Speed8HistoricalFirstPartyProtocol(unittest.TestCase):
    def test_original_four_source_atomic_speed_limit_protocol(self):
        compiler=shutil.which("clang++") or shutil.which("c++")
        if not compiler:self.skipTest("A C++17 compiler is required")
        source=ROOT/"speed8/test_speed_protocol.cpp"
        self.assertTrue(source.is_file())
        self.assertIn("ChooseUnifiedSample",source.read_text())
        with tempfile.TemporaryDirectory() as td:
            exe=pathlib.Path(td)/"speed8-check"
            subprocess.run([compiler,"-std=c++17","-Wall","-Wextra","-Werror",
                            str(source),"-o",str(exe)],check=True)
            run=subprocess.run([str(exe)],check=True,capture_output=True,text=True)
        self.assertIn("DF_SPEED_PROTOCOL_UNIT_PASS",run.stdout)
    def test_data_adapter_is_not_a_vendor_HUD_binary_or_Sileo_claim(self):
        for name in ("DFSpeedProtocol.hpp","DFSpeedGMapWire.hpp"):
            content=(ROOT/"speed8"/name).read_text()
            self.assertNotIn("CBBridgeManager",content)
            self.assertNotIn("license",content.lower().split("not a copy")[0])
        package=(ROOT.parent/"jb-embedded-appbridge/package_integrated.py").read_text()
        self.assertIn('"native12_speed8_hud_independent_parity_proven":False',package)
        self.assertNotIn("DuoFaceSpeedHUD.dylib",package)
    def test_portable_speed8_view_preserves_own_original_visual_contract(self):
        view=(ROOT/"speed8/DFNative8SpeedHUDView.mm").read_text()
        header=(ROOT/"speed8/DFNative8SpeedHUDView.h").read_text()
        self.assertIn("CGSizeMake(104*self.visualScale,46*self.visualScale)",view)
        self.assertIn("const CGFloat sign=34*sc;",view)
        self.assertIn("minimumPressDuration=0.6",view)
        self.assertIn("for(NSInteger i=1;i<=8;i++)",view)
        self.assertIn("DFSpeedHUDReadBest(&sample)",view)
        self.assertIn('@"—"',view)  # unknown data, not fake speed
        self.assertIn("DFNative8SpeedHUDView",header)
        self.assertIn("ownerWindow",header)
        # This portable view never mounts itself; old CBWindow gate is gone.
        self.assertNotIn("sharedInstanceIfExists",view)
        self.assertNotIn("@interface CBWindow",view)
        self.assertNotIn("__attribute__((constructor))",view)
        self.assertNotIn("CBBridgedSplitApp",view)
        build=(ROOT/"build.sh").read_text()
        self.assertNotIn("speed8/DFNative8SpeedHUDView.mm",build) # owner not runtime-proven

if __name__=="__main__":unittest.main(verbosity=2)
