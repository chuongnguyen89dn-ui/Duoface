#!/usr/bin/env python3
"""Read-only check SHA-locked *actually signed* QA146 integrated DEB payload/filters.
No package scripts/install/modified iPhone. Proprietary CarBridge is NOT required.
"""
import argparse,hashlib,json,pathlib,plistlib,subprocess,tempfile
PIN="1785d5d6bef53337033f5664d5acfc573dabe20892bd629649fab5730b04e078"
PKG="com.duoface.jb.embedded"
VERSION="0.0.146~native-home-release1"
SKIP=("carbridge","duonavi","duodash","sideplay","cortex.carplayenable")
def digest(path):
 h=hashlib.sha256()
 with path.open("rb") as f:
  for block in iter(lambda:f.read(1048576),b""):h.update(block)
 return h.hexdigest()
def field(deb,k):
 return subprocess.run(["dpkg-deb","-f",str(deb),k],capture_output=True,check=True,text=True).stdout.strip()
def main():
 args=argparse.ArgumentParser()
 args.add_argument("--deb",required=True,type=pathlib.Path)
 args.add_argument("--out",required=True,type=pathlib.Path)
 v=args.parse_args()
 assert digest(v.deb)==PIN
 meta={k:field(v.deb,k) for k in ("Package","Version","Architecture","Depends","Conflicts","Replaces","Provides","Description")}
 assert meta["Package"]==PKG and meta["Version"]==VERSION
 assert meta["Architecture"]=="iphoneos-arm64"
 assert "carbridge" not in meta["Depends"].lower()
 assert "mobilesubstrate" in meta["Depends"].lower()
 details={}
 with tempfile.TemporaryDirectory(prefix="duoface-qa146-original-package-forensic-") as t:
  dest=pathlib.Path(t)/"stage"
  dest.mkdir()
  subprocess.run(["dpkg-deb","-x",str(v.deb),str(dest)],check=True,capture_output=True)
  files=sorted(x for x in dest.rglob("*") if x.is_file() and not x.is_symlink())
  rels=[x.relative_to(dest).as_posix() for x in files]
  offenders=[x for x in rels if any(k in x.lower() for k in SKIP)]
  assert not offenders,offenders
  for rel in rels:
   if rel.endswith(".plist") and "DynamicLibraries/" in rel:
    try:
     plist=plistlib.loads((dest/rel).read_bytes())
     if isinstance(plist,dict) and "Filter" in plist:
      details[rel]=plist["Filter"]
    except (ValueError,TypeError,OverflowError):pass
  dylibs=[x for x in rels if x.endswith(".dylib")]
  must=["DFTouchOwnerProbe.dylib","DFCarPlayDockOwner.dylib",
        "DFYouTubeOrientationRelay.dylib","DFGofaMapResize141.dylib"]
  for name in must:
   assert any(x.endswith("/"+name) for x in dylibs),"missing signed own module "+name
  expected={
   "DFYouTubeOrientationRelay.plist":{"Filter":{"Bundles":["com.google.ios.youtube"]}},
   "DFGofaMapResize141.plist":{"Filter":{"Bundles":["com.lumi.GOFA"]}},
  }
  for name,record in expected.items():
   matches=[k for k in details if k.endswith("/"+name)]
   assert len(matches)==1 and details[matches[0]]==record["Filter"],(name,matches)
  filters={
   "named_app_only":{},
   "springboard_carplay_internal":{},
   "other_filters":{},
  }
  for path,filter_ in details.items():
   bs=filter_.get("Bundles",[])
   if any(x in ("com.google.ios.youtube","com.lumi.GOFA") for x in bs):
    filters["named_app_only"][path]=filter_
   elif all(x.startswith("com.apple.") for x in bs) and bs:
    filters["springboard_carplay_internal"][path]=filter_
   else:
    filters["other_filters"][path]=filter_
 result={
  "actual_signed_deb_sha256":PIN,"exact_deb_size":v.deb.stat().st_size,
  "dpkg_control":meta,"file_count":len(files),"dylib_count":len(dylibs),
  "all_dylib_filenames":dylibs,"filters":filters,
  "third_party_carbridge_files_detected_by_name":offenders,
  "package_claims_official_carbridge_dependency":False,
  "actual_runtime_success_tested":False,
  "scope":"SHA-locked signed integrated DEB filesystem and dpkg control; source provenance alone not dynamic vendor-code plagiarism proof",
 }
 v.out.parent.mkdir(parents=True,exist_ok=True)
 v.out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
 print("QA146_INTEGRATED_SIGNED_DEB_BINARY_FILTERS_CONTROL_READONLY_VERIFIED",
       len(files),len(dylibs),len(details))
if __name__=="__main__":main()
