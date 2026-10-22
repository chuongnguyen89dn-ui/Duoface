#!/usr/bin/env python3
"""Extract actual Native12 scene settings block INVOKE body by ARM64 ADR target.

No Objective-C ABI/semantics inferred from method names; no vendor runtime
included in newly compiled DuoFace. Input must be byte-identical immutable
DuoFaceDashboard.dylib and its method index (see VERIFIED_ORIGINAL_SHA below).
"""
import argparse
import bisect
import hashlib
import json
import pathlib
import re
import subprocess

VERIFIED_ORIGINAL_SHA="9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
VERIFIED_INDEX_BLOB="efa45df59bc3c16887cc979bf3aedc0c93c92111"
ORIGINAL_DEB_SHA="2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
IMP=0xad5bc
ADR_PC=0xadaa8
ADR_DELTA=460
EXPECTED_TARGET=0xadc74
LINE=re.compile(r"^\s*([0-9a-fA-F]+):\s+(\w[\w.]*)\s*(.*)$")

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--binary",type=pathlib.Path,required=True)
    p.add_argument("--method-index",type=pathlib.Path,required=True)
    p.add_argument("--original-instructions",type=pathlib.Path,required=True)
    p.add_argument("--out",type=pathlib.Path,required=True)
    a=p.parse_args()
    sha=hashlib.sha256(a.binary.read_bytes()).hexdigest()
    if sha!=VERIFIED_ORIGINAL_SHA:
        raise ValueError("Original Dashboard SHA mismatch")
    data=a.method_index.read_bytes()
    idxsha=hashlib.sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest()
    if idxsha!=VERIFIED_INDEX_BLOB:
        raise ValueError("Original Git method-index blob mismatch")
    idx=json.loads(data)
    dash=next(z for z in idx["native12"] if z["filename"]=="DuoFaceDashboard.dylib")
    if dash["sha256"]!=VERIFIED_ORIGINAL_SHA:
        raise ValueError("Wrong method index binary")
    method=next(z for z in dash["objc_methods"]
                if z["class"]=="CBBridgedUIAppView" and z["selector"]=="updateSceneSettingsFrame")
    if int(method["imp"],16)!=IMP:
        raise ValueError("Original IMP address changed")
    prior=json.loads(a.original_instructions.read_text())
    if prior["dashboard_macho_sha256"]!=VERIFIED_ORIGINAL_SHA:
        raise ValueError("Mismatched disassembly source")
    body=next(z["instructions"] for z in prior["methods"]
              if z["class"]=="CBBridgedUIAppView" and z["selector"]=="updateSceneSettingsFrame")
    observed={int(m.group(1),16):line for line in body
              if (m:=LINE.match(line))}
    if (f"adr\tx8, #{ADR_DELTA}" not in observed.get(ADR_PC,"")):
        raise ValueError("Original stack block ADR target not present")
    checks={
        0xada98:"str\tx8, [sp, #0x10]",
        0xada9c:"adrp\tx8,",
        0xadaa4:"str\td0, [sp, #0x18]",
        0xadaa8:f"adr\tx8, #{ADR_DELTA}",
        0xadab8:"stp\tx8, x9, [sp, #0x20]",
        0xadabc:"stp\td8, d9, [sp, #0x30]",
        0xadac0:"add\tx2, sp, #0x10",
        0xadacc:"bl\t0x2ecd00",
    }
    for pc,fragment in checks.items():
        if fragment not in observed.get(pc,""):
            raise ValueError("Original callsite mismatch "+hex(pc)+" "+fragment)
    target=ADR_PC+ADR_DELTA
    if target!=EXPECTED_TARGET:
        raise ValueError("Unexpected block invoke ADR")
    starts=sorted({int(v,16) for v in dash["lc_function_starts"]} |
                  {int(m["imp"],16) for m in dash["objc_methods"]})
    if target not in starts:
        raise ValueError("Original invoke does not coincide with verified function start")
    pos=bisect.bisect_right(starts,target)
    if pos>=len(starts):
        raise ValueError("Missing next function boundary")
    end=starts[pos]
    if not target<end<=target+0x2000:
        raise ValueError("Unreasonable bounded native function")
    raw=subprocess.run(["llvm-objdump","--macho","--disassemble",
                       "--no-show-raw-insn",str(a.binary)],capture_output=True,text=True,
                       encoding="utf8",errors="replace")
    if raw.returncode:
        raise RuntimeError("llvm-objdump failed: "+raw.stderr[-1000:])
    ins=[]
    for line in raw.stdout.splitlines():
        m=LINE.match(line)
        if not m:continue
        pc=int(m.group(1),16)
        if target<=pc<end:
            ins.append(line.strip())
    if not ins or not ins[0].startswith(hex(target)[2:]+":"):
        raise ValueError("Invoke body missing at target")
    result={
      "kind":"ORIGINAL_NATIVE12_ARM64_SCENE_SETTINGS_BLOCK_INVOKE_NOT_RUNTIME",
      "original_native12_deb_sha256":ORIGINAL_DEB_SHA,
      "dashboard_sha256":VERIFIED_ORIGINAL_SHA,
      "method_index_git_blob":VERIFIED_INDEX_BLOB,
      "caller_class":"CBBridgedUIAppView",
      "caller_selector":"updateSceneSettingsFrame",
      "caller_imp":hex(IMP),
      "callsite_adr_pc":hex(ADR_PC),
      "adr_offset_bytes":ADR_DELTA,
      "block_invoke_pc":hex(target),
      "next_function_pc":hex(end),
      "block_capture_pcs":[hex(pc) for pc in checks],
      "original_machine_instructions":ins,
      "vendor_binary_shipped":False,
      "new_runtime_changed":False,
      "device_validated":False,
      "inferred_scene_settings_abi":False,
    }
    a.out.mkdir(parents=True,exist_ok=True)
    path=a.out/"SCENE_SETTINGS_BLOCK_INVOKE_ARM64.json"
    path.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
    print("ORIGINAL_NATIVE12_SCENE_BLOCK_INVOKE_BYTES_VERIFIED",
          result["block_invoke_pc"],result["next_function_pc"],len(ins))

if __name__=="__main__":
    main()
