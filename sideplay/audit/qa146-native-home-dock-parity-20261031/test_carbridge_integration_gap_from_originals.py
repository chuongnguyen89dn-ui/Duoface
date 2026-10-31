#!/usr/bin/env python3
"""Read-only, falsifiable QA146 first-party bridge vs actual DuoNavi DEB gap checks.
Never copies third-party CarBridge code, signatures, licenses or packages.
"""
import argparse,hashlib,json,pathlib
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def method(d,pkg,cl,sel):
 rows=d["original_bridges"][pkg]["methods"][cl]
 return next(x for x in rows if x["selector"]==sel)
def main():
 ap=argparse.ArgumentParser()
 ap.add_argument("--root",type=pathlib.Path,required=True)
 ap.add_argument("--original-report",type=pathlib.Path,required=True)
 ap.add_argument("--out",type=pathlib.Path,required=True)
 a=ap.parse_args()
 data=json.loads(a.original_report.read_text())
 native=a.root/"sideplay/duoface-native-scene-host"
 broker=(native/"DFHomeStandalone144.m").read_text()
 home=(native/"DFCarPlayOwnerObserver.h").read_text()
 host=(native/"DFSceneHost.m").read_text()
 build=(native/"build.sh").read_text()
 pkg=(a.root/"sideplay/jb-embedded-appbridge/package_integrated.py").read_text()
 checks={}
 for original in ("duonavi","native12_derived"):
  original_refs={
   "start":method(data,original,"CBBridgeManagerDashboard","-prepareAndRequestActivation:"),
   "activation":method(data,original,"CBBridgeManagerDashboard","-bridgeDidActivate:"),
   "deactivation":method(data,original,"CBBridgeManagerDashboard","-bridgeDidDeactivate"),
   "dock":method(data,original,"CBBridgeManagerDashboard","-setAppDockActiveBundleID:"),
   "home":method(data,original,"CBBridgeManagerDashboard","-setHomeButtonInApp:"),
   "official":method(data,original,"CBBridgeManagerDashboard","-closeOfficialTopApp:"),
   "request":method(data,original,"CBBridgeManagerDashboard","-requestStateChange:"),
   "state":method(data,original,"CBBridgeManagerDashboard","-handleStateDict:"),
  }
  required={
   "start":("pending","setPending:","prepareHomeScreenForBridge:"),
   "activation":("setActivated:","setAppDockActiveBundleID:","setHomeButtonInApp:"),
   "deactivation":("setActivated:","setAppDockActiveBundleID:","setHomeButtonInApp:"),
   "dock":("appDockVC","appHistory","_bundleIdentifierDidBecomeVisible:previousBundleIdentifier:","_refreshAppDock"),
   "home":("homeButton","setDisplayState:"),
   "official":("_foregroundActiveScene","workspace","requestStateChange:","deactivateApplication:"),
   "request":("writeToFile:atomically:","postNotificationName:object:userInfo:"),
   "state":("bridgeDidActivate:","bridgeDidDeactivate"),
  }
  for kind,words in required.items():
   loc=original_refs[kind]
   if not loc["method_located"] or not all(w in loc["selector_xrefs"] for w in words):
    raise AssertionError(original+" "+kind+" original method xref contract not proven "+str(loc))
  checks[original]={k:{"imp":v["imp"],"xrefs":list(required[k])} for k,v in original_refs.items()}
 # Negative controls: only the standalone external Home broker, not all DuoFace modules.
 assert "DF144Original(self,cmd,manager,icon);return;" in broker
 assert "notify_post(DF144RequestNotify)" in broker
 assert "UIRootSceneWindow" in broker and "UIWindowLevelNormal+1" in broker
 assert "hostViewForBundleID:self.bundle" in broker
 assert "DF144Original(self,cmd,manager,icon);" not in broker.split('// Native Apple Home remains in place')[1].split('static void DF144Install')[0]
 assert "_refreshAppDock" not in broker and "setAppDockActiveBundleID" not in broker
 assert "_bundleIdentifierDidBecomeVisible" not in broker
 assert "requestStateChange:" not in broker
 assert 'notify_post("com.duoface.nativehost.standalone144.stop")' in home
 assert 'DFOwnerDBHomeOriginal(object,sel,event)' in home
 assert "scheduledTimerWithTimeInterval:0.35" in host
 assert "[self.bundleID isEqualToString:@\"com.google.ios.youtube\"]" in host
 assert 'DFYouTubeOrientationRelay.plist' in build and 'DFGofaMapResize141.plist' in build
 assert 'DFAppViewportRelay' in pkg and "Unexpected obsolete app viewport relay" in pkg
 assert 'contains_third_party_carbridge":False' in pkg
 assert 'separate_carbridge_dependency":False' in pkg
 assert "com.leftyfl1p.carbridge" in pkg.split("EXCLUDED=")[1].split("\n")[0]
 assert 'Depends: firmware (>= 16.0), mobilesubstrate' in pkg
 checks["first_party_current_source"]={
  "direct_selected_app_native_callback_consumed":True,
  "only_external_overlay_broker_not_native_app_activation":True,
  "no_real_app_history_or_dock_refresh_in_standalone_broker":True,
  "home_only_standalone_stop_with_original_forward":True,
  "native_host_watches_scene_every_seconds":0.35,
  "youtube_only_relay_and_gofa_only_relay_in_nativehost_build":True,
  "vendor_carbridge_not_shipped":True,
  "firstparty_equivalent_not_complete":True
 }
 out={
  "evidence_scope":"Static exact selected original DEB methods + source assertions only",
  "original_imm_report_sha256":sha(a.original_report),
  "original_references":checks,
  "not_confirmed":"User QA146 real scene PID/event latency, live iOS16 original selector branches, vendor CarBridge proprietary implementation, actual native Dock state",
  "critical_correction":"Original DuoNavi also writes a state plist and posts a notification; claims that use of file+notification alone explains QA146 slowness are NOT justified.",
  "next_gate":"Instrument native app activation and native Dock/previous context, then compare physical first touch/video frame; do not publish QA147 from these static checks."
 }
 a.out.parent.mkdir(parents=True,exist_ok=True)
 a.out.write_text(json.dumps(out,ensure_ascii=False,indent=2)+"\n")
 print("QA146_EMBEDDED_CARBRIDGE_ORIGINAL_BRIDGE_AND_CURRENT_GAPS_VERIFIED")
if __name__=="__main__":main()
