#!/usr/bin/env python3
"""Read-only compare QA136 device log process evidence and two checksum-pinned original DEBs.
No proprietary binary, raw device log, app IDs or licenses in outputs.
"""
import argparse, collections, hashlib, io, json, plistlib, re, subprocess, tarfile
from pathlib import Path

PINS={
    "DuoNavi104":"f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd",
    "DuoDash113Repacked_NOT_STOCK":"ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465",
}
MARKERS=[
    "CARApplication", "_newApplicationLibrary", "FBSApplicationLibrary",
    "addApplicationProxy:withOverrideURL:", "_notifyDidAddApplications:",
    "DBApplicationInfo", "CRCarPlayAppDeclaration", "effectivePolicyForAppDeclaration:",
    "_CARDashboardHomeViewController","_setupIconModel","iconManager:launchIcon:",
    "DashBoard","CarPlaySupport","LSBundleProxy","entitlementValueForKey:ofClass:",
    "appbridge_enabled", "appbridge_app_sections", "CNABAppPickerController",
]
DISPLAY=re.compile(r"(?i)Dashboard|CarPlay|FBSApplicationLibrary|DBApplicationInfo|iconModel|HomePublisher")
def sha(b): return hashlib.sha256(b).hexdigest()
def pkg(path,name):
    raw=path.read_bytes()
    if sha(raw)!=PINS[name]:raise ValueError("Wrong input DEB "+name+" "+sha(raw))
    result={"input_sha":sha(raw),"plist_filters":[],"dylib_markers":{},"image_names":[]}
    data=subprocess.run(["dpkg-deb","--fsys-tarfile",str(path)],check=True,stdout=subprocess.PIPE).stdout
    with tarfile.open(fileobj=io.BytesIO(data),mode="r:") as tar:
        for member in tar:
            if not member.isfile():continue
            namepath=member.name.lstrip("./")
            if namepath.endswith(".plist") and ("DynamicLibraries/" in namepath or "TweakInject/" in namepath):
                try:
                    pl=plistlib.loads(tar.extractfile(member).read())
                    if isinstance(pl,dict) and "Filter" in pl:
                        fl=pl.get("Filter")
                        if not isinstance(fl,dict):continue
                        result["plist_filters"].append({"name":Path(namepath).name,
                            "executables":[x for x in fl.get("Executables",[]) if isinstance(x,str)],
                            "bundles":[x for x in fl.get("Bundles",[]) if isinstance(x,str)]})
                except (OSError, ValueError, TypeError):pass
            if namepath.endswith(".dylib"):
                b=tar.extractfile(member).read()
                found=[x for x in MARKERS if x.encode() in b]
                # Only original constants, never vendor implementation/instructions.
                if found:
                    result["dylib_markers"][Path(namepath).name]=found
                    result["image_names"].append(Path(namepath).name)
    return result

def log_evidence(path):
    raw=path.read_bytes()
    if len(raw)<100_000:raise ValueError("Not a full uploaded log")
    wanted=re.compile(r"^===\s*(.*?)\s*===\s*$")
    sections=collections.Counter()
    current="unsectioned"; counts=collections.Counter()
    geometry=collections.Counter()
    for line in raw.decode("utf-8","replace").splitlines():
        m=wanted.match(line)
        if m:current=m.group(1)
        if "DuoFaceGeometry119-Dashboard.jsonl" in current:
            geometry["lines"]+=1
            if "not available" in line.lower():geometry["unavailable_markers"]+=1
            if '"process"' in line:geometry["process_fields"]+=1
            if "Dashboard" in line:geometry["Dashboard_refs"]+=1
            if len(line)<15000 and line.lstrip().startswith("{"):
                try:
                    record=json.loads(line)
                    if isinstance(record,dict):
                        fields=set(record)
                        for key in ("process","event","pid","window_owner","windowCount","native_window_count"):
                            if key in fields:
                                geometry["key_"+key]+=1
                        if str(record.get("process","")).lower() in ("dashboard","dashBoard"):
                            geometry["dashboard_process_json"]+=1
                except json.JSONDecodeError:pass
        if "DuoFaceHomePublisher136.log" in current:
            counts["home136_lines"]+=1
            if "reconcile=6" in line:counts["reconcile_six"]+=1
            if "verified-library=FBSApplicationLibrary" in line:counts["verified_library"]+=1
        if ("DashBoard" in current or "Dashboard" in current) and "No log" in line:counts["missing_dashboard_log"]+=1
    return {"sha256":sha(raw),"size":len(raw),"lines":len(raw.splitlines()),
            "dashboard_geometry_section":dict(geometry),"qa136_fbs":dict(counts)}
def main():
    p=argparse.ArgumentParser()
    p.add_argument("--duonavi",type=Path,required=True)
    p.add_argument("--duodash-repacked",type=Path,required=True)
    p.add_argument("--log",type=Path,required=True)
    p.add_argument("--out",type=Path,required=True)
    a=p.parse_args()
    x={"kind":"DEVICE_LOG_AND_TWO_SOURCE_VERIFIED_DEB_PROCESS_SCOPE_READ_ONLY",
       "original_DuoDash_standalone_not_available":True,
       "note":"DuoDash input is a separately SHA-pinned 1.1.3 Fullscreen427 REPACK, NOT original stock 1.1.3.",
       "original_packages":{n:pkg(path,n) for n,path in (
           ("DuoNavi104",a.duonavi),
           ("DuoDash113Repacked_NOT_STOCK",a.duodash_repacked))},
       "real_user_QA136_Log16":log_evidence(a.log),
       "limits":"String/Plist markers do not prove invocation. Dashboard geometry export is not a native Home icon callback or successful icon tap. No current device connected."}
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(x,ensure_ascii=False,indent=2)+"\n")
    print("ORIGINAL_DEB_SCOPE_CHECKSUMS_PASS",len(x["original_packages"]))
    for n,c in x["original_packages"].items():print("BIN",n,c["input_sha"],"filters",c["plist_filters"],"markers",c["dylib_markers"])
    print("LOG16_DASHBOARD",x["real_user_QA136_Log16"]["dashboard_geometry_section"])
if __name__=="__main__": main()
