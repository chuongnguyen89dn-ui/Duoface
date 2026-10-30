#!/usr/bin/env python3
"""Deep, bounded, original OmniCar BKS hook trace, read-only.

Disassembles the real BKS symbol resolver, suspected function replacement and
original-pointer storage consumers. Also examines Native12 original known 1/0
calls for controlled contrasts. Outputs instructions/evidence, never patches
binaries or treats static paths as witnessed on the car.
"""
import argparse
import hashlib
import json
import re
import struct
import subprocess
import tempfile
from pathlib import Path
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
from audit_native12_license_class_xrefs import MachO, select_arm64
from audit_native12_carplay_add_app_chain import methods

PINS={
 "OmniCar103":"d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd",
 "Native12Derived":"2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad",
 "DuoNavi104":"f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd"
}
PATHS={
 "OmniCar103":"var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarAppBridge.dylib",
 "Native12Derived":"var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib",
 "DuoNavi104":"var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.dylib"
}
CS=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
def sha(path):
 h=hashlib.sha256()
 with open(path,"rb") as s:
  for p in iter(lambda:s.read(1048576),b""):h.update(p)
 return h.hexdigest()
def asm(m,start,size):
 ofs=m.map(start)
 ins=list(CS.disasm(m.data[ofs:ofs+size],start))
 return [{"pc":hex(x.address),"mnemonic":x.mnemonic,"op":x.op_str} for x in ins]
def registers(m,sel):
 # Inspect __text for literal address producer and direct + indirect load users.
 needle=sel
 hit=[]
 for sec in m.sections:
  if sec["name"]!="__text" or sec["size"]>10000000:continue
  inst=list(CS.disasm(m.data[sec["fileoff"]:sec["fileoff"]+sec["size"]],sec["vm"]))
  for i,x in enumerate(inst):
   if x.mnemonic in ("adrp","add","ldr","str","adr"):
    if hex(sel) in x.op_str:
     hit.append({"pc":hex(x.address),"op":x.op_str,"before":[f"{y.address:#x} {y.mnemonic} {y.op_str}" for y in inst[max(i-7,0):i]],"after":[f"{y.address:#x} {y.mnemonic} {y.op_str}" for y in inst[i:i+12]]})
 return hit[:40]
def adrp_add_xrefs(m,vm):
 found=[]
 for sec in m.sections:
  if sec["name"]!="__text" or sec["size"]>15000000:continue
  inst=list(CS.disasm(m.data[sec["fileoff"]:sec["fileoff"]+sec["size"]],sec["vm"]))
  p={}
  for i,z in enumerate(inst):
   if z.mnemonic=="adrp":
    f=re.fullmatch(r"(x\d+), #(0x[0-9a-f]+)",z.op_str)
    if f:p[f.group(1)]=int(f.group(2),16)
   elif z.mnemonic in ("add","ldr","str"):
    if z.mnemonic=="add":
     f=re.fullmatch(r"(x\d+), (x\d+), #(0x[0-9a-f]+)",z.op_str)
     target=p[f.group(2)]+int(f.group(3),16) if f and f.group(2) in p else None
    else:
     f=re.fullmatch(r"(x\d+), \[(x\d+), #(0x[0-9a-f]+)\]",z.op_str)
     target=p[f.group(2)]+int(f.group(3),16) if f and f.group(2) in p else None
    if target==vm:
     found.append({"pc":hex(z.address),"kind":z.mnemonic,"instructions":[f"{y.address:#x} {y.mnemonic} {y.op_str}" for y in inst[max(0,i-8):min(len(inst),i+18)]]})
 return found[:50]
def class_method_owners(m,pcs):
 try:
  entries=[]
  for cls in m.classes():
   for name,x in methods(m,cls).items():
    if x["vm"]:entries.append((x["vm"],cls,name,x.get("type","")))
  entries.sort()
  out={}
  for pc in pcs:
   preceding=[(vm,cl,sel,typ) for vm,cl,sel,typ in entries if vm<=pc]
   if preceding:
    vm,cl,sel,typ=preceding[-1]
    # Nearest method entry is not guaranteed the true owner due to anonymous C
    # functions, so never describe this as proven class ownership.
    out[hex(pc)]={"nearest_previous_objc_method":f"{cl}.{sel}","method_start":hex(vm),
                  "distance":pc-vm,"proven_same_function":False}
  return out
 except (ValueError,IndexError,AssertionError,KeyError):
  return {"status":"objc method metadata unable to resolve"}
