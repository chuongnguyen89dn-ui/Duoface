#!/usr/bin/env python3
"""Evidence-only compare DuoFace QA146 vs pinned public iOS CarPlay projects.
Do not execute/copy reference code. Read immutable source and method xref report.
"""
import argparse,hashlib,json,pathlib,re

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def locate(text,needle):
 match=re.search(re.escape(needle),text)
 return None if not match else text.count("\n",0,match.start())+1
def check(path,fields,strict=True):
 raw=path.read_text(encoding="utf-8")
 hits={key:{"present":locate(raw,s) is not None,"line":locate(raw,s)}
       for key,s in fields.items()}
 if strict and not all(x["present"] for x in hits.values()):
  raise AssertionError(f"Required recorded source syntax moved: {path}: {hits}")
 return {"sha256":sha(path),"bytes":path.stat().st_size,"checks":hits}
def main():
 p=argparse.ArgumentParser()
 p.add_argument("--carsurf",type=pathlib.Path,required=True)
 p.add_argument("--carplayenable",type=pathlib.Path,required=True)
 p.add_argument("--repo",type=pathlib.Path,required=True)
 p.add_argument("--original",type=pathlib.Path,required=True)
 p.add_argument("--output",type=pathlib.Path,required=True)
 args=p.parse_args()
 result={
  "scope":"static source/extracted method xrefs only",
  "runtime_claims_verified":False,
  "carplay_ios_16_7_16_device_probe":False,
  "pinned_external_commits":{
    "pavunato/carsurf":"72cd0f8bf8d0bd1086e78fe7c7be6fff715702f8",
    "EthanArbuckle/carplay-cast":"696bc72bfd0df9bea80a333e7c3307cd410f6156"},
  "source_syntax_fingerprints":{}
 }
 scripts={
 "carsurf_dash_workspace":(args.carsurf/"sbtweak/CSCarLaunch.m",{
   "actual_carplay_process":'isEqualToString:@"CarPlay"',
   "owned_workspace_type":"DBDashboardWorkspaceOwner",
   "workspace_init_owner":"initWithOwner:",
   "live_workspace_weak":"static __weak id gWorkspace",
   "native_application_controller":"DBApplicationController",
   "native_application_lookup":"applicationWithBundleIdentifier:",
   "native_request":"DBMutableWorkspaceStateChangeRequest",
   "native_activate":"activateApplication:",
   "native_state_change":"requestStateChange:",
   "native_active_readback":"activeBundleIdentifier",
   "non_native_workspace_filtered":"ignored DBWorkspace",
 }),
 "carsurf_ios16_admission":(args.carsurf/"sbtweak/CSSystem.m",{
   "ios16_17_gate":"operatingSystemVersion.majorVersion < 18",
   "scoped_launchservices":"CSInstallSceneManifestSpoof()",
   "separate_carplay_activation":"CSInstallCarLaunch()",
 }),
 "carsurf_scene_in_app":(args.carsurf/"apptweak/CSSceneBridge.m",{
   "roles_from_car":"CSIsCarSceneRole",
   "app_owns_uiwindowscene":"UIWindowSceneSessionRoleApplication",
   "scene_connected":"CSCarSceneConnected",
   "app_screen_measure":"CSCarViewportForWindow",
   "independent_scene_disconnected":"CSCarSceneDisconnected",
 }),
 "carsurf_per_app_layout":(args.carsurf/"sbtweak/CSSceneManifestSpoof.m",{
   "typed_proxy":"LSBundleProxy",
   "manifest":"UIApplicationSceneManifest",
   "carplay_role":"UIWindowSceneSessionRoleCarPlay",
   "template_hidden":"CPTemplateApplication",
 }),
 "carplayenable_native_dock_history":(args.carplayenable/"src/hooks/CarPlay.xm",{
   "apple_carplay_launch_event":"CARApplicationLaunchInfo",
   "real_history":"_currentAppHistory",
   "recent_history_transition":"_bundleIdentifierDidBecomeVisible:previousBundleIdentifier:",
   "real_dock_refresh":"_refreshAppDock",
   "real_dock_press":"_dockButtonPressed:",
   "native_event":"handleEvent:",
 }),
 "duoface_q146_own_overlay":(args.repo/"sideplay/duoface-native-scene-host/DFHomeStandalone144.m",{
   "native_selected_tap":"iconManager:launchIconForIconView:",
   "interprocess_notify":"notify_post(DF144RequestNotify)",
   "remote_springboard_host":"hostViewForBundleID:",
   "owned_window":"UIRootSceneWindow",
   "above_content_window":"UIWindowLevelNormal+1",
   "only_split_mode_false":"setSplitMode:NO",
   "pending_no_render_proof":"pending-scene",
 }),
 "duoface_q146_home_forced_stop":(args.repo/"sideplay/duoface-native-scene-host/DFCarPlayOwnerObserver.h",{
   "native_button":"homeButtonUp:",
   "forced_stop":"com.duoface.nativehost.standalone144.stop",
   "normal_home_forward":"DFOwnerDBHomeOriginal(object,sel,event)",
 })}
 for label,(path,needles) in scripts.items():
  result["source_syntax_fingerprints"][label]=check(path,needles)
 raw=json.loads(args.original.read_text())
 original=raw["references"]
 if original["duonavi"]["scanned_method_count"]!=18 or original["native12_derived"]["scanned_method_count"]!=17:
  raise AssertionError("Unexpected original project IMP counts")
 def entry(pkg,cls,name):
  rows=original[pkg]["methods"][cls]
  return next(x for x in rows if x["method"]==name)
 names=("setActivated:","setAppDockActiveBundleID:","setHomeButtonInApp:")
 bridges={}
 for pkg in ("duonavi","native12_derived"):
  row={}
  for method in ("-bridgeDidActivate:","-bridgeDidDeactivate"):
   obj=entry(pkg,"CBBridgeManagerDashboard",method)
   selectors=obj["selectors"]
   if not all(x in selectors for x in names):raise AssertionError("Missing original coupled native activation transition")
   row[method]={"original_imp":obj["imp"],
                "required_selector_sequence_observed":all(x in selectors for x in names),
                "observed_selectors":names,
                "order":{x:selectors.index(x) for x in names},
                "is_runtime_trace":False}
  bridges[pkg]=row
 result["original_dock_home_bridge_activation"]=bridges
 result["original_imp_report_sha256"]=sha(args.original)
 result["duodash_repack_limitation"]=original["duodash_repack"].get("objc_metadata_parser_limitation")
 result["verified_distinction"]={
  "qa146_is_standalone_overlay":True,
  "carsurf_has_real_dashboard_workspace_launch_path":True,
  "carplayenable_used_explicit_real_dock_history_update":True,
  "duonavi_couples_bridge_active_appdock_home_state_at_own_method_body":True,
  "no_current_device_proof":True,
  "copy_vendor_code":False,
  "no_release":True}
 args.output.parent.mkdir(parents=True,exist_ok=True)
 args.output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
 for label,record in result["source_syntax_fingerprints"].items():
  print("SOURCE_VERIFIED",label,record["sha256"],"checks",len(record["checks"]))
 for pkg,bridges in result["original_dock_home_bridge_activation"].items():
  for name,e in bridges.items():
   print("ORIGINAL_BRIDGE_ACTIVATION",pkg,name,e["original_imp"],e["order"])
 print("MULTISOURCE_HOME_DOCK_SCENE_FORENSIC_READONLY_PASS")
if __name__=="__main__":main()
