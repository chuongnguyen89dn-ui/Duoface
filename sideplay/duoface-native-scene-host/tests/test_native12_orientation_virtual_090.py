"""Source-only comparison with SHA-pinned ORIGINAL Native12 callback semantics.
Does not pretend that the YouTube video pixels have been tested.
"""
import json
import pathlib
import unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
REPO=ROOT.parents[1]
ORIGINAL=(REPO/"sideplay/audit/native12-083-rotation-20261028/"
    "NATIVE12_ORIGINAL_36_HOOK_CALLBACKS_RUN_40667230467.json")

class NativeOrientationVirtual090(unittest.TestCase):
    def test_scope_and_registration(self):
        impl=(ROOT/"DFYouTubeOrientationVirtualization.m").read_text()
        relay=(ROOT/"DFYouTubeOrientationRelay.m").read_text()
        plist=(ROOT/"DFYouTubeOrientationRelay.plist").read_text()
        self.assertIn("<string>com.google.ios.youtube</string>",plist)
        self.assertIn('isEqual:DFYTBundle',impl)
        self.assertIn('operatingSystemVersion.majorVersion!=16',impl)
        self.assertIn('dlsym(RTLD_DEFAULT,"MSHookMessageEx")',impl)
        self.assertIn('MSHookMessageEx-symbol-unavailable',impl)
        self.assertIn('method_getNumberOfArguments(method)!=args',impl)
        self.assertIn('window.windowScene==DFYTLeasedScene',impl)
        self.assertIn('NSDate.date.timeIntervalSince1970<=DFYTLeaseDeadline',impl)
        self.assertIn('DFYTVirtualUpdateLease(self.state,owned)',relay)
        self.assertIn('else DFYTVirtualUpdateLease(state,self.scene)',relay)
        self.assertIn('DFYTVirtualInstall()',relay)
        self.assertIn('DFYTVirtualClearLease();',relay)
        self.assertIn('@"virtualization":DFYTVirtualSnapshot()',relay)
        self.assertIn('return DFYTOrigSceneOrientation?',impl)
        self.assertIn('return DFYTOrigDeviceOrientation?',impl)
    def test_real_original_callbacks_and_restore(self):
        orig=json.loads(ORIGINAL.read_text())
        callbacks={(a['class'],a['selector']):a for a in orig['callbacks']}
        self.assertEqual(orig['original_hooks_count'],36)
        for cls,sel,pc in [
            ('UIViewController','supportedInterfaceOrientations','0x2acc04'),
            ('UIViewController','__supportedInterfaceOrientations','0x2acc60'),
            ('UIWindowScene','interfaceOrientation','0x2ad7f0'),
            ('UIDevice','orientation','0x2ad8d0'),
            ('UIWindow','_rotateWindowToOrientation:updateStatusBar:duration:skipCallbacks:','0x2acfd8'),
            ('UIWindow','_setRotatableViewOrientation:duration:force:','0x2acef4'),
        ]:
            self.assertEqual(callbacks[(cls,sel)]['exact_start'],pc)
        code=(ROOT/"DFYouTubeOrientationVirtualization.m").read_text()
        self.assertIn('UIInterfaceOrientationMaskPortrait',code)
        self.assertIn('UIInterfaceOrientationPortrait',code)
        self.assertIn('UIDeviceOrientationPortrait',code)
        self.assertIn('DFYTOrigSupported(controller,cmd)',code)
        self.assertIn('DFYTOrigInternalSupported(controller,cmd)',code)
        self.assertIn('DFYTOrigWindowRotate(window,cmd,orientation,statusBar,duration,skipCallbacks)',code)
        self.assertIn('DFYTOrigWindowRotatable(window,cmd,orientation,duration,force)',code)
        self.assertIn('DFYTVirtualClearLease',code)
        self.assertNotIn('method_setImplementation',code)
        self.assertNotIn('setInterfaceOrientation:',code)
        self.assertNotIn('UIScreen.bounds',code)
    def test_package_and_source_only_link(self):
        build=(ROOT/"build.sh").read_text()
        wf=(REPO/".github/workflows/duoface-native12-source-only-validation.yml").read_text()
        for code in (build,wf):
            self.assertIn('DFYouTubeOrientationRelay.m DFYouTubeOrientationVirtualization.m',code)
        self.assertIn("DFSceneLifecycle.m",build)

if __name__=="__main__":
    unittest.main()
