import pathlib, plistlib, unittest
P=pathlib.Path(__file__).resolve().parents[1]
def read(name):return (P/name).read_text()
class CandidateSafety(unittest.TestCase):
 def test_process_is_carplay_only(self):
  assert plistlib.loads((P/"DFFirstPartyAdmission.plist").read_bytes())["Filter"]["Executables"]==["CarPlay"]
  self.assertIn('processName isEqualToString:@"CarPlay"',read("DFFirstPartyAdmission.m"))
  self.assertIn("SpringBoard must NEVER load",read("DFFirstPartyAdmission.m"))
 def test_exact_abi_and_narrow_bundle(self):
  s=read("DFFirstPartyAdmission.m")
  for required in ('@40@0:8@16#24#32','@32@0:8@16#24','com.duoface.native.scenehost',
        'if(real)return real','DFOriginal3(proxy,sel,key,expected,valueClass)',
        'DFOriginal2(proxy,sel,key,expected)','NSNumber.class','DFExplicitConsent()',
        'DFDisable','RiskAcknowledged','if(os.majorVersion!=16','method_getTypeEncoding',
        'MSHookMessageEx','bundleIdentifier','SBStarkCapable','CARCapableApp'):
   self.assertIn(required,s)
  for forbidden in ('LSBundleInfoCachedValues','FBSApplicationInfo','CARApplicationController',
       'DBWorkspace','launchctl','killall','sbreload','postinst','windowLevel',
       'com.apple.developer.carplay-maps','com.apple.developer.carplay-audio',
       'method_setImplementation','SBStarkLaunchModes'):
   self.assertNotIn(forbidden,s)
 def test_package_isolated(self):
  c=read("control")
  self.assertIn("Package: com.duoface.carplay.firstpartyadmission",c)
  for term in ("Conflicts:","Replaces:","Breaks:"):self.assertNotIn(term,c)
  self.assertFalse((P/"postinst").exists())
  self.assertFalse((P/"prerm").exists())
  self.assertIn("INSTALL_TARGET_PROCESSES =",read("Makefile"))
if __name__=="__main__":unittest.main(verbosity=2)
