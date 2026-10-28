#!/usr/bin/env python3
"""Read-only comparison of pinned ORIGINAL OmniCar DEB map/scene capabilities.
No extraction or redistribution of vendor source/binary is included in report.
Run on Ubuntu with dpkg-deb, strings; preserves only hashes, selector occurrences,
filter metadata and first-party DuoFace scene-policy source evidence.
"""
import argparse, hashlib, json, pathlib, plistlib, re, subprocess, tempfile
EXPECTED="d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd"
KEYS={
 "map_bundle_ids":["com.apple.Maps","com.google.Maps","com.google.maps","com.waze.iphone"],
 "native_carplay_navigation":["CPMapTemplate","CPTemplateApplicationScene","CPWindow","MKMapView","CPNavigationSession"],
 "maps_navigation":["mapView","navigation","routeGuidance","displayMap","mapContent"],
 "bridge":["appBridgeZoom","appBridgeOrientation","effectiveOrientation:","requestedOrientation","layoutPane:","sceneBox","setSceneBox:","sceneHandle","sceneIfExists","updateSettingsWithBlock:","setInterfaceOrientation:","SBSceneView"],
 "carplay":["SCPCarSplit","SCPCarPane","CarPlay","Dashboard","CARApp"]
}
def run(*args):return subprocess.run(args,check=True,text=True,capture_output=True).stdout
def main():
 p=argparse.ArgumentParser()
 p.add_argument("--omnicar",type=pathlib.Path,required=True)
 p.add_argument("--source",type=pathlib.Path,required=True)
 p.add_argument("--out",type=pathlib.Path,required=True)
 a=p.parse_args()
 raw=a.omnicar.read_bytes();sha=hashlib.sha256(raw).hexdigest()
 if sha!=EXPECTED:raise RuntimeError("original OmniCar SHA mismatch "+sha)
 with tempfile.TemporaryDirectory() as td:
  folder=pathlib.Path(td);run("dpkg-deb","-x",str(a.omnicar),str(folder))
  meta={k:run("dpkg-deb","-f",str(a.omnicar),k).strip() for k in ("Package","Version","Architecture")}
  binaries=[]; injection=[]
  for path in sorted(folder.rglob("*")):
   if not path.is_file():continue
   relative=path.relative_to(folder).as_posix()
   if path.suffix.lower()==".plist":
    try:
     v=plistlib.loads(path.read_bytes())
     if isinstance(v,dict) and "Filter" in v:injection.append({"path":relative,"filter":v["Filter"]})
    except Exception:pass
   if path.suffix.lower()!=".dylib" and not (binaries==[] and path.name.endswith(".app")):continue
   values=run("strings","-a",str(path)).splitlines()
   hay=set(values)
   findings={}
   for group,keys in KEYS.items():
    findings[group]=[{"literal":key,"count":sum(key in line for line in values),
                       "exact":key in hay} for key in keys]
   binaries.append({"path":relative,"sha256":hashlib.sha256(path.read_bytes()).hexdigest(),"size":path.stat().st_size,"markers":findings})
 src=a.source.read_text()
 result={
  "status":"READ_ONLY_STATIC_DEB_SELECTOR_SCAN_NOT_DEVICE_MAP_RENDER_PROOF",
  "input":{"sha256":sha,"bytes":len(raw),"control":meta},
  "original_payload_modules":binaries,
  "original_injection_filters":injection,
  "duoface_current_source":{
   "file":"sideplay/duoface-native-scene-host/DFSceneHost.m",
   "host_main_display_scene":'initWithApplicationForMainDisplay:' in src,
   "reference_size_fixed_double":'CGSizeMake(round(size.width*2),round(size.height*2))' in src,
   "no_orientation_only_transaction":'setInterfaceOrientation:' not in src,
   "early_registration":src.find('DFSceneOrientationPolicyRegister(')<src.find('DFHostInt(self.appController, @"setRequestedMode:", 2)') if 'DFSceneOrientationPolicyRegister(' in src else False
  },
  "known_original_ARM64_control_flow_from_sha_pinned_previous_audit":{
   "ABHost.zoom":"0xae20..0xae90 reads appBridgeZoom/100 clamps 0.6..1.0",
   "ABHost.layoutPane":"0xed74..0xed80 logical=bounds/zoom, 0xedac transform zoom, 0xf074 sceneBox physical bounds",
   "ABHost.layoutPane scene transaction":"0xf248 setFrame, 0xf280 setInterfaceOrientation, 0xf2b8 background 0, 0xf30c foreground 1",
   "references":"Omnicar/audit/OmniCar_AppBridge_exact_scene_settings_and_layout_20261023.md and audit/omnicar_native12_verified_layout_policy_20261023.json"
  },
  "limits":[
   "Missing selector literal does not prove absent behavior: original code may use dynamic names, encrypted assets, system APIs",
   "Presence of literal proves only static binary metadata, not that live Maps uses that method",
   "Original navigation/Google Maps CarPlay CPWindow may be owned by Apple/Google scene and cannot be equated with phone-main-display hosted scene",
   "No vendor binary retained in this report; no licensing logic copied",
   "Do not force CPMapTemplate or imitate another application's entitlement to render its native CarPlay map"
  ]
 }
 a.out.parent.mkdir(parents=True,exist_ok=True)
 a.out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
 print("PASS original OmniCar map/scene static selector audit",len(binaries),"binary modules",len(injection),"injection filters","source header main display=",result["duoface_current_source"]["host_main_display_scene"])
if __name__=="__main__":main()
