import pathlib, plistlib, unittest
P=pathlib.Path(__file__).resolve().parents[1]
def read(name):return (P/name).read_text()
class CandidateSafety(unittest.TestCase):
 def test_process_is_carplay_only(self):
  assert plistlib.loads((P/"DFFirstPartyAdmission.plist").read_bytes())["Filter"]["Executables"]==["CarPlay","SpringBoard"]
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
  self.assertIn("Version: 0.0.6~sbpair1",c)
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
  self.assertIn('sel_registerName("_newApplicationLibrary")',s)
  self.assertNotIn('objc_msgSend)(dash,library',s)
 def test_carplay_preflight_loaded_version_no_springboard_restart(self):
  s=read("DFFirstPartyAdmission.m")
  for must in ("DFTracePreflight","DFTraceSignal","DFTraceStatus",
      '"Version":@5','@"HooksReady":@(ready)','DFHooksInstalled&&DFOriginal3&&DFOriginal2',
      'method_getTypeEncoding(method)','DashBoardFactoryABI',
      'CFNotificationCenterAddObserver','DFCheckConsentAndArm(@"trace-preflight")'):
   self.assertIn(must,s)
  self.assertNotIn('hook(dash',s)
  self.assertNotIn('method_setImplementation',s)
  self.assertNotIn('requestStateChange',s)
 def test_roster_probe_is_readonly_one_shot(self):
  s=read("DFFirstPartyAdmission.m")
  for key in ('roster-readonly','DFRosterSignal','DFLastRosterRequestID',
              'appProxy=absent','CarPlayRole=%@','@24@0:8@16',
              '@32@0:8@16#24','writeToFile:DFRosterRequest atomically:YES',
              'DFExplicitConsent()','DFHostID','30','CFNotificationCenterAddObserver'):
   self.assertIn(key,s)
  for blocked in ('LSApplicationWorkspace','registerApplication','unregisterApplication',
     'activateApplication','requestStateChange',
     'FBSApplicationInfo','LSBundleInfoCachedValues','method_setImplementation'):
   self.assertNotIn(blocked,s)
 def test_firstparty_springboard_cached_value_path(self):
  s=read("DFFirstPartySpringBoard.m")
  for x in ('"@24@0:8@16"','"B24@0:8@16"','LSBundleInfoCachedValues',
      'weakToStrongObjectsMapTable','MSHookMessageEx','origBulk(proxy,cmd,keys)',
      'origBool(obj,cmd,key)','return real; // preserve private LS runtime class',
      'kKill','RiskAcknowledged','com.duoface.native.scenehost','SpringBoard',
      'CFNotificationCenterAddObserver','arm(); // early initial roster'):
   self.assertIn(x,s)
  self.assertIn('DFFirstPartySpringBoard.m',read("Makefile"))
  for x in ('method_setImplementation','DBWorkspace','killall','sbreload'):
   self.assertNotIn(x,s)
  self.assertIn('DFCheckConsentAndArm(@"constructor-early")',read("DFFirstPartyAdmission.m"))
if __name__=="__main__":unittest.main(verbosity=2)
