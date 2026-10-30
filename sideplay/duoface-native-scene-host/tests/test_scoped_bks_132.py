"""QA132 independent BKS original-first owner-scoped screen policy; static fail-closed contracts.

Physical YouTube Play acceptance MUST be measured on parked iPhone; SDK compile
is separate. Never assert this test proves user-device security or rendering.
"""
from pathlib import Path
import unittest
SRC=(Path(__file__).resolve().parents[1]/"DFTouchOwnerProbe.m").read_text()

class BKSOriginalFirst(unittest.TestCase):
 def test_exact_symbol_and_runtime_provider(self):
  self.assertIn('dlsym(RTLD_DEFAULT,"BKSDisplayServicesSetScreenBlanked")',SRC)
  self.assertIn('"MSHookFunction"',SRC)
  self.assertIn('DFOriginalScreenBlank132',SRC)
  self.assertIn('sDFBKSOriginal132=(DFScreenBlankFn132)trampoline;',SRC)
  self.assertIn('sDFBKSOriginal132=(DFScreenBlankFn132)original;',SRC)
 def test_original_always_first_even_when_owned(self):
  x=SRC[SRC.index('static void DFOriginalScreenBlank132(int blanked) {'):]
  self.assertLess(x.index('original(blanked);'),x.index('if(blanked!=1)return;'))
  self.assertIn('DFMaybeRestoreDisplay132(@"system-blank")',x)
 def test_bounded_lock_and_valid_native_carplay_owner(self):
  start=SRC.index('static BOOL DFActiveHostedLockedPane132(void) {')
  end=SRC.index('static void DFMaybeRestoreDisplay132',start)
  x=SRC[start:end]
  for k in ('!NSThread.isMainThread','!sChrome','!sActivated','!sSession',
            '!DFSessionStillActive()','!DFConnectedCarDisplay()',
            'snapshot[@"RunningScenes"]','[snapshot[@"RunningScenes"] integerValue]<1',
            '[snapshot[@"StartupActive"] boolValue]',
            'UIApplication.sharedApplication.protectedDataAvailable'):
   self.assertIn(k,x)
 def test_delayed_rechecks_no_unbounded_loops(self):
  x=SRC[SRC.index('static void DFMaybeRestoreDisplay132(NSString *cause) {'):]
  for k in ('sDFBKSPending132','sDFBKSUnblanked132',
            'dispatch_after(','0.8*NSEC_PER_SEC','serial!=sDFBKSSerial132',
            'generation!=sGeneration','![session isEqualToString:sSession]',
            '!DFActiveHostedLockedPane132()', 'sDFBKSOriginal132(0);'):
   self.assertIn(k,x)
 def test_home_and_disconnect_restore(self):
  start=SRC.index('static void DFStopProbe(NSString *reason) {')
  stop=SRC[start:]
  self.assertLess(stop.index('DFReleaseScopedBlankPolicy132();'),
                  stop.index('[sChrome hideAllExternalWindowsImmediately]'))
  x=SRC[SRC.index('static void DFReleaseScopedBlankPolicy132(void) {'):start]
  self.assertIn('++sDFBKSSerial132;',x)
  self.assertIn('sDFBKSOriginal132(1);',x)
  self.assertIn('[sDFBKSSession132 isEqualToString:sSession]',x)
  self.assertIn('!UIApplication.sharedApplication.protectedDataAvailable',x)
  self.assertIn('DFStopProbe(@"native-home-button")',SRC)
  self.assertIn('DFStopProbe(@"nativehost-disconnected")',SRC)
 def test_no_unlock_or_global_brightness(self):
  for forbidden in ('setUILocked:', 'setBrightness:', 'setIdleTimerDisabled:',
                    'CFSTR("PreventUserIdleDisplaySleep")',
                    'BKSDisplayServicesSetScreenBlanked(0);',
                    'sendEvent:', 'IOHIDEventCreateDigitizer'):
   self.assertNotIn(forbidden,SRC)

if __name__=="__main__": unittest.main()
