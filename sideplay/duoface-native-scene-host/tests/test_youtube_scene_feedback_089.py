"""Evidence-anchored source regression for DuoFace .89, not device QA."""
import pathlib
import unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
def read(name):
    return (ROOT/name).read_text(encoding="utf-8")
class YoutubeSplitFeedback089(unittest.TestCase):
    def test_v2_split_and_lease_are_mandatory(self):
        header=read("DFYouTubeHostState.h")
        host=read("DFSceneHost.m")
        runtime=read("tests/youtube_handshake_runtime.m")
        self.assertIn('![state[@"version"] isEqual:@2]',header)
        self.assertIn('!DFYTNumber(state[@"isSplit"])',header)
        self.assertIn('@"isSplit":@(self.splitUIVisible)',host)
        self.assertIn('self.splitUIVisible',host)
        self.assertIn('setSplitMode:(BOOL)isSplit forHostedView:(UIView *)view',host)
        chrome=read("DFNative12Chrome.m")
        self.assertIn('activeSlots>1 && self.focus<0 && !self.startupActive',chrome)
        self.assertIn('[DFSceneHost sharedHost] setSplitMode:',chrome)
        self.assertIn('self.hostedScenes[(NSUInteger)i]',chrome)
        self.assertIn('@"isSplit":@YES',runtime)
        self.assertIn('DFYTValidState(state,now)',host)
        self.assertIn('DFYTShouldAccept(state,self.state',read("DFYouTubeOrientationRelay.m"))
    def test_real_scene_controller_mismatch_drives_bounded_public_uikit(self):
        app=read("DFYouTubeOrientationRelay.m")
        self.assertIn('window.rootViewController.interfaceOrientation!=UIInterfaceOrientationPortrait',app)
        self.assertIn('[self.state[@"isSplit"] boolValue]',app)
        self.assertIn('lastGeometryCheckKey',app)
        self.assertIn('dispatch_after(dispatch_time(DISPATCH_TIME_NOW',app)
        self.assertIn('[controller setNeedsUpdateOfSupportedInterfaceOrientations]',app)
        self.assertIn('UIWindowSceneGeometryPreferencesIOS',app)
        self.assertIn('requestGeometryUpdateWithPreferences:preferences',app)
        self.assertIn('UIInterfaceOrientationMaskPortrait',app)
        self.assertIn('relay.scene!=expectedScene',app)
        self.assertIn('target.windowScene!=expectedScene',app)
        self.assertIn('controllerMismatch',app)
        self.assertIn('geometry-request-rejected',app)
        self.assertNotIn('AVPlayer',app)
        self.assertNotIn('UIDevice.currentDevice',app)
        self.assertNotIn('setInterfaceOrientation:',app)
        self.assertNotIn('updateSettingsWithBlock:',app)
        self.assertIn('self.lastGeometryCheckKey=nil',app)
    def test_host_client_feedback_without_remote_mutation(self):
        host=read("DFSceneHost.m")
        self.assertIn('DFCall0(self.scene,@"clientSettings")',host)
        self.assertIn('DFObservedRemoteInterfaceOrientation(client)',host)
        self.assertIn('clientOrientation=%ld serverOrientation=%ld',host)
        self.assertIn('ack[@"controllerMismatch"]',host)
        self.assertIn('ack[@"geometryRequest"]',host)
        self.assertIn('self.owner.live[self.bundleID]!=self',host)
        self.assertIn('DFSceneLifecycle.m',read("build.sh"))
        self.assertEqual("0.50",read("DFHostedMapRenderSize.h").split("return (CGFloat)")[1].split(";")[0])
        self.assertIn("<string>com.google.ios.youtube</string>",read("DFYouTubeOrientationRelay.plist"))
    def test_versioning_isolated_previous_baseline(self):
        self.assertIn("0.1.101~logo3s1",read("build.sh"))
        self.assertIn("0.1.101~logo3s1",read("control"))
        self.assertIn("0.0.90~nativegetters1",read("DFDeepTrace.h"))

if __name__ == "__main__":
    unittest.main()
