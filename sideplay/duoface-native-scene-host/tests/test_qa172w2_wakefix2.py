import pathlib, re, unittest
ROOT = pathlib.Path(__file__).resolve().parents[1]
CHROME = (ROOT / "DFNative12Chrome.m").read_text()
TRACE = (ROOT / "DFDeepTrace.h").read_text()
CTRL = (ROOT / "control").read_text()
PKG = (ROOT.parent / "jb-embedded-appbridge" / "package_integrated.py").read_text()

def app_touch_method(source):
 """Select the implementation, never the earlier callback registration."""
 start=source.index('- (void)df177HandleAppTouch {')
 end=source.index('- (void)realAppTouched:',start)
 return source[start:end]

def has_immediate_layout(source):
 body=app_touch_method(source)
 immediate=body.split('dispatch_after(',1)[0]
 return bool(re.search(r'\[\s*(?:self|owner)\s+layoutControls\s*\]',immediate))

def touch_admission_precedes_timers(source):
 """The tested policy must gate the real handler and receive host evidence."""
 immediate=app_touch_method(source).split('dispatch_after(',1)[0]
 guard=re.search(r'if\s*\(\s*!DF177AppTouchRecordMatches\(parsed,liveProcesses,'
                 r'\s*self\.touch177Session\.startedAt,now\)\)return;',immediate)
 if not guard:return False
 evidence=immediate[:guard.start()]
 if not all(token in evidence for token in (
     'for(UIView *surface in self.hostedScenes)',
     'NSNumber *pid=[host verifiedPIDForHostedView:surface];',
     'liveProcesses[hostedBundle]=pid;')):return False
 changes=list(re.finditer(r'self\.(?:borderUntil|controlsUntil)\s*=',immediate))
 return bool(changes) and all(change.start()>guard.end() for change in changes)

