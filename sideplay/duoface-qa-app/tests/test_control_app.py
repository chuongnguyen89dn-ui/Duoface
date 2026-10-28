import pathlib, plistlib, unittest
P=pathlib.Path(__file__).resolve().parents[1]
def read(p):return (P/p).read_text()
class DuoFaceQACtrl(unittest.TestCase):
 def test_real_app_bundle_and_rootless_deb(self):
  p=plistlib.loads((P/"Info.plist").read_bytes())
  self.assertEqual(p["CFBundleIdentifier"],"com.duoface.qa.control")
  self.assertEqual(p["CFBundleExecutable"],"DuoFaceQA")
  self.assertEqual(p["CFBundlePackageType"],"APPL")
  c=read("control")
  self.assertIn("Package: com.duoface.qa.controlapp",c)
  self.assertIn("Version: 0.1.9~mapowner1",c)
  self.assertIn("com.duoface.carplay.sbadmissionprobe",c)
  self.assertIn("com.duoface.carplay.firstpartyadmission",c)
  self.assertIn("com.duoface.carplay.nativescenehost",c)
  self.assertIn("com.duoface.carplay.nativejoinprobe",c)
  self.assertIn("0.0.5~controlapp1",c)
  self.assertNotIn("Conflicts:",c)
  self.assertNotIn("Replaces:",c)
  self.assertIn("/var/jb/Applications/DuoFaceQA.app",read("build.sh"))
  self.assertIn('uicache',read("postinst"))
  self.assertNotIn("sbreload",read("postinst"))
  self.assertNotIn("killall",read("postinst"))
 def test_working_controls_not_mockups(self):
  s=read("DFQARootController.m")
  for required in ["UIStackView","UIScrollView","UISwitch",
                   "UISegmentedControl","DuoFace QA","baseChanged:",
                   "bridgeChanged:","trialChanged:","geometryChanged:",
                   "stopTrial:","shareLog:",'@"Enabled"',
                   '@"NativeSidebarTrial"','@"HostFullscreen"',
                   "DFWriteFlag(","DFFresh(","DFLastLines(",
                   "UIActivityViewController","source[@","surface[@",
                   "writeToFile:path atomically:YES"]:
   if required=="source[@":continue
   self.assertIn(required,s)
  self.assertIn("DuoFaceNativeBridgeQA.log",s)
  self.assertIn("DuoFaceNativeSceneJoin.log",s)
  self.assertIn("DuoFaceCarPlayOwnerSnapshot.log",s)
  self.assertIn("shareMapsOwnerLog:",s)
  self.assertIn("copyItemAtPath:DFMapsOwnerLog",s)
  self.assertIn("fileURLWithPath:tmp",s)
  self.assertIn("DuoFaceSBAdmissionProbe.log",s)
  self.assertIn("DuoFaceFirstPartySpringBoard.log",s)
  self.assertIn("SpringBoard first-party roster",s)
  self.assertIn("có hook SpringBoard VÀ CarPlay",s)
  self.assertIn("DuoFaceFirstPartyAdmission.log",s)
  self.assertIn("enableFirstParty:",s)
  self.assertIn("disableFirstParty:",s)
  self.assertIn('CFSTR("com.duoface.firstparty-admission.refresh")',s)
  self.assertIn("DFAdmissionSignal,NULL,NULL,YES",s)
  self.assertIn("0.0.6~sbpair1",read("control"))
  self.assertIn("0.0.1~readonly1",read("control"))
  for label in ("startAdmissionTrace:","stopAdmissionTrace:","DuoFaceAdmissionTrace.log",
                "com.duoface.admission-trace.request.plist","AuditOnly",
                "DFTraceStatus", "DFTraceDisable"):
   self.assertIn(label,s)
  self.assertIn("runRosterProbe:",s)
  self.assertIn("DFRosterSignal,NULL,NULL,YES",s)
  self.assertIn("com.duoface.firstparty-roster.request.plist",s)
  self.assertIn("DFLastLines(DFAdmissionLog,80)",s)
  for required in ("DFTraceStatus","DFTraceSignal","traceReadinessLabel",
                   "readyAck","hookReady","CHƯA SẴN SÀNG","integerValue]==5"):
   self.assertIn(required,s)
  self.assertNotIn('@"Kind":@"consolidated-target",',s[s.index("- (void)startAdmissionTrace:"):s.index("- (void)runRosterProbe:")])
  self.assertIn('sb[@"Enabled"]=@NO',s)
  self.assertIn('sbStopped=[sb writeToFile:DFSBRequest atomically:YES]',s)
  self.assertIn('if(!(written&&killed&&sbStopped))',s)
  self.assertIn("runSBAdmissionProbe:",s)
  self.assertIn("CFNotificationCenterPostNotification",s)
  self.assertIn("DFLastLines(DFSBLog,120)",s)
  self.assertIn("com.duoface.native-scene-owner.v1.plist",s)
  self.assertIn('self.nativeSceneLabel.text',s)
  self.assertIn('DFLastLines(DFSceneProbeLog,120)',s)
  self.assertIn("Không ghi được",s)
  self.assertIn("ACK không phải",s)
  for forbidden in ("system(","execv(","LSBundleProxy",
                    "method_setImplementation","sbreload",
                    "objc_addLoadImageFunc","FBSDisplayConfiguration"):
   self.assertNotIn(forbidden,s)
 def test_no_automatic_risky_flags_on_install(self):
  for p in ["postinst","prerm"]:
   s=read(p)
   for flag in ("NativeSidebarTrial", "HostFullscreen", "Enabled=true",
                "launchctl","ldrestart","killall"):
    self.assertNotIn(flag,s)
  en=plistlib.loads((P/"entitlements.plist").read_bytes())
  self.assertTrue(en["com.apple.private.security.no-container"])
  self.assertFalse(en["com.apple.private.security.container-required"])
  self.assertNotIn("task_for_pid-allow",en)
 def test_rootless_script_and_rollback(self):
  s=read("build.sh")
  self.assertIn("arm64-apple-ios16.0",s)
  self.assertIn("ldid -Sentitlements.plist",s)
  self.assertIn("dpkg-deb --build",s)
  self.assertIn("Info.plist",s)
  self.assertIn("generate_icon.swift",s)
 def test_bridge_accepts_app_mode_not_split_slot_zoom(self):
  qa=(P/"../mytweak-native-bridgeqa/DFCPNativeBridgeQA.m").read_text()
  self.assertIn("qa-control-app-fullscreen-mode",qa)
  self.assertIn('cfg[@"HostFullscreen"]=@(next)',qa)
  self.assertIn("MTCPBridgeWriteHostFullscreen(self.publisher.session,self.wholeHostFullscreen)",qa)
  self.assertNotIn("LSBundleProxy",qa)
if __name__=="__main__":unittest.main(verbosity=2)
