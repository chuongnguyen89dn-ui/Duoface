#!/usr/bin/env python3
import unittest, plistlib
from pathlib import Path
R=Path(__file__).resolve().parents[1]
def file(n):return (R/n).read_text()
class NativeOwnerSafety(unittest.TestCase):
 def test_independent_package_and_exact_carplay_filter(self):
  c=file("control")
  self.assertIn("Package: com.duoface.carplay.nativejoinprobe",c)
  self.assertIn("Version: 0.0.4~mapowner1",c)
  self.assertNotIn("Conflicts:",c)
  self.assertNotIn("Replaces:",c)
  filter=plistlib.loads((R/"DFNativeSceneJoinProbe.plist").read_bytes())
  self.assertEqual(filter["Filter"]["Executables"],["CarPlay","CarPlayApp"])
 def test_only_read_native_window_state(self):
  c=file("DFNativeSceneProbe.m")
  for expected in ('DBDashboardRootViewController','DBDockWindow','DBStatusBarWindow',
                   'window.safeAreaInsets','DFNativeSceneUsable(',
                   'UISceneActivationStateForegroundActive','DFNativeSceneOwnerRecord('):
   # window.safeAreaInsets corresponds to dashboardWindow.safeAreaInsets
   if expected=='window.safeAreaInsets':expected='dashboardWindow.safeAreaInsets'
   self.assertIn(expected,c)
  # On iOS16 the native bar is often owned by a sibling CarPlay UIWindowScene.
  # These MUST be cross-scene measurements on the same UIScreen, not w.frame.
  for required in ('ws.screen!=dashboardWindow.screen',
                   'convertRect:w.bounds fromWindow:w',
                   'CARStatusBarWindow', 'CGRectIntersection(full,converted)',
                   'if(dashboardWindow)break;', 'nativeBarWindow=w;barInScene=visible;'):
   self.assertIn(required,c)
  self.assertNotIn('CGRect frame=w.frame;',c)
  for method in ('CARApplication', 'LSBundleProxy', 'FBSApplicationInfo',
                 'DFProbeNativeAppAdmissionABI()', 'DBWorkspace', 'DBApplicationController',
                 'DBDashboardWorkspaceOwner', 'DBMutableWorkspaceStateChangeRequest',
                 'method_getTypeEncoding', 'DFProbeNativeWorkspaceABI()'):
   self.assertIn(method,c)
  self.assertIn('previous[@"Session"] isEqual:self.session',c)
  for forbidden in ('candidate.frame=','bar.hidden=', 'setWindowLevel:',
          'initWithDisplayConfiguration:', 'UIRootSceneWindow', 'drawViewHierarchyInRect',
          'objc_msgSend',
          'setRootViewController:','makeKeyAndVisible','SBApplicationController'):
   self.assertNotIn(forbidden,c)
 def test_boot_safety_and_source_boundary(self):
  t=file("Tweak.x")
  self.assertNotIn("%hook",t)
  self.assertIn("DFNativeSceneProbeStart()",t)
  self.assertIn("10*NSEC_PER_SEC",t)
  for bad in ("SpringBoard", "objc_addLoadImageFunc", "MSHookMessageEx"):
   self.assertNotIn(bad,t)
  m=file("Makefile")
  self.assertIn("arm64 arm64e",m)
  self.assertIn("DFNativeSceneContract.m",m)
  self.assertIn("DFCarPlayLiveOwnerSnapshot.m",m)
  self.assertIn("DFCarPlayCaptureLiveOwnerSnapshot(self.session)",file("DFNativeSceneProbe.m"))
  live=file("DFCarPlayLiveOwnerSnapshot.m")
  for required in ("processPID", "CarPlayApp", "session.persistentIdentifier", "sceneHostView",
                   "sceneHostViewStatus", "viewIfLoaded", "childViewControllers",
                   "class_getInstanceMethod", "method_copyReturnType", "connectedScenes",
                   "mapsNativeOwnerProven", "limitedControllers"):
   self.assertIn(required,live)
  for forbidden in ("foregroundSceneWithSettings", "backgroundSceneWithCompletion",
                    "setFrame:", "makeKeyAndVisible", "requestStateChange:",
                    "MSHookMessageEx", "CGContextDraw", "setRootViewController:"):
   self.assertNotIn(forbidden,live)
  self.assertNotIn("DFNativeSidebarTrial.m",m)
 def test_contract_refuses_stale_session(self):
  c=file("DFNativeSceneContract.m")
  for required in ('age>3.0', 'CGRectContainsRect(f,u)',
                   'DFNativeSceneSplit(', 'isfinite', 'Kind', 'Session'):
   self.assertIn(required,c)
  self.assertNotIn('45.0',c)
if __name__=="__main__":unittest.main(verbosity=2)
