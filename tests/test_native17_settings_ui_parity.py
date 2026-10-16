#!/usr/bin/env python3
"""Read-only regression contracts for user-verified native12 core and native17 UI-only add-on."""
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "runtime/settings/DFSettingsUIRestore.mm"
PLIST = ROOT / "runtime/settings/DuoFaceSettingsUIRestore.plist"
BUILD = ROOT / "migration/full_payload/native_test/build_native17_settings_ui_parity.py"

class UIOnlyParityTests(unittest.TestCase):
    def test_bundle_only(self):
        import plistlib
        filt = plistlib.loads(PLIST.read_bytes())["Filter"]
        self.assertEqual(filt, {
            "Executables": ["DuoFaceUI"], "Bundles": ["com.duoface.duofaceui"]
        })

    def test_presentational_filter_not_license_engine(self):
        text = SOURCE.read_text()
        for term in ("DFIsObsoleteLicenseRow", "duoface pro",
                     "DFVisibleOriginalRows", "DFVisibleCount",
                     "DFVisibleCell", "DFVisibleSelect",
                     "CBGeneralSettingsViewController"):
            self.assertIn(term, text)
        for dangerous in ("CBLicenseSyncManager", "A_DuoFaceNativeNoLease",
                          "checkAndSyncLicenseIfNeeded", "isLicenseCurrentlyValid",
                          "presentLicenseWarningModalWithType",
                          "terminateApplicationWithBundleID",
                          "terminateAllBridgedApplications"):
            self.assertNotIn(dangerous, text)

    def test_fallback_and_swizzle_chain(self):
        source = SOURCE.read_text()
        self.assertIn("return indices ? (NSInteger)indices.count : original;", source)
        self.assertIn("if (!indices) return visible;", source)
        for selector in ("numberOfRowsInSection:",
                         "cellForRowAtIndexPath:",
                         "didSelectRowAtIndexPath:"):
            self.assertIn("tableView:" + selector, source)
        self.assertIn("method_getImplementation(rows)", source)
        self.assertIn("method_getImplementation(cells)", source)
        self.assertIn("method_getImplementation(select)", source)

    def test_locked_native16_baseline(self):
        text = BUILD.read_text()
        self.assertIn("5d5cbd368c24d0c074b081d16aaf7d006467c3e9cfef01ee12378ce79d716fae", text)
        self.assertIn("cb40346d8ca504cb399abe31367847b4f980a01ba93810986ce1acf1fbe9eef9", text)
        self.assertIn("9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea", text)
        self.assertIn("0986cf70b4c613ad011520204337e1e2b403d24111f39f14f70628fb57e61d50", text)
        self.assertIn("d0246415f4020f353e5ec7373d8d375cbbda868471fd1a467f8e57654c4d01ad", text)
        self.assertIn("assert all(after[k] == before[k] for k in before)", text)
        self.assertIn('"restored_license_methods_or_registration": False', text)
        self.assertIn('"original_nolease_library_reintroduced": False', text)

if __name__ == "__main__":
    unittest.main()
