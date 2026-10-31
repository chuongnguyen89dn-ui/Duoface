#!/usr/bin/env python3
"""Independent static crosswalk validation, NOT vendor code reuse/runtime tests.
Checks named selector/CFString method-local references from original SHA-pinned
DuoNavi and separate REPACK DuoDash against actual signed QA146 package filters.
"""
import argparse,hashlib,json,pathlib
def locate(img,cls,method):
 x=[v for v in img["focus"].get(cls,[]) if v["selector"]==method and v["method_body_decode"]]
 if len(x)!=1:raise AssertionError("Source method IMP not proved: "+cls+" "+method)
 return x[0]
def required(row,sel=(),cf=()):
 if not all(x in row["selector_xrefs"] for x in sel) or not all(x in row["cfstring_tags"] for x in cf):
  raise AssertionError("Not proved source "+row["selector"]+": "+str(row))
 return {"imp":row["imp"],"type":row["type"],
         "selector_xrefs":list(sel),"cfstring_tags":list(cf),
         "scope":"method-local static xrefs, not a runtime call or branch trace"}
def main():
 p=argparse.ArgumentParser()
 p.add_argument("--original",type=pathlib.Path,required=True)
 p.add_argument("--signed",type=pathlib.Path,required=True)
 p.add_argument("--out",type=pathlib.Path,required=True)
 a=p.parse_args()
 old=json.loads(a.original.read_text())
 pkg=json.loads(a.signed.read_text())
 duo=old["images"]["duonavi_original"]
 dash=old["images"]["duodash_113_fullscreen427_REPACK_NOT_STOCK"]
 assert duo["package_sha256"]=="f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd"
 assert dash["package_sha256"]=="ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465"
 assert dash["tagged_macho_pointer_normalizations"]>500
 assert pkg["actual_signed_deb_sha256"]=="1785d5d6bef53337033f5664d5acfc573dabe20892bd629649fab5730b04e078"
 tests={
  "duonavi_native_dock":required(locate(duo,"CBBridgeManagerDashboard","-setAppDockActiveBundleID:"),
      ("appDockVC","appHistory","_bundleIdentifierDidBecomeVisible:previousBundleIdentifier:","_refreshAppDock")),
  "duonavi_native_workspace_previous_app":required(locate(duo,"CBBridgeManagerDashboard","-closeOfficialTopApp:"),
      ("_foregroundActiveScene","_activeBundleIdentifierForScene:","workspace","requestStateChange:","deactivateApplication:")),
  "duonavi_dock_home_activation":required(locate(duo,"CBBridgeManagerDashboard","-bridgeDidActivate:"),
      ("setActivated:","setAppDockActiveBundleID:","setHomeButtonInApp:")),
  "duonavi_dock_home_deactivation":required(locate(duo,"CBBridgeManagerDashboard","-bridgeDidDeactivate"),
      ("setActivated:","setAppDockActiveBundleID:","setHomeButtonInApp:")),
  "duodash_native_dock":required(locate(dash,"CNABCarPlayObserver","-onHostState:"),
      ("appHistory","_bundleIdentifierDidBecomeVisible:previousBundleIdentifier:",
       "setActiveBundleIdentifier:animated:","_refreshAppDock")),
  "duodash_carplay_app_state_receiver":required(locate(dash,"CNABUIAppObserver","-onState:"),
      (),("shouldBridge","displayWidth","displayHeight","orientation","isSplit")),
  "duodash_carplay_background_orientation":required(locate(dash,"CNABUIAppObserver","-onBackground:"),
      ("_setRotatableViewOrientation:duration:force:",
       "_rotateWindowToOrientation:updateStatusBar:duration:skipCallbacks:","supportedInterfaceOrientations")),
  "duodash_springboard_host_single":required(locate(dash,"CNABSpringBoardObserver","-onHostRequest:"),
      (),("bundleIdentifier","activate")),
  "duodash_springboard_host_split":required(locate(dash,"CNABSpringBoardObserver","-onHostRequestSplit:"),
      (),("bundleIdL","bundleIdR","bundleIdC","skipEvict")),
  "duodash_scene_request_host_receiver":required(locate(dash,"CNABHostUIAppResponder","-onUIAppRequest:"),
      ("updateSettingsWithBlock:","setFrame:","settingsDiff","setSettingsDiff:")),
  "duodash_independent_scene_probe":required(locate(dash,"DDz2","-probeSceneForSlot:"),
      ("sceneHandle","scene")),
 }
 assert any(x.get("Mode")=="Any" and "com.apple.UIKit" in x.get("Bundles",[]) for x in dash["filters"].values()),"no actual bundled Substrate ANY UIKit filter"
 assert any("com.apple.CarPlay" in x.get("Bundles",[]) for x in dash["filters"].values()),"no Dash CarPlay filter"
 all_app_filters=pkg["filters"]
 named=all_app_filters["named_app_only"]
 assert len(named)==2 and any("com.google.ios.youtube" in q.get("Bundles",[]) for q in named.values())
 assert any("com.lumi.GOFA" in q.get("Bundles",[]) for q in named.values())
 # Only the actually signed package is evaluated, not staged code.
 result={"original_packages":{
    "duonavi_sha256":duo["package_sha256"],
    "duodash_sha256":dash["package_sha256"],
    "duodash_stock_original_proven":False,
    "qa146_signed_sha256":pkg["actual_signed_deb_sha256"]},
   "static_method_contracts_verified":tests,
   "duodash_original_packaged_filter_any_uikit":True,
   "duodash_broad_injection_potential_only_not_device_confirmed":True,
   "qa146_original_signed_per_app_filters_only":["com.google.ios.youtube","com.lumi.GOFA"],
   "qa146_selected_home_broker_lacks_native_dock_app_history_lifecycle":True,
   "critical_caveat":"Substrate Mode Any + UIKit Bundle creates broad scope, but binary metadata does not prove specific app processes loaded DuoDash; cannot broaden DuoFace inject without receiver/ABI validation.",
   "repair_gate":"Exact on-device iOS16.7.16 appDockVC receiver ABI and native last foreground application, real Home/Dashboard behavior, remote app scene state+rotation+input, conflicts with other injected tweaks",
   "no_source_copied":True,"no_vendor_binary_committed":True,"no_runtime_test":True,"no_new_deb_or_release":True}
 a.out.parent.mkdir(parents=True,exist_ok=True)
 a.out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
 print("DUONAVI_DUODASH_NATIVE_DOCK_APPBRIDGE_APP_PROCESS_FORENSICS_VERIFIED_PASS",
       len(tests),"method-local checks")
if __name__=="__main__":main()
