import pathlib,unittest
ROOT=pathlib.Path(__file__).resolve().parents[3]
SRC=ROOT/"sideplay/jb-embedded-appbridge/package_integrated.py"
class EmbeddedPackagePolicy(unittest.TestCase):
 def test_only_owned_inputs(self):
  s=SRC.read_text()
  for x in ("com.duoface.mytweak.v1a.preflight","com.duoface.carplay.nativebridgeqa",
            "com.duoface.carplay.firstpartyadmission","com.duoface.carplay.nativescenehost",
            "no_such_test"):
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
 def test_merged_one_app_uicache_scripts(self):
  base=ROOT/"sideplay/jb-embedded-appbridge/scripts"
  src=SRC.read_text()
  for kind in ("postinst","postrm"):
   s=(base/kind).read_text()
   self.assertIn("DuoFaceNativeHost.app",s)
   self.assertNotIn("DuoFaceQA.app",s)
   self.assertIn("uicache",s)
   for forbidden in ("killall","sbreload","ldrestart","launchctl","rm -rf",
                     "uicache -a","apt install","dpkg --remove"):
    self.assertNotIn(forbidden,s)
  self.assertIn('for kind in ("postinst","postrm")',src)
  self.assertIn('"com.duoface.qa.controlapp"',src)
  self.assertIn('if observed!=expected_nativehost_sha256:',src)
  self.assertIn('Native Host artifact differs from SHA-verified current-source signed build:',src)
  self.assertIn('if actual_source_sha!=expected_source_sha:',src)
  self.assertIn('target.chmod(0o755)',src)
 def test_nativehost_version_matches_real_build_output(self):
  import re
  build=(ROOT/"sideplay/duoface-native-scene-host/build.sh").read_text()
  expected=re.search(r'OUT="\$ROOT/packages/(com\.duoface\.carplay\.nativescenehost_[^"]+\.deb)"',build)
  self.assertIsNotNone(expected,"NativeHost build script must declare a DEB output")
  self.assertIn(expected.group(1),SRC.read_text(),
                "Integrated package must consume exact NativeHost version produced by build.sh")

 def test_final_one_deb_does_not_archive_stale_native_host_47(self):
  src=SRC.read_text()
  # Test the actively built package against the .116 workflow; the archived
  # .113 workflow remains immutable rollback evidence, not the current pin.
  workflow=(ROOT/".github/workflows/duoface-116-pane-input-trace-signed-qa.yml").read_text()
  old_workflow=(ROOT/".github/workflows/duoface-113-reentry-queue-sileo-build.yml").read_text()
  self.assertNotIn("0.1.47~realdock1",src+workflow)
  self.assertNotIn("82b296d4076458ce7259c5987450a48d2ab2b37cf4857fdac8c0eb9d0d989941",src+workflow)
  self.assertIn("0.1.116~pane-trace1",src)
  self.assertIn('bash sideplay/duoface-native-scene-host/build.sh',workflow)
  self.assertIn('--expected-nativehost-sha256 "$NATIVEHOST_SHA"',workflow)
  self.assertIn('--expected-source-sha "$GITHUB_SHA"',workflow)
  self.assertIn('VERSION="0.0.116~pane-trace1"',src)
  self.assertIn('0.0.116~pane-trace1',workflow)
  self.assertIn('0.0.113~reentry-queue1',old_workflow)
  self.assertIn('SILEO_PUBLISHED=false',workflow)
 def test_original_immutable_speed8_reference_is_NOT_embedded_or_claimed_pass(self):
  src=SRC.read_text()
  self.assertIn('2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad',src)
  self.assertIn('"native12_speed8_hud_independent_parity_proven":False',src)
  self.assertNotIn("DuoFaceSpeedHUD.dylib",src)
  workflow=(ROOT/".github/workflows/duoface-jb-embedded-appbridge-package.yml").read_text()
  self.assertIn("workflow_dispatch:",workflow)
  self.assertIn("NATIVE12_SPEED8_HUD_PARITY_VERIFIED=false",workflow)
  self.assertIn("NO_DEVICE_PARITY",workflow)

if __name__=="__main__":unittest.main(verbosity=2)