class QA172Wakefix2(unittest.TestCase):
 def test_version_coherence(self):
  for text in (TRACE, CTRL, PKG):
   self.assertIn("wakefix4", text)
   self.assertNotIn("wakefix3map1", text)
  self.assertNotIn("wakefix1", TRACE)
  self.assertNotIn("wakefix1", PKG)
  self.assertIn("Version: 0.1.172~wakefix4", CTRL)

 def test_shield_window_gone(self):
  for token in ("DFNativeWakeShieldView","wakeShieldViews",
                "syncWakeShields","source=shield-touch"):
   self.assertNotIn(token, CHROME)

 def test_permanent_gate_present(self):
  for token in ("DFNativeWakeGateView","ensureWakeGates","wakeGateViews",
                "source=gate-touch"):
   self.assertIn(token, CHROME)

 def test_gate_hittest_contract(self):
  gate = CHROME.split("@implementation DFNativeWakeGateView")[1].split("@end")[0]
  self.assertIn("hitTest:", gate)
  self.assertIn("shouldConsume", gate)
  self.assertIn("return nil", gate)
  self.assertIn("touchesBegan", gate)

 def test_gate_respects_keyboard(self):
  self.assertIn("kbVisible177", CHROME)
  relay = (ROOT / "DFAppTouch177.h").read_text()+(ROOT / "DFKeyboardState177.h").read_text()
  self.assertIn("com.duoface.ipc.v177.kbstate", relay)

 def test_app_touch_stays_timers_only(self):
  body=app_touch_method(CHROME)
  self.assertIn('touch177RecheckGeneration',body)
  self.assertIn('!owner.kbVisible177',body)
  self.assertFalse(has_immediate_layout(CHROME))

 def test_app_touch_guard_detects_real_method_regression(self):
  # The old split matched a call site and checked only 11 characters.
  # Inject into the real method: the check must now detect the regression.
  marker='- (void)df177HandleAppTouch {'
  broken=CHROME.replace(marker,marker+'\n    [self layoutControls];',1)
  self.assertTrue(has_immediate_layout(broken))

 def test_touch_sender_and_receiver_use_process_owned_v2(self):
  sender=(ROOT/'DFAppTouch177.h').read_text()
  begin=sender.index('static inline void DF177AppTouchNoteBegan(')
  end=sender.index('static IMP DF177SendEventOriginal',begin)
  body=sender[begin:end]
  self.assertIn('@"version": @2',body)
  self.assertIn('@"pid": @(getpid())',body)
  self.assertTrue(touch_admission_precedes_timers(CHROME))
  # A validator somewhere in the file is insufficient: removing the actual
  # return, trusting the sender PID or mutating a timer first must be caught.
  unguarded=CHROME.replace('if(!DF177AppTouchRecordMatches(parsed,liveProcesses,',
                          'if(DF177AppTouchRecordMatches(parsed,liveProcesses,',1)
  self.assertFalse(touch_admission_precedes_timers(unguarded))
  body=app_touch_method(CHROME)
  forged=body.replace('NSNumber *pid=[host verifiedPIDForHostedView:surface];',
                      'NSNumber *pid=parsed[@"pid"];',1)
  self.assertFalse(touch_admission_precedes_timers(CHROME.replace(body,forged,1)))
  marker='- (void)df177HandleAppTouch {'
  early=CHROME.replace(marker,marker+'\n    self.controlsUntil=1;',1)
  self.assertFalse(touch_admission_precedes_timers(early))

 def test_touch_callbacks_are_bound_to_active_chrome_session(self):
  body=app_touch_method(CHROME)
  immediate,delayed=body.split('dispatch_after(',1)
  self.assertIn('NSUInteger session=self.touch177Session.generation;',immediate)
  self.assertIn('!DF177AppTouchRecheckAllowed(owner.touch177Session,',delayed)
  self.assertIn('session,owner,DF177CurrentTouchOwner,gen,',delayed)
  self.assertLess(delayed.index('DF177AppTouchRecheckAllowed'),
                  delayed.index('[owner df177RefreshKeyboardState]'))
  start=CHROME[CHROME.index('- (BOOL)start {'):CHROME.index('CGRect cr=self.contentRect;',
          CHROME.index('- (BOOL)start {'))]
  stop=CHROME[CHROME.index('- (void)stop {'):]
  self.assertIn('DF177AppTouchBeginSession(self.touch177Session,',start)
  self.assertIn('DF177AppTouchEndSession(self.touch177Session)',stop)
  for section in (start,stop):
   self.assertIn('DF177AppTouchNextGeneration(self.touch177RecheckGeneration)',section)
  self.assertIn('if(DF177CurrentTouchOwner==self)DF177CurrentTouchOwner=nil;',stop)

 def test_keyboard_is_owned_and_unknown_state_does_not_consume(self):
  self.assertIn('verifiedPIDForHostedView:surface',CHROME)
  self.assertIn('DF177ReadKeyboardState(bundle,pid)',CHROME)
  self.assertIn('!owner.kbStateKnown177',CHROME)
  begin=CHROME.index('- (void)df177HandleKbState {')
  end=CHROME.index('- (void)df177HandleAppTouch {',begin)
  body=CHROME[begin:end]
  immediate=body.split('dispatch_async(',1)[0]
  self.assertNotRegex(immediate,r'\[\s*self\s+layoutControls\s*\]')
  self.assertIn('if(!self.kbVisible177 && self.kbStateKnown177)',body)
  self.assertNotIn('BOOL wasVisible=',body)

 def test_delayed_layout_requires_fresh_known_keyboard_state(self):
  for begin,end in (('- (void)noteUserActivity {',
                     '- (BOOL)df177RefreshKeyboardState {'),
                    ('- (void)df177HandleAppTouch {',
                     '- (void)realAppTouched:')):
   body=CHROME[CHROME.index(begin):CHROME.index(end,CHROME.index(begin))]
   delayed=body.split('dispatch_after(',1)[1]
   self.assertIn('[owner df177RefreshKeyboardState];',delayed)
   self.assertIn('if(owner.kbStateKnown177 && !owner.kbVisible177)',delayed)

if __name__ == "__main__":
 unittest.main()
