import importlib.util
from pathlib import Path
import unittest
path=Path(__file__).resolve().parents[1]/"analyze_consolidated_trace.py"
spec=importlib.util.spec_from_file_location("dftrace",path)
m=importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
RID="d0869294-1e21-443e-8bd4-e27e5d8fad58"
class TestBoundedAnalysis(unittest.TestCase):
 def test_empty_is_unknown(self):
  result=m.analyze("","",RID)
  self.assertEqual(result["status"],"INSUFFICIENT_FRESH_EVIDENCE")
  self.assertEqual(result["hypotheses"]["H3_library_built_before_hook"],"INDETERMINATE_no_library_creation_timestamp")
 def test_old_armed_log_is_not_a_sample(self):
  result=m.analyze("[DFAdmission/CarPlay] opt-in two typed getters armed via startup","",RID)
  self.assertEqual(result["sample_count"],0)
 def test_reports_possible_value_class_mismatch_without_claiming_fix(self):
  trace=f"[DFTrace] run={RID} hook-ready\n[DFTrace] run={RID} sample=1/16 selector=typed3 key=CARCapableApp expected=NSNumber valuesExpected=NSDictionary originalClass=nil auditOnly=true"
  sb=f"[DuoFaceSBAdmission] result state=complete request={RID} target-found process=SpringBoard"
  result=m.analyze(trace,sb,RID)
  self.assertEqual(result["status"],"NO_PHYSICAL_ICON_UNRESOLVED")
  self.assertEqual(result["springboard_proxy"],"present")
  self.assertEqual(result["hypotheses"]["H2_class_guards"],"POSSIBLE_values_class_mismatch")
 def test_scene_needs_explicit_observation(self):
  result=m.analyze("","",RID,True,"[DuoFaceNativeHost] native-carplay-scene-connected")
  self.assertEqual(result["status"],"ICON_AND_NATIVE_SCENE_OBSERVED")
if __name__=="__main__":unittest.main(verbosity=2)
