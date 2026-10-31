#!/usr/bin/env python3
"""Read-only authentic original DuoNavi / derived Native12 integrated AppBridge ownership map.
Audits bridge selector implementation sites, app-side filters, transition controls.
Does not scan license implementations or copy disassembly, binary data, vendor code.
"""
import argparse,bisect,hashlib,json,pathlib,plistlib,subprocess,tempfile
from audit_native12_license_class_xrefs import MachO,select_arm64
from decode_original_home_roster_callsites import function_starts
from trace_original_home_semantic_selectors import one

ORIGINALS={
"duonavi":("f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd",
           "44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15",
           "DuoNaviDashboard.dylib"),
"native12_derived":("2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad",
           "9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea",
           "DuoFaceDashboard.dylib")
}
CLASSES=("CBBridgeManagerDashboard","CBBridgeManager","CBBridgedUIAppView","CBBridgedSplitApp","CBDashboardShared")
KEYWORDS=("bridge","activat","dismiss","home","dock","scene","app","request","track","display","layout","window","state","orientation","foreground","background","content")
SKIP=("license","purchase","trial","policy","subscription","storekit","verification","auth")
def digest(p):
 h=hashlib.sha256()
 with p.open("rb") as fd:
  for x in iter(lambda:fd.read(1048576),b""):h.update(x)
 return h.hexdigest()
def method_imps(m,cl,cname):
 if cname not in cl:return []
 ptr=cl[cname]["class_ptr"]
 out=[]
 for kind,obj in (("-",ptr),("+",m.ptr(ptr))):
  if not obj:continue
  head=m.ptr((m.ptr(obj+32)&~7)+32)
  if not head:continue
  flags,count=m.p32(head),m.p32(head+4)
  if count>1000:raise ValueError("unsafe method count")
  rel=bool(flags&0x80000000)
  stride=12 if rel else 24
  for i in range(count):
   pos=head+8+stride*i
   if rel:
    ref=pos+m.pi32(pos)
    selvm=ref if flags&0x40000000 else m.ptr(ref)
    imp=pos+8+m.pi32(pos+8)
   else:
    selvm=m.ptr(pos);imp=m.ptr(pos+16)
   method=m.cstr(selvm)
   if not method:continue
   if not any(k in method.lower() for k in KEYWORDS):continue
   if any(k in method.lower() for k in SKIP):continue
   out.append((kind+method,imp))
 return out
def examine(label,pkg,root):
 item=ORIGINALS[label]
 assert digest(pkg)==item[0],("wrong original",label)
 subprocess.run(["dpkg-deb","-x",str(pkg),str(root)],check=True,capture_output=True)
 dylibs=list(root.rglob(item[2]))
 assert len(dylibs)==1 and digest(dylibs[0])==item[1]
 m=MachO(select_arm64(dylibs[0].read_bytes()))
 cl=m.classes()
 starts=function_starts(m)
 result={"package_sha256":item[0],"macho_sha256":item[1],
         "original_vendor_binary_in_report":False,"native_runtime_branch_executed":False,
         "methods":{},"relevant_class_method_inventory":{},
         "injection_filters":{}}
 for filt in sorted(root.rglob("*.plist")):
  if filt.stat().st_size>100000:continue
  try:
   d=plistlib.loads(filt.read_bytes())
   if isinstance(d,dict) and isinstance(d.get("Filter"),dict):
    result["injection_filters"][str(filt.relative_to(root))]=d["Filter"]
  except (TypeError,ValueError,OverflowError):pass
 for cname in CLASSES:
  methodpairs=method_imps(m,cl,cname)
  if not methodpairs:continue
  result["relevant_class_method_inventory"][cname]=[name for name,imp in methodpairs]
  rows=[]
  for name,imp in methodpairs:
   idx=bisect.bisect_right(starts,imp)-1
   row={"selector":name,"imp":hex(imp),"method_located":False,"selector_xrefs":[],"cfstrings":[]}
   if idx>=0:
    lo=starts[idx];hi=starts[idx+1] if idx+1<len(starts) else lo+0x300
    if lo<=imp<hi and 8<=hi-lo<=0x5000:
     row["method_located"]=True
     row["start"]=hex(lo);row["end"]=hex(hi)
     try:
      found=one(m,lo,hi,cname+":"+name)
      row["selector_xrefs"]=list(dict.fromkeys(x["name"] for x in found["resolved"] if x["type"]=="selector" and not any(k in x["name"].lower() for k in SKIP)))[:110]
      row["cfstrings"]=list(dict.fromkeys(x["name"] for x in found["resolved"] if x["type"]=="cfstring" and not any(k in x["name"].lower() for k in SKIP)))[:8]
      row["instruction_count"]=found["instructions"]
     except (ValueError,IndexError,KeyError,OverflowError) as e:
      row["decode_warning"]=type(e).__name__
   rows.append(row)
  result["methods"][cname]=rows
 return result

def main():
 ap=argparse.ArgumentParser()
 for label in ORIGINALS:ap.add_argument("--"+label,required=True,type=pathlib.Path)
 ap.add_argument("--out",required=True,type=pathlib.Path)
 args=ap.parse_args()
 results={}
 with tempfile.TemporaryDirectory(prefix="carbridge-original-readonly-") as tmp:
  for label in ORIGINALS:
   results[label]=examine(label,getattr(args,label),pathlib.Path(tmp)/label)
   print("PINNED_ORIGINAL_METHOD_SCAN",label,
         {x:len(v) for x,v in results[label]["methods"].items()})
 out={"scope":"original DuoNavi native CarPlay bridge + Native12-derived, static only",
      "not_carbridge_official_product":True,
      "official_carbridge_binary_available":False,
      "no_vendor_logic_copied":True,"no_license_code_scanned":True,
      "no_iphone_runtime_execution":True,
      "original_bridges":results}
 for key in results:
  d=results[key]["methods"]
  dash=d.get("CBBridgeManagerDashboard",[])
  needed=("bridgeDidActivate:","bridgeDidDeactivate","prepareHomeScreenForBridge:")
  assert all(any(z["selector"].endswith(y) and z["method_located"] for z in dash) for y in needed)
  # A deployed bridge needs both lifecycle and native app integration
  activate=next(z for z in dash if z["selector"].endswith("bridgeDidActivate:"))
  assert all(t in activate["selector_xrefs"] for t in
    ("setActivated:","setAppDockActiveBundleID:","setHomeButtonInApp:"))
 args.out.parent.mkdir(parents=True,exist_ok=True)
 args.out.write_text(json.dumps(out,ensure_ascii=False,indent=2)+"\n")
 print("ORIGINAL_DUONAVI_NATIVE_BRIDGE_DEEP_AUDIT_NO_CARBRIDGE_VENDOR_CODE_PASS")
if __name__=="__main__":main()
