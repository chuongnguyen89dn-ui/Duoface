#!/usr/bin/env python3
"""Native12 and DuoNavi screenBlank preference + actual BKS 0/1 callers.

Read-only two SHA-pinned original/reference DEB binary forensic crosswalk.
Includes file/ObjC metadata, bounded ARM64, and plist value evidence only.
Does not infer device state or transplant vendor implementation.
"""
import argparse,hashlib,json,plistlib,re,subprocess,tempfile
from pathlib import Path
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
from audit_native12_license_class_xrefs import MachO,select_arm64
from trace_omnicar_abhost_method_and_unblank_owner import all_classes
PINS={
 "Native12Derived":"2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad",
 "DuoNavi104":"f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd"
}
SITES={
 "Native12Derived":[0x31af0,0x31da8],
 "DuoNavi104":[0xae32c,0x16169c,0x192e68,0x1a63dc,0x1a642c,0x1bf0d0]
}
DASH={"Native12Derived":"DuoFaceDashboard.dylib","DuoNavi104":"DuoNaviDashboard.dylib"}
METH=re.compile(r"screenBlank|BlankScreen|backlight|brightness|displaySleep|[Cc]arDisconnected|[Ss]ettingsChanged|[Ll]oadPreferences|[Ss]avePreferences|[Pp]references|[Ii]dle[Tt]imer",re.I)
CS=Cs(CS_ARCH_ARM64,CS_MODE_ARM)

def sha(path):
 h=hashlib.sha256()
 with open(path,"rb") as f:
  for ch in iter(lambda:f.read(1024*1024),b""):h.update(ch)
 return h.hexdigest()
def block(m,vm,before=0,after=0):
 start=max(vm-before,0)
 if start%4: start-=start%4
 try:off=m.map(start)
 except (ValueError,IndexError,KeyError,AssertionError):return []
 result=[]
 for x in CS.disasm(m.data[off:off+before+after],start):
  result.append({"pc":hex(x.address),"op":x.op_str,"mnemonic":x.mnemonic})
 return result
def sel_methods(m):
 classes=all_classes(m)
 result=[]
 all_imps=[]
 for c in classes:
  for k in ("instance","class_methods"):
   for x in c[k]["methods"]:
    imp=x.get("imp_vm"); name=x.get("selector")
    if not imp:continue
    try:pc=int(imp,16)
    except ValueError:continue
    all_imps.append((pc,c["class"],k,name))
    if name and METH.search(name):
      result.append({"class":c["class"],"kind":k,"selector":name,"imp_vm":imp,
        "first_32_instructions":block(m,pc,0,128)})
 all_imps.sort()
 return len(classes), result, all_imps
def owners(imp_list,pc):
 prior=[i for i in imp_list if i[0]<=pc]
 after=[i for i in imp_list if i[0]>pc]
 return {"nearest_preceding_imp":{
    "vm":hex(prior[-1][0]),"class":prior[-1][1],"method_kind":prior[-1][2],
    "selector":prior[-1][3],"distance":pc-prior[-1][0]} if prior else None,
    "next_method_start":hex(after[0][0]) if after else None,
    "is_owner_proven":False,"note":"No C function, blocks or ObjC dynamic dispatch boundary proven by nearest-IMP"}
def search_plists(root):
 out=[]
 for fp in root.rglob("*"):
  if not fp.is_file() or fp.stat().st_size>2000000:continue
  if fp.suffix.lower() not in (".plist",".json"):continue
  try:
   raw=fp.read_bytes()
   data=plistlib.loads(raw) if fp.suffix.lower()==".plist" else json.loads(raw.decode())
  except (ValueError,TypeError,UnicodeError,OverflowError,RecursionError):continue
  def seek(obj,path,depth):
   if depth>7:return
   if isinstance(obj,dict):
    for k,v in obj.items():
     k=str(k)
     if re.search("screen.?blank|prevent.?display.?sleep|[Ii]dle[Tt]imer",k):
      out.append({"file":fp.relative_to(root).as_posix(),"key":path+"."+k,
                  "type":type(v).__name__,
                  "value":v if isinstance(v,(bool,int,float,str)) and len(str(v))<200 else "<complex>"})
     seek(v,path+"."+k,depth+1)
   elif isinstance(obj,(list,tuple)):
    for i,v in enumerate(obj[:200]):seek(v,path+f"[{i}]",depth+1)
  seek(data,"$",0)
 return out[:100]
def main():
 ap=argparse.ArgumentParser()
 for k in PINS:ap.add_argument("--"+k,required=True,type=Path)
 ap.add_argument("--out",required=True,type=Path)
 a=ap.parse_args()
 out={"purpose":"original Native12 vs DuoNavi BKS callsites and preference default research",
      "device_runtime_observed":False,"preferences_live_default_proven":False,
      "vendor_code_copied_into_duoface":False,"packages":{}}
 with tempfile.TemporaryDirectory(prefix="df-bks-pref-") as td:
  for name,pin in PINS.items():
   deb=getattr(a,name)
   actual=sha(deb)
   if actual!=pin:raise RuntimeError(f"SHA mismatch {name} actual {actual} expected {pin}")
   root=Path(td)/name
   subprocess.run(["dpkg-deb","-x",str(deb),str(root)],check=True)
   dylibs=sorted(p for p in root.rglob("*.dylib") if p.is_file())
   rec={"package_sha256":actual,"dylib_count":len(dylibs),"plists":search_plists(root),
        "machos_with_screenblank_method":[]}
   found_dashboard=False
   for path in dylibs:
    if path.stat().st_size>35000000:continue
    data=path.read_bytes()
    try:
     m=MachO(select_arm64(data))
     count,methods,all_imp=sel_methods(m)
    except (ValueError,IndexError,AssertionError,KeyError) as ex:
     rec.setdefault("unparsed",[]).append({"path":path.name,"error":str(ex)[:200]})
     continue
    entry={"file":path.relative_to(root).as_posix(),
      "file_sha256":hashlib.sha256(data).hexdigest(),
      "objc_class_count":count,
      "screenblank_related_methods":methods[:90]}
    if path.name==DASH[name]:
     found_dashboard=True
     entry["bks_literal_sites"]=[]
     for pc in SITES[name]:
      # larger 192B before and 244B after for guards, call 0/1 and symbol lookup
      entry["bks_literal_sites"].append({"site":hex(pc),
          "bounded_instructions":block(m,pc,192,244),
          "nearest_imp":owners(all_imp,pc)})
    if methods or path.name==DASH[name]:
     rec["machos_with_screenblank_method"].append(entry)
   if not found_dashboard:raise RuntimeError("Missing required Dashboard dylib "+name)
   out["packages"][name]=rec
 a.out.parent.mkdir(parents=True,exist_ok=True)
 a.out.write_text(json.dumps(out,ensure_ascii=False,indent=2)+"\n")
 for name,item in out["packages"].items():
  print("ORIGINAL_BKS_PREF_AUDIT",name,"dylibs",item["dylib_count"],
   "files_of_interest",len(item["machos_with_screenblank_method"]),
   "found_plist_entries",len(item["plists"]))
  for f in item["machos_with_screenblank_method"]:
   print("METHODS",name,f["file"]," ".join(z["class"]+"."+str(z["selector"])+"="+z["imp_vm"]
        for z in f["screenblank_related_methods"][:35]))
 print("ORIGINAL_TWO_SIGNED_DEB_BKS_PREF_METHODS_READ_ONLY")
if __name__=="__main__":main()
