import pathlib, plistlib, unittest
P=pathlib.Path(__file__).resolve().parents[1]
def read(n):return (P/n).read_text()
class SBProbeSafety(unittest.TestCase):
 def test_exact_filter_and_independent_package(self):
  x=plistlib.loads((P/"DFReadOnlySBAdmissionProbe.plist").read_bytes())
  self.assertEqual(x["Filter"]["Executables"],["SpringBoard"])
  c=read("control")
  self.assertIn("Package: com.duoface.carplay.sbadmissionprobe",c)
  self.assertIn("0.0.1~readonly1",c)
  for forbidden in ("Conflicts:","Replaces:","Breaks:"):self.assertNotIn(forbidden,c)
  self.assertFalse((P/"postinst").exists())
  self.assertFalse((P/"prerm").exists())
 def test_no_private_methods_called_or_any_hooks(self):
  m=read("DFSpringBoardAdmissionProbe.m")
  for item in ("method_getTypeEncoding","NSClassFromString", "CFNotificationCenterAddObserver",
               "CFNotificationCenterGetDarwinNotifyCenter", "DFRunOnce", "age>30", 'off[@"Enabled"]=@NO',
               "com.duoface.nativejoin.sborder.probe","LSBundleInfoCachedValues",
               "objectForInfoDictionaryKey:ofClass:"):
   self.assertIn(item,m)
  for bad in ("%hook","MSHookMessageEx","method_setImplementation","method_exchangeImplementations",
              "objc_msgSend","objc_addLoadImageFunc","_dyld_register_func_for_add_image",
              "windowLevel", "UIRootSceneWindow","SBAppViewController","sbreload",
              "entitlementValueForKey3(", "applicationProxyForIdentifier:)",
              "launchctl","killall","CARApplicationController"):
   self.assertNotIn(bad,m)
  self.assertNotIn('initWithDisplayConfiguration:',m)
  self.assertIn('processName isEqualToString:@"SpringBoard"',m)
  self.assertIn("if(os.majorVersion!=16)",m)
 def test_one_shot_arming_and_output(self):
  m=read("DFSpringBoardAdmissionProbe.m")
  self.assertLess(m.index('off[@"Enabled"]=@NO'),m.index("DFReadOnlyInventory(rid);"))
  self.assertIn("if(![off writeToFile:DFRequestPath atomically:YES])",m)
  self.assertIn("DuoFaceSBAdmissionProbe.log",m)
  self.assertIn("springboard-admission-readonly",m)
  self.assertIn("RequestID",m)
 def test_theos_rootless_safe(self):
  s=read("Makefile")
  self.assertIn("ARCHS = arm64 arm64e",s)
  self.assertIn("THEOS_PACKAGE_SCHEME = rootless",s)
  self.assertIn("DFSpringBoardAdmissionProbe.m",s)
  self.assertIn("INSTALL_TARGET_PROCESSES =",s)
if __name__=="__main__":unittest.main(verbosity=2)
