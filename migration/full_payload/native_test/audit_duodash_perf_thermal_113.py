#!/usr/bin/env python3
"""Read-only focused Mach-O audit of DuoDash 1.1.3 Optimize CPU And Thermal.

DuoDash reference artifact is pinned from DauDat-CarPlay. The file may be a
fullscreen-patched/repacked variant, NOT verified identical to the source 1.1.3
DEB previously uploaded in the user's other conversation. No tweak is executed.
No claim of real CPU, thermal, FPS improvements is made from static findings.
"""
from __future__ import annotations
import argparse, hashlib, json, plistlib, re, struct, subprocess, tempfile
from pathlib import Path
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
from audit_native12_license_class_xrefs import MachO, select_arm64
from audit_native12_carplay_add_app_chain import methods

PINNED_GIT_BLOB = "6f3e7a4543a01358b3c1e24653aec5bdb3975206"
KNOWN_OTHER_STOCK_REPACK_SHA256 = "16ffab22b4246dea9978cae92df7ec635d833ec067b4d9f425a231b26edec601"
TARGET_KEYS = (
    "perf_tweak_enabled", "com.sensetechlab.duodash.settings",
    "deepsleep_enabled","pane_unload_close_enabled",
    "com.sensetechlab.settings.changed",
)
RELEVANT = re.compile(
    r"perf_tweak|Optimize CPU|therm|thermal|cadisplaylink|displaylink|fps|"
    r"framerate|frameRate|FramesPerSecond|frameInterval|preferredFrameRate|"
    r"reduceMotion|animation|minimumFrame|maximumFrame|appbridge|"
    r"settings.changed|lowPower|CPU|backlight", re.I)
STRING_SELECTORS=(
    "perf_tweak_enabled","setPreferredFramesPerSecond:","preferredFramesPerSecond",
    "setPreferredFrameRateRange:","preferredFrameRateRange","CADisplayLink",
    "displayLinkWithTarget:selector:","screen","setFrameInterval:","setFrameRate:",
    "setMinimumFrameDuration:","setMaximumFrameDuration:","setMaximumFPS:",
    "setAnimationDuration:","setSpeed:","setPaused:","setHidden:","setAlpha:",
    "thermalState","systemThermalState","setNeedsDisplay","setNeedsLayout",
    "kCAFrameRateRangeDefault","setAllowsFrameRateRangeOverride:",
    "FPS","frameRate","perf_tweak_enabled","com.sensetechlab.settings.changed",
    "com.sensetechlab.duodash.settings",
    "notify_register_dispatch","CFPreferencesCopyAppValue","CFPreferencesAppSynchronize",
)
PREF_PATHS=(
"var/jb/Library/PreferenceLoader/Preferences/DuoDashPrefs.plist",
"var/jb/Library/PreferenceBundles/DuoDashPrefs.bundle/Root.plist",
)
def sha256(b):return hashlib.sha256(b).hexdigest()
def cap(data,limit=100):return data[:limit]
def text_extract(root:Path):
    found=[]
    for p in root.rglob("*"):
        if not p.is_file() or p.stat().st_size<20000:continue
        if p.suffix.lower() in (".png",".jpg",".jpeg",".heic"):continue
        raw=p.read_bytes()
        if any(x.encode("utf-8") in raw for x in TARGET_KEYS):
            found.append({"file":p.relative_to(root).as_posix(),"sha256":sha256(raw),
                          "bytes":len(raw),
                          "term_counts":{term:raw.count(term.encode()) for term in TARGET_KEYS}})
    return found

def fat_slices(raw:bytes):
    magic=raw[:4]
    if magic==bytes.fromhex("cffaedfe"):
        return {"arm64":raw}
    if magic not in (bytes.fromhex("cafebabe"),bytes.fromhex("cafebabf")):
        return {"unrecognized":raw[:128]}
    is64=magic==bytes.fromhex("cafebabf")
    n=struct.unpack_from(">I",raw,4)[0]; stride=32 if is64 else 20
    slices={}
    for i in range(n):
        at=8+i*stride
        cpu,sub=struct.unpack_from(">II",raw,at)
        off,size=struct.unpack_from(">QQ" if is64 else ">II",raw,at+8)
        if off+size>len(raw):continue
        if cpu==0x0100000c:
            label="arm64e" if (sub & 0xff)==2 else "arm64"
            slices[label]=raw[off:off+size]
    return slices

