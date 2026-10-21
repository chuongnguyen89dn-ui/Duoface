from pathlib import Path
import plistlib,subprocess,sys,unittest
P=Path(__file__).resolve().parents[1]
ROOT=P.parent
def get(file):return (P/file).read_text()
class Gate1Safety(unittest.TestCase):
 def test_unique_isolated_dpkg(self):
  c=get("control")
  self.assertIn("Package: com.duoface.carplay.gate1smoke",c)
  self.assertIn("Version: 0.0.1~smoke1",c)
  self.assertIn("iphoneos-arm64",c)
  for x in ("Conflicts:","Replaces:","Breaks:","Provides:","com.duonavi","com.duoface.independent"):
   self.assertNotIn(x,c)
 def test_scene_is_properly_declared(self):
  p=plistlib.loads((P/"Info.plist").read_bytes())
  self.assertEqual(p["CFBundleIdentifier"],"com.duoface.gate1smoke")
  self.assertEqual(p["CFBundleExecutable"],"DuoFaceGate1")
  self.assertIn("UIWindowSceneSessionRoleCarPlay",p["UIApplicationSceneManifest"]["UISceneConfigurations"])
  for x in ("GATE1_CARPLAY_SCENE_CONNECTED","initWithWindowScene:ws","makeKeyAndVisible"):
   self.assertIn(x,get("Gate1App.m"))
  for forbidden in ("UIRootSceneWindow","FBSDisplayConfiguration","IOHIDEvent","GSEvent"):
   self.assertNotIn(forbidden,get("Gate1App.m"))
 def test_default_off_auto_expiry_and_kill_switch(self):
  app=get("Gate1App.m")
  for marker in ('@"ExpiresAt":@(expires)','10 phút','Disable();','com.duoface.gate1smoke.refresh',
                 '.duoface-gate1smoke-disable', 'com.duoface.gate1smoke',
                 'RiskAcknowledged','enable-refused'):
   self.assertIn(marker,app)
  for f in ("postinst","prerm","postrm"):
   script=get(f)
   for forbidden in ("killall","sbreload","ldrestart","launchctl","dpkg --remove","apt remove",
                     "rm -rf","com.duoface.independent"):
    self.assertNotIn(forbidden,script)
  self.assertIn(".duoface-gate1smoke-disable",get("postinst"))
  self.assertIn(".duoface-gate1smoke-disable",get("prerm"))
  self.assertIn("uicache",get("postinst"))
 def test_scope_generates_only_our_gate(self):
  subprocess.run([sys.executable,str(P/"prepare.py")],check=True)
  for f in ("Gate1CarPlay.m","Gate1SpringBoard.m"):
   src=(P/".generated"/f).read_text()
   for key in ("com.duoface.gate1smoke","ExpiresAt","now+900.0",
               "com.duoface.gate1smoke.refresh",".duoface-gate1smoke-disable"):
    self.assertIn(key,src)
   self.assertNotIn("com.duoface.native.scenehost",src)
   self.assertNotIn("com.duoface.firstparty-admission.refresh",src)
  self.assertIn("gate1-smoke-SpringBoard-loaded", (P/".generated"/"Gate1SpringBoard.m").read_text())
  p=plistlib.loads((P/"DFGate1SmokeAdmission.plist").read_bytes())
  self.assertEqual(p["Filter"]["Executables"],["SpringBoard","CarPlay"])
 def test_no_vendor_modules_or_duplicate_app(self):
  src=get("build.sh")
  self.assertIn('python3 prepare.py',src)
  self.assertIn('make clean package FINALPACKAGE=1',src)
  self.assertIn('DuoFaceGate1.app',src)
  self.assertIn('DFGate1SmokeAdmission.dylib',src)
  self.assertIn("test -s",src)
  for key in ("DuoDash","Duonavi","CBLicense","CarBridge.dylib"):
   self.assertNotIn(key,src)
if __name__=="__main__": unittest.main(verbosity=2)
