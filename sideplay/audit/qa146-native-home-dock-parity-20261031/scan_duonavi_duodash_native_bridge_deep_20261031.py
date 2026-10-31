#!/usr/bin/env python3
"""READ ONLY: actual SHA-verified DuoNavi 1.0.4 vs DuoDash 1.1.3 Fullscreen427 REPACK.
Repair previously known DuoDash tagged ObjC metadata parser limitation from
first-party Oct27 parser. Only emit class/method/IMP/selector xrefs, not code/license.
Method references are STATIC, not proof of branch/real device behavior.
"""
import argparse,bisect,hashlib,json,pathlib,plistlib,subprocess,tempfile
from audit_native12_license_class_xrefs import MachO,select_arm64
from audit_native12_carplay_add_app_chain import methods
from trace_original_home_semantic_selectors import one

PIN={
 "duonavi_original":{
  "package":"f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd",
  "macho":"44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15",
  "dylib":"DuoNaviDashboard.dylib"},
 "duodash_113_fullscreen427_REPACK_NOT_STOCK":{
  "package":"ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465",
  "macho":"b41dd7f892bfd3722e95a40f764a989886078b4a30943c1f0b50d47b6e248a47",
  "dylib":"DuoDash.dylib"}
}
RELEVANT=("bridge","scene","window","app","activate","deactivate","launch","dock","home",
          "request","host","split","state","layout","orientation","display","frame",
          "touch","input","process","restart","terminate","background","foreground",
          "switch","notify","message","observe","history","dismiss","close","start","stop")
EXCLUDE=("license","purchase","receipt","trial","storekit","subscription","auth","verify",
         "payment","premium","checksub","resetlicense")
CLASS_ALLOW=("CBBridgeManagerDashboard","CBBridgeManager","CBBridgedUIAppView",
             "CBBridgedSplitApp","CNABSpringBoardObserver","CNABUIApp",
             "DDz1","DDz2")
def sha(p):
 h=hashlib.sha256()
 with p.open("rb") as fd:
  for block in iter(lambda:fd.read(1048576),b""):h.update(block)
 return h.hexdigest()
class RepackedTaggedMachO(MachO):
 normalized=0
 def map(self,vm):
  try:return super().map(vm)
  except ValueError:
   clean=vm & 0x0000FFFFFFFFFFFF
   if clean==vm:raise
   value=super().map(clean)
   self.normalized+=1
   return value
def filter_debs(path):
 filters={}
 for p in sorted(path.rglob("*.plist")):
  if p.stat().st_size>100000:continue
  try:
   d=plistlib.loads(p.read_bytes())
   if isinstance(d,dict) and isinstance(d.get("Filter"),dict):
    filters[str(p.relative_to(path))]=d["Filter"]
  except (ValueError,TypeError,OverflowError):pass
 return filters
def is_relevant(sel):
 s=sel.lower()
 return any(x in s for x in RELEVANT) and not any(x in s for x in EXCLUDE)
