"""Regression fences for the independent .86 candidate.

These are SOURCE tests, not a claim that a real Google Maps native CPWindow
can be hosted concurrently with the DuoFace foreground scene.
"""
import pathlib
import unittest

ROOT=pathlib.Path(__file__).resolve().parents[1]
def read(p):
    return (ROOT/p).read_text()

class NativeOwner086(unittest.TestCase):
    def test_original_backed_youtube_remote_orientation_is_owner_scoped(self):
        s=read("DFSceneHost.m")
        self.assertIn('DFObservedRemoteInterfaceOrientation(remoteSettings)',s)
        self.assertIn('DFMutableRemoteOrientationABI(settings)',s)
        self.assertIn('remoteOrientation>=2 && remoteOrientation<=4',s)
        self.assertIn('[self.bundleID isEqualToString:@"com.google.ios.youtube"]',s)
        self.assertIn('UIInterfaceOrientationPortrait',s)
        self.assertIn('surface.sceneGeneration!=generation',s)
        self.assertIn('surface.scene!=hostedScene',s)
        self.assertIn('DFCall0(DFCall0(surface.appController,@"sceneHandle"),@"sceneIfExists")!=hostedScene',s)
        self.assertIn('!DFHostingFlag(surface.appController,@"isHostingAnApp",NO)',s)
        self.assertIn('if (!unchanged || youtubePortraitRepair)',s)
        self.assertIn('if (!unchanged && settings && [settings respondsToSelector:fgSelector])',s)
        self.assertIn('if (!unchanged && settings && [settings respondsToSelector:bgSelector])',s)
        self.assertNotIn('UIInterfaceOrientationLandscapeRight',s)
        self.assertNotIn('UIInterfaceOrientationLandscapeLeft',s)

    def test_real_maps_carplay_owner_probe_is_readonly_and_integrated(self):
        build=read("build.sh")
        dock=read("DFCarPlayDockOwner.m")
        probe=(ROOT.parent/"native-carplay-scene-v1"/"DFCarPlayLiveOwnerSnapshot.m").read_text()
        self.assertIn('DFCarPlayLiveOwnerSnapshot.m',build)
        self.assertIn('DFIntegratedCarPlayCaptureLiveOwnerSnapshot',build)
        self.assertIn('DFIntegratedCarPlayCaptureLiveOwnerSnapshot',dock)
        self.assertIn('DBApplicationSceneViewController',probe)
        self.assertIn('hostedBundleIdentifier',probe)
        self.assertIn('hostedSceneIdentifier',probe)
        self.assertIn('sceneHostViewPointer',probe)
        # The source derives nativeScenePointer via the existing
        # identity-safe DFGetOwnerObject's key+Pointer writer.
        self.assertIn('DFGetOwnerObject(vc,@"scene",log,@"nativeScene")',probe)
        self.assertIn('@"Pointer"',probe)
        self.assertIn('CarPlayApp',dock)
        self.assertIn('map-owner-v8',dock)
        self.assertNotIn('sceneHostView addSubview',dock)
        self.assertNotIn('removeFromSuperview',probe)
        self.assertNotIn('foregroundSceneWithSettings:',dock)

    def test_rejected_cosmetic_map_zoom_not_restored(self):
        p=read("DFHostedMapRenderSize.h")
        self.assertIn('return (CGFloat)0.50;',p)
        self.assertIn('round(pane.width*2.0),round(pane.height*2.0)',p)
        self.assertNotIn('0.80',p.split("NS_INLINE CGFloat DFHostedViewportScaleForBundle",1)[1])
        self.assertIn('0.0.88~uikitreflow1',read("DFDeepTrace.h"))
        self.assertIn('0.1.97~uikitreflow1',read("control"))

if __name__=="__main__":
    unittest.main(verbosity=2)
