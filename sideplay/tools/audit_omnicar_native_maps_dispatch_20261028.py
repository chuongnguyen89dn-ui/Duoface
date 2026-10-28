#!/usr/bin/env python3
"""Static original OmniCar native CarPlay-app/phone-bridge dispatch audit.
References only signed original SHA-pinned DEB. No runtime hook; no vendor code
or binary written to final repo. Reports verifiable method machine instructions.
"""
from pathlib import Path
import argparse,hashlib,json,struct,subprocess,tempfile
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
SHA="d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd"
WANTED={
("SCPCarSplit","isCarPlayApp:"):"0xff20",
("SCPCarSplit","openApp:slot:"):"0x164d4",
("SCPCarSplit","hostApp:inPane:"):"0x3e490",
("SCPCarSplit","paneSize:forBundle:"):"0x1b328",
("SCPCarSplit","publishCarPlayApps"):"0x21b1c",
("SCPCarSplit","pushSceneSizes"):"0x1c550",
("SCPCarSplit","pickerMapForPane:height:"):"0x329a0"
}
def arm64_fat(fat):
 if struct.unpack_from(">I",fat)[0]!=0xcafebabe:raise RuntimeError("missing FAT header")
 n=struct.unpack_from(">I",fat,4)[0]
 for j in range(n):
  cpu,sub,off,size,align=struct.unpack_from(">IIIII",fat,8+20*j)
  if cpu==0x0100000c and sub==0:
   out=fat[off:off+size]
   assert struct.unpack_from("<I",out)[0]==0xfeedfacf
   return out
 raise RuntimeError("no arm64")
def cstr(b,pos):
 if pos<0 or pos>=len(b):raise RuntimeError("out of bounds cstr")
 return b[pos:b.index(b"\0",pos)].decode("utf8","replace")
def original_methods(b):
 u=lambda p:struct.unpack_from("<Q",b,p)[0]
 i=lambda p:struct.unpack_from("<I",b,p)[0]
 si=lambda p:struct.unpack_from("<i",b,p)[0]
 mask=(1<<48)-1
 methods={}
 for p in range(0x7fd80,0x7fdd8,8):
  cl=u(p)&mask;ro=u(cl+32)&mask;owner=cstr(b,u(ro+24)&mask)
  tab=u(ro+32)&mask
  if not tab:continue
  size=i(tab)&0xffff;count=i(tab+4)
  if size!=12 or count>1000:raise RuntimeError("unexpected ObjC metadata")
  for j in range(count):
   e=tab+8+size*j
   name=cstr(b,u(e+si(e))&mask)
   methods[(owner,name)]=e+8+si(e+8)
 return methods
def scan(deb):
 raw=deb.read_bytes()
 assert hashlib.sha256(raw).hexdigest()==SHA,"input mismatch"
 with tempfile.TemporaryDirectory() as td:
  subprocess.run(["dpkg-deb","-x",str(deb),td],check=True)
  b=arm64_fat((Path(td)/"var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarSplitScreen.dylib").read_bytes())
  methods=original_methods(b)
  pcs=sorted(set(methods.values()))
  dis=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
  result={}
  for key,want in WANTED.items():
   start=methods.get(key)
   assert start==int(want,16),(key,start,want)
   after=next((v for v in pcs if v>start),len(b))
   # A method may exceed a page; include start 0x500 bytes or real IMP end.
   size=min(after-start,0x500)
   instructions=[{"pc":hex(x.address),"mnemonic":x.mnemonic,"op_str":x.op_str}
      for x in dis.disasm(b[start:start+size],start)]
   bl=[x for x in instructions if x["mnemonic"] in ("bl","blr")]
   result[key[0]+"."+key[1]]={
      "verified_imp":hex(start),"next_method_boundary":hex(after),
      "instructions_shown":len(instructions),"disassembly_truncated":after-start>size,
      "direct_calls":bl,
      "instructions":instructions[:140]}
  return {"status":"ORIGINAL_ARM64_STATIC_NATIVE_CARPLAY_ROUTING_AUDIT_NO_DEVICE_EXECUTION",
          "original_deb_sha256":SHA,"split_arm64_methods":result,
          "limits":["Selector names and static calls do not prove that Apple Maps reached a branch in the current CarPlay session",
                    "No vendor license/payload copied. This report is not an entitlement or ability to embed native CPWindow",
                    "Do not transfer OmniCar method pointers or lifecycle logic to independent DuoFace without verifying scene owner"]}
def main():
 p=argparse.ArgumentParser();p.add_argument("--deb",type=Path,required=True);p.add_argument("--out",type=Path,required=True)
 a=p.parse_args();result=scan(a.deb);a.out.parent.mkdir(parents=True,exist_ok=True)
 a.out.write_text(json.dumps(result,indent=2,ensure_ascii=False)+"\n")
 print("OMNICAR_NATIVE_MAP_ORIGINAL_IMP_SCAN_PASS",len(result["split_arm64_methods"]))
if __name__=="__main__":main()
