"""QA153 actual phone foreground eviction: static safety regression, NOT device acceptance."""
from pathlib import Path
import hashlib
import unittest

ROOT=Path(__file__).resolve().parents[1]
EVICT=(ROOT/"DF153PhoneEviction.h").read_text()
SOLO=(ROOT/"DFHomeStandalone144.m").read_text()
FSM=(ROOT/"DFNativePrepOnce152.h").read_text()
HOST=(ROOT/"DFSceneHost.m").read_bytes()

class PhoneNativeEviction153(unittest.TestCase):
 def test_phone_owns_request_and_gates_before_scene_creation(self):
  body=SOLO.split("static void DF144Consume(void) {",1)[1].split("__attribute__((constructor))static void DF144StartSpringBoard(void)",1)[0]
  self.assertLess(body.index("DF144ValidRequest(p,"),body.index("DF153PreparePhoneForSelectedApp(uuid,p["))
  self.assertLess(body.index("DF144Allowed(p["),body.index("DF153PreparePhoneForSelectedApp(uuid,p["))
  self.assertLess(body.index("DF153PreparePhoneForSelectedApp(uuid,p["),body.index("[DF144Owner begin:p]"))
  self.assertIn("DF144LastRequest isEqualToString:uuid",body)
  self.assertIn("DF144ValidRequest(p,NSDate.date.timeIntervalSince1970)",body)
  self.assertIn("DF144Allowed(p[",body)
  self.assertIn("DF150ReplyRejected(p)",body)
  self.assertIn('#import "DF153PhoneEviction.h"',SOLO)
 def test_phone_home_only_for_same_current_foreground(self):
  body=EVICT.split("static void DF153PreparePhoneForSelectedApp(",1)[1]
  for token in (
      'processName isEqualToString:@"SpringBoard"',
      'DF144Get(springboard,"_accessibilityFrontMostApplication")',
      'DF144Get(front,"bundleIdentifier")',
      'DF144Get(front,"processState")',
      '[bundle isEqualToString:target]',
      'DF153BoolGetter(process,"isForeground",&foreground)',
      'if(!front ||',
      'class_getClassMethod(controllerClass,sel_registerName("sharedInstance"))',
      'strcmp(method_getTypeEncoding(shared),"@16@0:8")',
      'class_getInstanceMethod(object_getClass(controller),sel_registerName("clickedMenuButton"))',
      'strcmp(method_getTypeEncoding(click),"v16@0:8")',
      'sel_registerName("clickedMenuButton")',
      'qa153-verified-phone-target-eviction'):
    self.assertIn(token,body)
  self.assertLess(body.index('[bundle isEqualToString:target]'),body.index('sel_registerName("clickedMenuButton")'))
  self.assertLess(body.index('DF153BoolGetter(process,"isForeground",&foreground)'),body.index('sel_registerName("clickedMenuButton")'))
  self.assertEqual(body.count('((void(*)(id,SEL))objc_msgSend)(controller,sel_registerName("clickedMenuButton"))'),1)
  self.assertNotIn("createRequestWithOptions:",EVICT)
  self.assertNotIn("executeTransitionRequest:",EVICT)
  self.assertNotIn("SBHomeScreenEntity",EVICT)
 def test_bounded_cancel_and_no_synthetic_activation(self):
  self.assertIn('DF152Begin(&DF153PhonePrep)',EVICT)
  self.assertIn('DF152FinishOnce(&DF153PhonePrep,generation)',EVICT)
  self.assertIn('DF152Revoke(&DF153PhonePrep)',EVICT)
  self.assertIn('0.12*NSEC_PER_SEC',EVICT)
  self.assertIn('qa153-phone-old-completion-rejected',EVICT)
  self.assertIn('qa153-phone-home-exception',EVICT)
  self.assertIn('DF153PhoneRevoke();[DF144Owner stop:@"native-Home-exit"];',SOLO)
  self.assertIn('DF153PhoneRevoke();[DF144Owner stop:@"native-app-switch"];',SOLO)
  self.assertIn('DF153PhoneRevoke();[DF144Owner stop:@"native-owner-or-consent-revoked"];',SOLO)
  self.assertIn("DF152Revoke",FSM)
  self.assertNotIn("scene-ready-and-play-verified",EVICT)
 def test_host_geometry_is_identical_baseline(self):
  blob=hashlib.sha1(b"blob "+str(len(HOST)).encode()+b"\0"+HOST).hexdigest()
  self.assertEqual(blob,"ec2924c145be4edaaa27b7320bb869b18de12c6b")
  self.assertIn("DF149Receive(&DF149Life", (ROOT/"DFNativeDockSync147.h").read_text())

if __name__=="__main__": unittest.main()
