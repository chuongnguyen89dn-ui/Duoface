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
  # Replace an obsolete whole-file .91 SHA. The Chrome now legitimately
  # includes later workspace/rotation features, but the trusted .92 touch
  # paths MUST remain byte-identical to the device-approved source.
  import json
  b=(R/'DFNative12Chrome.m').read_text(encoding='utf8')
  golden=json.loads((R/'tests/fixtures/divider92_exact_source.json').read_text())
  for name,section in golden['parts'].items():
   i=b.index(section['start'])
   j=b.index(section['end'],i)
   self.assertEqual(b[i:j],section['text'],name)
  logo=(R/'tests/fixtures/logo92_contact_and_swap_baseline.txt').read_text()
  i=b.index('- (void)logoTouchDown:')
  j=b.index('// The divider window itself is re-framed',i)
  self.assertEqual(b[i:j],logo)
  self.assertIn('DFSlotCountForPreset(self.preset)<=1',b)
  self.assertIn('divider92-hidden-owner-contact-cancelled-for-next-reveal',b)
 def test_v37_reference_dispatch_and_touch_wake(self):
  s=(R/'DFSceneHost.m').read_text()
  self.assertIn('BOOL applied=child2Applied||child3Applied||main2Applied;',s)
  self.assertIn('inner.frame=(CGRect){CGPointZero,logical};',s)
  self.assertIn('hostedScene,update,setVerifiedNative12Frame',s)
  self.assertIn('postNotificationName:DFSceneHostDidObserveTouchNotification',s)
  self.assertNotIn('requestedSceneOrientation',s)
