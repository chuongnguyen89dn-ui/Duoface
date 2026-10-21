from pathlib import Path
import plistlib,subprocess,sys,unittest
P=Path(__file__).resolve().parents[1]
ROOT=P.parent
def get(file):return (P/file).read_text()
class Gate1Safety(unittest.TestCase):
 def test_unique_isolated_dpkg(self):
  c=get("control")
  self.assertIn("Package: com.duoface.carplay.gate1smoke",c)
  self.assertIn("Version: 0.0.7~fbsquery1",c)
  self.assertIn("iphoneos-arm64",c)
  for x in ("Conflicts:","Replaces:","Breaks:","Provides:","com.duonavi","com.duoface.independent"):
   self.assertNotIn(x,c)
 def test_scene_is_properly_declared(self):
  p=plistlib.loads((P/"Info.plist").read_bytes())
  self.assertEqual(p["CFBundleIdentifier"],"com.duoface.gate1smoke")
  self.assertEqual(p["CFBundleExecutable"],"DuoFaceGate1")
  self.assertIn("UIWindowSceneSessionRoleCarPlay",p["UIApplicationSceneManifest"]["UISceneConfigurations"])
  for x in ("GATE1_CARPLAY_SCENE_CONNECTED","initWithWindowScene:ws","makeKeyAndVisible"):
   self.assertIn(x,get("Gate1App.m"))
  for forbidden in ("UIRootSceneWindow","FBSDisplayConfiguration","IOHIDEvent","GSEvent"):
   self.assertNotIn(forbidden,get("Gate1App.m"))
 def test_default_off_auto_expiry_and_kill_switch(self):
  app=get("Gate1App.m")
  for marker in ('GATE1_MODE=MANUAL_NO_TIMEOUT','Disable();','com.duoface.gate1smoke.refresh',
                 '.duoface-gate1smoke-disable', 'com.duoface.gate1smoke',
                 'RiskAcknowledged','enable-refused'):
   self.assertIn(marker,app)
  for f in ("postinst","prerm","postrm"):
   script=get(f)
   for forbidden in ("killall","sbreload","ldrestart","launchctl","dpkg --remove","apt remove",
                     "rm -rf","com.duoface.independent"):
    self.assertNotIn(forbidden,script)
  self.assertIn(".duoface-gate1smoke-disable",get("postinst"))
  self.assertIn(".duoface-gate1smoke-disable",get("prerm"))
  self.assertIn("uicache",get("postinst"))
  self.assertIn(".duoface-gate1smoke-paused-old",get("prerm"))
 def test_enable_button_reports_exact_failure_and_restores_legacy(self):
  app=get("Gate1App.m")
  for marker in ("OldGateActive(void)","kOldKill","kPauseMarker",
       "enable-refused-reason=","cannot-write-gate1-preferences",
       "cannot-pause-legacy-gate","cannot-remove-gate1-kill-file",
       "gate1-preferences-readback-failed","RestoreLegacyGate",
       "GATE1_MODE=MANUAL_NO_TIMEOUT","Tạm khóa gate cũ và BẬT"):
   self.assertIn(marker,app)
  self.assertNotIn("enable-refused (old gate enabled or preferences denied)",app)
  self.assertNotIn("TTL_REMAINING",app)
 def test_runtime_one_shot_diagnostic_scope(self):
  p=get("Gate1RuntimeProbe.m")
  for term in ("RequestID","AuditOnly","age>45","LSApplicationProxy",
     "DBApplicationController","HookReady","OWN_APP_MISSING_FROM_ROSTER",
     "CARPLAY_PROCESS_ONLY","NOT_PROBED_WITHOUT_VERIFIED_VEHICLE"):
   self.assertIn(term,p)
  for forbidden in ("setIconState:forVehicleID:","requestStateChange:",
      "_loadApplicationWithInfo:","killall","sbreload"):
   self.assertNotIn(forbidden,p)
  self.assertIn("Gate1RuntimeProbe.m",get("Makefile"))
  self.assertIn("DFGate1CarPlayHooksReady",get("prepare.py"))
  self.assertIn("DFGate1SpringBoardHooksReady",get("prepare.py"))
  self.assertIn("KIỂM TRA ĐĂNG KÝ",get("Gate1App.m"))
 def test_new_roster_bridge_is_one_bundle_and_opt_in(self):
  s=get("Gate1RosterBridge.m")
  for marker in ('com.duoface.gate1smoke','FBSApplicationLibrary',
                 'allInstalledApplications','DBApplicationController',
                 '_loadApplicationWithInfo:','_didAddApplications:',
                 'DFConsent','DFMatches','RequestID','roster-apply'):
   self.assertIn(marker,s)
  for forbidden in ('setIconState:forVehicleID:','requestStateChange:',
                    'killall','sbreload','com.pavunato.carsurf'):
   self.assertNotIn(forbidden,s)
  self.assertIn("Gate1RosterBridge.m",get("Makefile"))
  self.assertIn("THỬ HIỆN TRÊN CARPLAY",get("Gate1App.m"))
  self.assertIn("runAdmission",get("Gate1App.m"))
 def test_ios16_fbs_refresh_when_db_controller_missing(self):
  bridge=get("Gate1RosterBridge.m")
  for required in ('FBSApplicationInfo','DFTrackLibrary(owner)','weakObjectsHashTable',
      'DFRefreshFBS(nonce);return;', 'FBS_OWN_APP_RETURNED_NOT_HOME_VERIFIED',
      'FBS_NO_LIVE_LIBRARY_SEEN_RECONNECT_CARPLAY',
      'FBS_INVALIDATE_ABI_UNAVAILABLE', 'DFMatches([library class],"invalidate",NO'):
    self.assertIn(required,bridge)
  self.assertNotIn('if(!c){DFReport(nonce,@"DASHBOARD_CONTROLLER_NOT_LOADED"',bridge)
  self.assertNotIn('setIconState:forVehicleID:',bridge)
  app=get("Gate1App.m")
  self.assertGreater(app.rindex('--- THỬ ĐƯA VÀO CARPLAY ---'),
                     app.index('--- KẾT QUẢ ĐĂNG KÝ (CHỈ ĐỌC) ---'))
  self.assertIn("FBS refreshed=",app)
 def test_device_zero_query_fix_enumerates_real_fbs_instance(self):
  code=get("Gate1RosterBridge.m")
  self.assertIn('((void(*)(id,SEL))objc_msgSend)(library,invalidate)',code)
  self.assertIn('((id(*)(id,SEL))objc_msgSend)(library,all)',code)
  self.assertIn('DFMatches([library class],"allInstalledApplications",NO',code)
  self.assertIn('FBS_QUERY_NO_OWN_APP',code)
  self.assertIn('FBS_OWN_APP_RETURNED_NOT_HOME_VERIFIED',code)
  self.assertIn('FBSInfoResult',code)
  self.assertIn('FBS_OWN_APP_RETURNED_NOT_HOME_VERIFIED',code)
  self.assertIn('InfoResult=%@',get("Gate1App.m"))
  self.assertIn('ownReturned=%@',get("Gate1App.m"))
  for unsafe in ('setIconState:forVehicleID:', 'killall', 'sbreload', 'requestStateChange:'):
   self.assertNotIn(unsafe,code)
 def test_scope_generates_only_our_gate(self):
  subprocess.run([sys.executable,str(P/"prepare.py")],check=True)
  for f in ("Gate1CarPlay.m","Gate1SpringBoard.m"):
   src=(P/".generated"/f).read_text()
   for key in ("com.duoface.gate1smoke","oldEffective",
               "com.duoface.gate1smoke.refresh",".duoface-gate1smoke-disable"):
    self.assertIn(key,src)
   self.assertEqual(src.count("com.duoface.native.scenehost"),1) # read-only old gate check
   self.assertNotIn("com.duoface.firstparty-admission.refresh",src)
  self.assertIn("gate1-smoke-SpringBoard-loaded", (P/".generated"/"Gate1SpringBoard.m").read_text())
  p=plistlib.loads((P/"DFGate1SmokeAdmission.plist").read_bytes())
  self.assertEqual(p["Filter"]["Executables"],["SpringBoard","CarPlay"])
 def test_no_vendor_modules_or_duplicate_app(self):
  src=get("build.sh")
  self.assertIn('python3 prepare.py',src)
  self.assertIn('make clean package FINALPACKAGE=1',src)
  self.assertIn('-Wl,-headerpad,0x1000',src)
  self.assertIn('verify_macho.py',src)
  self.assertIn('DuoFaceGate1.app',src)
  self.assertIn('DFGate1SmokeAdmission.dylib',src)
  self.assertIn("test -s",src)
  for key in ("DuoDash","Duonavi","CBLicense","CarBridge.dylib"):
   self.assertNotIn(key,src)
if __name__=="__main__": unittest.main(verbosity=2)
