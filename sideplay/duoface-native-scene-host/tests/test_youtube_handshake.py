"""Distribution/owner boundary regression for the Native12-inspired app half."""
import plistlib
import unittest
from pathlib import Path
R=Path(__file__).resolve().parents[1]
class YouTubeHandshake(unittest.TestCase):
 def test_exact_app_filter_and_build(self):
  self.assertEqual(plistlib.loads((R/'DFYouTubeOrientationRelay.plist').read_bytes()),
                   {'Filter':{'Bundles':['com.google.ios.youtube']}})
  build=(R/'build.sh').read_text()
  self.assertIn('DFYouTubeOrientationRelay.m',build)
  self.assertIn('ldid -S "$YT_DYLIB"',build)
 def test_relay_scope(self):
  src=(R/'DFYouTubeOrientationRelay.m').read_text()
  for needed in ['DFYTShouldAccept', '_sceneIdentifier', 'window.windowScene!=owned',
                 'UIWindowLevelNormal','DFYTRotationABI(window)','[self reset]',
                 'saved.frame','saved.bounds','saved.orientation','if(changed || !self.scene)']:
   self.assertIn(needed,src)
  for forbidden in ['MSHookMessageEx','setRequestedMode:','setForeground:',
                    'setOrientation:', 'UIScreen.mainScreen']:
   self.assertNotIn(forbidden,src)
  self.assertIn('requestGeometryUpdateWithPreferences:preferences',src)
  self.assertIn('[self.state[@"isSplit"] boolValue]',src)
  self.assertIn('relay.scene!=expectedScene',src)
 def test_host_leases_only_committed_owned_scene(self):
  src=(R/'DFSceneHost.m').read_text()
  for needed in ['DFYTObject(self.scene,@"identifier")','self.owner.live[self.bundleID]!=self',
                 'DFCall0(handle,@"sceneIfExists")!=self.scene','CGSize committed=self.committedReferenceSize;',
                 'self.youtubeOwner=NSUUID.UUID.UUIDString','[self revokeYouTubeState]',
                 'youtube-app-handshake-ack']:
   self.assertIn(needed,src)
