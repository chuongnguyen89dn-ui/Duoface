#!/usr/bin/env python3
"""Independent read-only original-DEB iPhone lock / CarPlay-host crosswalk.

SHA verifies both *original* DEBs; no vendor binary or license is saved.
Distinguishes selector presence from disassembled IMP and from hardware use.
"""
import argparse,bisect,hashlib,json,pathlib,re,subprocess,tempfile
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
from audit_native12_license_class_xrefs import MachO,select_arm64
from audit_native12_carplay_add_app_chain import methods,disassemble
ORIGINAL={
 "DuoNavi104":("f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd",
              "44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15",
              "DuoNaviDashboard.dylib"),
 "Native12":("2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad",
             "9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea",
             "DuoFaceDashboard.dylib")
}
GROUPS={
 "sleep-backlight":["acquireCarPlaySleepAssertion","releaseCarPlaySleepAssertion",
  "PreventUserIdleSystemSleep","IOPMAssertionCreateWithName","IOPMAssertionRelease",
  "BKSDisplayServicesSetScreenBlanked","isIdleTimerDisabled","setIdleTimerDisabled",
  "setScreenBlankEnabled"],
 "under-lock":["SBSuspendedUnderLockManager","_shouldBeBackgroundUnderLockForScene",
  "shouldBeUnderLockForScene","interceptUpdateForScene","underLock","lockState",
  "isLocked","lockScreen"],
 "scene-lifecycle":["FBScene","updateSettings:withTransitionContext:completion:",
  "sceneHandle:didUpdateSettingsWithDiff:previousSettings:",
  "sceneHandle:didDestroyScene:","setAutomatesLifecycle:","setIgnoresOcclusions:",
  "setForeground:","setBackgrounded:","sceneDidEnterBackground:","sceneWillResignActive:"],
 "display-external":["carPlayUIScreen","carPlayCADisplay","carPlayWindowScene","UIWindowScene",
  "UIScreenDidDisconnectNotification","disconnectCarPlay","performAutoResume",
  "createWindows","resizeWindows","carPlayUsableBounds"],
 "video-activity":["setPreventsDisplaySleepDuringVideoPlayback:","audioOnlyBackgroundMode",
  "AVAudioSession","AVPlayer","noteUserActivity","updateSceneFrame",
  "refreshSceneLayout","supportsInterfaceOrientation"]
}
METHOD_PATTERN=re.compile(r"(?i)(?:sleep|assertion|lock|idle|power|background|foreground|suspend|"
                          r"resume|CarPlay|connect|disconnect|scene|display|window|bridge|"
                          r"updateLayout|startInParent|stop|noteUserActivity|occlusion)")
STR_PATTERN=re.compile("|".join(re.escape(v) for vv in GROUPS.values() for v in vv),re.I)
def sha(x):return hashlib.sha256(pathlib.Path(x).read_bytes()).hexdigest()
def is_macho(x):
 try:return pathlib.Path(x).read_bytes()[:4] in (bytes.fromhex("cffaedfe"),bytes.fromhex("feedfacf"),
                        bytes.fromhex("cafebabe"),bytes.fromhex("bebafeca"))
 except OSError:return False
def original_binary(src,dest,name):
 code=ORIGINAL[name]
 if sha(src)!=code[0]:raise ValueError("Original "+name+" DEB wrong SHA")
 subprocess.run(["dpkg-deb","-x",str(src),str(dest)],check=True)
 matches=list(dest.rglob(code[2]))
 if len(matches)!=1:raise RuntimeError(name+" dylib missing/ambiguous "+str(matches))
 if sha(matches[0])!=code[1]:raise ValueError(name+" dylib SHA mismatch")
 return matches[0]
