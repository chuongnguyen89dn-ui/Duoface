#!/usr/bin/env python3
"""Read-only ARM64 xref map for original CARApplication Home roster hooks.

No original binary/instructions stored; report contains function boundaries,
literal/selector reference kinds and aggregate counts only.
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

PINS={
 "DuoNavi104":"44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15",
 "Native12Reference":"9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"}
MARKERS=[
 "CARApplication","CARApplicationInfo","DBApplicationInfo",
 "_newApplicationLibrary","setLaunchAsCarApplication:",
 "bridgedApps","appSelected:","homeButtonUp:",
 "MSHookMessageEx","shouldInterceptLaunchForApp:",
 "isBridgedApp:","received settings updated notification"]
def function_starts(m):
 data=m.data
 pos=32
 base=next(v[0] for v in m.segments if v[4]=="__TEXT")
 starts=[]
 for _ in range(m.ncmds):
  cmd,size=struct.unpack_from("<II",data,pos)
  if cmd==0x26:
   off,length=struct.unpack_from("<II",data,pos+8)
   vm=base;d=0;bits=0
   for x in data[off:off+length]:
    d|=(x&127)<<bits
    if x&128:bits+=7;continue
    if not d:break
    vm+=d;starts.append(vm);d=bits=0
  pos+=size
 return sorted(set(starts))
def literals(m):
 out={}
 for sec in m.sections:
  if sec["name"] not in ("__cstring","__objc_methname","__objc_classname"):continue
  raw=m.data[sec["fileoff"]:sec["fileoff"]+sec["size"]]
  for word in MARKERS:
   item=word.encode()+b"\0"
   at=raw.find(item)
   while at>=0:
    if at==0 or raw[at-1]==0:
     out[sec["vm"]+at]=word
    at=raw.find(item,at+1)
 return out
def targets(m,actual):
 out=dict(actual)
 for sec in m.sections:
  if sec["name"] not in ("__objc_selrefs","__objc_classrefs","__cfstring"):continue
  if sec["size"]>5_000_000:continue
  for off in range(0,sec["size"]-7,8):
   addr=sec["vm"]+off
   ptr=struct.unpack_from("<Q",m.data,sec["fileoff"]+off)[0]
   if ptr in actual:
    out[addr]="indirect:"+actual[ptr]
 return out
def analyze(name,path):
 raw=path.read_bytes()
 sha=hashlib.sha256(raw).hexdigest()
 assert sha==PINS[name],(name,"bad original image")
 m=MachO(select_arm64(raw))
 found=literals(m)
 hits=targets(m,found)
 starts=function_starts(m)
 cs=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
 reports={}
 for sec in m.sections:
  if sec["name"]!="__text":continue
  page={}
  for ins in cs.disasm(m.data[sec["fileoff"]:sec["fileoff"]+sec["size"]],sec["vm"]):
   op=ins.op_str
   reg=None;target=None
   a=re.match(r"(x[0-9]+), #(?:0x)?([0-9a-f]+)$",op)
   if ins.mnemonic in ("adrp","adr") and a:
    reg=a[1];val=int(a[2],16)
    if ins.mnemonic=="adrp":page[reg]=val
    target=val
   b=re.match(r"(x[0-9]+), (x[0-9]+), #(?:0x)?([0-9a-f]+)$",op)
   if ins.mnemonic=="add" and b and b[2] in page:
    reg=b[1];target=page[b[2]]+int(b[3],16)
   c=re.match(r"(x[0-9]+), \[(x[0-9]+), #(?:0x)?([0-9a-f]+)\]$",op)
   if ins.mnemonic=="ldr" and c and c[2] in page:
    reg=c[1];target=page[c[2]]+int(c[3],16)
   if target in hits:
    idx=bisect.bisect_right(starts,ins.address)-1
    boundary=starts[idx] if idx>=0 else None
    marker=hits[target]
    key=hex(boundary) if boundary is not None else "none"
    row=reports.setdefault(key,{"vm":key,"refs":[]})
    if len(row["refs"])<36:
     row["refs"].append({"pc":hex(ins.address),"marker":marker,"op":ins.mnemonic})
   if reg and target is not None and ins.mnemonic!="ldr":
    page[reg]=target
 records=sorted(reports.values(),key=lambda x:int(x["vm"],16) if x["vm"]!="none" else -1)
 return {"name":name,"sha256":sha,"tracked_literals":len(found),
         "tracked_adr_targets":len(hits),"function_refs":records,
         "matchedFunctions":len(records)}
def main():
 p=argparse.ArgumentParser()
 p.add_argument("--duonavi",type=Path,required=True)
 p.add_argument("--native12",type=Path,required=True)
 p.add_argument("--out",type=Path,required=True)
 a=p.parse_args()
 v={"scope":"SHA-verified exact original ARM64 adrp/adr selector/literal xrefs; not live execution",
    "DuoNavi104":analyze("DuoNavi104",a.duonavi),
    "Native12Reference":analyze("Native12Reference",a.native12)}
 a.out.parent.mkdir(parents=True,exist_ok=True)
 a.out.write_text(json.dumps(v,indent=2,ensure_ascii=False)+"\n")
 for k in ("DuoNavi104","Native12Reference"):
  r=v[k]
  for x in r["function_refs"]:
   refs="|".join(sorted(set(z["marker"] for z in x["refs"])))
   if "newApplicationLibrary" in refs or "CARApplication" in refs:
    print(k,"HOME_ROSTER_XREF",x["vm"],refs[:250])
  print(k,"XREF_FUNCTIONS",r["matchedFunctions"])
if __name__=="__main__":main()
