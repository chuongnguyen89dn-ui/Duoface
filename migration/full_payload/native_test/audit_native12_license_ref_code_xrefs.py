#!/usr/bin/env python3
"""Read-only lower-bound arm64 code xrefs into 14 license-class pointer slots.

An ADRP+LDR/ADD into a classref is a potential runtime dependency.
Absence is NOT proof of no dynamic ObjC class/name lookup; never auto-delete.
"""
import argparse, hashlib, json, pathlib, re, subprocess, tempfile
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
from audit_native12_license_class_xrefs import MachO, select_arm64, BINARIES, NATIVE12_SHA
BINARY_TOOLS="audit/payload-migration/NATIVE12_ACTUAL_LICENSE_CLASS_XREFS.json"

def scan(m,candidates):
    # All classref/superref VM addresses; class_registration is not a code use.
    refs={}
    for c in candidates:
        for p in c["pointer_references"]:
            if p["role"]=="class_registration":continue
            refs[int(p["vm"],16)]={"class":c["class"],"role":p["role"]}
    hits=[]
    dis=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
    for sec in m.sections:
        if sec["name"]!="__text":continue
        raw=m.data[sec["fileoff"]:sec["fileoff"]+sec["size"]]
        recent={}
        for op in dis.disasm(raw,sec["vm"]):
            code=op.mnemonic
            if code in ("b","bl","blr","ret","br","cbz","cbnz","tbz","tbnz"):
                recent.clear()
                continue
            if code=="adrp":
                mt=re.fullmatch(r"(x\d+), #?(0x[0-9a-fA-F]+)",op.op_str)
                if mt:recent[mt.group(1)]=int(mt.group(2),16)
                continue
            if code in ("ldr","ldur","add"):
                # Many compiler variants use adrp xN,page; ldr xM,[xN,#off]
                mt=re.fullmatch(r"(x\d+), \[(x\d+)(?:, #?(0x[0-9a-fA-F]+|\d+))?\]",op.op_str)
                if mt:
                    dest,base=mt.group(1,2); off=int(mt.group(3),0) if mt.group(3) else 0
                    target=recent.get(base)
                    if target is not None and target+off in refs:
                        hits.append({"vm":hex(op.address),"arm64":op.mnemonic+" "+op.op_str,
                                     "pointer_slot_vm":hex(target+off),**refs[target+off]})
                    recent.pop(dest,None)
                    continue
                add=re.fullmatch(r"(x\d+), (x\d+), #?(0x[0-9a-fA-F]+|\d+)",op.op_str)
                if add:
                    dest,base=add.group(1,2); off=int(add.group(3),0)
                    target=recent.get(base)
                    if target is not None and target+off in refs:
                        hits.append({"vm":hex(op.address),"arm64":op.mnemonic+" "+op.op_str,
                                     "pointer_slot_vm":hex(target+off),**refs[target+off]})
                    recent.pop(dest,None)
                    continue
            if re.match(r"^(x\d+)[,\s]",op.op_str) and op.mnemonic not in ("cmp","tst","str","stp"):
                recent.pop(op.op_str.split(",")[0],None)
    return refs,hits

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--deb",required=True,type=pathlib.Path)
    p.add_argument("--candidates",default=BINARY_TOOLS,type=pathlib.Path)
    p.add_argument("--out",required=True,type=pathlib.Path)
    a=p.parse_args()
    assert hashlib.sha256(a.deb.read_bytes()).hexdigest()==NATIVE12_SHA
    prior=json.loads(a.candidates.read_text())
    assert prior["candidates_checked"]==14
    with tempfile.TemporaryDirectory(prefix="df-license-ref-calls-") as d:
        subprocess.run(["dpkg-deb","-x",str(a.deb),d],check=True)
        out={}
        for name,path in BINARIES.items():
            m=MachO(select_arm64((pathlib.Path(d)/path).read_bytes()))
            refs,hits=scan(m,prior["binaries"][name]["candidate_classes"])
            out[name]={"pointer_slots":len(refs),"static_instruction_hits":hits,
                       "matched_instruction_count":len(hits),
                       "scan_is_conservative_not_dynamic_liveness_proof":True}
    result={"status":"NATIVE12_LICENSE_CLASSREF_ARM64_READONLY",
            "deb_sha256":NATIVE12_SHA,"candidates":14,"physical_removal_performed":False,
            "dynamic_objc_dispatch_proven_absent":False,
            "safe_to_delete_classes":False,"binaries":out}
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
    print(json.dumps({n:{"slots":x["pointer_slots"],"hits":x["matched_instruction_count"],
                         "examples":x["static_instruction_hits"][:12]}
        for n,x in out.items()},indent=2))
    print("READONLY_xrefs_PASS; ABSENCE_OF_HITS_NOT_SAFE_TO_DELETE_BY_ITSELF")
if __name__=="__main__":main()
