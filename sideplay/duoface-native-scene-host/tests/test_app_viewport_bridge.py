""".74 distribution regression: retired .73 relay must not ship."""
import unittest
from pathlib import Path
R=Path(__file__).resolve().parents[1]
class RecoveryDistribution(unittest.TestCase):
 def test_no_app_process_relay(self):
  build=(R/'build.sh').read_text()
  self.assertNotIn('DFAppViewportRelay.m',build)
  self.assertNotIn('DFAppViewportRelay.plist',build)
  host=(R/'DFSceneHost.m').read_text()
  self.assertNotIn('notify_set_state',host)
  # The original .83 forbade ALL scene orientation writes. This scoped
  # .86 candidate permits only observed/ABI-checked owned YouTube main scene.
  self.assertIn('[self.bundleID isEqualToString:@"com.google.ios.youtube"]',host)
  self.assertIn('DFMutableRemoteOrientationABI(settings)',host)
  self.assertIn('surface.sceneGeneration!=generation',host)
 def test_current_ui_preserved(self):
  import hashlib
  # Verified user-approved .91 Chrome logo 3s gate intentionally changed the
  # prior byte pin; keep this new exact source pin with split/solo isolated.
  # Legacy .88 pin is superseded, not a failed YouTube video regression.
  b=(R/'DFNative12Chrome.m').read_bytes()
  added=b'''        // Native12 split and SOLO are UI state, not inferred from a second
        // loaded app or the pane's width. One visible YouTube pane plus one
        // EMPTY pane is still split. The host owns the app-scene IPC lease.
        id hosted=self.hostedScenes[(NSUInteger)i];
        if([hosted isKindOfClass:UIView.class]) {
            [[DFSceneHost sharedHost] setSplitMode:
                (activeSlots>1 && self.focus<0 && !self.startupActive)
                forHostedView:(UIView *)hosted];
        }
'''
  self.assertEqual(b.count(added),1)
  original=b.replace(added,b'')
  self.assertIn(b'DFLogoHoldAdvance(&self->_logoHoldGate',original)
  self.assertIn(b'self->_dividerDrag.axis=DFDragLogo',original)
  self.assertEqual(hashlib.sha1(b'blob '+str(len(original)).encode()+b'\0'+original).hexdigest(),
                   '107de289688a652ae419d48f7af0ff265b561baa')
 def test_v37_reference_dispatch_and_touch_wake(self):
  s=(R/'DFSceneHost.m').read_text()
  self.assertIn('BOOL applied=child2Applied||child3Applied||main2Applied;',s)
  self.assertIn('inner.frame=(CGRect){CGPointZero,logical};',s)
  self.assertIn('hostedScene,update,setVerifiedNative12Frame',s)
  self.assertIn('postNotificationName:DFSceneHostDidObserveTouchNotification',s)
  self.assertNotIn('requestedSceneOrientation',s)
