"""B1 contracts + real Foundation state/block ABI tests on the macOS CI runner.
No test here represents Maps pixels, actual Dashboard ABI or vehicle touch PASS.
"""
import pathlib, subprocess, sys, tempfile, unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
REPO=ROOT.parents[1]
def read(p):return (ROOT/p).read_text()
class QA182B1(unittest.TestCase):
 def test_native_dispatch_precedes_all_phone_host_calls(self):
  chrome=read('DFNative12Chrome.m')
  manual=chrome.split('- (void)appPicker:(DFAppPickerVC *)picker\n didSelectBundleID:',1)[1]
  self.assertLess(manual.index('[self assignNativeMaps182:physicalSlot]'),manual.index('hostViewForBundleID:bundleID'))
  restore=chrome.split('- (void)restoreNextSavedWorkspaceApp {',1)[1].split('- (',1)[0]
  self.assertLess(restore.index('[self assignNativeMaps182:physical]'),restore.index('hostViewForBundleID:bundle'))
  self.assertIn('Maps native assignment forbids phone-scene hosting',read('DFSceneHost.m'))
  self.assertIn('native-slot-unassigned',chrome)
  self.assertIn('Chrome-Home-or-disconnect',chrome)
 def test_real_library_and_genuine_declaration(self):
  core=read('DFHomePublisher136Core.m').split('id DF182ReconcileNativeMaps(',1)[1].split('// Returns count',1)[0]
  self.assertIn('allInstalledApplications',core)
  self.assertIn('_notifyDidAddApplications:',core)
  self.assertIn('DFHome141InfoHasDeclaration',core)
  for forbidden in ('DFHome141CompleteInfo(', 'DFHome140Enabled(', 'DFHome136Enabled(', 'setCarPlayDeclaration:'):
   self.assertNotIn(forbidden,core)
  bridge=read('DF182DashboardBridge.m')
  self.assertIn('DF182CapturedDashboardWorkspace()',bridge)
  self.assertIn('activateApplication:',bridge)
  self.assertNotIn('hostViewForBundleID',bridge)
 def test_provenance_placement_and_lifecycle_gates(self):
  s=(REPO/'sideplay/native-carplay-scene-v1/DF182NativeMaps.m').read_text()
  for evidence in ('sceneProvenance','controllerProvenance','settingsClass','sceneRole','windowRole','sceneID','sceneClientProcessBundle',
                   'convertRect:screenRect fromCoordinateSpace:window.screen.coordinateSpace','clipsToBounds',
                   'target-SpringBoard-window=hidden','DF182VoidCompletion(completion)',
                   'native-scene-provenance-timeout-10s-STOP-no-phone-fallback'):
   self.assertIn(evidence,s)
  self.assertNotIn('hasPrefix:@"Car["',s)
  self.assertIn('self.stopped=YES; // Revokes swallow BEFORE',s)
  self.assertIn('DF182Scene(controller)==self.scene',s)
  self.assertIn('r[@"Touch"]=@"UNVERIFIED"',s)
  self.assertIn('r[@"NativePixels"]=@"UNVERIFIED"',s)
  prelaunch=s.split('if(!self.launchAttempted) {',1)[1]
  self.assertLess(prelaunch.index('targetForWindow:windows.firstObject'),prelaunch.index('launch(self.assignment)'))
  frame=s.split('static CGRect DF182Frame(',1)[1].split('static void DF182Deactivate',1)[0]
  self.assertIn('targetForWindow:DF182Owner.window',frame)
  self.assertNotIn('[DF182Owner owns:',frame) # scene creation needs the size before adoption
 def test_frozen_h1_exact_bytes(self):
  for name in ('DFAppTouch177.h','DFH1Wake188.m'):
   old=subprocess.check_output(['git','show',f'b7a9b45d2c5389a1f41b547887176466a8d628fb:sideplay/duoface-native-scene-host/{name}'],cwd=REPO)
   self.assertEqual((ROOT/name).read_bytes(),old)
 def test_instrumentation_covers_both_processes_and_export(self):
  s=read('DFCarPlayDockOwner.m').split('static void DFZMapSceneWatch(',1)[1].split('__attribute__',1)[0]
  self.assertIn('isEqualToString:@"CarPlayApp"',s)
  self.assertIn('isEqualToString:@"CarPlay"',s)
  self.assertIn('DuoFaceHomeRoster165.log',read('DFNativeDiagnostics.m'))
  self.assertIn('qa181-b0',read('DF181B0Probe.h'))
 def test_versions(self):
  self.assertIn('Version: 0.1.185~admission1',read('control'))
  self.assertIn('<key>CFBundleVersion</key><string>185</string>',read('Info.plist'))
  self.assertIn('VERSION="0.0.185~admission1"',(REPO/'sideplay/jb-embedded-appbridge/package_integrated.py').read_text())
 @unittest.skipUnless(sys.platform=='darwin','Foundation runtime requires macOS CI')
 def test_real_assignment_expiry_and_completion_abi(self):
  with tempfile.TemporaryDirectory() as d:
   out=str(pathlib.Path(d)/'assignment182')
   subprocess.run(['clang','-fobjc-arc','-fblocks','-Wall','-Wextra','-Werror','-Wno-deprecated-declarations',
     '-framework','Foundation',str(ROOT/'tests/assignment_182_runtime.m'),'-o',out],check=True)
   r=subprocess.run([out],check=True,capture_output=True,text=True)
   self.assertIn('QA182_ASSIGNMENT_LIFETIME_AND_COMPLETION_ABI_RUNTIME_PASS',r.stdout)
if __name__=='__main__':unittest.main()
