#!/usr/bin/env python3
"""Read-only original OmniCar 1.0.3 FULL native split method survey vs DuoFace .90.

SHA-pinned original DEB + independent source + real CarPlay owner snapshots.
Contains no original code/license, no runtime hooks and no speculative map scaling.
"""
import argparse,collections,hashlib,json,re,subprocess,tempfile
from pathlib import Path
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
from audit_omnicar_native_maps_dispatch_20261028 import SHA,arm64_fat,original_methods
from audit_original_omnicar_native_map_cfstrings_v2 import cfstring

EXPECTED_IMPS={
 ("SCPCarSplit","isCarPlayApp:"):0xff20,
 ("SCPCarSplit","openApp:slot:"):0x164d4,
 ("SCPCarSplit","hostApp:inPane:"):0x3e490,
 ("SCPCarSplit","adopt:slot:"):0x1942c,
 ("SCPCarSplit","sceneOfViewController:"):0x1aaf4,
 ("SCPCarSplit","pushSceneSizes"):0x1c550,
 ("SCPCarSplit","paneSize:forBundle:"):0x1b328,
 ("SCPCarSplit","publishCarPlayApps"):0x21b1c,
 ("SCPCarSplit","scene:destroyedForViewController:ownScene:"):0x1ad58,
 ("SCPHostedAppVC","sceneHostView"):0xfdbc,
}
# Group names describe responsibilities, NOT which runtime branch was taken.
GROUPS={
 "native-carplay-admission":r"isCarPlayApp|publishCarPlayApps|openApp:slot|showPickerForSlot|appBridge|CarPlay",
 "native-scene-owner":r"adopt|sceneOfViewController|scene:destroyed|verifyScene|pushSceneSizes|foregroundScene|backgroundScene|handle|host",
 "split-geometry":r"layout|frame|paneSize|sceneSize|bounds|fraction|divider|ratio|rebuildDividers|normalizeFractions",
 "split-input-controls":r"touch|Tapped|Pressed|showBar|setBarVisible|hideBar|toggleBar|hitTest|gestur|drag|Pan:",
 "split-solo-focus":r"solo|Solo|zoom|Zoom|swap|Swap|focused|focus|closeSlot|removePane|reopen|remembered",
 "app-roster-picker":r"picker|Picker|launcher|Launcher|appList|AppList|running|Running|tab|Tab|icon|Icon",
 "lifecycle-background":r"background|Background|foreground|Foreground|destroy|terminate|launch|Launch|watchdog|Timer|timer",
 "startup-appearance":r"startup|Startup|theme|Theme|color|Color|logo|Logo|wall|Wall|splash|Splash",
}
# Explicit OWN source bridge contract, intentionally distinct from a method port.
CURRENT={
 "native-carplay-admission":["sideplay/duoface-native-scene-host/DFAppPickerVC.m",
    "sideplay/duoface-native-scene-host/DFSceneHost.m"],
 "native-scene-owner":["sideplay/native-carplay-scene-v1/DFCarPlayLiveOwnerSnapshot.m",
    "sideplay/duoface-native-scene-host/DFCarPlayDockOwner.m",
    "sideplay/duoface-native-scene-host/DFSceneHost.m",
    "sideplay/duoface-native-scene-host/DFSceneLifecycle.m"],
 "split-geometry":["sideplay/duoface-native-scene-host/DFNative12Chrome.m",
    "sideplay/duoface-native-scene-host/DFSceneHost.m",
    "sideplay/duoface-native-scene-host/DFDividerDrag.h"],
 "split-input-controls":["sideplay/duoface-native-scene-host/DFNative12Chrome.m",
    "sideplay/duoface-native-scene-host/DFTouchOwnerProbe.m"],
 "split-solo-focus":["sideplay/duoface-native-scene-host/DFNative12Chrome.m",
    "sideplay/duoface-native-scene-host/DFSceneHost.m"],
 "app-roster-picker":["sideplay/duoface-native-scene-host/DFAppPickerVC.m",
    "sideplay/duoface-native-scene-host/DFNative12Chrome.m"],
 "lifecycle-background":["sideplay/duoface-native-scene-host/DFSceneLifecycle.m",
    "sideplay/duoface-native-scene-host/DFSceneHost.m"],
 "startup-appearance":["sideplay/duoface-native-scene-host/DFNative12Chrome.m",
    "sideplay/duoface-native-scene-host/DFNativeHostRootController.m"],
}
PRIOR_STATIC_CALLS=[
 ["SCPCarSplit.openApp:slot:","SCPCarSplit.isCarPlayApp:","original 0x164d4/0xff20 route classification; caller relation needs dynamic selector trace"],
 ["SCPCarSplit.adopt:slot:","SCPCarSplit.sceneOfViewController:","original native VC adoption and owning scene chain, exact original IMPs"],
 ["SCPCarSplit.pushSceneSizes","foregroundSceneWithSettings:completion:","original 0x1c738 native scene host update call"],
 ["SCPCarSplit.hostApp:inPane:","com.anlai.omnicar/appbridge.open","original 0x3ea84 phone AppBridge IPC, NOT native Maps"],
 ["SCPCarSplit.setBarVisible:forPane:","4s bar timer","original 0x24424 original 4 second one-shot; not proof divider knob idle"],
 ["OmniCarAppBridge.ABHost.layoutPane:","updateSettingsWithBlock:","original 0xf048 remote iPhone scene transaction, separate from native Maps"],
]
def sha(path):
 return hashlib.sha256(path.read_bytes()).hexdigest()

