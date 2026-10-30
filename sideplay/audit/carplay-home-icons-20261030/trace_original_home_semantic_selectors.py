#!/usr/bin/env python3
"""Read-only original Home catalog selector data-flow in 4 exact ARM64 functions.

SHA-checked original DuoNavi and Native12-derived images. Captures selector and
NSString names plus virtual machine addresses; no disassembled vendor methods.
"""
import argparse,hashlib,json,re,struct
from pathlib import Path
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
from audit_native12_license_class_xrefs import MachO,select_arm64
NAMES={
 "DuoNavi104":("44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15",
     [(0x3106f4,0x310a50,"home_library_register"),
      (0x2f16bc,0x2f2130,"catalog_merge"),
      (0x2f2130,0x2f22a0,"appinfo_register"),
      (0x2f2bdc,0x2f2ed0,"launch_policy")]),
 "Native12Reference":("9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea",
     [(0x2e9d48,0x2ea0a4,"home_library_register"),
      (0x2ca974,0x2cb5c0,"catalog_merge"),
      (0x2cb5c0,0x2cb730,"appinfo_register"),
      (0x2cc0b0,0x2cc3a4,"launch_policy")])
}
def annotation(m,vm):
 if not vm:return None
 kind=None
 for sec in m.sections:
  if sec["vm"]<=vm<sec["vm"]+sec["size"]:
   kind=sec["name"];break
 if not kind:return None
 try:
  if kind=="__objc_selrefs":
   return {"kind":"selector","name":m.cstr(m.ptr(vm))}
  if kind=="__cfstring":
   return {"kind":"cfstring","name":m.cstr(m.ptr(vm+16))}
  if kind in ("__cstring","__objc_methname","__objc_classname"):
   return {"kind":kind,"name":m.cstr(vm)}
  if kind=="__objc_classrefs":
   return {"kind":"classref","name":hex(m.ptr(vm))}
 except (ValueError,KeyError,IndexError,UnicodeDecodeError,struct.error):
  return None
 return None
def one(m,lo,hi,label):
 cs=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
 code=m.data[m.map(lo):m.map(lo)+(hi-lo)]
 events=[]
 page={}
 for ins in cs.disasm(code,lo):
  opcode=ins.mnemonic
  s=ins.op_str
  target=None
  if opcode in ("adrp","adr"):
   a=re.fullmatch(r"(x\d+), #(0x[0-9a-f]+)",s)
   if a:
    target=int(a[2],16)
    if opcode=="adrp":page[a[1]]=target
  elif opcode in ("add","ldr"):
   a=re.fullmatch(r"(x\d+), (x\d+), #(0x[0-9a-f]+)",s)
   if opcode=="add" and a and a[2] in page:
    target=page[a[2]]+int(a[3],16)
   b=re.fullmatch(r"(x\d+), \[(x\d+), #(0x[0-9a-f]+)\]",s)
   if opcode=="ldr" and b and b[2] in page:
    target=page[b[2]]+int(b[3],16)
   c=re.fullmatch(r"(x\d+), #(0x[0-9a-f]+)",s)
   if opcode=="ldr" and c:target=int(c[2],16)
  a=annotation(m,target)
  if a and a.get("name") and len(a["name"])<=120:
   events.append({"pc":hex(ins.address),"op":opcode,"type":a["kind"],"name":a["name"]})
 return {"lo":hex(lo),"hi":hex(hi),"instructions":(hi-lo)//4,
         "resolved":events,"resolvedCount":len(events)}
def inspect(name,file):
 raw=file.read_bytes();sha,funcs=NAMES[name]
 assert hashlib.sha256(raw).hexdigest()==sha,(name,"wrong original")
 m=MachO(select_arm64(raw))
 return {"SHA256":sha,"methods":{label:one(m,lo,hi,label) for lo,hi,label in funcs}}
def main():
 p=argparse.ArgumentParser()
 p.add_argument("--duonavi",type=Path,required=True)
 p.add_argument("--native12",type=Path,required=True)
 p.add_argument("--out",type=Path,required=True)
 a=p.parse_args()
 record={"purpose":"SHA-pinned original ABI named selector/CFString references, not code reuse",
    "DuoNavi104":inspect("DuoNavi104",a.duonavi),
    "Native12Reference":inspect("Native12Reference",a.native12)}
 a.out.parent.mkdir(parents=True,exist_ok=True)
 a.out.write_text(json.dumps(record,indent=2,ensure_ascii=False)+"\n")
 for name in ("DuoNavi104","Native12Reference"):
  for key,item in record[name]["methods"].items():
   unique=list(dict.fromkeys(v["name"] for v in item["resolved"]))
   print(name,key,item["resolvedCount"]," ".join(unique[:65]))
 print("ORIGINAL_HOME_EIGHT_FUNCTION_SELECTOR_DATAFLOW_PASS")
if __name__=="__main__":main()
