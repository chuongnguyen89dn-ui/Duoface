#!/usr/bin/env python3
"""Read-only SHA-pinned SIX DEB display/power/scene call-site crosscheck.

Original binaries are only read as inputs; no proprietary assembly is
copied into independent runtime. A string or local xref is NOT proof
that a method executed on the user's iPhone.
"""
import argparse, hashlib, json, pathlib, re, struct, subprocess, tempfile
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
from audit_native12_license_class_xrefs import MachO, select_arm64
from audit_native12_carplay_add_app_chain import methods

PINS={
    "Native12Derived":"2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad",
    "DuoNavi104":"f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd",
    "OmniCar103":"d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd",
    "SidePlay104":"7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c",
    "DuoDash113Repack":"ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465",
    "DuoFaceQA130":"d0573ac14e402dfca450e4b01fd57f898ed03852b354361b0a8acf54a432e24b",
}
MARKERS=[
    "BKSDisplayServicesSetScreenBlanked","setScreenBlankEnabled:",
    "screenBlankEnabled","setPreventsDisplaySleepDuringVideoPlayback:",
    "setIdleTimerDisabled:","PreventUserIdleSystemSleep",
    "PreventUserIdleDisplaySleep","IOPMAssertionCreateWithName",
    "IOPMAssertionRelease","setAudioOnlyBackgroundMode:",
    "_shouldBeBackgroundUnderLockForScene:withSettings:",
    "interceptUpdateForScene:withNewSettings:",
    "shouldBeUnderLockForScene:","CADisplayLink",
    "displayLinkWithTarget:selector:","initWithCADisplay:isMainDisplay:",
    "SBBacklightController","_setScreenBrightness:"
]
METHOD_MATCH=re.compile("screenBlank|displaySleep|[Ii]dle[Tt]imer|[Cc]ar[Pp]lay[Ss]leep|[Bb]acklight|[Bb]rightness|[Aa]udioOnlyBackground",re.I)
def sha(path):
    h=hashlib.sha256()
    with open(path,"rb") as f:
        for b in iter(lambda:f.read(1048576),b""):h.update(b)
    return h.hexdigest()
def literal_vms(m,keyword):
    encoded=keyword.encode()+b"\x00"
    locations=[]
    for sec in m.sections:
        if sec["name"] not in ("__cstring","__objc_methname","__const"):continue
        # __const may contain arbitrary binary: exact NUL-terminated match only.
        if sec["size"]>60000000:continue
        off=sec["fileoff"]
        raw=m.data[off:off+sec["size"]]
        position=0
        while len(locations)<15:
            idx=raw.find(encoded,position)
            if idx<0:break
            if idx==0 or raw[idx-1]==0:
                locations.append(sec["vm"]+idx)
            position=idx+len(encoded)
    return locations

def pointers_to(m,vm):
    answer=set()
    needle=struct.pack("<Q",vm)
    for sec in m.sections:
        if sec["size"]<8 or sec["size"]>50000000:continue
        if not sec["segment"].startswith(("__DATA","__AUTH","__DATA_CONST")):continue
        body=m.data[sec["fileoff"]:sec["fileoff"]+sec["size"]]
        i=0
        while len(answer)<20:
            i=body.find(needle,i)
            if i<0:break
            if i%8==0:answer.add(sec["vm"]+i)
            i+=8
    return answer

def refscan(m,marker_vms):
    # Only text sections: never disassemble .rodata or a vendor license.
    matched=[]
    cs=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
    for sec in m.sections:
        if sec["name"]!="__text" or sec["size"]>55000000:continue
        off=sec["fileoff"]
        ins=list(cs.disasm(m.data[off:off+sec["size"]],sec["vm"]))
        pages={}
        recent=[]
        for i,z in enumerate(ins):
            operand=z.op_str
            if z.mnemonic=="adrp":
                m0=re.fullmatch(r"(x\d+),\s*#(0x[0-9a-f]+)",operand)
                if m0:pages[m0.group(1)]=int(m0.group(2),16)
            elif z.mnemonic in ("add","ldr"):
                if z.mnemonic=="add":
                    m0=re.fullmatch(r"(x\d+),\s*(x\d+),\s*#(0x[0-9a-f]+)",operand)
                    if m0 and m0.group(2) in pages:
                        addr=pages[m0.group(2)]+int(m0.group(3),16)
                        if addr in marker_vms:
                            context=ins[max(0,i-5):min(len(ins),i+9)]
                            matched.append({"pc":hex(z.address),"target_vm":hex(addr),
                                            "kind":"direct_literal_pointer",
                                            "near":[f"{t.address:#x} {t.mnemonic} {t.op_str}" for t in context]})
                else:
                    m0=re.fullmatch(r"(x\d+),\s*\[(x\d+),\s*#(0x[0-9a-f]+)\]",operand)
                    if m0 and m0.group(2) in pages:
                        addr=pages[m0.group(2)]+int(m0.group(3),16)
                        if addr in marker_vms:
                            matched.append({"pc":hex(z.address),"target_vm":hex(addr),
                                            "kind":"loaded_cf_or_sel_ref",
                                            "near":[f"{t.address:#x} {t.mnemonic} {t.op_str}"
                                                    for t in ins[max(0,i-5):min(len(ins),i+9)]]})
            if len(matched)>=85:break
    return matched[:85]