def decode_original(path):
 if sha(path)!=SHA:raise RuntimeError("REFUSE original OmniCar checksum mismatch")
 with tempfile.TemporaryDirectory() as temp:
  subprocess.run(["dpkg-deb","-x",str(path),temp],check=True,stdout=subprocess.DEVNULL)
  dylib=Path(temp)/"var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarSplitScreen.dylib"
  if sha(dylib)!="f696b518579266cf99cfd46f85cb54931d18e679c793a563ee2fcc9bf8115754":
   raise RuntimeError("REFUSE original split dylib checksum mismatch")
  binary=arm64_fat(dylib.read_bytes())
  methods=original_methods(binary)
  for key,pc in EXPECTED_IMPS.items():
   if methods.get(key)!=pc:raise RuntimeError("ORIGINAL IMP DIFF %s %s"%(key,hex(pc)))
  starts=sorted(set(methods.values()))
  decoder=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
  records=[]
  for (cls,selector),start in sorted(methods.items(),key=lambda x:(x[0][0],x[1])):
   end=next((v for v in starts if v>start),len(binary))
   size=min(end-start,0x10000)
   if size<=0 or start<0 or start>=len(binary):continue
   ins=list(decoder.disasm(binary[start:start+size],start))
   if not ins:continue
   groups=[g for g,pat in GROUPS.items() if re.search(pat,selector,re.I)]
   calls=[{"at":hex(i.address),"target":i.op_str} for i in ins if i.mnemonic in ("bl","blr")]
   literal=[]
   # Real ARM64 ADRP+ADD CFString loading, only store supported literal values.
   for i,o in enumerate(ins[:-1]):
    if o.mnemonic!="adrp" or ins[i+1].mnemonic!="add":continue
    m=re.fullmatch(r"(x\d+),\s*#(0x[0-9a-f]+)",o.op_str)
    if not m:continue
    reg,page=m.groups()
    z=re.fullmatch(r"("+reg+r"),\s*("+reg+r"),\s*#(0x[0-9a-f]+)",ins[i+1].op_str)
    if not z:continue
    val=cfstring(binary,int(page,16)+int(z.group(3),16))
    if val and len(literal)<24:literal.append({"pc":hex(o.address),"value":val})
   records.append({"class":cls,"selector":selector,"imp":hex(start),
     "end_next_method":hex(end),"instruction_count_sampled":len(ins),
     "truncated":size<end-start,"groups":groups,
     "direct_bl_sites":calls[:32],"original_cfstrings":literal})
  return records

def scan_current(repo):
 out={}
 for group,paths in CURRENT.items():
  files=[]
  for p in paths:
   data=(repo/p).read_text(encoding="utf8")
   decl=[{"line":i,"declaration":m.group(0).strip()[:170]}
     for i,line in enumerate(data.splitlines(),1)
     if (m:=re.match(r"\s*[-+]\s*\([^)]*\)\s*\w+[^{;]*",line))]
   files.append({"source":p,"source_sha256":hashlib.sha256(data.encode("utf8")).hexdigest(),
                 "method_declarations":decl[:100],
                 "has_native_scene_instance":("initWithApplicationForMainDisplay:" not in data and "sceneHostView" in data)})
  out[group]=files
 return out

