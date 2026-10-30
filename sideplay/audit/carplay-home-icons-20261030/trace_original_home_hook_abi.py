#!/usr/bin/env python3
"""Bounded, source-independent ABI research for original iOS16 CARApplication hooks.

Original ARM64 is decoded exclusively in CI and audit-only output is produced.
No vendor dylib or implementation is shipped as part of DuoFace.
"""
import argparse,bisect,hashlib,json,re,struct
from pathlib import Path
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
from audit_native12_license_class_xrefs import MachO,select_arm64

PINS={
 "DuoNavi104":("44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15",{
  "home_library_hook_registration":0x3106f4,
  "catalog_enabled_installed":0x2f16bc,
  "carplay_appinfo_factory":0x2f2130,
  "launch_as_car_application":0x2f2bdc}),
 "Native12Reference":("9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea",{
  "home_library_hook_registration":0x2e9d48,
  "catalog_enabled_installed":0x2ca974,
  "carplay_appinfo_factory":0x2cb5c0,
  "launch_as_car_application":0x2cc0b0})
}
RELEVANT=("CARApplication","_newApplicationLibrary","CARApplicationInfo","DBApplicationInfo",
          "setLaunchAsCarApplication:","bridgedApps","allInstalledApplications",
          "MSHookMessageEx","notify_register","objc_msgSend","class_get",
          "update","settings")
def starts(m):
 p=32; t=next(x[0] for x in m.segments if x[4]=="__TEXT");out=[]
 for _ in range(m.ncmds):
  c,s=struct.unpack_from("<II",m.data,p)
  if c==0x26:
   off,count=struct.unpack_from("<II",m.data,p+8)
   vm=t;v=shift=0
   for b in m.data[off:off+count]:
    v|=(b&127)<<shift
    if b&128:shift+=7;continue
    if not v:break
    vm+=v;out.append(vm);v=shift=0
  p+=s
 return sorted(set(out))
def inspect(name,path):
 pin,targets=PINS[name]
 data=path.read_bytes()
 assert hashlib.sha256(data).hexdigest()==pin,(name,"wrong original SHA")
 m=MachO(select_arm64(data)); boundaries=starts(m)
 cs=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
 report={}
 for label,lo in targets.items():
  assert lo in boundaries,(name,label,"invalid LC_FUNCTION_STARTS boundary")
  ix=bisect.bisect_right(boundaries,lo)
  hi=boundaries[ix] if ix<len(boundaries) else lo+0x1000
  length=(hi-lo)//4
  assert 20<=length<=3000,(name,label,length)
  ins=list(cs.disasm(m.data[m.map(lo):m.map(lo)+4*length],lo))
  assert len(ins)==length,(name,label,"incomplete decode")
  # Small bounded audit windows, not a reconstructed vendor implementation.
  head=[f"{x.address:#x} {x.mnemonic} {x.op_str}" for x in ins[:50]]
  calls=[{"pc":hex(x.address),"op":x.mnemonic,"dest":x.op_str}
         for x in ins if x.mnemonic in ("bl","blr","br")][:160]
  returns=[hex(x.address) for x in ins if x.mnemonic=="ret"][:20]
  class_refs=[{"pc":hex(x.address),"instruction":x.mnemonic+" "+x.op_str}
    for x in ins if x.mnemonic in ("adr","adrp","ldr")][:100]
  tail=[f"{x.address:#x} {x.mnemonic} {x.op_str}" for x in ins[-32:]]
  report[label]={"lo":hex(lo),"hi":hex(hi),"instructions":length,
   "head":head,"calls":calls,"returns":returns,"pc_relative":class_refs,"tail":tail}
  print(name,label,hex(lo),hex(hi),"insns",length,"calls",len(calls),
        "returns",len(returns))
 return {"sha256":pin,"functions":report}
def main():
 p=argparse.ArgumentParser()
 p.add_argument("--duonavi",required=True,type=Path)
 p.add_argument("--native12",required=True,type=Path)
 p.add_argument("--out",required=True,type=Path)
 a=p.parse_args()
 report={"purpose":"original function bounds, external callsites, ABI hints only; no physical test",
         "DuoNavi104":inspect("DuoNavi104",a.duonavi),
         "Native12Reference":inspect("Native12Reference",a.native12)}
 a.out.parent.mkdir(parents=True,exist_ok=True)
 a.out.write_text(json.dumps(report,indent=2)+"\n")
 print("ORIGINAL_IOS16_HOME_LIBRARY_FOUR_FUNCTIONS_EACH_ABI_RESEARCH_COMPLETE")
if __name__=="__main__":main()
