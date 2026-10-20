import importlib.util
import pathlib
import unittest

PATH = pathlib.Path(__file__).resolve().parents[1] / "verify_admission_coverage.py"
spec=importlib.util.spec_from_file_location("df_coverage",PATH)
module=importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class TestAdmissionCoverage(unittest.TestCase):
    def test_source_invariants(self):
        result=module.audit()
        self.assertEqual(result["result"],"PASS_SOURCE_STATIC",result["static_checks"])
        self.assertTrue(all(result["static_checks"].values()))
        self.assertFalse(result["device_tested_by_this_script"])
        self.assertFalse(result["source_changed_by_this_script"])
        self.assertEqual(result["evidence"]["injection_executables"],["CarPlay"])
        self.assertFalse(result["evidence"]["host_has_apple_category_entitlement"])
    def test_observability_is_not_admission(self):
        result=module.audit()
        self.assertIn("real_DashBoard_filtered_roster_membership",result["runtime_unknown"])
        self.assertIn("original_typed3_return_type_and_value",result["runtime_unknown"])
        self.assertIn("whether_roster_filter_invoked_before_hook_installed",result["runtime_unknown"])
        self.assertTrue(result["evidence"]["hook_is_queued_on_main_from_constructor"])
        self.assertTrue(result["evidence"]["has_values_expected_number_check"])
    def test_no_publication_by_audit(self):
        s=PATH.read_text()
        for forbidden in ("subprocess.run(","requests.post(","os.system(","git push","make package","killall SpringBoard","launchctl kickstart"):
            self.assertNotIn(forbidden,s)

if __name__=="__main__": unittest.main(verbosity=2)