def scan_owner_log(path):
 entries=[json.loads(line) for line in path.read_text(encoding="utf8").splitlines() if line.strip()]
 points=[]
 for i,j in enumerate(entries):
  for c in j.get("controllers",[]):
   if c.get("controllerClass")!="DBApplicationSceneViewController":continue
   points.append({"snapshot_index":i,"utc":j.get("utc"),
      "process_pid":j.get("processPID"),
      "hosted_bundle":c.get("hostedBundleIdentifier"),
      "hosted_fbscene_identifier":c.get("hostedSceneIdentifier"),
      "native_info_getter_status":c.get("nativeApplicationInfoStatus"),
      "native_fbscene_getter_status":c.get("nativeSceneStatus"),
      "scene_host_view_status":c.get("sceneHostViewStatus"),
      # Preserve only intra-log identity equality, not raw device pointers.
      "_pointer":c.get("controllerPointer")})
 for x,y in zip(points,points[1:]):
  y["same_controller_as_previous"]=x["_pointer"]==y["_pointer"] and x["process_pid"]==y["process_pid"]
 for p in points:p.pop("_pointer",None)
 google=[p for p in points if p["hosted_bundle"]=="com.google.Maps"]
 own=[p for p in points if p["hosted_bundle"]=="com.duoface.native.scenehost"]
 # Exact observed same controller replacement, not proof of duplicate host.
 swap=any(a["same_controller_as_previous"] and a["hosted_bundle"]!=b["hosted_bundle"]
    and a["hosted_bundle"]=="com.duoface.native.scenehost" and b["hosted_bundle"]=="com.google.Maps"
    for b,a in zip(points,points[1:]))
 return {"snapshot_count":len(entries),"owner_controller_observation_count":len(points),
         "native_google_maps_snapshots":len(google),"native_duoface_snapshots":len(own),
         "observed_same_controller_maps_to_duoface_handoff":swap,
         "observations":points,
         "limits":["Same VC switched hosted app: no proof of two simultaneous full native Maps views",
                   "Dashboard map widget is NOT the full navigation app scene",
                   "No foreign FBS scene creation, ownership hijack or native scene mutation was attempted"]}

def main():
 p=argparse.ArgumentParser()
 p.add_argument("--omnicar-deb",required=True,type=Path)
 p.add_argument("--duoface-root",required=True,type=Path)
 p.add_argument("--owner-log",required=True,type=Path)
 p.add_argument("--out",required=True,type=Path)
 x=p.parse_args()
 records=decode_original(x.omnicar_deb)
 original_hooks=x.duoface_root/"sideplay/audit/native12-083-rotation-20261028/NATIVE12_ORIGINAL_36_HOOK_CALLBACKS_RUN_40667230467.json"
 hk=json.loads(original_hooks.read_text())
 assert hk["original_hooks_count"]==len(hk["callbacks"])==36
 owner=scan_owner_log(x.owner_log)
 assert owner["native_google_maps_snapshots"]>=2
 assert owner["observed_same_controller_maps_to_duoface_handoff"]
 grouping={g:[{"class":r["class"],"selector":r["selector"],"imp":r["imp"]}
             for r in records if g in r["groups"]] for g in GROUPS}
 result={"status":"ORIGINAL_OMNICAR_ALL_METHODS_PLUS_NATIVE12_HOOKS_DUOFACE90_SOURCE_AND_REAL_OWNER_LOG_STATIC_CROSSWALK",
  "original_omnicar_deb_sha256":SHA,
  "original_split_dylib_sha256":"f696b518579266cf99cfd46f85cb54931d18e679c793a563ee2fcc9bf8115754",
  "original_verified_class_method_count":len(records),
  "original_verified_classes":dict(collections.Counter(r["class"] for r in records)),
  "original_omnicar_full_method_index":records,
  "original_ui_groups":grouping,
  "source_crosswalk":scan_current(x.duoface_root),
  "existing_native12_hook_count":hk["original_hooks_count"],
  "native12_orientation_original_deb_sha256":hk["original_deb_sha256"],
  "verified_original_call_chain_anchors":PRIOR_STATIC_CALLS,
  "native_carplay_owner_real_device_log":owner,
  "first_party_runtime_gaps":[
     "DuoFace DFSceneHost exclusively creates SBDeviceApplicationSceneEntity for MAIN iPhone display; native Maps CarPlay scene has DIFFERENT owner/role.",
     "Native Google Maps was actually hosted in CarPlay native FBScene in owner log; same DBApplicationSceneViewController then hosted DuoFace scene, not two concurrently.",
     "No verified safe second live native scene/CPWindow is available for independent reparenting into a DuoFace pane; do not destroy/steal navigation or fake CPWindow.",
     "Original OmniCar split native route + phone AppBridge route separated; current DuoFace .90 has only phone scene for selected apps.",
     "DuoFace .90 YouTube orientation device PASS reported by user; protect it, Maps/Dock/panes full parity not proven."],
  "limits":["Code-level static original audit + recorded device scene owner snapshots only; no new live device test.",
            "Method names/PC and BL sites do not prove exact runtime call edges through objc_msgSend.",
            "Do not copy original methods, license, binary, entitlements or speculative zoom.",
            "Do not claim complete native Maps split without live controller scene handoff verification."]
 }
 x.out.parent.mkdir(parents=True,exist_ok=True)
 x.out.write_text(json.dumps(result,indent=2,ensure_ascii=False)+"\n",encoding="utf8")
 print("OMNICAR_ORIGINAL_FULL_UI_NATIVE_MAP_CROSSWALK_PASS methods",len(records),"classes",len(result["original_verified_classes"]),
       "real_google_maps",owner["native_google_maps_snapshots"],"same_vc",owner["observed_same_controller_maps_to_duoface_handoff"])
if __name__=="__main__":main()
