#!/usr/bin/env python3
"""Fresh read-only complete original-DEB package/CarPlay Home ownership analysis.
All binaries are SHA-verified and NEVER executed or redistributed.
"""
import argparse,bisect,hashlib,json,pathlib,plistlib,subprocess,tempfile
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
from audit_native12_license_class_xrefs import MachO,select_arm64
from decode_original_home_roster_callsites import function_starts
from trace_original_home_semantic_selectors import one as semantic

PINS={
 "duonavi":("f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd","44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15"),
 "native12":("2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad","9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"),
 "duodash_repack":("ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465","b41dd7f892bfd3722e95a40f764a989886078b4a30943c1f0b50d47b6e248a47"),
 "omnicar":("d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd",None),
 "sideplay":("7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c",None)}
STAGES={
 "home_roster":["CARApplication","_newApplicationLibrary","FBSApplicationLibrary","DBApplicationInfo","CRCarPlayAppDeclaration","_setupIconModel"],
 "home_tap":["iconManager:launchIconForIconView:","iconManager:launchIcon:","shouldInterceptLaunchForApp:"],
 "bridge_request":["startBridging:","onHostRequest:","onHostRequestSplit:","requestStateChange:","cnabBuildSceneHostForBid:displaySize:"],
 "standalone_scene":["SBDeviceApplicationSceneEntity","SBAppViewController","setHosting:","setRequestedMode:","setAutomatesLifecycle:"],
 "app_side":["setBridgeState:width:height:orientation:","setAudioOnlyBackgroundMode:","setInterfaceOrientation:","refreshSceneLayout"],
 "media_input":["sendEvent:","touchesBegan:withEvent:","sceneHandle","setIgnoresOcclusions:"],
 "close_back":["stopBridging","sceneDidEnterBackground:","stopAllHosts","sceneDidDisconnect:","dismiss"],
 "native_dock":["DBStatusBarWindow","DBRootStatusBarViewController","Dock","CarPlay"]}
MACHO={"cffaedfe","cefaedfe","cafebabe","bebafeca","cafebabf","bfbafeca"}
CLASS_HINTS=("Bridge","Host","Dashboard","Scene","AppView","Home","Split","Observer","AppPicker")
def sha(p):
 h=hashlib.sha256()
 with p.open("rb") as f:
  for b in iter(lambda:f.read(1024*1024),b""):h.update(b)
 return h.hexdigest()
def run(*cmd):
 return subprocess.run([str(x) for x in cmd],capture_output=True,check=True).stdout.decode(errors="replace")
def save(path,data):
 path.parent.mkdir(parents=True,exist_ok=True)
 path.write_text(json.dumps(data,ensure_ascii=False,indent=2,sort_keys=True)+"\n")
