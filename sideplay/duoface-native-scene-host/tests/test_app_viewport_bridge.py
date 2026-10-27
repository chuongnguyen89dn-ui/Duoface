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
  self.assertNotIn('setInterfaceOrientation:',host)
 def test_current_ui_preserved(self):
  import hashlib
  # Blob verified at .73 source; byte-for-byte chrome preservation.
  b=(R/'DFNative12Chrome.m').read_bytes()
  self.assertEqual(hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest(),'9e5772b9d6fef1e2c6f7c0baca23367bda03113a')
 def test_v37_reference_dispatch_and_touch_wake(self):
  s=(R/'DFSceneHost.m').read_text()
  self.assertIn('BOOL applied=child2Applied||child3Applied||main2Applied;',s)
  self.assertIn('inner.frame=(CGRect){CGPointZero,logical};',s)
  self.assertIn('hostedScene,update,setVerifiedNative12Frame',s)
  self.assertIn('postNotificationName:DFSceneHostDidObserveTouchNotification',s)
  self.assertNotIn('requestedSceneOrientation',s)
