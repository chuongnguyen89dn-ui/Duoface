#!/usr/bin/env python3
"""Static forensic trace of original CarPlayPro Speed GOFA Swift payload literal construction.

Inputs are the original 60k ARM64 disassembly and original Mach-O function-starts.
No proprietary code is used at runtime and no field is assumed to exist in GOFA.
"""
from __future__ import annotations
import argparse
import bisect
import gzip
import json
import re
from pathlib import Path

PIVOTS={"gofa_speed_swift":0x3e390,"gofa_alert_swift":0x3e940,
        "gofa_speed_callback":0x3d468,"gofa_alert_callback":0x3cfb4}
ROW=re.compile(r"^([0-9a-fA-F]{8,16})\t([0-9a-fA-F]{8})\t([a-z0-9.]+)\t(.*?)$")
IMM=re.compile(r"^\s*([xw])(\d+),\s*#(0x[0-9a-fA-F]+|\d+)(?:,\s*lsl\s*#(\d+))?\s*$")
DEST=re.compile(r"^\s*([xw])(\d+),")

def text8(v:int)->str:
    return "".join(chr(b) if 32<=b<127 else "\\x%02x"%b
                   for b in (v&((1<<64)-1)).to_bytes(8,"little"))

def extract(rows,start,end):
    registers={}
    literals=[]
    branches=[]
    seen=set()
    for pc,op,args in rows:
        if pc<start or pc>=end:continue
        if op in ("bl","blr"):
            branches.append({"address":hex(pc),"kind":op,"target":args})
        if op in ("mov","movz","movk","movn"):
            m=IMM.match(args)
            if m:
                mode,reg,num,shift=m.groups()
                reg=int(reg);num=int(num,0);shift=int(shift or 0)
                if reg<=30 and shift<=48 and shift%16==0:
                    if op=="movk":
                        old,addr=registers.get(reg,(0,[]))
                        val=(old&~(0xffff<<shift))|((num&0xffff)<<shift)
                        addr=addr+[pc]
                    elif op=="movn":
                        val=(~((num&0xffff)<<shift))&((1<<64)-1);addr=[pc]
                    else:
                        val=(num<<shift)&((1<<64)-1);addr=[pc]
                    registers[reg]=(val,addr)
                    value=text8(val)
                    if len(re.findall("[A-Za-z]",value))>=4:
                        key=(val,tuple(addr))
                        if key not in seen:
                            seen.add(key)
                            literals.append({"at":hex(pc),"register":"x"+str(reg),
                               "ascii_le_escaped":value,"raw_le":val.to_bytes(8,"little").hex(),
                               "origin":list(map(hex,addr)),
                               "proof":"register_immediate_only_not_runtime_field"})
                    continue
        if op=="bl":
            for n in range(19):registers.pop(n,None)
        else:
            m=DEST.match(args)
            if m and op not in ("cmp","cmn","tst","str","stp","stur","cbz","cbnz","tbz","tbnz"):
                registers.pop(int(m.group(2)),None)
    return {"start":hex(start),"end_exclusive":hex(end),
            "immediate_literals":literals,"control_calls":branches}

def analyze(disasm,starts):
    starts=sorted(set(starts))
    rows=[]
    for line in disasm.splitlines():
        m=ROW.match(line)
        if m:rows.append((int(m.group(1),16),m.group(3),m.group(4)))
    if len(rows)<60000:raise RuntimeError("original binary disassembly truncated")
    report={"source":"CarPlayPro Speed 0.9.97 original SpeedAlerts.dylib arm64",
       "static_only":True,"not_vendor_source_code":True,
       "not_runtime_payload_schema":True,
       "original_instruction_count":len(rows),"functions":{}}
    addresses={row[0] for row in rows}
    for name,start in PIVOTS.items():
        if start not in starts or start not in addresses:
            raise RuntimeError("original GOFA pivot missing "+hex(start))
        i=bisect.bisect_right(starts,start)
        end=starts[i] if i<len(starts) else max(addresses)+4
        report["functions"][name]=extract(rows,start,end)
    return report

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--disassembly",type=Path,required=True)
    p.add_argument("--function-starts",type=Path,required=True)
    p.add_argument("--out",type=Path,required=True)
    a=p.parse_args()
    with gzip.open(a.disassembly,"rt",encoding="utf-8") as f:original=f.read()
    report=analyze(original,json.loads(a.function_starts.read_text()))
    a.out.mkdir(parents=True,exist_ok=True)
    (a.out/"GOFA_SWIFT_LITERAL_REGISTER_TRACE.json").write_text(
         json.dumps(report,indent=2,ensure_ascii=False)+"\n")
    md=["# CarPlayPro Speed 0.9.97 — original Swift GOFA immediate trace",
        "STATIC BINARY evidence only. Candidate ASCII register text is not a GOFA model field.",
        "Actual instructions: "+str(report["original_instruction_count"])]
    for name,datum in report["functions"].items():
        md.append("\n## "+name+" "+datum["start"]+" ... "+datum["end_exclusive"])
        md.append("Candidates: "+str(len(datum["immediate_literals"])))
        for row in datum["immediate_literals"]:
            md.append("- "+row["at"]+" "+row["register"]+" LE="+row["ascii_le_escaped"]+
                      " origin="+",".join(row["origin"]))
    (a.out/"GOFA_SWIFT_LITERAL_REGISTER_TRACE.md").write_text("\n".join(md)+"\n")
    print("QA169_ORIGINAL_ARM64_GOFA_LITERAL_TRACE",{
        "instructions":report["original_instruction_count"],
        "candidates":{n:len(v["immediate_literals"]) for n,v in report["functions"].items()},
        "hardware_untested":True})
if __name__=="__main__":main()
