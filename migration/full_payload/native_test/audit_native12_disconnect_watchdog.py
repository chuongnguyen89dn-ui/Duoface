#!/usr/bin/env python3
"""Read-only arm64 disassembly of actual native12 CarPlay disconnect watchdog.
Produce exact offsets, branch targets, literals and code evidence, NOT speculation.
No changes to Mach-O, pkg, installed device, hook, or Sileo.
"""
from __future__ import annotations
import argparse, hashlib, json, re, subprocess, tempfile
from pathlib import Path
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
from audit_native12_license_class_xrefs import MachO, select_arm64, NATIVE12_SHA, BINARIES

TARGETS=(
 "scheduleMandatoryDisconnectWatchdog",
 "cancelMandatoryDisconnectWatchdog",
 "enforceMandatoryDisconnectKill",
 "handleScreenDidDisconnect:",
 "handleScreenDidConnect:",
 "handleCarPlayConnectionChanged:",
 "terminateAllBridgedApplications",
 "terminateApplicationWithBundleID:",
 "collectActiveAndSessionAppBundleIDs",
 "killProcessesForBundleIdentifiers:",
 "performAutoResume",
)
def methods(m, classname):
    cls=m.classes()[classname]
    base=cls["class_ptr"]; allmethods=[]
    for kind,obj in (("-",base),("+",m.ptr(base))):
        if not obj:continue
        ro=m.ptr(obj+32)&~7
        head=m.ptr(ro+32)
        if not head:continue
        flags,count=m.p32(head),m.p32(head+4)
        assert count<500
        relative=bool(flags&0x80000000)
        stride=12 if relative else 24
        for i in range(count):
            e=head+8+i*stride
            if relative:
                name_vm=e+m.pi32(e)
                selvm=name_vm if flags&0x40000000 else m.ptr(name_vm)
                imp=e+8+m.pi32(e+8)
            else:
                selvm=m.ptr(e);imp=m.ptr(e+16)
            name=m.cstr(selvm)
            if name:
                allmethods.append((kind+name,imp))
    return allmethods

def disasm(m, address, maxbytes, known):
    off=m.map(address)
    region=m.data[off:off+maxbytes]
    cs=Cs(CS_ARCH_ARM64, CS_MODE_ARM)
    lines=[]
    for instr in cs.disasm(region,address):
        if len(lines)>=500:break
        operands=instr.op_str
        interesting=(instr.mnemonic in ("bl","blr","b","ret","cbz","cbnz",
             "tbz","tbnz","mov","movk","movz","movn","adr","adrp",
             "add","ldr","ldur","str","stp","fmov","fcvt","fmul","scvtf"))
        comment=""
        if instr.mnemonic=="bl":
            try:
                target=int(operands.strip().lstrip("#"),0)
                if target in known:comment=" ; DIRECT_INTERNAL_METHOD="+known[target]
            except ValueError:pass
        if interesting:
            lines.append({"vm":hex(instr.address),"asm":instr.mnemonic+" "+operands+comment,
                          "machine":instr.bytes.hex()})
        else:
            lines.append({"vm":hex(instr.address),"asm":instr.mnemonic+" "+operands})
    return lines

def ascii_strings_near(m, words):
    allstrings=[]
    for sec in m.sections:
        if sec["name"] not in ("__cstring","__objc_methname","__objc_methtype"):continue
        off=sec["fileoff"]
        raw=m.data[off:off+sec["size"]]
        for mat in re.finditer(rb"[\x20-\x7e]{5,}\x00",raw):
            s=mat.group()[:-1].decode("ascii","replace")
            if any(w in s.lower() for w in words):
                allstrings.append({"vm":hex(sec["vm"]+mat.start()),"string":s[:320]})
    return allstrings[:130]

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--deb",type=Path,required=True)
    ap.add_argument("--out",type=Path,required=True)
    args=ap.parse_args()
    assert hashlib.sha256(args.deb.read_bytes()).hexdigest()==NATIVE12_SHA
    with tempfile.TemporaryDirectory(prefix="df-watchdog-native12-") as t:
        subprocess.run(["dpkg-deb","-x",str(args.deb),t],check=True)
        raw=(Path(t)/BINARIES["DuoFaceDashboard"]).read_bytes()
    m=MachO(select_arm64(raw))
    cls=methods(m,"CBBridgeManager")
    alladdrs=sorted(set(address for _,address in cls))
    byname=dict(cls);known={address:name for name,address in cls}
    out={}
    for selector in TARGETS:
        name="-"+selector
        if name not in byname:raise RuntimeError("missing "+name)
        start=byname[name]
        nextaddress=next((v for v in alladdrs if v>start),start+2000)
        # Never bleed unboundedly into unrelated method implementations.
        region=min(nextaddress-start,4096)
        ins=disasm(m,start,region,known)
        out[selector]={"vm":hex(start),"fileoff":hex(m.map(start)),
                       "upper_bound_next_method":hex(nextaddress),
                       "disassembled_bytes":len(ins)*4,
                       "lines":ins}
    data={
      "status":"NATIVE12_DISCONNECT_WATCHDOG_CODE_READONLY",
      "deb_sha256":NATIVE12_SHA,
      "host_sha256":hashlib.sha256(raw).hexdigest(),
      "arm64_sha256":hashlib.sha256(m.data).hexdigest(),
      "class":"CBBridgeManager",
      "methods":out,
      "related_strings":ascii_strings_near(m,
         ("watchdog","disconnect","mandatory","kill","carplay","cleanup","expire","sec","timeout")),
      "assumptions_not_proven_by_static_disassembly":[
        "actual on-device event dispatch","live timer wall-clock delay",
        "which apps are terminated","whether user toggles change native12 behavior"],
      "deb_modified":False,
    }
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(data,ensure_ascii=False,indent=2)+"\n")
    print(json.dumps({"status":data["status"],"methods":
            {k:{"vm":v["vm"],"instructions":len(v["lines"])} for k,v in out.items()},
          "related_strings":len(data["related_strings"])},indent=2))
    for k in ("scheduleMandatoryDisconnectWatchdog","cancelMandatoryDisconnectWatchdog",
              "enforceMandatoryDisconnectKill","handleScreenDidDisconnect:"):
        print("METHOD",k,"BEGIN")
        for l in out[k]["lines"][:240]:
            print(l["vm"],l["asm"])
        print("METHOD",k,"END")
if __name__=="__main__":main()
