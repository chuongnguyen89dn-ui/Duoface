#!/usr/bin/env python3
"""Immutable read-only original-DEB method IMP and semantic selector xref scan.

This is NOT an interpretation of branch execution or an implementation of a vendor
license/tweak. No vendor instructions or binary bytes are copied to the report.
"""
import argparse,bisect,hashlib,json,pathlib,subprocess,tempfile
from audit_native12_license_class_xrefs import MachO,select_arm64
from decode_original_home_roster_callsites import function_starts
from trace_original_home_semantic_selectors import one

PINS={
 "duonavi":("f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd",
            "44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15",
            "DuoNaviDashboard.dylib"),
 "native12_derived":("2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad",
            "9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea",
            "DuoFaceDashboard.dylib"),
 "duodash_repack":("ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465",
            "b41dd7f892bfd3722e95a40f764a989886078b4a30943c1f0b50d47b6e248a47",
            "DuoDash.dylib")
}
METHODS={
 "CBBridgeManagerDashboard":(
  "startBridging:","startBridging:withCompletion:","stopBridging",
  "stopBridgingWithCompletion:","prepareHomeScreenForBridge:",
  "bridgeDidActivate:","bridgeDidDeactivate","setHomeButtonInApp:",
  "shouldInterceptLaunchForApp:"),
 "CBBridgeManager":(
  "trackBridgedBundleID:","runningBridgedApplications","requestStateChange:",
  "loadNewAppFromCurrentRequest:","sendStateToApp:shouldBridge:"),
 "CBBridgedUIAppView":(
  "refreshSceneLayout","updateSceneFrame","updateSceneSettingsFrame","hostedScene"),
 "CNABSpringBoardObserver":("onHostRequest:","onHostRequestSplit:"),
 "CNABUIApp":("setBridgeState:width:height:orientation:",),
 "DDz2":("cnabBuildSceneHostForBid:displaySize:",)
}
def hashfile(path):
 h=hashlib.sha256()
 with open(path,"rb") as f:
  for blob in iter(lambda:f.read(1048576),b""):h.update(blob)
 return h.hexdigest()

def method_imps(m,cname,requested,cl):
 if cname not in cl:return None
 ptr=cl[cname]["class_ptr"]
 out=[]
 for kind,obj in (("-",ptr),("+",m.ptr(ptr))):
  if not obj:continue
  head=m.ptr((m.ptr(obj+32)&~7)+32)
  if not head:continue
  flags,count=m.p32(head),m.p32(head+4)
  if count>1000:raise ValueError("unbounded method list "+cname)
  rel=bool(flags&0x80000000)
  stride=12 if rel else 24
  for idx in range(count):
   place=head+8+stride*idx
   if rel:
    ref=place+m.pi32(place)
    selvm=ref if flags&0x40000000 else m.ptr(ref)
    imp=place+8+m.pi32(place+8)
   else:
    selvm=m.ptr(place)
    imp=m.ptr(place+16)
   sel=m.cstr(selvm)
   if sel in requested:
    out.append((kind+sel,imp))
 return out

def scan(label,deb,root):
 p=PINS[label]
 if hashfile(deb)!=p[0]:raise RuntimeError("wrong pinned package "+label)
 subprocess.run(["dpkg-deb","-x",str(deb),str(root)],check=True)
 matches=list(root.rglob(p[2]))
 if len(matches)!=1 or hashfile(matches[0])!=p[1]:
  raise RuntimeError("wrong pinned MachO "+label)
 m=MachO(select_arm64(matches[0].read_bytes()))
 starts=function_starts(m)
 out={"deb_sha256":p[0],"macho_sha256":p[1],
      "scanned_method_count":0,"methods":{},
      "scope":"static method IMP + named selector/CFString xrefs only; no runtime branch proof"}
 # The repacked DuoDash uses a different dyld/fixup representation. Our
 # legacy MachO.classes parser can reject that image; record it as UNKNOWN
 # instead of claiming its methods are absent or extrapolating ABI.
 try:
  classes=m.classes()
 except (ValueError,IndexError,KeyError) as exc:
  out["objc_metadata_parser_limitation"]=type(exc).__name__+": "+str(exc)[:140]
  out["method_absence_proven"]=False
  return out
 for cname,req in METHODS.items():
  found=method_imps(m,cname,set(req),classes)
  if found is None:continue
  records=[]
  for meth,imp in found:
   index=bisect.bisect_right(starts,imp)-1
   entry={"method":meth,"imp":hex(imp),"verified_within_function":False,
          "selectors":[],"cfstrings":[],"observed_named_xrefs":[]}
   if index<0:records.append(entry);continue
   lo=starts[index];hi=starts[index+1] if index+1<len(starts) else lo+0x200
   entry["function_start"]=hex(lo);entry["function_end"]=hex(hi)
   if not(lo<=imp<hi and 16<=hi-lo<=0x3000):
    records.append(entry);continue
   entry["verified_within_function"]=True
   try:
    obs=one(m,lo,hi,cname+"::"+meth)
    selector=[x["name"] for x in obs["resolved"] if x.get("type")=="selector"]
    cf=[x["name"] for x in obs["resolved"] if x.get("type")=="cfstring"]
    # Keep unique named selectors and short strings only. No code bytes/operands.
    entry["selectors"]=list(dict.fromkeys(selector))[:140]
    entry["cfstrings"]=list(dict.fromkeys(cf))[:30]
    entry["observed_named_xrefs"]=[
     {"pc":x["pc"],"kind":x["type"],"name":x["name"]}
     for x in obs["resolved"] if x.get("type")=="selector"
     and any(k in x["name"].lower() for k in
        ("home","bridge","app","dock","scene","orient","state","activ","track","window","foreground","back","recent"))
     ][:120]
    entry["instruction_count"]=obs["instructions"]
   except (ValueError,IndexError,KeyError) as exc:
    entry["decode_warning"]=type(exc).__name__
   records.append(entry)
  if records:
   out["methods"][cname]=records
   out["scanned_method_count"]+=len(records)
 return out

def main():
 ap=argparse.ArgumentParser()
 for name in PINS:ap.add_argument("--"+name,required=True,type=pathlib.Path)
 ap.add_argument("--out",required=True,type=pathlib.Path)
 a=ap.parse_args();a.out.parent.mkdir(parents=True,exist_ok=True)
 with tempfile.TemporaryDirectory(prefix="duoface-original-static-") as tmp:
  reports={}
  for name in PINS:
   reports[name]=scan(name,getattr(a,name),pathlib.Path(tmp)/name)
   print("ORIGINAL_AUDIT",name,
         "methods",reports[name]["scanned_method_count"])
 if reports["duonavi"]["scanned_method_count"]<10:
  raise RuntimeError("original DuoNavi method extraction unexpectedly empty")
 if reports["native12_derived"]["scanned_method_count"]<10:
  raise RuntimeError("derived Native12 method extraction unexpectedly empty")
 out={"device_runtime_proof":False,"vendor_binaries_copied":False,
      "license_methods_studied":False,
      "purpose":"original navigation, active app and orientation interface correlations",
      "references":reports}
 a.out.write_text(json.dumps(out,indent=2,ensure_ascii=False)+"\n")
 for n,data in reports.items():
  for cl,entries in data["methods"].items():
   for e in entries:
    print("ORIGINAL_IMP",n,cl,e["method"],e["imp"],
      "home_or_dock_refs",sum(("home" in x["name"].lower() or "dock" in x["name"].lower()) for x in e["observed_named_xrefs"]))
 print("ORIGINAL_METHOD_XREFS_READONLY_COMPLETE")
if __name__=="__main__":main()
