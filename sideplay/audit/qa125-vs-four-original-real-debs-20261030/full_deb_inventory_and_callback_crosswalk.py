#!/usr/bin/env python3
"""READ-ONLY SHA-pinned original-DEB vs CURRENT SIGNED QA125 inventory.

Actual bytes: rootless package control, maintainer scripts, every extracted file,
every Mach-O's strings/imports/UUID, ObjC method-index for Native12, first-party
source hook overlaps. Selector/keyword presence is NEVER functional equivalence.
Does not modify device, deploy software, execute original code, or copy licenses.
"""
import argparse, collections, hashlib, json, os, pathlib, plistlib, re, subprocess, tempfile
from datetime import datetime, timezone

PINS = {
    "Native12": "2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad",
    "DuoNavi104": "f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd",
    "OmniCar103": "d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd",
    "SidePlay104": None,  # Git blob file is pinned to the inspected commit, full SHA printed
    "DuoFaceQA125": "1914f4e2c6e8dce0fadb5035166c0869966759fb74eb1c89424712dcf71cbe93",
}
SOURCE_MODULES = [
    "sideplay/duoface-native-scene-host/DFSceneLifecycle.m",
    "sideplay/duoface-native-scene-host/DFSceneHost.m",
    "sideplay/duoface-native-scene-host/DFNativeHostAppDelegate.m",
    "sideplay/duoface-native-scene-host/DFTouchOwnerProbe.m",
    "sideplay/duoface-native-scene-host/DFNative12Chrome.m",
    "sideplay/duoface-native-scene-host/DFNativeMapPaneCoordinator.m",
    "sideplay/duoface-native-scene-host/DFDockZoomCoordinator.m",
    "sideplay/duoface-native-scene-host/DFYouTubeOrientationRelay.m",
]
RISK_SELECTORS = [
    "updateSettingsWithBlock:", "updateSettings:withTransitionContext:completion:",
    "sceneHandle:didUpdateSettingsWithDiff:previousSettings:",
    "setForeground:", "setBackgrounded:", "automatesLifecycle",
    "setAutomatesLifecycle:", "setIgnoresOcclusions:",
    "setRequestedMode:", "setFrame:", "sceneIfExists",
    "_shouldBeBackgroundUnderLockForScene:withSettings:",
    "interceptUpdateForScene:withNewSettings:",
    "shouldBeUnderLockForScene:", "setAudioOnlyBackgroundMode:",
    "refreshSceneLayout", "setInterfaceOrientation:",
    "sceneDidEnterBackground:", "sceneWillResignActive:",
    "sendEvent:", "touchesBegan:withEvent:", "touchesEnded:withEvent:",
    "isHostingAnApp", "updateLayout", "updateSceneSettingsFrame"
]
FEATURE_TERMS = {
    "scene-host": ["sceneHandle", "updateSettings", "FBScene", "SBAppViewController"],
    "app-scene-foreground": ["setForeground:", "setBackgrounded:", "automatesLifecycle", "setRequestedMode:"],
    "lock": ["SBSuspendedUnderLockManager", "shouldBeUnderLockForScene:", "_shouldBeBackgroundUnderLockForScene:"],
    "carplay": ["CPWindow", "CPTemplate", "CarPlay", "SBSCarPlay"],
    "touch": ["sendEvent:", "touchesBegan:withEvent:", "touchesEnded:withEvent:"],
    "youtube": ["com.google.ios.youtube", "youtube", "YouTube"],
    "reconnect": ["sceneDidDisconnect:", "didDisconnect", "disconnect", "restore"],
    "zoom": ["Zoom", "zoom", "Fullscreen", "fullscreen"],
    "map": ["CPMapTemplate", "MapKit", "MKMap", "Maps"],
    "picker": ["appBridgeApps", "AppPicker", "showAllApps", "AppManager"],
    "dock": ["dock", "Dock", "Dashboard"],
    "license-proprietary": ["license", "activation", "subscription"],
}
MACHO_MAGICS = {"cffaedfe", "cefaedfe", "cafebabe", "bebafeca", "cafebabf", "bfbafeca"}

