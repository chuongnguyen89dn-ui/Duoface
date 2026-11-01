#!/usr/bin/env python3
"""Resolve original SpeedAlerts ARM64 dlsym strings and callback literal xrefs.

Read-only, no vendor code execution, no activation changes. Answers what
MSHookFunction at 0x393f0/0x39408/0x39420 really hooks, and searches for
references to the independently verified GOFA wrapper address pair.
"""
from __future__ import annotations
import argparse, gzip, json, re
from pathlib import Path

# Original disassembly from exact main audit. Addresses refer to thin ARM64 VM.
DLSYM_NAME_ADDRS=(0x54cf4,0x54d04,0x54d14)
CALLBACK_ADDRS={
    "gofa_alert_callback":0x3cfb4,
    "gofa_speed_callback":0x3d468,
    "gofa_alert_export":0x3e93c,
    "gofa_speed_export":0x3e38c,
}
ASMLINE=re.compile(r"^([0-9a-f]{16})\s+[0-9a-f]{8}\s+(\S+)(?:\s+(.*))?$")
ADRP=re.compile(r"^x(\d+), #0x([0-9a-f]+)$")
ADD=re.compile(r"^x(\d+), x(\d+), #0x([0-9a-f]+)$")
ADR=re.compile(r"^x(\d+), #0x([0-9a-f]+)$")
def c_string(raw:bytes,vmaddr:int,sec:dict)->str:
    if not sec["addr"]<=vmaddr<sec["addr"]+sec["size"]:
        raise RuntimeError("string address outside original __cstring: "+hex(vmaddr))
    offset=sec["offset"]+(vmaddr-sec["addr"])
    finish=raw.find(b"\0",offset,min(offset+256,sec["offset"]+sec["size"]))
    if finish<0:raise RuntimeError("not a bounded original C string at "+hex(vmaddr))
    return raw[offset:finish].decode("ascii")

def extract(asm:str,thin:bytes,loads:dict)->dict:
    sec=next(x for x in loads["sections"] if x["segment"]=="__TEXT" and x["section"]=="__cstring")
    names={hex(a):c_string(thin,a,sec) for a in DLSYM_NAME_ADDRS}
    # These are audio-session function names; the 3 associated MSHookFunction
    # calls in original 0x38f60 must NEVER be presented as GOFA data hooks.
    if tuple(names.values())!=("AudioQueueStart","AudioQueuePause","AudioQueueStop"):
        raise RuntimeError("unexpected dlsym symbols: "+str(names))
    rows=[]
    for line in asm.splitlines():
        m=ASMLINE.match(line)
        if m:rows.append((int(m[1],16),m[2],m[3] or "",line))
    xrefs=[]
    callbacks=set(CALLBACK_ADDRS.values())
    for i,(at,mnemonic,args,raw_line) in enumerate(rows):
        ma=ADRP.match(args) if mnemonic=="adrp" else None
        if ma:
            reg=int(ma[1]);base=int(ma[2],16)
            for j in range(i+1,min(i+14,len(rows))):
                at2,op,arguments,raw2=rows[j]
                if at2-at>52:break
                mb=ADD.match(arguments) if op=="add" else None
                if mb and int(mb[2])==reg and base+int(mb[3],16) in callbacks:
                    target=base+int(mb[3],16)
                    xrefs.append({"target":hex(target),"at":hex(at2),
                                  "base_address":hex(at),"instructions":[raw_line,raw2]})
        ma=ADR.match(args) if mnemonic=="adr" else None
        if ma and int(ma[2],16) in callbacks:
            xrefs.append({"target":hex(int(ma[2],16)),"at":hex(at),
                          "instructions":[raw_line]})
    # Exact callback function references can use Swift metadata or different
    # relocations, so an empty list is not evidence the callback is unused.
    return {"static_only":True,"verified_dlsym_names":names,
      "audio_hook_registration_call_sites":["0x393f0","0x39408","0x39420"],
      "hook_call_kind":"MSHookFunction with AudioQueueStart/Pause/Stop",
      "goFA_callback_addresses":{k:hex(v) for k,v in CALLBACK_ADDRS.items()},
      "direct_adrp_add_or_adr_callback_literal_xrefs":xrefs,
      "limitations":"Does not decode Swift object layouts or prove runtime GOFA alert delivery."}

def main():
    ap=argparse.ArgumentParser()
    for n in ("thin","load_commands","disassembly","out"):
        ap.add_argument("--"+n.replace("_","-"),type=Path,required=True)
    a=ap.parse_args()
    result=extract(gzip.decompress(a.disassembly.read_bytes()).decode(),
      a.thin.read_bytes(),json.loads(a.load_commands.read_text()))
    a.out.mkdir(parents=True,exist_ok=True)
    (a.out/"GOFA_HOOK_REGISTRATION_CORRECTION.json").write_text(json.dumps(result,indent=2)+"\n")
    lines=["# Evidence correction: original CarPlayPro Speed 0.9.97 GOFA vs AudioQueue",
      "","**CONFIRMED**: The three `dlsym` names loaded at 0x393a0, 0x393b4 and 0x393c8",
      "are **AudioQueueStart, AudioQueuePause, AudioQueueStop** respectively.",
      "Thus the `MSHookFunction` calls at 0x393f0/0x39408/0x39420",
      "observe AUDIO, not the GOFA speed/traffic alert data source.",
      "These calls had been incorrectly labelled 'GOFA candidate' in an earlier",
      "static report; the corrected label is 'AudioQueue monitoring'.",
      "","## Original exact __cstring addresses"]
    lines += ["- `"+k+"`: `"+v+"`" for k,v in result["verified_dlsym_names"].items()]
    lines += ["","## Literal references to GOFA data helper/callback addresses",
      "Detected direct ADR/ADRP+ADD patterns (not a complete Swift/ObjC xref graph)."]
    for x in result["direct_adrp_add_or_adr_callback_literal_xrefs"][:140]:
        lines += ["- callback `"+x["target"]+"` referenced at `"+x["at"]+"`"]
    if not result["direct_adrp_add_or_adr_callback_literal_xrefs"]:
        lines += ["- None matched; indirect Swift/ObjC and encoded relocations remain unexamined."]
    lines += ["","## Next forensic target",
      "Distinguish actual GOFA Swift model hooks from unrelated audio hooks.",
      "The real GOFA callback addresses `0x3cfb4` and `0x3d468`",
      "invoke original `_SAGofaAlertPayload` at `0x3e93c` and",
      "`_SAGofaSpeedPayload` at `0x3e38c`, respectively.",
      "Their actual GOFA producer types and model schema are not yet proved.",
      "No camera/sign/turn data should be invented on DuoFace."]
    (a.out/"GOFA_HOOK_REGISTRATION_CORRECTION.md").write_text("\n".join(lines)+"\n")
    print("QA166_ORIGINAL_AUDIO_HOOK_NOT_GOFA_PROVEN",len(result["direct_adrp_add_or_adr_callback_literal_xrefs"]))
if __name__=="__main__":
    main()
