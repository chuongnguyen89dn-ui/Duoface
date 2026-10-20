import pathlib,unittest
ROOT=pathlib.Path(__file__).resolve().parents[3]
SRC=ROOT/"sideplay/jb-embedded-appbridge/package_integrated.py"
class EmbeddedPackagePolicy(unittest.TestCase):
 def test_only_owned_inputs(self):
  s=SRC.read_text()
  for x in ("com.duoface.mytweak.v1a.preflight","com.duoface.carplay.nativebridgeqa",
            "com.duoface.carplay.firstpartyadmission","com.duoface.carplay.nativescenehost",
            "com.duoface.qa.controlapp","no_such_test"):
   if x=="no_such_test":continue
   self.assertIn(x,s)
  self.assertIn('"Depends: firmware (>= 16.0), mobilesubstrate"',s)
  self.assertIn('separate_carbridge_dependency":False',s)
  self.assertIn('contains_third_party_carbridge":False',s)
  self.assertIn('device_carplay_icon_tested":False',s)
 def test_will_not_redistribute_vendor_and_does_not_auto_restart(self):
  s=SRC.read_text()
  self.assertIn('if any(x in package for x in EXCLUDED)',s)
  self.assertIn('if str(rel) in seen:raise RuntimeError',s)
  self.assertIn('if not str(rel).startswith("var/jb/")',s)
  for command in ("killall SpringBoard","sbreload","ldrestart","launchctl kickstart",
                  "import DuoNaviDashboard","copy sideplay-reference.deb"):
   self.assertNotIn(command,s)
 def test_does_not_publish_or_claim_carplay_success(self):
  s=SRC.read_text()
  self.assertIn('sileo_published":False',s)
  self.assertIn('real_two_app_scene_tested":False',s)
  self.assertIn('native_content_receiver_compiled":True',s)
  self.assertIn('native_content_receiver_device_verified":False',s)
  self.assertIn('requires_replacing_old_qa_packages":True',s)
  self.assertIn('"uicache_registration_scripts_included":True',s)
  self.assertIn('"auto_respring_on_install":False',s)
 def test_merged_two_app_uicache_scripts(self):
  base=ROOT/"sideplay/jb-embedded-appbridge/scripts"
  src=SRC.read_text()
  for kind in ("postinst","postrm"):
   s=(base/kind).read_text()
   self.assertIn("DuoFaceNativeHost.app",s)
   self.assertIn("DuoFaceQA.app",s)
   self.assertIn("uicache",s)
   for forbidden in ("killall","sbreload","ldrestart","launchctl","rm -rf",
                     "uicache -a","apt install","dpkg --remove"):
    self.assertNotIn(forbidden,s)
  self.assertIn('for kind in ("postinst","postrm")',src)
  self.assertIn('target.chmod(0o755)',src)
 def test_nativehost_version_matches_real_build_output(self):
  import re
  build=(ROOT/"sideplay/duoface-native-scene-host/build.sh").read_text()
  expected=re.search(r'OUT="\\$ROOT/packages/(com\\.duoface\\.carplay\\.nativescenehost_[^"]+\\.deb)"',build)
  self.assertIsNotNone(expected,"NativeHost build script must declare a DEB output")
  self.assertIn(expected.group(1),SRC.read_text(),
                "Integrated package must consume exact NativeHost version produced by build.sh")
if __name__=="__main__":unittest.main(verbosity=2)
