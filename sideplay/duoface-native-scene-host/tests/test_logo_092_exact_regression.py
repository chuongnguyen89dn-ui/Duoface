"""Guard user-requested exact .92 three-second logo behavior in future builds."""
import hashlib
from pathlib import Path
import unittest
BASE=Path(__file__).resolve().parents[1]
def git_blob(path):
 data=(BASE/path).read_bytes()
 return hashlib.sha1(b"blob "+str(len(data)).encode()+bytes([0])+data).hexdigest()
class Logo92SourcePin(unittest.TestCase):
 def test_original_092_logo_chrome_exact(self):
  self.assertEqual(git_blob("DFNative12Chrome.m"),"367689325f6ff84d8d258ff9891ec85338a7d647")
 def test_original_092_gate_exact(self):
  self.assertEqual(git_blob("DFLogoHoldGate.h"),"a4ed2919cdf0b6482bf4a08c55a8050683b702b9")
 def test_three_second_raw_contact_source_contract(self):
  s=(BASE/"DFNative12Chrome.m").read_text()
  for token in ("logoTouchDown:","logoTouchChanged:","logoTouchFinished:","DFLogoHoldAdvance(","logoTouchPending=YES"):
   self.assertIn(token,s)
if __name__=="__main__":unittest.main()