def main():
 p=argparse.ArgumentParser()
 for name in PINS:p.add_argument("--"+name,required=True,type=Path)
 p.add_argument("--out",required=True,type=Path)
 args=p.parse_args()
 results={"kind":"deep native ARM64 BKS callback and direct xrefs on three real original DEBs",
          "dynamic_executed_on_user_phone":False,"patches_applied":False,
          "not_a_brightness_or_touch_fix":True,"packages":{}}
 with tempfile.TemporaryDirectory() as t:
  for name,expected in PINS.items():
   path=getattr(args,name)
   actual=sha(path)
   if actual!=expected:raise RuntimeError(f"SHA256 FAIL {name}: {actual}")
   root=Path(t)/name
   subprocess.run(["dpkg-deb","-x",str(path),str(root)],check=True,capture_output=True)
   data=(root/PATHS[name]).read_bytes()
   m=MachO(select_arm64(data))
   results["packages"][name]={"deb_sha256":actual,"embedded_dylib_sha256":hashlib.sha256(data).hexdigest()}
   if name=="OmniCar103":
    # Exact pc register values from prior complete six-DEB scan 41057818631.
    register=asm(m,0x6ef0,0xb0)
    assert any(z["pc"]=="0x6f54" and z["op"]=="x1, x1, #0x3ee" for z in register)
    assert any(z["pc"]=="0x6f5c" and z["mnemonic"]=="bl" for z in register)
    assert any(z["pc"]=="0x6f80" and z["mnemonic"]=="b" for z in register)
    # A successful dynamic lookup transfers BKS replacement=0x777c,
    # old function pointer storage=0x3ea10, then dispatches to a function
    # stub 0x243e0. The hook call is not the BKS function itself.
    assert any(z["pc"]=="0x6f68" and "#0x77c" in z["op"] for z in register)
    assert any(z["pc"]=="0x6f70" and "#0xa10" in z["op"] for z in register)
    results["packages"][name].update({
      "register_bks_dlsym_and_hook":{"pc":"0x6f54","instructions":register,
          "likely_replace_function_vm":"0x777c","original_pointer_slot_vm":"0x3ea10",
          "symbol_looked_up":"BKSDisplayServicesSetScreenBlanked",
          "hook_installer_stub":"0x243e0","hook_installer_symbol_identity":"not independently resolved"},
      "replacement_callback":{"entry":"0x777c","instructions":asm(m,0x777c,0x160)},
      "original_pointer_slot_users":adrp_add_xrefs(m,0x3ea10),
      "replacement_function_xrefs":adrp_add_xrefs(m,0x777c),
      "callsite_stubs":{"dlsym":"0x245f0","hook_installer":"0x243e0",
                        "dlsym_stub_instructions":asm(m,0x245f0,0x20),
                        "hook_stub_instructions":asm(m,0x243e0,0x20)},
      "nearest_objc_owners":class_method_owners(m,[0x6f54,0x777c])})
   else:
    callsites=([0x31af0,0x31da8] if name=="Native12Derived" else
               [0xae32c,0x16169c,0x192e68,0x1a63dc,0x1a642c,0x1bf0d0])
    results["packages"][name]["symbol_resolution_callers"]=[
      {"literal_pc":hex(pc),"bounded_instructions":asm(m,pc-0x14,0x54)}
      for pc in callsites]
 path=args.out
 path.mkdir(parents=True,exist_ok=True)
 (path/"DEEP_BKS_ARM64.json").write_text(json.dumps(results,indent=2,ensure_ascii=False)+"\n")
 entry=results["packages"]["OmniCar103"]["replacement_callback"]["instructions"]
 msg=" ".join(f"{x['pc']}:{x['mnemonic']}:{x['op']}" for x in entry[:30])
 print("OMNICAR_BKS_HOOK_AND_REPLACEMENT_REAL_DEB_SHA_PASS",msg[:900])
 print("BKS_TRACE_USERS",len(results["packages"]["OmniCar103"]["original_pointer_slot_users"]))
if __name__=="__main__":main()
