#!/usr/bin/env python3
"""Bounded, read-only ARM64 inspection of three known SidePlay v1.0.4-1 SPPane methods.

Not a generalized selector hunt. Exact original extracted dylib and known
SPPane selector VM addresses from SHA-pinned repository index only.
"""
import hashlib
import json
import os
import re
import subprocess
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]
BINARY=ROOT/"sideplay/extracted-1.0.4-1/rootfs/var/jb/Library/MobileSubstrate/DynamicLibraries/SidePlay.dylib"
INDEX=ROOT/"sideplay/native12-display/audit/SIDEPLAY_SPLIT_OWNER_SELECTORS.json"
OUT=ROOT/"sideplay/native12-display/audit/SIDEPLAY_SCENE_FRAME_ARM64_CALLS_20261026.json"
EXPECTED="0fc34c6c8e47283d2223d70facfe3e86ed76bd568958786b67a9430127242971"
NAMES=["layoutInFrame:scaleMode:","applySceneFrame:","restoreSceneFrame","setSceneFrame:orientation:"]
EXPECTED_IMP={"layoutInFrame:scaleMode:":0x2f6e0,
              "applySceneFrame:":0x313f8,
              "restoreSceneFrame":0x31468,
              "setSceneFrame:orientation:":0x31500}
LINE=re.compile(r"^\s*([0-9a-fA-F]+):\s+(.+)$")

def main():
    data=BINARY.read_bytes()
    sha=hashlib.sha256(data).hexdigest()
    assert sha==EXPECTED,(sha,"unexpected SidePlay binary")
    index=json.loads(INDEX.read_text())
    assert index["sha256"]==sha
    pane=next(x for x in index["matches"] if x["class"]=="SPPane")
    byname={x["selector"].lstrip("-"):x for x in pane["selectors"]}
    # The JSON stores '-selector'; normalize only the known four targets.
    def found(name):
        for rec in pane["selectors"]:
            if rec["selector"].lstrip("-")==name:return rec
        raise AssertionError("missing known original selector "+name)
    selected={n:found(n) for n in NAMES}
    for n,rec in selected.items():
        assert int(rec["imp"],16)==EXPECTED_IMP[n],(n,rec)
    cmd=[os.environ.get("OBJDUMP","llvm-objdump-18"),"--macho","--disassemble",
         "--no-show-raw-insn",str(BINARY)]
    out=subprocess.run(cmd,capture_output=True,text=True,errors="replace")
    if out.returncode:raise RuntimeError("llvm objdump failed "+out.stderr[-2500:])
    asm={}
    for line in out.stdout.splitlines():
        m=LINE.match(line)
        if m:
            pc=int(m.group(1),16)
            asm[pc]=m.group(2)
    if not asm:raise RuntimeError("no disassembled source instructions")
    # Each method's bounded end is the next *known SPPane selector IMP*,
    # not an invented function size nor a guessed return instruction.
    starts=sorted(int(x["imp"],16) for x in pane["selectors"])
    report=[]
    for name,rec in selected.items():
        start=EXPECTED_IMP[name]
        higher=[x for x in starts if x>start]
        if not higher:raise RuntimeError("missing next IMP for "+name)
        stop=min(higher)
        ins=[{"pc":hex(a),"asm":asm[a]} for a in sorted(asm) if start<=a<stop]
        if not ins or int(ins[0]["pc"],16)!=start:
            raise RuntimeError("original IMP missing "+name)
        calls=[{"pc":x["pc"],"asm":x["asm"]} for x in ins
               if any(t in x["asm"] for t in
                  ("bl\t","objc","scene","setting","frame","layout",
                   "orientation","reference","transform","scale","ret"))]
        report.append({"class":"SPPane","selector":name,"type":rec["type"],
                       "imp":hex(start),"bounded_next_imp":hex(stop),
                       "instruction_count":len(ins),
                       "instructions":ins,"calls_and_indicators":calls})
    OUT.parent.mkdir(parents=True,exist_ok=True)
    OUT.write_text(json.dumps({
        "status":"ORIGINAL_SIDEPLAY_1041_PINNED_ARM64_INSTRUCTIONS_NOT_DEVICE_EXECUTION",
        "original_sideplay_dylib_sha256":sha,
        "known_method_index_sha256":hashlib.sha256(INDEX.read_bytes()).hexdigest(),
        "llvm_command":cmd,
        "selection":"four precisely identified SPPane method bodies",
        "methods":report,"source_binary_modified":False,
        "vendor_code_ported":False,"DuoFace_runtime_modified":False
    },indent=2,ensure_ascii=False)+"\n")
    for x in report:
        print(x["selector"],x["imp"],x["bounded_next_imp"],
              "ARM64",x["instruction_count"],"key_calls",len(x["calls_and_indicators"]))
    print("SIDEPLAY_PINNED_SCENE_METHODS_DISASSEMBLED",str(OUT))

if __name__=="__main__":main()
