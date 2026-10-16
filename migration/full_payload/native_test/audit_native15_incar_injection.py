#!/usr/bin/env python3
"""Inspect installed-package equivalents only: no device access or tweak execution."""
import hashlib,json,plistlib,pathlib,subprocess,tempfile,argparse
SHA="8d111e638dce357dfb1187c5b10fdf776d7485c95198ad4cf248d6b51d1740e3"
def main():
 p=argparse.ArgumentParser();p.add_argument("--deb",required=True,type=pathlib.Path);p.add_argument("--out",required=True,type=pathlib.Path);a=p.parse_args()
 assert hashlib.sha256(a.deb.read_bytes()).hexdigest()==SHA
 with tempfile.TemporaryDirectory(prefix="df15-injection-readonly-") as d:
  subprocess.run(["dpkg-deb","-x",str(a.deb),d],check=True)
  root=pathlib.Path(d)
  native=root/"var/jb/Library/MobileSubstrate/DynamicLibraries"
  opts=[]
  for f in native.glob("*.plist"):
   try:
    x=plistlib.loads(f.read_bytes())
   except Exception as e:x={"parse_error":str(e)}
   opts.append({"path":str(f.relative_to(root)),"plist":x})
  inf=[]
  for f in root.rglob("Info.plist"):
   if "DuoFace" in str(f):
    try:
     x=plistlib.loads(f.read_bytes())
     inf.append({"path":str(f.relative_to(root)),"bundle":x.get("CFBundleIdentifier"),"executable":x.get("CFBundleExecutable")})
    except Exception:pass
  entries=[]
  for x in root.rglob("*"):
   if x.is_file() and ("Preferences" in str(x) or "DuoFaceDashboard" in x.name):entries.append(str(x.relative_to(root)))
  result={"status":"NATIVE15_INCAR_INJECTION_PLIST_READONLY","package_sha256":SHA,
     "mobile_substrate_filters":opts,"app_identity":inf,"relevant_files":entries[:250],
     "runtime_process_known":False,"class_load_timing_known":False,"device_tested":False,"package_modified":False,
     "notes":"The Dylib presence and SpringBoard filter do not guarantee hook activation. Check constructor and runtime fallback separately."}
  a.out.parent.mkdir(parents=True,exist_ok=True);a.out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
  print(json.dumps({"status":result["status"],"filters":opts,"identities":inf},ensure_ascii=False,indent=2))
if __name__=="__main__":main()