def inspect(name,deb,tmp):
 assert sha(deb)==PINS[name][0],(name,"bad original package SHA",sha(deb))
 root=tmp/"root"
 root.mkdir(parents=True,exist_ok=True)
 run("dpkg-deb","-x",deb,root)
 control=run("dpkg-deb","-f",deb)
 meta={}
 for ln in control.splitlines():
  if ": " in ln:
   k,v=ln.split(": ",1)
   if k in ("Package","Version","Architecture","Name","Depends"):meta[k]=v[:160]
 output={"package_sha256":sha(deb),"control":meta,"files":[],"modules":{},
         "filters":{},"scene_config":{},"stage_modules":{},"method_classes":{}}
 for f in sorted(root.rglob("*")):
  if not f.is_file() or f.is_symlink():continue
  rel=f.relative_to(root).as_posix()
  with f.open("rb") as io:header=io.read(4).hex()
  ismach=header in MACHO
  output["files"].append({"path":rel,"sha256":sha(f),"bytes":f.stat().st_size,"mach_o":ismach})
  if f.suffix==".plist" and f.stat().st_size<400000:
   try:
    info=plistlib.loads(f.read_bytes())
    if isinstance(info,dict):
     flt=info.get("Filter")
     if isinstance(flt,dict):
      output["filters"][rel]={k:flt[k][:45] for k in ("Bundles","Executables")
           if isinstance(flt.get(k),list)}
     out={k:info[k] for k in ("CFBundleIdentifier","SBStarkLaunchModes","CFBundleExecutable")
          if k in info}
     if out:output["scene_config"][rel]=out
   except (ValueError,TypeError,OverflowError):pass
  if not ismach:continue
  toks=set(run("strings","-a",f).splitlines())
  markers={stage:[v for v in vals if v in toks] for stage,vals in STAGES.items()}
  output["stage_modules"][rel]={k:v for k,v in markers.items() if v}
  output["modules"][rel]={"sha256":sha(f),"bytes":f.stat().st_size,
                          "signals":output["stage_modules"][rel]}
  try:
   m=MachO(select_arm64(f.read_bytes()))
   cl=m.classes()
   chosen={}
   for cname,data in cl.items():
    if any(h.lower() in cname.lower() for h in CLASS_HINTS):
     hits=[method for method in data["methods"] if
          any(h.lower() in method.lower() for h in
              ("bridg","host","scene","launch","home","split","appSelected".lower()))]
     if hits:chosen[cname]=hits[:45]
   if chosen:output["method_classes"][rel]=dict(list(chosen.items())[:60])
   output["modules"][rel]["objc_class_count"]=len(cl)
  except (ValueError,IndexError,KeyError,OverflowError) as err:
   output["modules"][rel]["metadata_parse_error"]=str(err)[:160]
 output["file_count"]=len(output["files"])
 output["macho_count"]=len(output["modules"])
 output["scope"]="all extracted files, all detected Mach-O, first-party filtered selected selectors; static only"
 return output,root
def home_trace(root):
 files=list(root.rglob("DuoNaviDashboard.dylib"))
 assert len(files)==1
 assert sha(files[0])==PINS["duonavi"][1]
 m=MachO(select_arm64(files[0].read_bytes()))
 funcs=function_starts(m)
 pcs={"iconview":0x3110f4,"iconview_actions":0x3112ac,
      "icon":0x311478,"icon_location":0x311630,
      "icon_location_animated":0x3117fc,"icon_alternate":0x3119d4}
 out={}
 for label,pc in pcs.items():
  ix=bisect.bisect_right(funcs,pc)-1
  assert ix>=0,label
  start=funcs[ix];end=funcs[ix+1] if ix+1<len(funcs) else start+0x400
  assert start<=pc<end and 16<=end-start<=0x3000,(label,hex(start),hex(end))
  a=semantic(m,start,end,label)
  keep={"shouldInterceptLaunchForApp:","startBridging:","stopBridging",
        "pending","activated","setIcon:"}
  refs=[{"pc":r["pc"],"selector":r["name"]} for r in a["resolved"] if r["name"] in keep]
  out[label]={"target_pc":hex(pc),"fn_start":hex(start),"fn_end":hex(end),
              "instructions":a["instructions"],"direct_resolved_references":refs,
              "presence_only_not_executed":True}
 return out