def read_metadata(binary):
 m=MachO(select_arm64(pathlib.Path(binary).read_bytes()))
 classes=m.classes()
 allmethods={}
 failed={}
 for name in classes:
  try:allmethods[name]=methods(m,name)
  except (ValueError,IndexError,KeyError,AssertionError) as e:
   failed[name]=type(e).__name__
 starts=sorted((v["vm"],cl,sel) for cl,dd in allmethods.items()
                 for sel,v in dd.items() if v.get("vm"))
 return m,classes,allmethods,starts,failed
def bounded(m,lo,starts,n=200):
 idx=bisect.bisect_right([x[0] for x in starts],lo)
 upper=starts[idx][0] if idx<len(starts) else lo+0x900
 upper=min(upper,lo+0x900)
 try:return disassemble(m,lo,upper)[:n]
 except (ValueError,KeyError,IndexError):return ["decode-unavailable"]
def method_audit(name,binary):
 m,classes,items,starts,failed=read_metadata(binary)
 methods_flat=[{"class":cl,"selector":sel,"imp":hex(v["vm"])}
       for cl,dd in items.items() for sel,v in dd.items()
       if METHOD_PATTERN.search(cl+"."+sel) and v.get("vm")]
 focused=[]
 # Every relevant candidate is inventoried; dump disassembly for top-priority
 # lock/foreground/sleep/CarPlay owner methods, NOT only global selector strings.
 for x in methods_flat:
  cl,sel=x["class"],x["selector"]
  priority=(10 if re.search(r"(?i)SleepAssertion|UnderLock|foreground|Background|"
          r"sceneHandle|sceneDid|CarPlay|suspend|startInParent|stopInParent",sel) else 0)
  priority+=(5 if re.search(r"(?i)^CBBridgeManager$|^CBWindow$|^CBBridgedUIAppView$|"
           r"^CBBridgedSplitApp$|^CBDuoFace|AppViewController|Scene",cl) else 0)
  if priority<10:continue
  focused.append((priority,x))
 focused.sort(key=lambda row:(-row[0],row[1]["class"],row[1]["selector"]))
 selected=[]
 for _,v in focused[:90]:
  instruction=bounded(m,int(v["imp"],16),starts,140)
  selected.append({**v,"disassembly":instruction})
 # Scan all real machine-code BLs for named IMP call sites; direct vs objc_msgSend
 # is recorded, not conflated. This cannot cover dynamic objc dispatch.
 direct={}
 exact={v["selector"].lower().lstrip("-+"):v for v in methods_flat}
 for target in ("acquireCarPlaySleepAssertion","releaseCarPlaySleepAssertion",
                "carPlayUsableBounds","refreshSceneLayout","performAutoResume"):
  found=[(cl,sel,v["vm"]) for cl,dd in items.items() for sel,v in dd.items()
         if sel.lstrip("-+").lower()==target.lower() and v.get("vm")]
  if not found:continue
  targetvm=found[0][2]
  direct[target]={"IMP":hex(targetvm),"callers":[]}
  for seg in m.sections:
   if seg["name"]!="__text" or seg["size"]>15000000:continue
   try:
    data=m.data[seg["fileoff"]:seg["fileoff"]+seg["size"]]
    instr=Cs(CS_ARCH_ARM64,CS_MODE_ARM).disasm(data,seg["vm"])
    addrs=[x[0] for x in starts]
    for inst in instr:
     if inst.mnemonic!="bl" or inst.op_str!="#"+hex(targetvm):continue
     i=bisect.bisect_right(addrs,inst.address)-1
     caller=(starts[i][1]+"."+starts[i][2] if i>=0 else "unknown")
     direct[target]["callers"].append({"PC":hex(inst.address),"nearestObjC":caller})
   except Exception as e:direct[target]["scan_error"]=type(e).__name__+":"+str(e)[:150]
   break
 return {"sha256":sha(binary),"classes":len(classes),"objcMethodCount":sum(len(v) for v in items.values()),
         "candidateMethodCount":len(methods_flat),"methodsWithDecodeErrors":failed,
         "methodInventory":methods_flat[:1200],"selectedDisassembly":selected,
         "directMachineCodeCallsites":direct}
