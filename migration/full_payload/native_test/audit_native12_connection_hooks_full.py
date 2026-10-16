#!/usr/bin/env python3
"""Read-only all selector signatures for connection hook owner classes.
Never modifies DEB; helps choose exact safe adapter entrypoints and prefs access.
"""
from pathlib import Path
import argparse, hashlib, json, subprocess, tempfile
from audit_native12_license_class_xrefs import MachO, select_arm64, BINARIES, NATIVE12_SHA

INTEREST={
"DuoFaceUI":{"CBGeneralSettingsViewController"},
"DuoFaceDashboard":{"CBBridgeManager","CBDashboardSettings","CBBridgeManagerDashboard","CBAppSettings","CBAppManager"}
}
def read(binary,raw):
 m=MachO(select_arm64(raw))
 out={}
 classes=m.classes()
 for cname in INTEREST[binary]:
  if cname not in classes:
   continue
  ptr=classes[cname]["class_ptr"]
  rows=[]
  for kind,object_addr in (("-",ptr),("+",m.ptr(ptr))):
   ro=m.ptr(object_addr+32)&~7
   lst=m.ptr(ro+32)
   if not lst:continue
   flags,count=m.p32(lst),m.p32(lst+4)
   assert count<500,(cname,count)
   rel=bool(flags&0x80000000)
   for i in range(count):
    entry=lst+8+i*(12 if rel else 24)
    if rel:
     a=entry+m.pi32(entry)
     sel_vm=a if flags&0x40000000 else m.ptr(a)
     type_vm=entry+4+m.pi32(entry+4)
     imp_vm=entry+8+m.pi32(entry+8)
    else:
     sel_vm=m.ptr(entry);type_vm=m.ptr(entry+8);imp_vm=m.ptr(entry+16)
    rows.append({"sel":kind+m.cstr(sel_vm),"type":m.cstr(type_vm),"imp_vm":hex(imp_vm)})
  out[cname]=rows
 return out

def main():
 p=argparse.ArgumentParser();p.add_argument("--deb",type=Path,required=True);p.add_argument("--out",type=Path,required=True);a=p.parse_args()
 assert hashlib.sha256(a.deb.read_bytes()).hexdigest()==NATIVE12_SHA
 with tempfile.TemporaryDirectory(prefix="df-connection-owner-") as temp:
  subprocess.run(["dpkg-deb","-x",str(a.deb),temp],check=True)
  binaries={k:read(k,(Path(temp)/path).read_bytes()) for k,path in BINARIES.items()}
 result={"status":"NATIVE12_CONNECTION_HOOK_OWNERS_FULL_OBJC_READONLY","deb_sha256":NATIVE12_SHA,"debs_modified":0,"binaries":binaries}
 a.out.parent.mkdir(parents=True,exist_ok=True);a.out.write_text(json.dumps(result,indent=2)+"\n")
 for bin,classes in binaries.items():
  print(bin,{cl:len(rows) for cl,rows in classes.items()})
  for cl,rows in classes.items():
   print(cl,[(x["sel"],x["type"]) for x in rows if any(term in x["sel"].lower() for term in ("connect","activate","launch","settings","bridg","current","terminate","start","load","save","pref","app","shared"))])
if __name__=="__main__":main()