def main():
 arg=argparse.ArgumentParser()
 for k in PINS:arg.add_argument("--"+k,required=True,type=pathlib.Path)
 arg.add_argument("--out",required=True,type=pathlib.Path)
 a=arg.parse_args();a.out.mkdir(parents=True,exist_ok=True)
 records={}
 with tempfile.TemporaryDirectory(prefix="original-qa144-") as temp:
  for name in PINS:
   rec,root=inspect(name,getattr(a,name),pathlib.Path(temp)/name)
   records[name]=rec
   if name=="duonavi":tap=home_trace(root)
   print("READ_ORIGINAL_DEB",name,"files",rec["file_count"],"machos",rec["macho_count"])
 assert all(v["file_count"]>10 and v["macho_count"]>0 for v in records.values())
 save(a.out/"ALL_FIVE_DEBS_FILES_MACHO_PLISTS_AND_METHODS.json",records)
 save(a.out/"ORIGINAL_DUONAVI_NATIVE_HOME_TAP_DECODED.json",tap)
 stages=[]
 for name,rec in records.items():
  for stage in STAGES:
   count=sum(stage in x for x in rec["stage_modules"].values())
   stages.append({"package":name,"stage":stage,"modules_with_marker":count,
                  "marker_is_execution_proof":False})
 save(a.out/"PER_STAGE_OWNERSHIP_MATRIX.json",stages)
 summary=[
  "# QA144 original-DEB complete ownership investigation (read-only)",
  "",
  "All five original/reference package binaries have been SHA verified and extracted.",
  "DuoDash is a REPACK, not independently verified stock; Native12 is a derived package.",
  "No original vendor executable ran, no source modification was made, no Sileo release.",
  "",
  "## Whole-package original evidence",
  "| Package | SHA256 | Files | Mach-O |",
  "|---|---|---:|---:|"]
 for name,rec in records.items():
  summary.append("| "+name+" | "+rec["package_sha256"]+
                 " | "+str(rec["file_count"])+" | "+str(rec["macho_count"])+" |")
 summary+=["","## Actual DuoNavi native Home callbacks — six source code bodies",
          "| Handler | Function start | Direct semantic references |",
          "|---|---|---|"]
 for name,entry in tap.items():
  sels=list(dict.fromkeys(x["selector"] for x in entry["direct_resolved_references"]))
  summary.append("| "+name+" | "+entry["fn_start"]+" | "+(", ".join(sels) or "not decoded")+" |")
 summary+=["","## Evidence interpretation, without speculation",
  "- Native Home registration, Home tap event, per-app bridge request, remote SpringBoard scene host, app-side state, input, Home/Back teardown and native Dock are audited as eight SEPARATE stages in PER_STAGE_OWNERSHIP_MATRIX.json.",
  "- Original DuoNavi Home source references shouldInterceptLaunchForApp: and startBridging: with separate pending/activated/stopBridging markers; actual branch outcome is NOT proven by static selector references.",
  "- DuoDash REPACK has structurally distinct onHostRequest: (single) and onHostRequestSplit: (split). Previous exact IMP archive names functions onHostRequest: 0xf968, onHostRequestSplit: 0xfd90, cnabBuildSceneHostForBid:displaySize: 0x1b7a0; this audit newly checks all actual repack files and module markers.",
  "- QA143 FIRST-PARTY source demonstrably launches the DuoFace native Home icon and calls its DFNative12Chrome slot0 app-picker, so it cannot satisfy direct standalone CarPlay Home launch. The QA144 work branch has excluded that wrong interceptor from future builds.",
  "- Architectural gap: a real separately-owned ONE-APP external CarPlay content surface, and a separately accepted one-app request+readiness/teardown protocol are NOT in the independent code. Original marker existence cannot replace iOS16.7.16 live ABI+scene measurements.",
  "- Full original-device functional parity remains unverified. Do not attempt new Sileo installs until standalone owner exists and passes scene-ready input/teardown gates. Preserve native Apple Dock and all supported apps.",
  "",
  "## Files",
  "ALL_FIVE_DEBS_FILES_MACHO_PLISTS_AND_METHODS.json: per-file SHA, binary/class, injected process filters and stage marker evidence.",
  "ORIGINAL_DUONAVI_NATIVE_HOME_TAP_DECODED.json: exact six native ARM64 handler boundaries and resolved selector PC references (no disassembly bytes).",
  "PER_STAGE_OWNERSHIP_MATRIX.json: per-package producer/consumer signal presence (not runtime call traces).",
  "CI_RESULT.txt: exact reproducible run and guarantees.",
  ""]
 (a.out/"ORIGINAL_OWNER_PIPELINE_VERDICT.md").write_text("\n".join(summary))
 (a.out/"CI_RESULT.txt").write_text("ORIGINAL_PACKAGE_COUNT=5\n"
    "DUODASH_REPACK_NOT_STOCK=true\nNATIVE12_DERIVED_NOT_STOCK=true\n"
    "WHOLE_PACKAGE_AND_ALL_MACHO_SCANNED=true\n"
    "DUONAVI_6_HOME_HANDLER_BODIES_SCANNED=true\n"
    "RUNTIME_DEVICE_LAUNCH_VERIFIED=false\n"
    "QA144_SIGNED_BUILD=false\nSILEO_PUBLISHED=false\n")
 print("QA144_FIVE_WHOLE_DEBS_AND_SIX_HOME_HANDLER_STATIC_AUDIT_COMPLETE")
if __name__=="__main__":main()