def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def run(args, check=True):
    p=subprocess.run([str(x) for x in args], capture_output=True, text=True, errors="replace")
    if check and p.returncode: raise RuntimeError("command failed: "+str(args)+"\n"+p.stderr[-1600:])
    return p.stdout if p.returncode==0 else ""
def is_macho(p):
    with p.open("rb") as f: return f.read(4).hex() in MACHO_MAGICS
def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False, sort_keys=True)+"\n")
def safe_value(obj):
    if isinstance(obj,(str,int,float,bool)) or obj is None:return obj
    if isinstance(obj,list):return [safe_value(x) for x in obj[:100]]
    if isinstance(obj,dict):return {str(k):safe_value(v) for k,v in obj.items() if isinstance(k,(str,int))}
    return repr(obj)[:150]
def snapshot(deb, name, root):
    root.mkdir(parents=True,exist_ok=True)
    run(["dpkg-deb","-x",deb,root])
    ctr=root.parent/(name+"-DEBIAN")
    ctr.mkdir()
    run(["dpkg-deb","-e",deb,ctr])
    controls={}
    for p in sorted(ctr.rglob("*")):
        if p.is_file():controls[p.name]={"sha256":digest(p),"text":p.read_text(errors="replace")[:4500] if p.stat().st_size<8000 else "[large binary]"}
    manifest=[];selectors=set();plists={};libraries={};allstr={}
    binaries=[]
    for f in sorted(root.rglob("*")):
        if not f.is_file() or f.is_symlink():continue
        rel=f.relative_to(root).as_posix()
        item={"path":rel,"bytes":f.stat().st_size,"sha256":digest(f),
              "mode":oct(f.stat().st_mode & 0o777),"mach_o":is_macho(f)}
        manifest.append(item)
        if f.suffix==".plist":
            try:
                obj=plistlib.loads(f.read_bytes())
                if isinstance(obj,dict):
                    plists[rel]={k:safe_value(v) for k,v in obj.items()
                                 if k in ("Filter","CFBundleIdentifier","CFBundleExecutable","CFBundleVersion",
                                          "UIApplicationSceneManifest","UIBackgroundModes","UIRequiredDeviceCapabilities",
                                          "NSPrincipalClass","CFBundleShortVersionString")}
            except (ValueError,TypeError,OverflowError):pass
        if item["mach_o"]:
            binaries.append(rel)
            strings=set(run(["strings","-a",f],False).splitlines())
            allstr[rel]=strings;selectors.update(strings)
            uuid=run(["xcrun","dwarfdump","--uuid",f],False).strip()
            dylib=run(["otool","-L",f],False).splitlines()
            libraries[rel]={"uuid":uuid[:500],"imports":[x.strip() for x in dylib[1:]],
                            "matched_probes":[p for p in RISK_SELECTORS if p in strings],
                            "feature_terms":{cat:[q for q in terms if q in strings] for cat,terms in FEATURE_TERMS.items()}}
    return {"package":name,"sha256":digest(deb),"control":controls,
      "files":manifest,"plists":plists,"macho":libraries,
      "binary_count":len(binaries),"file_count":len(manifest),
      "unique_binary_strings":len(selectors),
      "risk_selectors_any_binary":{x:[path for path,tokens in allstr.items() if x in tokens] for x in RISK_SELECTORS},
      "feature_indicators":{k:sorted(set(t for words in (info["feature_terms"][k] for info in libraries.values()) for t in words))
         for k in FEATURE_TERMS}, "all_strings":selectors}