def collect_vm_literals(m:MachO, raw:bytes):
    result={}
    for sec in m.sections:
        if sec["name"] not in ("__cstring","__objc_methname","__objc_classname"):continue
        piece=raw[sec["fileoff"]:sec["fileoff"]+sec["size"]]
        for match in re.finditer(rb"[\x20-\x7e]{4,}\x00",piece):
            s=match.group()[:-1].decode("utf-8","replace")
            if RELEVANT.search(s):
                result[sec["vm"]+match.start()]=s
    return result

def text_disassembly(m:MachO,raw:bytes):
    cs=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
    rows=[]
    for sec in m.sections:
        if sec["name"]!="__text":continue
        b=raw[sec["fileoff"]:sec["fileoff"]+sec["size"]]
        for instr in cs.disasm(b,sec["vm"]):
            rows.append({"at":instr.address,"m":instr.mnemonic,"o":instr.op_str})
    return rows

def relevant_xrefs(rows, vm_literals, limit=60):
    """Approximate ADRP/ADD/ADR access to relevant C-strings in __TEXT.

    Do not claim all references have been found. Record instruction neighborhoods
    and selector strings where possible. Distinguish literal ref from behavior.
    """
    exact={addr:val for addr,val in vm_literals.items()}
    near=[]
    regs={}
    for i,ins in enumerate(rows):
        m=ins["m"]; op=ins["o"]
        direct=None
        adrp=re.match(r"(x\d+), #0x([0-9a-f]+)",op) if m in ("adrp","adr") else None
        if adrp:
            dest=adrp.group(1);val=int(adrp.group(2),16)
            regs[dest]=(val,i)
            if m=="adr" and val in exact:direct=(val,exact[val])
        plus=re.match(r"(x\d+), (x\d+), #0x([0-9a-f]+)",op) if m=="add" else None
        if plus:
            dest,base,imm=plus.group(1),plus.group(2),int(plus.group(3),16)
            if base in regs:
                page,prev=regs[base]
                if i-prev<16:
                    addr=page+imm
                    regs[dest]=(addr,i)
                    if addr in exact:direct=(addr,exact[addr])
        if direct:
            near.append({
              "address":hex(ins["at"]),
              "literal_address":hex(direct[0]),"literal":direct[1],
              "nearby_disassembly":["%#x: %s %s"%(z["at"],z["m"],z["o"])
                                     for z in rows[max(0,i-48):i+90]]
            })
        if len(near)>=limit:break
    return near

def objc_overview(m:MachO):
    out={"status":None,"classes":[],"candidate_methods":[],"method_ranges":[]}
    try:
        cls=m.classes()
    except Exception as e:
        out["status"]="parse_error "+type(e).__name__+": "+str(e)
        return out
    out["status"]="parsed"
    out["classes"]=sorted(cls)
    for name,base in cls.items():
        cand=[x for x in base["methods"] if RELEVANT.search(x)]
        if cand:
            out["candidate_methods"].append({"class":name,"matches":cap(cand,60)})
        try:
            d=methods(m,name)
        except Exception:
            continue
        for meth,val in d.items():
            if not val.get("vm"):continue
            out["method_ranges"].append((val["vm"],name+"."+meth))
    out["method_ranges"].sort()
    return out

def method_at(vm, ranges):
    lo,hi=0,len(ranges)
    while lo<hi:
        mid=(lo+hi)//2
        if ranges[mid][0]<=vm:lo=mid+1
        else:hi=mid
    if lo==0:return None
    return {"class_method":ranges[lo-1][1],"vm":hex(ranges[lo-1][0]),
            "next_method_vm":hex(ranges[lo][0]) if lo<len(ranges) else None}

def inspect_binary(path, root):
    raw=path.read_bytes()
    descriptor={"file":path.relative_to(root).as_posix(),
                "sha256_full":sha256(raw),"size":len(raw),
                "raw_term_counts":{w:raw.count(w.encode("utf8")) for w in STRING_SELECTORS},
                "slices":{}}
    for cpu,b in fat_slices(raw).items():
        if cpu=="unrecognized":continue
        try:
            macho=MachO(b)
            literals=collect_vm_literals(macho,b)
            rows=text_disassembly(macho,b)
            objc=objc_overview(macho)
            sites=relevant_xrefs(rows,literals,100)
            for site in sites:
                owner=method_at(int(site["address"],16),objc["method_ranges"])
                site["containing_objc_method_candidate"]=owner
            objc.pop("method_ranges",None)
            descriptor["slices"][cpu]={
                "sha256":sha256(b),"size":len(b),
                "objc":objc,
                "relevant_literals":[{"vm":hex(a),"value":v} for a,v in literals.items()][:230],
                "candidate_refs":sites,
                "total_disassembly_instructions":len(rows),
            }
        except Exception as e:
            descriptor["slices"][cpu]={"status":"analysis_error","error":type(e).__name__+": "+str(e),"sha256":sha256(b)}
    return descriptor

