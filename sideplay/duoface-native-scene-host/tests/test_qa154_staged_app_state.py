"""QA154 source-only owner/recovery invariants; no app-side installation."""
from pathlib import Path
import hashlib
import unittest
ROOT=Path(__file__).resolve().parents[1]
PUB=(ROOT/"DFHomeStandalone144.m").read_text()
API=(ROOT/"DF154AppStateProtocol.h").read_text()
RELAY=(ROOT/"DF154GeneralAppStateRelay.m").read_text()
BUILD=(ROOT/"build.sh").read_text()
FROZEN=(ROOT/"DFSceneHost.m").read_bytes()

class GenericStateStaging(unittest.TestCase):
 def test_real_live_scene_and_owned_identity_before_publish(self):
  sub=PUB.split("- (void)publishGeneralAppState:(BOOL)active {",1)[1].split("- (NSNumber *)verifiedProcessStatePIDForView:",1)[0]
  for token in ("isLiveSceneForHostedView:self.surface","bundleIDForHostedView:self.surface",
                'DF144Get(self.surface,"scene")','DF144Get(remoteScene,"identifier")',
                'DFHostedLogicalSizeForBundle','"requestID":self.request','"owner":self.generalOwner'):
   self.assertIn(token,sub)
  self.assertLess(sub.index("isLiveSceneForHostedView:self.surface"),sub.index("DF154Post(state)"))
  self.assertIn("[self publishGeneralAppState:NO];",PUB)
  self.assertIn("DF144Owner publishGeneralAppState:YES",PUB)
 def test_short_lease_restore_and_no_device_wide_changes(self):
  self.assertIn("NSDistributedNotificationCenter",API)
  self.assertIn("age>3.0",API)
  self.assertIn('window.windowScene!=target',RELAY)
  self.assertIn('window.windowLevel!=UIWindowLevelNormal',RELAY)
  for x in ('owner-terminal','lease-expired','owner-replaced','window.frame=original.frame'):
   self.assertIn(x,RELAY)
  self.assertNotIn("setInterfaceOrientation:",RELAY)
 def test_generic_receiver_not_in_build(self):
  self.assertNotIn("DF154GeneralAppStateRelay.m",BUILD)
 def test_frozen_host_unmodified(self):
  sha=hashlib.sha1(b"blob "+str(len(FROZEN)).encode()+b"\0"+FROZEN).hexdigest()
  self.assertEqual(sha,"ec2924c145be4edaaa27b7320bb869b18de12c6b")

if __name__=="__main__":
 unittest.main()
