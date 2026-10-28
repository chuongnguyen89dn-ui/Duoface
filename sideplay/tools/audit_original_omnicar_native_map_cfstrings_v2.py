#!/usr/bin/env python3
"""Deep, read-only SHA-pinned OmniCar native CarPlay map dispatch inspection.

Resolves actual ARM64 CFString literals at original method callsites.
This is NOT authorization to host someone else's native CPWindow, nor a patch.
"""
import argparse,hashlib,json,re,struct,subprocess,tempfile
from pathlib import Path
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
from audit_omnicar_native_maps_dispatch_20261028 import SHA, arm64_fat, original_methods

METHODS=["isCarPlayApp:","openApp:slot:","hostApp:inPane:",
         "paneSize:forBundle:","publishCarPlayApps","pushSceneSizes",
         "pickerMapForPane:height:"]
MASK=(1<<48)-1

def cfstring(binary,address):
    if address<0 or address+32>len(binary):return None
    try:
        rawptr=struct.unpack_from("<Q",binary,address+16)[0]&MASK
        n=struct.unpack_from("<Q",binary,address+24)[0]
        if n<3 or n>160 or rawptr+n>len(binary):return None
        raw=binary[rawptr:rawptr+n]
        value=raw.decode("utf-8")
        if not value.isprintable() or "\x00" in value:return None
        return value
    except (ValueError,UnicodeError,struct.error):
        return None

def extract(binary,methods):
    dis=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
    allpc=sorted(set(methods.values()))
    out={}
    for name in METHODS:
        st=methods.get(("SCPCarSplit",name))
        if st is None:raise RuntimeError("missing original "+name)
        end=next((p for p in allpc if p>st),len(binary))
        if end<=st or end-st>0x10000:raise RuntimeError("method boundary invalid")
        ins=list(dis.disasm(binary[st:end],st))
        literals=[]
        calls=[]
        for i,x in enumerate(ins):
            # ADRP points at a page. Consecutive ADD builds exact CFString address.
            if x.mnemonic=="adrp" and i+1<len(ins):
                m=re.fullmatch(r"(x\d+),\s*#(0x[0-9a-f]+)",x.op_str)
                nxt=ins[i+1]
                if m and nxt.mnemonic=="add":
                    reg,page=m.groups()
                    a=re.fullmatch(r"("+reg+r"),\s*("+reg+r"),\s*#(0x[0-9a-f]+)",nxt.op_str)
                    if a:
                        target=int(page,16)+int(a.group(3),16)
                        value=cfstring(binary,target)
                        if value:
                            literals.append({"pc":hex(x.address),"cfstring":hex(target),
                                             "literal":value})
            if x.mnemonic in ("bl","blr"):
                calls.append({"pc":hex(x.address),"target":x.op_str})
        out[name]={"imp":hex(st),"end":hex(end),"instruction_count":len(ins),
                   "cfstring_literals":literals,"calls":calls,
                   "conditional_branches":[{"pc":hex(x.address),"asm":x.mnemonic+" "+x.op_str}
                     for x in ins if x.mnemonic.startswith(("tb","cb","b."))],
                   "selected_arm64_instruction_trace":[{"pc":hex(x.address),
                     "asm":x.mnemonic+" "+x.op_str} for x in ins[:min(245,len(ins))]]}
    return out

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--deb",type=Path,required=True)
    p.add_argument("--out",type=Path,required=True)
    a=p.parse_args()
    if hashlib.sha256(a.deb.read_bytes()).hexdigest()!=SHA:raise RuntimeError("original DEB SHA256 mismatch")
    with tempfile.TemporaryDirectory() as td:
        subprocess.run(["dpkg-deb","-x",str(a.deb),td],check=True)
        file=Path(td)/"var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarSplitScreen.dylib"
        binary=arm64_fat(file.read_bytes())
        result=extract(binary,original_methods(binary))
    data={"status":"ORIGINAL_ARM64_CFSTRING_AND_BRANCH_TRACE_ONLY_NOT_DEVICE_EXECUTION",
          "original_deb_sha256":SHA,"methods":result,
          "limits":["No source from OmniCar copied into DuoFace",
                    "A string or branch in binary does not prove device CarPlay map display",
                    "Native CarPlay map owner is distinct from iPhone SBDeviceApplicationSceneEntity",
                    "No speculative per-app visual zoom, no vendor entitlement or CPWindow impersonation"]}
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(data,indent=2,ensure_ascii=False)+"\n",encoding="utf8")
    print("OMNICAR_EXACT_NATIVE_SPLIT_CFSTRING_BRANCH_SCAN_PASS",
          len(result),"methods",sum(len(x["cfstring_literals"]) for x in result.values()),"literals")
if __name__=="__main__":main()
