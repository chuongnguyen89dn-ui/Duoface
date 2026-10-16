#!/usr/bin/env python3
"""Read-only map of direct license class references to containing native12 ObjC
method body, to avoid deleting classes still used by UI. Not a liveness proof."""
import argparse,hashlib,json,pathlib,subprocess,tempfile
from audit_native12_license_class_xrefs import NATIVE12_SHA,MachO,select_arm64,BINARIES
from audit_native12_carplay_add_app_chain import methods

def main():
 p=argparse.ArgumentParser();p.add_argument("--deb",type=pathlib.Path,required=True)
 p.add_argument("--xrefs",type=pathlib.Path,default=pathlib.Path("audit/payload-migration/NATIVE12_LICENSE_CLASSREF_CODE_XREFS.json"))
 p.add_argument("--out",type=pathlib.Path,required=True)
 a=p.parse_args()
 assert hashlib.sha256(a.deb.read_bytes()).hexdigest()==NATIVE12_SHA
 xref=json.loads(a.xrefs.read_text())
 assert xref["status"]=="NATIVE12_LICENSE_CLASSREF_ARM64_READONLY"
 with tempfile.TemporaryDirectory(prefix="df12-license-method-owners-") as td:
  subprocess.run(["dpkg-deb","-x",str(a.deb),td],check=True)
  out={}
  for binary,binfo in xref["binaries"].items():
   raw=(pathlib.Path(td)/BINARIES[binary]).read_bytes()
   m=MachO(select_arm64(raw))
   all_methods=[]
   for classname in m.classes():
    for sel,meta in methods(m,classname).items():
     all_methods.append((meta["vm"],classname,sel))
   all_methods.sort()
   found=[]
   for h in binfo["static_instruction_hits"]:
    addr=int(h["vm"],16)
    previous=[x for x in all_methods if x[0]<=addr]
    next_methods=[x for x in all_methods if x[0]>addr]
    owner=previous[-1] if previous else None
    successor=next_methods[0] if next_methods else None
    found.append({**h,
      "method_owner":owner and {"class":owner[1],"method":owner[2],
                                "imp_vm":hex(owner[0]),"offset_into_method":addr-owner[0]},
      "next_method_vm":successor and hex(successor[0]),
      "enclosing_method_estimated":bool(owner and (not successor or addr<successor[0]))})
   out[binary]={"method_count":len(all_methods),"xref_owners":found}
 result={"status":"NATIVE12_LICENSE_CLASSREF_CALLSITE_OWNERS_READONLY",
  "native12_sha256":NATIVE12_SHA,"physical_removal_performed":False,
  "dynamic_liveness_proven_absent":False,"binaries":out}
 a.out.parent.mkdir(parents=True,exist_ok=True)
 a.out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
 print(json.dumps({name:j["xref_owners"] for name,j in out.items()},indent=2))
if __name__=="__main__":main()
