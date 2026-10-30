"""QA127: evidence-tied nonduplicated geometry writer and scoped YouTube observer.
Only first-party source assertions: device evidence still required for Play/Zoom.
"""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
class OwnerReflow127(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.host=(ROOT/'DFSceneHost.m').read_text()
  cls.relay=(ROOT/'DFYouTubeOrientationRelay.m').read_text()
  cls.lifecycle=(ROOT/'DFSceneLifecycle.m').read_text()
  cls.native=(ROOT/'DFNativeHostAppDelegate.m').read_text()
  cls.chrome=(ROOT/'DFNative12Chrome.m').read_text()
 def test_frame_only_geometry_does_not_mutate_foreground(self):
  callback=self.host.split('void (^setVerifiedNative12Frame)(id)=^(id settings) {',1)[1].split('if (!unchanged || youtubePortraitRepair)',1)[0]
  self.assertIn('setFrame:',callback)
  self.assertIn('setInterfaceOrientation:',callback) # preserve QA90 owned portrait
  self.assertIn('sceneGeneration!=generation',callback)
  for expression in ('setForeground:', 'setBackgrounded:', 'setRequestedMode:', 'setUILocked:'):
   self.assertNotIn(expression,callback)
  self.assertIn('QA127 real-device root-cause audit',callback)
 def test_not_add_another_scene_policy_or_lock_bypass(self):
  self.assertEqual(self.lifecycle.count('sUpdate(scene,selector,forwarded,context,completion)'),1)
  self.assertIn('DFIsOwnedManualSceneObserver(controller,handle)',self.lifecycle)
  self.assertIn('sPreviousSceneObserver(controller,selector,handle,diff,previousSettings)',self.lifecycle)
  for x in ('setUILocked:', 'BKSDisplayServicesSetScreenBlanked','setBrightness:'):
   self.assertNotIn(x,self.lifecycle)
 def test_dedicated_youtube_lease_unchanged_and_window_event_scoped(self):
  source=self.relay
  block=source.split('- (void)windowVisible:(NSNotification *)notification {',1)[1].split('\n- (void)apply {',1)[0]
  self.assertIn('id subject=notification.object;',block)
  self.assertIn('[subject isKindOfClass:UIWindow.class]',block)
  self.assertIn('[subject isKindOfClass:UIWindowScene.class]',block)
  self.assertIn('window.windowScene!=owned',block)
  self.assertIn('window.hidden',block)
  self.assertIn('window.windowLevel!=UIWindowLevelNormal',block)
  self.assertIn('subject!=owned',block)
  self.assertIn('[self apply];',block)
  self.assertNotIn('(void)notification;',block)
  self.assertIn('if(changed || !self.scene)[self apply]',source)
  self.assertIn('DFYTVirtualUpdateLease(state,self.scene)',source)
  self.assertIn('UIWindowDidBecomeVisibleNotification',source)
  self.assertIn('UISceneDidActivateNotification',source)
  self.assertIn('DFYTRotate(window,UIInterfaceOrientationPortrait)',source)
 def test_home_disconnection_and_divider_untouched(self):
  for x in ('stopTouchOwnerWithReason:@"scene-background"',
            'stopTouchOwnerWithReason:@"template-disconnected"',
            'stopTouchOwnerWithReason:@"scene-disconnected"'):
   self.assertIn(x,self.native)
  for x in ('DFDragMove(&_dividerDrag','DFDragFinish(&_dividerDrag',
            'QA120' if False else 'divider-axis-end'):
   self.assertIn(x,self.chrome)
if __name__=='__main__':unittest.main()