def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--out",required=True,type=pathlib.Path)
    ap.add_argument("--native12",required=True,type=pathlib.Path)
    ap.add_argument("--duonavi",required=True,type=pathlib.Path)
    ap.add_argument("--omnicar",required=True,type=pathlib.Path)
    ap.add_argument("--sideplay",required=True,type=pathlib.Path)
    ap.add_argument("--qa125",required=True,type=pathlib.Path)
    ap.add_argument("--native12-index",required=True,type=pathlib.Path)
    args=ap.parse_args();args.out.mkdir(parents=True,exist_ok=True)
    names={"Native12":args.native12,"DuoNavi104":args.duonavi,
           "OmniCar103":args.omnicar,"SidePlay104":args.sideplay,"DuoFaceQA125":args.qa125}
    for name,path in names.items():
        if not path.is_file():raise SystemExit("missing "+name+" "+str(path))
        if PINS[name] and digest(path)!=PINS[name]:raise SystemExit("SHA mismatch "+name)
    if run(["git","hash-object",args.native12_index]).strip()!="efa45df59bc3c16887cc979bf3aedc0c93c92111":
        raise SystemExit("Native12 1385 method index hash mismatch")
    index=json.loads(args.native12_index.read_text())["native12"]
    assert sum(len(x["objc_methods"]) for x in index)==1385
    result={};source={};overlap={};classes={}
    with tempfile.TemporaryDirectory() as td:
        for name,path in names.items():
            r=snapshot(path,name,pathlib.Path(td)/name)
            write(args.out/(name+"_ALL_FILES_AND_BINARIES.json"),{k:v for k,v in r.items() if k!="all_strings"})
            result[name]={"sha256":r["sha256"],"file_count":r["file_count"],"binary_count":r["binary_count"],
                "objc_probe_count":sum(bool(v) for v in r["risk_selectors_any_binary"].values()),
                "total_binary_string_tokens":r["unique_binary_strings"],
                "control_version":r["control"].get("control",{}).get("text","").splitlines()[:12]}
            classes[name]=r["all_strings"]
        base=classes["DuoFaceQA125"]
        for name,strings in classes.items():
            if name=="DuoFaceQA125":continue
            common=sorted(strings&base)
            missing=sorted(strings-base)
            excess=sorted(base-strings)
            # These are indicators only; all selector comparisons are full sets, but
            # do not dump proprietary original strings or license sensitive content.
            overlap[name]={"shared_string_tokens_count":len(common),
               "original_only_string_tokens_count":len(missing),
               "duoface_only_string_tokens_count":len(excess),
               "risk_selectors_original_present":sorted(set(RISK_SELECTORS)&strings),
               "risk_selectors_qa125_present":sorted(set(RISK_SELECTORS)&base),
               "risk_selectors_original_only":sorted((set(RISK_SELECTORS)&strings)-base),
               "risk_selectors_qa125_only":sorted((set(RISK_SELECTORS)&base)-strings),
               "shared_risk_selectors":sorted(set(RISK_SELECTORS)&strings&base)}
    methodRows=[];methodClass=collections.Counter()
    for x in index:
        for m in x["objc_methods"]:
            selector=m["selector"]
            methodRows.append({"original_binary":x["filename"],"original_class":m["class"],
                "selector":selector,"type_encoding":m.get("type"),"original_imp":m["imp"],
                "selector_string_in_qa125":selector in base,
                "runtime_equivalent_proven":False})
            methodClass[m["class"]]+=1
    write(args.out/"NATIVE12_ALL_1385_METHODS_VS_QA125.json",{"methods":methodRows})
    write(args.out/"ALL_PACKAGE_SUMMARY.json",result)
    write(args.out/"ALL_PACKAGE_STRING_AND_SELECTOR_CROSSWALK.json",overlap)
    for module in SOURCE_MODULES:
        p=pathlib.Path(module)
        if not p.exists():source[module]={"available":False};continue
        lines=p.read_text().splitlines()
        source[module]={"sha256":digest(p),"lines":len(lines),
             "state_write_sites":[{"line":i,"text":l.strip()[:220]} for i,l in enumerate(lines,1)
              if re.search(r"setForeground:|setBackgrounded:|setRequestedMode:|updateSettingsWithBlock:|stopTouchOwnerWithReason:|sceneDidEnterBackground:|sceneWillResignActive:|DFUpdateScene|DFManagedSceneObserver|updateUISettingsWithBlock|youtube-app-handshake",l)]}
    write(args.out/"DUOFACE_QA125_REAL_SOURCE_HOOKS.json",source)
    methodPresent=sum(x["selector_string_in_qa125"] for x in methodRows)
    summary={"timestamp_utc":datetime.now(timezone.utc).isoformat(),
        "scope":"exact 5 SHA-locked/captured DEB artifacts (4 original reference + QA125 signed; SidePlay SHA recorded)",
        "originals":["Native12","DuoNavi104","OmniCar103","SidePlay104"],"candidate":"DuoFaceQA125",
        "all_package_summary":result,
        "original_native12_method_rows":1385,"original_native12_method_selector_string_present_in_qa125":methodPresent,
        "non_equivalence_rule":"String, selector/import and bundle/class overlap are clues only. Never assert callback ABI or runtime equivalence.",
        "source_hotspots":list(source),"duodash_stock":"NOT_PROVEN: stock binary not provided, earlier repack excluded from immutable originals",
        "license_rule":"Never reproduce vendor license, activation or proprietary code",
        "reality":"No device QA, no fixes made, and a system scene's effective owner cannot be verified by offline scan."}
    write(args.out/"SUMMARY.json",summary)
    md=["# Exact original DEBs vs signed DuoFace QA125 — complete offline inventory",
        "", "## SHA-pinned input: all files and all Mach-O (read-only)",
        "| Package | SHA256 | Extracted files | Mach-O |","|---|---|---:|---:|"]
    for name,r in result.items():
        md.append(f"| {name} | {r['sha256']} | {r['file_count']} | {r['binary_count']} |")
    md+=["","**Original Native12 1,385 method entries:** "+str(methodPresent)+"/1385 selector strings appear in QA125 binary. THIS IS NOT functional parity.",
         "","## What is verified vs unknown",
         "- Verified: every package file hash/size/mode, DEBIAN control/scripts, plist injection filters, every compiled Mach-O UUID/import/probe string, 1,385 original Native12 ObjC entries mapped to QA125 selector-string presence.",
         "- Unknown: method execution, return ABI in the device process, exact branch/callback ownership under lock, event ordering and Play ACK.",
         "- Stock DuoDash not included: previous comparison was a repack, not a byte-identical original; do not silently treat it as stock.",
         "","## Evidence files",
         "- [NAME]_ALL_FILES_AND_BINARIES.json — all paths/sha256/metadata and every Mach-O probe.",
         "- ALL_PACKAGE_STRING_AND_SELECTOR_CROSSWALK.json — original-only/shared/QA125-only selector probes, only string-level.",
         "- NATIVE12_ALL_1385_METHODS_VS_QA125.json — all actual reference ObjC method selectors and type encodings.",
         "- DUOFACE_QA125_REAL_SOURCE_HOOKS.json — exact line numbers for current first-party potentially conflicting scene/owner writes.",
         "- SUMMARY.json — exact artifact hashes and coverage.",
         "","## NON-GO / safety",
         "This is **not** evidence that every original app has been functionally recreated; binary equivalence and phone behavior require on-device owner/callback evidence. Do not copy original licensing or alter other packages. Avoid promoting an untested build to Sileo.",
         ""]
    (args.out/"REPORT.md").write_text("\n".join(md))
    print("SHA_PINNED_FIVE_REAL_DEBS_ALL_FILES_MACHO_AND_NATIVE12_1385_METHODS_PASS")
    print(json.dumps({k:{"files":v["file_count"],"macho":v["binary_count"]} for k,v in result.items()}))
if __name__=="__main__":main()
