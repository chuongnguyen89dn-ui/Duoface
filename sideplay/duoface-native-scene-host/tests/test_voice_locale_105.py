"""Check first-party user initiated one-shot speech, real settings and package entry."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text(encoding="utf8")
class VoiceAndLocale105(unittest.TestCase):
 def test_explicit_consent_and_voice_permissions(self):
  voice=read("DFVoiceAssistant.m")
  ui=read("DFNativeHostRootController.m")
  info=read("Info.plist")
  build=read("build.sh")
  self.assertIn("requestAuthorization:",voice)
  self.assertIn("requestRecordPermission:",voice)
  self.assertIn("AVAudioInputNode",voice)
  self.assertIn("recognitionTaskWithRequest:",voice)
  self.assertIn("12*NSEC_PER_SEC",voice)
  self.assertIn("toggleFromController:owner",ui)
  self.assertIn("Hãy dừng xe",ui)
  self.assertIn("NSSpeechRecognitionUsageDescription",info)
  self.assertIn("NSMicrophoneUsageDescription",info)
  self.assertIn("-framework Speech",build)
  self.assertIn("-framework AVFoundation",build)
  self.assertIn("DFVoiceAssistant.m",build)
  self.assertNotIn("DFVoiceAssistant.m",read("DFTouchOwnerProbe.m"))
 def test_uses_first_party_device_locale_and_voice_tts(self):
  voice=read("DFVoiceAssistant.m")
  phone=read("DFNativeHostRootController.m")
  picker=read("DFAppPickerVC.m")
  prefs=read("DFExtendedSettingsPolicy.h")
  for token in ('@"vi"', '@"en"', "DFSaveExtendedLanguage",
                "DFLocalize", "DFExtendedPrefsPath", "notify_post"):
   self.assertIn(token,prefs)
  self.assertIn("showLanguageOptions",phone)
  self.assertIn("DFSaveExtendedLanguage(lang)",phone)
  self.assertIn('@"vi-VN"',voice)
  self.assertIn('@"en-US"',voice)
  self.assertIn("AVSpeechSynthesizer",voice)
  self.assertIn("DFLocalize(",picker)
 def test_no_system_voiceloop_or_carplay_foreground_mutation(self):
  voice=read("DFVoiceAssistant.m")
  for token in ("SBUIController","activateApplication:","setForeground:",
                "turnOffScreenFully","performSelector:","startMonitoringSignificantLocationChanges"):
   self.assertNotIn(token,voice)
  self.assertIn("self.listening=YES",voice)
  self.assertIn("self.listening=NO",voice)
  self.assertIn("generation!=owner.generation",voice)
 def test_native_map_reflows_only_with_bound_session_and_owner(self):
  maps=(ROOT.parent/"native-carplay-scene-v1"/"DFNativeMapPaneCoordinator.m").read_text()
  self.assertIn("refreshAdoptedNativeMapBounds",maps)
  self.assertIn("self.invalidFrameTicks>=6",maps)
  self.assertIn("self.boundSession",maps)
  self.assertIn("DFPhysicalMapVerifyPane(physical,session,plan",maps)
  self.assertIn("self.pane.frame=next;",maps)
  self.assertIn("[self restore:&reason]",maps)
  self.assertNotIn("CGAffineTransformMakeScale",maps)
 def test_phone_manual_diagnostic_exports_actual_native_maps_evidence(self):
  exporter=read("DFNativeDiagnostics.m")
  for required in ("DuoFaceNativeMapPane.log", "map-pane.ack.v1.plist",
                   "physical-panes.v1.plist", "PhysicalSlot",
                   "HasLiveApp", "Native Maps pixels and actual route continuation"):
   self.assertIn(required,exporter)
  self.assertNotIn("mapAck[@\"RequestID\"]",exporter)
 def test_package_has_new_version_and_privacy(self):
  build=read("build.sh")
  control=read("control")
  info=read("Info.plist")
  for s in ("0.1.107~iphone-only-divider92","DFNativeMapPaneCoordinator.m"):
   self.assertTrue(s in build or s in control)
  self.assertIn("Version: 0.1.107~iphone-only-divider92",control)
  self.assertIn("0.1.107",info)
if __name__=="__main__":unittest.main(verbosity=2)
