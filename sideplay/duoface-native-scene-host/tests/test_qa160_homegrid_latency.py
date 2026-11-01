"""QA160 source contracts: scoped faster first scene probe and read-only native grid evidence.
These tests DO NOT assert hardware Home-grid success or real touch-ready latency.
"""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
SCENE=(ROOT/"DFSceneHost.m").read_text()
API=(ROOT/"DFSceneHost.h").read_text()
SOLO=(ROOT/"DFHomeStandalone144.m").read_text()
HOME=(ROOT/"DFCarPlayOwnerObserver.h").read_text()
DOCK=(ROOT/"DFNativeDockSync147.h").read_text()

class NativeGridLatency160(unittest.TestCase):
 def test_fast_probe_owned_by_standalone_only(self):
  self.assertIn("- (void)setFastInitialPolling:(BOOL)fast forHostedView:(UIView *)view;", API)
  self.assertIn("[[DFSceneHost sharedHost] setFastInitialPolling:YES forHostedView:v];",SOLO)
  self.assertIn("surface.started || surface.stopped ||",SCENE)
  self.assertIn("self.live[surface.bundleID]!=surface",SCENE)
  self.assertIn("self.fastInitialPolling?0.10:0.35",SCENE)
  self.assertIn("qa160-fast-initial-probe-complete",SCENE)
  self.assertIn("scheduledTimerWithTimeInterval:0.35 target:self",SCENE)
  self.assertIn('if(scene && supportsHosting && isHosting && viewAttached)',SCENE)
  self.assertIn("hostViewForBundleID:self.bundle error:&err",SOLO)
 def test_real_home_delegate_remains_apple_owned_and_trace_read_only(self):
  self.assertIn('DFOwnerDBHomeOriginal(object,sel,event);',HOME)
  self.assertIn('DFOwnerCARHomeOriginal(object,sel,event);',HOME)
  self.assertIn('DF160NativeHomeTrace(@"before-Apple-Home",object);',HOME)
  self.assertIn('DF160NativeHomeTrace(@"after-Apple-Home",object);',HOME)
  self.assertIn('DF160NativeHomeTrace(@"plus-200ms",live);',HOME)
  self.assertIn("qa160-native-home-page-snapshot-not-pixel",SOLO)
  self.assertIn("DBDashboardHomeViewController",SOLO)
  self.assertIn('DF144Original(self,cmd,manager,icon);',SOLO)
  self.assertIn('DF147Reset(@"native-home-stop")',SOLO)
  self.assertNotIn('DF160ForceNativeHomeGrid',SOLO+HOME)
 def test_no_optimistic_touch_claim_or_cross_app_replacement(self):
  self.assertIn("qa160-native-grid-icon-pressed",SOLO)
  self.assertIn("qa160-request-to-dock-ms",DOCK)
  self.assertIn("touchReady=unknown",DOCK)
  self.assertIn("scene-hosted-render-and-touch-unverified",SOLO)
  self.assertIn('DF144Log(@"qa159-native-home-stop-no-chooser"',SOLO)
  self.assertNotIn("setRequestedMode: 0",HOME)
if __name__=="__main__":unittest.main()
