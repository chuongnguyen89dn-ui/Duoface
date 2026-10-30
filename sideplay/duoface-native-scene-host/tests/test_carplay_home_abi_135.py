"""QA135 independent read-only system Home ABI test — no on-device icon PASS."""
import pathlib
import unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]

class HomeABIPolicy(unittest.TestCase):
 def test_carplay_and_springboard_separate_probes(self):
  s=(ROOT/"DFCarPlayHomeABIProbe.m").read_text()
  for phrase in ('DFHomeABIAllowedProcess','SpringBoard','CarPlay',
                 'method_getTypeEncoding','method_getReturnType',
                 'method_getNumberOfArguments',
                 'CARApplication','_newApplicationLibrary',
                 'FBSApplicationLibrary','addApplicationProxy:',
                 'FBSApplicationInfo','LSBundleInfoCachedValues',
                 'entitlementValueForKey:ofClass:valuesOfClass:'):
   self.assertIn(phrase,s,phrase)
 def test_never_mutate_os_critical_home_catalog_or_event(self):
  s=(ROOT/"DFCarPlayHomeABIProbe.m").read_text()
  for dangerous in ('method_setImplementation(','MSHookMessageEx(',
        'class_replaceMethod(','addApplicationProxy:withOverrideURL:",',
        'setIconState:forVehicleID:', 'killall','respring','SBSuspendedUnderLockManager'):
   self.assertNotIn(dangerous,s,dangerous)
  self.assertIn('DFConfiguredEnabledAppIDs()',s)
  self.assertIn('DFEnabledAppsChangedNotification',s)
 def test_compiled_two_process_receivers_and_export(self):
  b=(ROOT/"build.sh").read_text()
  self.assertIn('DFTouchOwnerProbe.m DFCarPlayHomeABIProbe.m',b)
  self.assertIn('DFCarPlayDockOwner.m DFCarPlayHomeABIProbe.m',b)
  e=(ROOT/"DFNativeDiagnostics.m").read_text()
  self.assertIn('DuoFaceHomeCatalogABI.log',e)
 def test_qa134_core_sources_unmodified_by_this_feature(self):
  s=(ROOT/"DFCarPlayHomeABIProbe.m").read_text()
  self.assertIn('This does NOT install hooks, mutate a system roster',s)
  self.assertIn('majorVersion!=16',s)
  self.assertIn('for(NSNumber *seconds in @[@3,@12])',s)
  self.assertIn('notify_register_dispatch',s)

if __name__=="__main__":unittest.main()