def plist_settings(root):
    out={}
    for rel in PREF_PATHS:
        p=root/rel
        if not p.exists():continue
        z=plistlib.loads(p.read_bytes())
        out[rel]={
            "key_references":[entry for entry in z.get("items",[]) if
                              any(x in json.dumps(entry).lower() for x in ("perf","thermal","cpu","deep sleep"))],
            "all_items_count":len(z.get("items",[]))
        }
    return out

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--deb",type=Path,required=True)
    p.add_argument("--out",type=Path,required=True)
    args=p.parse_args()
    package=args.deb.read_bytes()
    blob=subprocess.check_output(["git","hash-object",str(args.deb)],text=True).strip()
    assert blob==PINNED_GIT_BLOB,(blob,PINNED_GIT_BLOB)
    metadata={k:subprocess.check_output(["dpkg-deb","-f",str(args.deb),k],text=True).strip()
              for k in ("Package","Version","Architecture","Description")}
    report={"status":"DUODASH_PERF_THERMAL_STATIC_PINNED_BINARY_AUDIT",
            "source_repo":"chuongnguyen89dn-ui/DauDat-CarPlay",
            "source_commit":"5f683ad16a2c4f2b37e333e891cfb8f7ba3e0d6b",
            "source_path":"DuoDash_1.1.3_Fullscreen427_iphoneos-arm64.deb",
            "source_git_blob_sha1":blob,
            "source_sha256":sha256(package),
            "previous_user_uploaded_repack_sha256":KNOWN_OTHER_STOCK_REPACK_SHA256,
            "identical_to_prior_user_uploaded_repack":sha256(package)==KNOWN_OTHER_STOCK_REPACK_SHA256,
            "source_kind_caution":"Previous user-provided 1.1.3 repack and DauDat fullscreen427 are NOT presumed identical",
            "package":metadata,"device_tested":False,"modified":False,
            "extracted_files_with_perf_setting":[],
            "plist_settings":{},"binaries":[]}
    with tempfile.TemporaryDirectory(prefix="duodash-113-perf-") as td:
        root=Path(td)
        subprocess.run(["dpkg-deb","-x",str(args.deb),str(root)],check=True)
        report["extracted_files_with_perf_setting"]=text_extract(root)
        report["plist_settings"]=plist_settings(root)
        for path in root.rglob("*"):
            if not path.is_file():continue
            rel=path.relative_to(root).as_posix()
            if rel.endswith(("DuoDash.dylib","DuoDashPrefs","DuoDash")):
                if not rel.endswith(".dylib") and path.stat().st_size<30000:continue
                report["binaries"].append(inspect_binary(path,root))
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
    print("PINNED_REF_GIT_BLOB_OK",blob)
    print("SOURCE_SHA256",report["source_sha256"])
    print("PACKAGE",metadata)
    print("MATCHES",report["extracted_files_with_perf_setting"])
    print("PREF_SWITCHES",report["plist_settings"])
    for item in report["binaries"]:
        print("BIN",item["file"],item["sha256_full"])
        for cpu,slice in item["slices"].items():
            print("SLICE",cpu,"STATUS",slice.get("status","analyzed"),
                  "LITERAL_COUNT",len(slice.get("relevant_literals",[])),
                  "REF_COUNT",len(slice.get("candidate_refs",[])))
            print("PERF_LITERAL_MATCHES",[x for x in slice.get("relevant_literals",[]) if
                                          "perf_tweak" in x["value"] or "thermal" in x["value"].lower()][:35])
            print("PERF_XREFS",[
              {"address":x["address"],"literal":x["literal"],"method":x.get("containing_objc_method_candidate")}
              for x in slice.get("candidate_refs",[]) if
              "perf_tweak" in x["literal"] or "thermal" in x["literal"].lower()
            ][:25])
            print("OBJ_METHOD_MATCH",slice.get("objc",{}).get("candidate_methods",[])[:25])
    print("DUODASH_CPU_THERMAL_STATIC_AUDIT_DONE_NOT_DEVICE_QA")

if __name__=="__main__":main()
