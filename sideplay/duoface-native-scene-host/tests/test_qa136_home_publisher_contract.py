"""QA136 source gates: physically working GOFA/Dock/lock untouched, new opt-in."""
from pathlib import Path
import plistlib
import unittest
ROOT=Path(__file__).resolve().parents[1]
class QA136HomeContract(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.phone=(ROOT/'DFNativeHostRootController.m').read_text()
  cls.build=(ROOT/'build.sh').read_text()
  cls.entry=(ROOT/'DFHomePublisher136Entry.m').read_text()
  cls.core=(ROOT/'DFHomePublisher136Core.m').read_text()
  cls.pref=(ROOT/'DFHomePublisher136Config.h').read_text()
 def test_explicit_phone_switch_default_off(self):
  for x in ('DFHome136Enabled()', 'DFHome136Write(control.on)', 'home136SwitchChanged:',
            'Hiện app trên CarPlay Home'):
   self.assertIn(x,self.phone)
  for x in ('@"Version":@1','@"Enabled":@(enabled)','DFHome136Changed',
            '.duoface-home136-disable'):
   self.assertIn(x,self.pref)
  self.assertIn('return NO;',self.pref)
 def test_proven_native_fbs_abi_and_no_registration_without_real_library(self):
  for x in ('DFHome136ReconcileVerifiedLibrary(id library)',
            'FBSApplicationLibrary','addApplicationProxy:withOverrideURL:',
            'v32@0:8@16@24','applicationInfoForBundleIdentifier:',
            '_notifyDidAddApplications:','DFHomeBridgeBundleIDs(installed,selected,nativeIDs.array)'):
   self.assertIn(x,self.core)
  for x in ('!DFHome136Enabled()', 'isKindOfClass:libraryClass', 'hasPrefix:@"com.apple."'):
   self.assertIn(x,self.core)
  self.assertNotIn('[[libraryClass alloc]',self.core)
 def test_source_and_original_behaviour_separated(self):
  for key in ('DFCarPlayDockOwner.m','DFCarPlayHomeABIProbe.m',
              'DFHomePublisher136Core.m','DFHomePublisher136Entry.m'):
   self.assertIn(key,self.build)
  self.assertIn('0.1.136~nativehome1',self.build)
  self.assertIn('DuoFaceHomePublisher136.log',
                (ROOT/'DFNativeDiagnostics.m').read_text())
  info=plistlib.loads((ROOT/'Info.plist').read_bytes())
  self.assertEqual(info['CFBundleVersion'],'136')
  self.assertEqual(info['CFBundleShortVersionString'],'0.1.136')
  for forbidden in ('MSHookMessageEx','method_setImplementation','setIconState:forVehicleID:',
                    'killall','respring','BKSDisplayServicesSetScreenBlanked'):
   self.assertNotIn(forbidden,self.entry+self.core)
 def test_system_lookup_only_real_ui_owner(self):
  self.assertIn('window.rootViewController',self.entry)
  self.assertIn('DFHome136ReconcileVerifiedLibrary(lib)',self.entry)
  self.assertIn('native-FBS-library-instance-not-exposed',self.entry)
  self.assertIn('DFHome136Enabled()',self.entry)
if __name__=='__main__':unittest.main()