def methods_related(m):
    try:
        classes=m.classes()
    except (ValueError,IndexError,KeyError,AssertionError) as exc:
        return {"status":"unresolved_arm64e_or_metadata:"+type(exc).__name__,"matched":[]}
    entries=[]
    for cls in classes:
        try: mm=methods(m,cls)
        except (ValueError,IndexError,KeyError,AssertionError):continue
        for name,val in mm.items():
            if METHOD_MATCH.search(name):
                entries.append({"class":cls,"selector":name,"imp":hex(val["vm"] or 0),
                                "abi":val.get("type","")})
    return {"status":"parsed","matched":entries[:90]}

def scan_binary(path):
    raw=path.read_bytes()
    try:
        m=MachO(select_arm64(raw))
    except (ValueError,AssertionError,IndexError) as e:
        return {"path":str(path),"error":type(e).__name__+":"+str(e)[:180]}
    signs={}
    vmtomarker={}
    for k in MARKERS:
        found=literal_vms(m,k)
        if found:
            signs[k]={"literal_vm":[hex(v) for v in found],"ref_vm":[]}
            for vm in found:
                vmtomarker[vm]=k
                for alias in pointers_to(m,vm):
                    vmtomarker[alias]=k
                    signs[k]["ref_vm"].append(hex(alias))
    refs=refscan(m,set(vmtomarker))
    for x in refs:x["marker"]=vmtomarker[int(x["target_vm"],16)]
    related=methods_related(m)
    return {"sha256":hashlib.sha256(raw).hexdigest(),"bytes":len(raw),
            "marker_locations":signs,"literal_reference_count":len(refs),
            "literal_callsite_samples":refs[:24],
            "objc_methods":related,
            "reference_scan_limitation":"adrp/add or adrp/ldr only; GOT, arm64e chained authenticated pointers, indirection and runtime dispatch can be missed"}

def main():
    p=argparse.ArgumentParser()
    for n in PINS:p.add_argument("--"+n,required=True)
    p.add_argument("--out",required=True,type=pathlib.Path)
    a=p.parse_args()
    out={"evidence":"real SHA checked DEB extraction and per-MachO ARM64 code call-site xref",
         "claim":"binary references only, not a runtime activated call trace",
         "provenance":{"Native12Derived":"original Dashboard payload inside independent derived reference package, not vendor stock package",
                       "DuoDash113Repack":"repacked DuoDash, not verified stock vendor byte identity"},
         "scans":{}}
    with tempfile.TemporaryDirectory(prefix="duoface-six-deb-readonly-") as td:
        for name,pin in PINS.items():
            path=pathlib.Path(getattr(a,name))
            if sha(path)!=pin:raise RuntimeError("FAILED CLOSED: "+name+" incorrect DEB SHA "+sha(path))
            root=pathlib.Path(td)/name
            root.mkdir(parents=True)
            subprocess.run(["dpkg-deb","-x",str(path),str(root)],check=True)
            metas=subprocess.check_output(["dpkg-deb","-f",str(path)],text=True)
            files=[]
            for f in sorted(root.rglob("*")):
                if not f.is_file():continue
                with f.open("rb") as stream:magic=stream.read(4)
                if magic not in [bytes.fromhex(x) for x in ("cffaedfe","cafebabe","cafebabf","bebafeca","bfbafeca")]:continue
                item=scan_binary(f)
                item["relative_path"]=f.relative_to(root).as_posix()
                item.pop("path",None)
                files.append(item)
            out["scans"][name]={"package_sha256":pin,
                 "control_subset":[line for line in metas.splitlines() if line.startswith(("Package:","Version:","Architecture:"))],
                 "macho_count":len(files),"macho":files}
            print("ORIGINAL_SCAN",name,"machos",len(files),
                  "BKS",sum("BKSDisplayServicesSetScreenBlanked" in f.get("marker_locations",{}) for f in files),
                  "screenBlankSel",sum("setScreenBlankEnabled:" in f.get("marker_locations",{}) for f in files),flush=True)
    # Compare only the exact tested source-lifecycle package; no parsing of
    # executable license data and no assertion about a powered phone.
    assert len(out["scans"])==6
    for name in ("Native12Derived","DuoNavi104","OmniCar103"):
        assert any(f.get("marker_locations") for f in out["scans"][name]["macho"]),name
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.mkdir(parents=True,exist_ok=True)
    (a.out/"MACHO_REFERENCES.json").write_text(json.dumps(out,indent=2,ensure_ascii=False)+"\n")
    digest={name:{"sha256":row["package_sha256"],"macho_count":row["macho_count"],
                   "candidates":[{"file":f["relative_path"],
                     "markers":sorted(f.get("marker_locations",{})),
                     "nearby_refs":[{"marker":y["marker"],"pc":y["pc"],"kind":y["kind"]}
                                  for y in f.get("literal_callsite_samples",[])[:12]],
                     "classes_status":f.get("objc_methods",{}).get("status")}
                    for f in row["macho"] if f.get("marker_locations")]}
            for name,row in out["scans"].items()}
    (a.out/"SUMMARY.json").write_text(json.dumps(digest,indent=2,ensure_ascii=False)+"\n")
    print("SIX_SHA_VERIFIED_DISPLAY_BINARY_REFERENCES_ONLY__NO_DEVICE_BACKLIGHT_CAUSAL_CLAIM")
if __name__=="__main__":main()