def main():
 p=argparse.ArgumentParser()
 p.add_argument("--duonavi-deb",required=True)
 p.add_argument("--native12-deb",required=True)
 p.add_argument("--current-source",required=True)
 p.add_argument("--out",required=True)
 a=p.parse_args()
 out=pathlib.Path(a.out);out.mkdir(exist_ok=True,parents=True)
 model={}
 with tempfile.TemporaryDirectory(prefix="df-org-lock-scan-") as td:
  for name,path in (("DuoNavi104",a.duonavi_deb),("Native12",a.native12_deb)):
   dest=pathlib.Path(td)/name;dest.mkdir()
   binary=original_binary(path,dest,name)
   all_strings={}
   binary_list=[]
   for f in dest.rglob("*"):
    if not f.is_file() or f.stat().st_size>50*1024*1024 or not is_macho(f):continue
    raw=subprocess.run(["strings","-a","-n","5",str(f)],check=True,capture_output=True,text=True,errors="replace").stdout
    hits={}
    for group,words in GROUPS.items():
     pattern=re.compile("|".join(map(re.escape,words)),re.I)
     hits[group]=sorted(set(line.strip()[:180] for line in raw.splitlines()
                       if pattern.search(line) and len(line)<250))[:150]
    binary_list.append({"path":str(f.relative_to(dest)),"sha256":sha(f),
                         "groups":hits})
   model[name]={"DEB_SHA256":ORIGINAL[name][0],"payload":binary_list,
                "primary":method_audit(name,binary)}
 root=pathlib.Path(a.current_source)
 current={}
 names={"DFNativeHostAppDelegate.m":["sceneWillResignActive:","sceneDidEnterBackground:","renewTouchOwnerHeartbeat","stopTouchOwnerWithReason"],
        "DFTouchOwnerProbe.m":["DFStopProbe","hideAllExternalWindowsImmediately","DFWatchdog","DFCarPlayPreventIdleSystemSleep121"],
        "DFSceneLifecycle.m":["incoming-background-owned-live","setForeground:","owned-manual-observer-consumed"],
        "DFSceneHost.m":["scene-foreground-observed-only","setIgnoresOcclusions","setAutomatesLifecycle"],
        "DFNative12Chrome.m":["qa120-pane-tap","userInteractionEnabled"]}
 for file,probes in names.items():
  data=(root/file).read_text()
  lines=data.splitlines()
  current[file]={"sha256":hashlib.sha256(data.encode()).hexdigest(),
                 "findings":{q:[{"line":i+1,"code":s.strip()[:220]} for i,s in enumerate(lines) if q in s][:8] for q in probes}}
 model["DuoFace_current_source"]=current
 (out/"SHA_PINNED_FULL_ORIGINAL_VS_CURRENT.json").write_text(json.dumps(model,ensure_ascii=False,indent=2)+"\n")
 lines=["# Native12 + DuoNavi original DEB full lock / screen / scene lifecycle forensic crosswalk",
        "","Original binaries SHA-pinned; all Mach-O payload files scanned for 5 relevant feature groups.",
        "ObjC class selectors and selected ARM64 methods inventoried. No binary, proprietary code",
        "or license is copied. Selector existence/directed calls do NOT prove runtime activation.","",
        "## Original reference identities"]
 for name in ("DuoNavi104","Native12"):
  d=model[name];f=d["primary"]
  lines += ["",f"### {name}",f"- Original DEB SHA256: `{d['DEB_SHA256']}`",
           f"- Main dylib SHA256: `{f['sha256']}`",
           f"- Mach-O binaries examined: {len(d['payload'])}",
           f"- ObjC classes decoded: {f['classes']}; methods: {f['objcMethodCount']};",
           f"- Relevant method names: {f['candidateMethodCount']}; ARM64 functions extracted: {len(f['selectedDisassembly'])}",""]
  for payload in d["payload"]:
   counts={k:len(v) for k,v in payload["groups"].items()}
   lines += [f"- `{payload['path']}` categories: {counts}"]
  lines += ["","### Exact original lifecycle/lock methods (method existence proven)",""]
  candidates=[v for v in f["methodInventory"] if re.search(
      r"(?i)sleepassertion|backgroundunderlock|underlock|scenehandle|foreground|"
      r"background|willresignactive|didenterbackground|carplay|suspend|resume",v["selector"])]
  lines += [f"- `{x['class']}.{x['selector']}` at `{x['imp']}`"
            for x in candidates[:170]]
  lines += ["","### Selected actual ARM64 proof and direct machine-code callsites"]
  for target,val in f["directMachineCodeCallsites"].items():
   lines += [f"- `{target}` IMP `{val['IMP']}`: {len(val['callers'])} direct BL callers"]
   lines += [f"  - PC `{x['PC']}`, nearest `{x['nearestObjC']}`" for x in val["callers"][:25]]
  for record in f["selectedDisassembly"]:
   if not re.search(r"(?i)SleepAssertion|UnderLock|sceneWillResignActive|"
             r"sceneDidEnterBackground|foreground|background",record["selector"]):continue
   lines += [f"#### `{record['class']}.{record['selector']}` @ `{record['imp']}`"]
   lines += ["    "+i.replace("`","'")[:200] for i in record["disassembly"][:80]]
 lines += ["","## Current first-party source gap (verified source lines)"]
 for name,entry in current.items():
  lines += [f"### `{name}` (sha256 `{entry['sha256']}`)"]
  for selector,found in entry["findings"].items():
   lines += [f"- `{selector}`: "+
       ("; ".join(f"L{z['line']} `{z['code']}`" for z in found) if found else "NOT FOUND")]
 lines += ["","## Causal classification (do not overclaim)",
   "- User device says Apple CarPlay native Dock remains visible while DuoFace panes go black. External display itself is still rendered. Last observed screenshot-size issue was fixed on QA120.",
   "- DuoFace current template delegate indiscriminately stops owned window chrome during scene resign/background; immediate stop hides **only DuoFace-owned windows** and watchdog detaches after heartbeat expires.",
   "- Source and prior QA119 device log establish a real hide/restart chain, but there is NO timestamped physical iPhone lock-button event tied to that chain. Distinguish CarPlay Home from iPhone lock before preserving lease.",
   "- YouTube can scroll/other menu clicks with phone dark but Play depends on phone screen lit. This may involve its own app/AV media foreground underlock state, not merely pane visibility or actual screen brightness.",
   "- Original proofs are exact machine-code methods + selector/group presence, NOT evidence that any original app is guaranteed never to blank under lock.",
   "- Do not copy vendor hooks, fake foreground for nonowned scenes, bypass lock, or keep system Dock covered.",
   "","## Acceptance and continuation",
   "- Before any patch: validate per-app host owner, lock state vs CarPlay Home, scene presence, active external screen and callback sequence together.",
   "- Patch only verified first-party owner/generation; preserve immediate teardown on CarPlay Home/disconnect and legitimate scene background, and no user data.",
   "- Run signed iOS build + source regressions before publishing, then on-device QA locked/unlocked Play and full Dock/geometry. No build/DEB/Sileo done by this read-only audit."]
 (out/"ORIGINAL_VS_QA120_LOCK_VERDICT.md").write_text("\n".join(lines)+"\n")
 print("LOCK_FULL_ORIGINAL_SCAN_PASS",json.dumps({k:{"methodCount":model[k]["primary"]["objcMethodCount"],
        "relevant":model[k]["primary"]["candidateMethodCount"],"MachOs":len(model[k]["payload"])}
        for k in ("DuoNavi104","Native12")},ensure_ascii=False))
if __name__=="__main__":main()
