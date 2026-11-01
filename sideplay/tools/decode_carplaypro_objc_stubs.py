#!/usr/bin/env python3
"""Recover all original SpeedAlerts arm64 ObjC selector stub names.

Use Mach-O __TEXT,__objc_stubs bytes, Capstone ARM64, and authenticated
__DATA,__objc_selrefs from original on-disk dylib. Does not execute the vendor
binary or depend on vendor activation. Exact call→selector evidence, not
runtime app model/traffic data proof.
"""
from __future__ import annotations
import argparse, json, re
from pathlib import Path
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
from resolve_carplaypro_hook_sources import ThinMachO

PAGE=re.compile(r"^x(\d+), #0x([0-9a-f]+)$")
LOAD=re.compile(r"^x(\d+), \[x(\d+), #0x([0-9a-f]+)\]$")
def decode(thin:bytes,loads:dict):
    macho=ThinMachO(thin,loads)
    sec=next(s for s in loads["sections"] if s["segment"]=="__TEXT" and s["section"]=="__objc_stubs")
    md=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
    if sec["size"]%20:raise RuntimeError("unexpected original ObjC stub size")
    out=[]
    for addr in range(sec["addr"],sec["addr"]+sec["size"],20):
        blob=macho.raw(addr,20)
        ins=list(md.disasm(blob,addr))
        name=None;selref=None;rawptr=None
        for i,x in enumerate(ins):
            if x.mnemonic!="adrp":continue
            m=PAGE.fullmatch(x.op_str)
            if not m:continue
            reg=int(m[1]);page=int(m[2],16)
            for y in ins[i+1:i+3]:
                if y.mnemonic!="ldr":continue
                k=LOAD.fullmatch(y.op_str)
                if not k or int(k[1])!=1 or int(k[2])!=reg:continue
                candidate=page+int(k[3],16)
                desc=macho.selref(candidate)
                if desc:
                    name=desc["name"];selref=hex(candidate);rawptr=desc["ptr"]
                    break
            if name:break
        out.append({"addr":hex(addr),"selector":name,"selref":selref,
                    "raw_pointer":rawptr,
                    "instructions":[f"{x.mnemonic} {x.op_str}" for x in ins]})
    return out

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--thin",required=True,type=Path)
    ap.add_argument("--loads",required=True,type=Path)
    ap.add_argument("--out",required=True,type=Path)
    a=ap.parse_args()
    rows=decode(a.thin.read_bytes(),json.loads(a.loads.read_text()))
    names={r["addr"]:r for r in rows}
    important=["0x440a0","0x44aa0","0x44be0","0x45e40","0x47e20",
               "0x45ce0","0x43a18","0x44c80","0x453a0","0x457a0",
               "0x43808","0x437fc"]
    compact={"static_original_only":True,"stub_count":len(rows),
             "resolved_stub_names":sum(bool(r["selector"]) for r in rows),
             "important_selectors":{a:names.get(a) for a in important},
             "all_stubs":rows}
    a.out.mkdir(parents=True,exist_ok=True)
    (a.out/"ORIGINAL_OBJC_STUB_SELECTORS.json").write_text(json.dumps(compact,indent=2)+"\n")
    md=["# Original CarPlayPro Speed: 880 ObjC message stubs decoded",
        "","Each selector is decoded from original auth-chained __objc_selrefs.",
        "Read-only static proof, **not** proof that a GOFA event fires on device.",
        f"","Resolved {compact['resolved_stub_names']} of {len(rows)} original stubs.",
        "","## Critical GOFA payload-registration call sites"]
    for addr in important:
        row=names.get(addr)
        if row:md.append(f"- `{addr}`: `{row['selector']}` (original selector ref `{row['selref']}`)")
    md.extend(["","## GOFA callback registration",
      "- At 0x3ce1c original code passes authenticated static block literals",
      "  containing alert callback 0x3cfb4 and speed callback 0x3d468",
      "  to ObjC stub 0x440a0.",
      "- Verify exact decoded selector above; ABI and schema of GOFA Swift",
      "  model still require actual running GOFA evidence before a DuoFace adapter.",
      "","## All resolved selector stubs"])
    md.extend(f"- `{r['addr']}`: `{r['selector']}`" for r in rows if r["selector"])
    (a.out/"ORIGINAL_OBJC_STUB_SELECTORS.md").write_text("\n".join(md)+"\n")
    print("QA166_ORIGINAL_OBJC_STUBS_DECODED",compact["resolved_stub_names"],"/",len(rows))
if __name__=="__main__":
    main()
