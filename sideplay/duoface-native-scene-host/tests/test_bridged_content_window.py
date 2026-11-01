"""True native CarPlay root/content ownership, original DuoNavi CBWindow callgraph.
Static source contract ONLY: not a device touch, Dock or visual acceptance test.
"""
from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
S=(R/"DFHomeStandalone144.m").read_text()
class NativeContentWindow(unittest.TestCase):
 def test_full_screen_root_and_separate_usable_content(self):
  body=S.split("- (BOOL)begin:(NSDictionary *)p {",1)[1].split("- (void)attemptOwnedReadyForView:",1)[0]
  for x in ('DF144OwnedPassThroughWindowClass(', 'w.frame=expectedScreen',
            'CGRectOffset(content,-expectedScreen.origin.x',
            'CGRectContainsRect(w.bounds,usable)',
            'objc_setAssociatedObject(w,&DF144NativeContentRectKey',
            'root.view=[[UIView alloc]initWithFrame:(CGRect){CGPointZero,expectedScreen.size}]',
            'UIView *contentView=[[UIView alloc]initWithFrame:usable]',
            '[root.view addSubview:contentView]',
            'v.frame=contentView.bounds',
            '[contentView addSubview:v]'):
   self.assertIn(x,body)
  self.assertLess(body.index('[root.view addSubview:contentView]'),body.index('[contentView addSubview:v]'))
  self.assertNotIn('w.frame=content;',body)
  self.assertNotIn('[root.view addSubview:v];',body)
 def test_dock_pass_through_without_stealing_real_app_input(self):
  src=S.split('static char DF144NativeContentRectKey;',1)[1].split('@interface DF144Solo',1)[0]
  for x in ('CGRectContainsPoint([value CGRectValue],point)',
            'if(!DF144OwnedWindowPoint(window,point))return NO;',
            'if(!DF144OwnedWindowPoint(window,point))return nil;',
            'objc_msgSendSuper','hit==w.rootViewController.view ? nil:hit',
            'objc_allocateClassPair(rootWindowClass',
            'objc_registerClassPair(cls)',
            'method_getTypeEncoding(insideMethod)',
            'method_getTypeEncoding(hitMethod)'):
   self.assertIn(x,src)
  self.assertNotIn('sendEvent:',src)
  self.assertNotIn('UIWindowLevelAlert',src)
 def test_standalone_state_and_original_pane_preserved(self):
  self.assertIn('DF144Allowed(p[@"BundleID"])',S)
  self.assertIn('self.generation!=generation',S)
  self.assertIn('self.surface!=v',S)
  self.assertIn('DFSceneHostDidFailNotification',S)
  self.assertIn('releaseHostedView:view',S)
  self.assertNotIn('setSelectedSlot:',S)
if __name__=="__main__":unittest.main()
