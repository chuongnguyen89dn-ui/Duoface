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
        'MSHookMessageEx','CFNotificationCenterAddObserver','DFRefreshSignal',
        'dispatch_get_main_queue','DFCheckConsentAndArm(@"qa-notify")','DFExplicitConsent()',
        'DFHooksInstalled','bundleIdentifier','SBStarkCapable','CARCapableApp'):
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
  self.assertIn("Version: 0.0.4~trace1",c)
  self.assertIn("if(!DFOriginal3)return nil;",read("DFFirstPartyAdmission.m"))
  self.assertIn("if(!DFOriginal2)return nil;",read("DFFirstPartyAdmission.m"))
 def test_diagnostic_pass_through_and_bounded(self):
  s=read("DFFirstPartyAdmission.m")
  for value in ('DFTraceObserve(proxy,key,expected,valueClass,real,@"typed3"))return real;',
                'DFTraceObserve(proxy,key,expected,Nil,real,@"typed2"))return real;',
                'DFTraceOwnBundle(proxy)','DFTraceActiveRequest()',
                'if(!DFExplicitConsent() || access(DFDisable,F_OK)==0',
                'age<=180','DFTraceSamples>=16','log-cap-reached',
                'originalClass=%@','valuesExpected=%@','auditOnly=true',
                'DuoFaceAdmissionTrace.log','DFTraceDisable'):
   self.assertIn(value,s)
  self.assertEqual(s.count('hook(c,s3,'),1)
  self.assertEqual(s.count('hook(c,s2,'),1)
  self.assertNotIn('hook(cached',s)
 def test_roster_probe_is_readonly_one_shot(self):
  s=read("DFFirstPartyAdmission.m")
  for key in ('roster-readonly','DFRosterSignal','DFLastRosterRequestID',
              'appProxy=absent','CarPlayRole=%@','@24@0:8@16',
              '@32@0:8@16#24','writeToFile:DFRosterRequest atomically:YES',
              'DFExplicitConsent()','DFHostID','30','CFNotificationCenterAddObserver'):
   self.assertIn(key,s)
  for blocked in ('LSApplicationWorkspace','registerApplication','unregisterApplication',
     'activateApplication','_newApplicationLibrary','requestStateChange',
     'FBSApplicationInfo','LSBundleInfoCachedValues','method_setImplementation'):
   self.assertNotIn(blocked,s)
if __name__=="__main__":unittest.main(verbosity=2)
