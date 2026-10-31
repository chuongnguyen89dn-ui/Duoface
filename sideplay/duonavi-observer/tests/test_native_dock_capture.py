import importlib.util,json,unittest
from pathlib import Path
root=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('capture',root/'analyze_native_dock.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class EvidenceTests(unittest.TestCase):
 def test_old_or_missing_log_stays_unknown(self):
  for raw in ('', '{"event":"ui_state_sample"}', '=== header ===\n{invalid'):
   r=m.analyze(raw)
   self.assertFalse(r['metadata_observed'])
   self.assertEqual(set(r['missing_selectors']),m.REQUIRED)
   self.assertFalse(r['activation_safe_to_implement'])
 def test_conflicting_owners_remain_separate(self):
  rows=[{'event':'native_dock_class_abi','class':c,'process':'CarPlay','pid':1,
    'image':'/System/Library/x','declared_methods':[{'selector':'_refreshAppDock',
       'encoding':ty,'argument_count':2}]} for c,ty in [('DBA','v16@0:8'),('DBB','@16@0:8')]]
  r=m.analyze('\n'.join(map(json.dumps,rows)))
  self.assertEqual(len(r['declaring_owners']['_refreshAppDock']),2)
  self.assertFalse(r['runtime_receiver_identity_verified'])
 def test_even_all_metadata_never_proves_fix(self):
  row={'event':'native_dock_class_abi','class':'DBFixture','declared_methods':[
    {'selector':s,'encoding':'fixture','argument_count':2} for s in m.REQUIRED]}
  r=m.analyze(json.dumps(row))
  self.assertEqual(r['missing_selectors'],[])
  self.assertFalse(r['device_fix_verified'])
  self.assertFalse(r['activation_safe_to_implement'])
 def test_probe_is_bounded_and_cannot_invoke_private_api(self):
  s=(root/'NativeDockABI.h').read_text()
  for term in ['dnDockSamples>=24','nodes<64','class_copyMethodList','class_copyIvarList',
      'free(classes)','free(methods)','free(ivars)']:
   self.assertIn(term,s)
  for term in ['objc_msgSend','object_getIvar','valueForKey:', 'performSelector:',
      'MSHookMessageEx','class_replaceMethod','method_setImplementation','method_invoke',
      'method_getImplementation','%hook','setHidden:','setFrame:','makeKeyAndVisible']:
   self.assertNotIn(term,s)
if __name__=='__main__':unittest.main()
