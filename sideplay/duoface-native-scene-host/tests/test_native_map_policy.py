"""Native map regressions: executable clock policy + exact host/owner contracts.

The Foundation lease/catalogue harnesses execute on macOS CI; these portable
checks do not prove live iOS scene adoption, map pixels or navigation keepalive.
"""
from pathlib import Path
import hashlib
import shutil
import subprocess
import tempfile
import unittest

from native_map_host_guard import LEASE_GUARD, LEASE_IMPORT, without_native_map_guard

ROOT = Path(__file__).resolve().parents[1]
MAP = ROOT.parent / "native-carplay-scene-v1"
FROZEN_HOST = "6a3c073f9d7502d588eb441d4ecb6c546c3f09f8"


def blob_hash(content):
    return hashlib.sha1(b"blob " + str(len(content)).encode() + b"\0" + content).hexdigest()


class NativeMapPolicy(unittest.TestCase):
    def test_actual_freshness_policy_executes(self):
        compiler = shutil.which("cc") or shutil.which("clang")
        self.assertIsNotNone(compiler, "A C compiler is required for the production policy test")
        with tempfile.TemporaryDirectory(prefix="df-native-map-") as temp:
            binary = str(Path(temp) / "native_map_freshness")
            subprocess.run([compiler, "-std=c11", "-Wall", "-Wextra", "-Werror",
                            str(ROOT / "tests/native_map_freshness_runtime.c"),
                            "-lm", "-o", binary], check=True)
            result = subprocess.run([binary], text=True, capture_output=True, check=True)
            self.assertIn("PASS_NATIVE_MAP_FRESHNESS", result.stdout)

    def test_only_exact_lease_guard_is_excluded_from_old_host_fingerprint(self):
        current = (ROOT / "DFSceneHost.m").read_bytes()
        self.assertEqual(blob_hash(without_native_map_guard(current)), FROZEN_HOST)
        # A geometry edit must still invalidate every old frozen-host gate.
        changed = current.replace(b"geometryWait=quickSoloInitialGeometry?0.12:0.30",
                                  b"geometryWait=quickSoloInitialGeometry?0.01:0.30", 1)
        self.assertNotEqual(changed, current)
        self.assertNotEqual(blob_hash(without_native_map_guard(changed)), FROZEN_HOST)
        for altered in (
            current.replace(LEASE_GUARD, b"", 1),
            current.replace(LEASE_IMPORT, b"", 1),
            current + LEASE_GUARD,
            current.replace(LEASE_GUARD, b"", 1) + LEASE_GUARD,
            current.replace(b"DFNativeMapOwnsBundleNow(bundleID)", b"YES", 1),
        ):
            with self.assertRaises(AssertionError):
                without_native_map_guard(altered)

    def test_explicit_bundle_is_bound_before_adoption_and_reconnect(self):
        source = (MAP / "DFNativeMapPaneCoordinator.m").read_text()
        self.assertIn('NSString *requestedBundle=cmd[@"BundleID"]', source)
        self.assertIn("DFMapUniqueOwnerForBundle(owners,requestedBundle)", source)
        self.assertIn("self.boundBundle=[requestedBundle copy]", source)
        self.assertIn("DFNativeMapSaveChoiceForBundle(self.slot,bundle)", source)
        self.assertIn("NSString *bundle=DFNativeMapChoiceBundle(saved)", source)
        self.assertIn("DFMapUniqueOwnerForBundle(owners,bundle)", source)
        self.assertIn('@"MapSlot":@(slot),@"BundleID":bundle', source)
        phone = (ROOT / "DFNativeHostRootController.m").read_text()
        self.assertIn('record[@"BundleID"]=bundle', phone)
        self.assertIn('nativeMapPaneCommand:@"Attach" slot:slot bundle:bundle', phone)
        self.assertNotIn("DFNativeMapSaveChoice", phone)

    def test_rebound_scene_or_stale_geometry_cannot_renew_a_lease(self):
        source = (MAP / "DFNativeMapPaneCoordinator.m").read_text()
        refresh = source.split("- (void)refreshAdoptedNativeMapBounds {", 1)[1].split(
            "- (void)tick:", 1)[0]
        self.assertLess(refresh.index("self.geometryVerified=NO;"),
                        refresh.index("DFPhysicalMapVerifyPane("))
        self.assertIn("[self.adapter hasVerifiedNativeOwner]", refresh)
        self.assertIn("[DFMapVerifiedBundle(self.owner) isEqual:self.boundBundle]", refresh)
        tick = source.split("- (void)tick:", 1)[1].split("- (void)start", 1)[0]
        self.assertIn("self.adapter.isAttached && self.geometryVerified", tick)
        self.assertIn("[bundle isEqual:self.boundBundle]", tick)
        adapter = (MAP / "DFNativeMapPaneAdapter.m").read_text()
        for contract in ("scene==self.nativeScene", "self.nativeSceneIdentifier",
                         "[DFMapOwnerBundle(vc) isEqual:self.nativeBundle]",
                         "![self hasVerifiedNativeOwner]"):
            self.assertIn(contract, adapter)

    def test_catalog_reads_existing_library_with_bounded_supported_scope(self):
        catalog = (MAP / "DFNativeMapCatalog.h").read_text()
        self.assertIn('NSClassFromString(@"FBSApplicationLibrary")', catalog)
        self.assertIn('DFNativeMapCatalogObject(library,@"allInstalledApplications")', catalog)
        self.assertIn("DFNativeMapAllowedBundle(bundle)", catalog)
        self.assertIn('[declared isEqual:bundle]', catalog)
        source = (MAP / "DFNativeMapPaneCoordinator.m").read_text()
        self.assertIn("DFNativeMapCatalogFromLibrary(library)", source)
        self.assertIn("if(!bundles)return", source)
        for forbidden in ("_newApplicationLibrary", "_launchAppWithInfo:",
                          "_sceneDidEnterBackground:", "setForeground:"):
            self.assertNotIn(forbidden, catalog + source)

    def test_detached_native_owner_can_release_only_an_empty_owned_pane(self):
        adapter = (MAP / "DFNativeMapPaneAdapter.m").read_text()
        discard = adapter.split("- (BOOL)discardDetachedNativeOwner {", 1)[1].split(
            "+ (NSString *)preflightNativeController:", 1)[0]
        self.assertIn("container.subviews.count", discard)
        self.assertIn("[view isDescendantOfView:container]", discard)
        self.assertIn("[self clearOwnershipReferences]", discard)
        for mutation in ("removeFromSuperview", "removeFromParentViewController", "addSubview"):
            self.assertNotIn(mutation, discard)
        coordinator = (MAP / "DFNativeMapPaneCoordinator.m").read_text()
        self.assertIn("if(!ok && [self.adapter discardDetachedNativeOwner])", coordinator)
        self.assertIn("if(self.adapter.isAttached || self.pane.subviews.count)return", coordinator)
        self.assertIn("[self invalidateLiveLeaseIfSessionActive]", coordinator)
        revoke = coordinator.split("- (void)invalidateLiveLeaseIfSessionActive {", 1)[1].split(
            "- (BOOL)restore:", 1)[0]
        self.assertIn('[pulse[@"Active"] isEqual:@YES]', revoke)
        self.assertIn('[pulse[@"Session"] isEqual:self.boundSession]', revoke)
        self.assertIn("DFNativeMapSampleFresh", revoke)
        self.assertIn("DFNativeMapClearLeaseForSession(self.boundSession)", revoke)


if __name__ == "__main__":
    unittest.main(verbosity=2)