def analyse(label,deb,temp):
 pin=PIN[label]
 assert sha(deb)==pin["package"],"wrong package "+label
 subprocess.run(["dpkg-deb","-x",str(deb),str(temp)],capture_output=True,check=True)
 matches=list(temp.rglob(pin["dylib"]))
 assert len(matches)==1 and sha(matches[0])==pin["macho"],"wrong original dylib "+label
 thin=select_arm64(matches[0].read_bytes())
 m=RepackedTaggedMachO(thin) if "REPACK" in label else MachO(thin)
 cls=m.classes()
 perclass={}
 for cname in sorted(cls):
  try:
   entries=methods(m,cname)
   if entries:perclass[cname]=entries
  except (ValueError,KeyError,IndexError,AssertionError):continue
 assert len(perclass)>=30,(label,len(perclass))
 allstarts=sorted(set((entry["vm"] & 0x0000FFFFFFFFFFFF if "REPACK" in label else entry["vm"])
                  for entries in perclass.values() for entry in entries.values()
                  if entry.get("vm") and entry.get("vm")>0))
 focus={}
 method_count=0
 for classname,entries in perclass.items():
  if classname not in CLASS_ALLOW and not classname.startswith("CNAB"):continue
  out=[]
  for selector,x in entries.items():
   if not is_relevant(selector):continue
   vm=x["vm"] & 0x0000FFFFFFFFFFFF if "REPACK" in label else x["vm"]
   if not vm:continue
   i=bisect.bisect_right(allstarts,vm)
   bound=allstarts[i] if i<len(allstarts) else vm+0x800
   span=bound-vm
   rec={"selector":selector,"imp":hex(vm),"type":x.get("type"),
        "next_objc_method_start":hex(bound),
        "bounded_scan_bytes":min(max(span,0),0x1000),"selector_xrefs":[],
        "cfstring_tags":[],"method_body_decode":False}
   if 16<=span<=0x30000:
    try:
     refs=one(m,vm,vm+min(span,0x1000),classname+":"+selector)["resolved"]
     rec["selector_xrefs"]=list(dict.fromkeys(x["name"] for x in refs if
               x["type"]=="selector" and not any(a in x["name"].lower() for a in EXCLUDE)))[:85]
     rec["cfstring_tags"]=list(dict.fromkeys(x["name"] for x in refs if
               x["type"]=="cfstring" and len(x["name"])<=100 and
               not any(a in x["name"].lower() for a in EXCLUDE)))[:8]
     rec["method_body_decode"]=True
    except (ValueError,KeyError,IndexError,OverflowError) as e:
     rec["decode_error"]=type(e).__name__
   out.append(rec);method_count+=1
  if out:focus[classname]=out
 out={"label":label,"package_sha256":pin["package"],"macho_sha256":pin["macho"],
      "repack_warning":"DuoDash is NOT confirmed stock" if "REPACK" in label else None,
      "classes_total":len(cls),"classes_parsed":len(perclass),
      "tagged_macho_pointer_normalizations":getattr(m,"normalized",0),
      "metadata_source":"first-party Oct27 tagged MachO parser and Objective-C class metadata",
      "method_count":method_count,"focus":focus,
      "filters":filter_debs(temp),"all_class_names_relevant":[s for s in sorted(cls)
              if "CNAB" in s or "DDz" in s or s.startswith("CBBridge")][:80]}
 if label=="duonavi_original":
  assert "CBBridgeManagerDashboard" in focus
  assert any(x["selector"]=="-setAppDockActiveBundleID:" and
              "_refreshAppDock" in x["selector_xrefs"]
             for x in focus["CBBridgeManagerDashboard"])
 else:
  for cname,sel in (("CNABUIApp","-setBridgeState:width:height:orientation:"),
                    ("CNABSpringBoardObserver","-onHostRequest:"),
                    ("CNABSpringBoardObserver","-onHostRequestSplit:"),
                    ("DDz2","-cnabBuildSceneHostForBid:displaySize:"),
                    ("DDz1","-showLayoutPanes:natives:bids:")):
   assert any(x["selector"]==sel and x["method_body_decode"]
              for x in focus.get(cname,[])),(cname,sel)
  assert out["tagged_macho_pointer_normalizations"]>0
 return out
def main():
 a=argparse.ArgumentParser()
 a.add_argument("--duonavi",type=pathlib.Path,required=True)
 a.add_argument("--duodash-repack",type=pathlib.Path,required=True)
 a.add_argument("--out",type=pathlib.Path,required=True)
 args=a.parse_args()
 with tempfile.TemporaryDirectory(prefix="duoface-original-native-deep-") as t:
  result={
   "classification":"sha-locked original DuoNavi vs separate DuoDash REPACK",
   "original_vendor_code_executed":False,
   "source_or_license_copied":False,
   "native_device_runtime_verified":False,
   "images":{},
  }
  for key,path in (("duonavi_original",args.duonavi),
                  ("duodash_113_fullscreen427_REPACK_NOT_STOCK",args.duodash_repack)):
   result["images"][key]=analyse(key,path,pathlib.Path(t)/key)
   item=result["images"][key]
   print("EXACT_ORIGINAL_DEB",key,item["package_sha256"],"parsed",item["classes_parsed"],
         "methods",item["method_count"],"fixups",item["tagged_macho_pointer_normalizations"])
 args.out.parent.mkdir(parents=True,exist_ok=True)
 args.out.write_text(json.dumps(result,indent=2,ensure_ascii=False)+"\n")
 print("DASHBOARD_ORIGINAL_DUONAVI_AND_DUODASH_REPACK_NATIVE_BRIDGE_CROSSWALK_PASS")
if __name__=="__main__":main()
