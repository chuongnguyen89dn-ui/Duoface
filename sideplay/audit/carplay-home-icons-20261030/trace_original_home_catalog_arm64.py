#!/usr/bin/env python3
"""Bounded read-only original ARM64 symbol xrefs for iOS16 CarPlay Home.

No vendor code is executed or copied; only reference addresses and target names
are persisted. Xrefs do NOT alone establish runtime invocation or launch.
"""
import argparse
import bisect
import hashlib
import json
import re
import struct
from pathlib import Path
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
from audit_native12_license_class_xrefs import MachO, select_arm64

SHA={
"DuoNavi104":"44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15",
"Native12Reference":"9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea",
}
LOOKUP=["_newApplicationLibrary","CARApplication","CARApplicationInfo",
 "DBApplicationInfo","setLaunchAsCarApplication:","bridgedApps",
 "received settings updated notification","MSHookMessageEx",
 "homeButtonUp:","showAppPickerForSlot:","appSelected:",
 "allInstalledApplications","SBStarkCapable","CARCapableApp",
 "entitlementValueForKey:ofClass:valuesOfClass:"]
def functions(m):
 out=[];position=32
 textbase=next(seg[0] for seg in m.segments if seg[4]=="__TEXT")
 for _ in range(m.ncmds):
  cmd,size=struct.unpack_from("<II",m.data,position)
  if cmd==0x26:
   off,length=struct.unpack_from("<II",m.data,position+8)
   current=textbase;value=shift=0
   for byte in m.data[off:off+length]:
    value|=(byte&127)<<shift
    if byte&128:shift+=7;continue
    if not value:break
    current+=value;out.append(current);value=shift=0
  position+=size
 return sorted(set(out))
def xrefs(m):
 target={}
 for sec in m.sections:
  if sec["name"] not in ("__cstring","__objc_methname","__objc_classname"):
   continue
  body=m.data[sec["fileoff"]:sec["fileoff"]+sec["size"]]
  for key in LOOKUP:
   index=body.find(key.encode()+b"\0")
   while index>=0:
    if index==0 or body[index-1]==0:
     target.setdefault(sec["vm"]+index,set()).add(key)
    index=body.find(key.encode()+b"\0",index+1)
 # Convert literal slot pointers (selrefs, classrefs) to the named target.
 for sec in m.sections:
  if not (sec["segment"].startswith(("__DATA","__AUTH")) and sec["size"]<25000000):continue
  body=m.data[sec["fileoff"]:sec["fileoff"]+sec["size"]]
  for vm,names in list(target.items()):
   packed=struct.pack("<Q",vm)
   i=body.find(packed)
   while i>=0:
    if i%8==0:target.setdefault(sec["vm"]+i,set()).update(names)
    i=body.find(packed,i+8)
 return target
def inspect(name,file):
 raw=file.read_bytes()
 assert hashlib.sha256(raw).hexdigest()==SHA[name],"wrong signed original image"
 m=MachO(select_arm64(raw))
 refs=xrefs(m); starts=functions(m)
 cs=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
 calls=[];seen=set()
 for sec in m.sections:
  if sec["name"]!="__text":continue
  body=m.data[sec["fileoff"]:sec["fileoff"]+sec["size"]]
  recent={}
  for ins in cs.disasm(body,sec["vm"]):
   op=ins.op_str
   if ins.mnemonic=="adrp":
    a=re.fullmatch(r"(x\d+), #0x([0-9a-f]+)",op)
    if a:recent[a[1]]=(int(a[2],16),ins.address)
    continue
   addr=None
   if ins.mnemonic in ("ldr","add"):
    b=re.fullmatch(r"(x\d+), (x\d+), #0x([0-9a-f]+)",op)
    if b and b[2] in recent and ins.address-recent[b[2]][1]<96:
     addr=recent[b[2]][0]+int(b[3],16)
    else:
     b=re.fullmatch(r"(x\d+), \[(x\d+), #0x([0-9a-f]+)\]",op)
     if b and b[2] in recent and ins.address-recent[b[2]][1]<96:
      addr=recent[b[2]][0]+int(b[3],16)
   if ins.mnemonic in ("adr","ldr") and addr is None:
    a=re.fullmatch(r"x\d+, #0x([0-9a-f]+)",op)
    if a:addr=int(a[1],16)
   if addr is None or addr not in refs:continue
   index=bisect.bisect_right(starts,ins.address)-1
   begin=starts[index] if index>=0 else None
   for marker in refs[addr]:
    dedup=(marker,begin,ins.address)
    if dedup in seen:continue
    seen.add(dedup)
    calls.append({"marker":marker,"instruction":hex(ins.address),
                  "function_start":hex(begin) if begin else None,
                  "target_pointer_or_literal":hex(addr)})
 return {"sha256":SHA[name],"function_count":len(starts),"ref_count":len(refs),
         "xref_count":len(calls),"references":calls[:250],
         "strings":["%s:%s"%(hex(k),",".join(sorted(v))) for k,v in refs.items()
           if any(x in v for x in ("_newApplicationLibrary","setLaunchAsCarApplication:"))][:30]}
def main():
 p=argparse.ArgumentParser()
 p.add_argument("--duonavi-image",type=Path,required=True)
 p.add_argument("--native12-image",type=Path,required=True)
 p.add_argument("--out",type=Path,required=True)
 a=p.parse_args()
 result={"evidence":"full original ARM64 direct PC-relative xrefs, not an executed app",
   "DuoNavi104":inspect("DuoNavi104",a.duonavi_image),
   "Native12Reference":inspect("Native12Reference",a.native12_image)}
 a.out.parent.mkdir(parents=True,exist_ok=True)
 a.out.write_text(json.dumps(result,indent=2)+"\n")
 for k in ("DuoNavi104","Native12Reference"):
  r=result[k]
  print(k,"function starts",r["function_count"],"typed-marker-xrefs",r["xref_count"])
 print("ORIGINAL_IOS16_HOME_CATALOG_ARM64_REFERENCE_SCAN_PASS")
if __name__=="__main__":main()
