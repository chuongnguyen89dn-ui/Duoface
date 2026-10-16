#!/usr/bin/env python3
"""Create native16 from EXACT published native15, replacing only CarPlay Add Apps hook + plist.
Never touch Dopamine, native12/15 installed bytes, or existing license machinery.
"""
import argparse,hashlib,json,pathlib,plistlib,re,shutil,subprocess,tempfile
BASE=pathlib.Path("dist/payload-migration/native15/com.duoface.independent_0.1.0~native15_iphoneos-arm64.deb")
BASE_SHA="8d111e638dce357dfb1187c5b10fdf776d7485c95198ad4cf248d6b51d1740e3"
ROOT="var/jb/Library/MobileSubstrate/DynamicLibraries/"
MOD=ROOT+"DuoFaceInCarAddApps"
HOSTS=("var/jb/Applications/DuoFaceUI.app/DuoFaceUI",ROOT+"DuoFaceDashboard.dylib")
SHA_HOSTS=("cb40346d8ca504cb399abe31367847b4f980a01ba93810986ce1acf1fbe9eef9",
           "9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea")
VERSION="0.1.0~native16"
def sha(raw):return hashlib.sha256(raw).hexdigest()
def command(*argv):return subprocess.check_output(argv,text=True,stderr=subprocess.STDOUT).strip()
def inventory(root):
 return {p.relative_to(root).as_posix():sha(p.read_bytes()) for p in root.rglob("*")
         if p.is_file() and p.relative_to(root).parts[0]!="DEBIAN"}
def main():
 ap=argparse.ArgumentParser()
 ap.add_argument("--picker-dylib",required=True,type=pathlib.Path)
 ap.add_argument("--out",required=True,type=pathlib.Path)
 ap.add_argument("--report",required=True,type=pathlib.Path)
 args=ap.parse_args()
 assert sha(BASE.read_bytes())==BASE_SHA,"Native15 published input SHA mismatch"
 assert command("dpkg-deb","-f",str(BASE),"Package")=="com.duoface.independent"
 assert command("dpkg-deb","-f",str(BASE),"Version")=="0.1.0~native15"
 assert not args.out.exists(),"Never overwrite existing DEB"
 assert len(args.picker_dylib.read_bytes())>2000
 with tempfile.TemporaryDirectory(prefix="duoface-native16-picker-fix-") as tmp:
  stage=pathlib.Path(tmp)/"stage"
  subprocess.run(["dpkg-deb","-R",str(BASE),str(stage)],check=True)
  original=inventory(stage)
  assert all(original.get(name)==value for name,value in zip(HOSTS,SHA_HOSTS))
  assert ROOT+"DuoFaceSmartConnection.dylib" in original
  assert ROOT+"DuoFaceSmartConnection.plist" in original
  assert MOD+".dylib" in original and MOD+".plist" in original
  new_module=stage/(MOD+".dylib")
  new_filter=stage/(MOD+".plist")
  shutil.copy2(args.picker_dylib,new_module)
  shutil.copy2(pathlib.Path("DuoFaceInCarAddApps.plist"),new_filter)
  # Sign only the independent replacement module.
  subprocess.run(["ldid","-S",str(new_module)],check=True)
  subprocess.run(["lipo",str(new_module),"-verify_arch","arm64"],check=True)
  filt=plistlib.loads(new_filter.read_bytes())["Filter"]
  expected={"SpringBoard","CarPlay","CarPlayApp","Dashboard"}
  assert set(filt["Executables"])==expected,filt
  assert set(filt["Bundles"])=={"com.apple.springboard","com.apple.CarPlay",
   "com.apple.CarPlayApp","com.apple.dashboard"},filt
  current=inventory(stage)
  assert set(current)==set(original)
  changed={k for k in current if current[k]!=original[k]}
  assert changed=={MOD+".dylib",MOD+".plist"},changed
  assert all(current.get(name)==value for name,value in zip(HOSTS,SHA_HOSTS))
  assert current[ROOT+"DuoFaceSmartConnection.dylib"]==original[ROOT+"DuoFaceSmartConnection.dylib"]
  assert current[ROOT+"DuoFaceSmartConnection.plist"]==original[ROOT+"DuoFaceSmartConnection.plist"]
  ctl=stage/"DEBIAN/control"
  text=ctl.read_text()
  assert re.search(r"(?m)^Version: 0\.1\.0~native15$",text)
  ctl.write_text(re.sub(r"(?m)^Version: 0\.1\.0~native15$",f"Version: {VERSION}",text,count=1))
  (stage/"DEBIAN/md5sums").write_text("\n".join(hashlib.md5((stage/k).read_bytes()).hexdigest()+"  "+k for k in sorted(current))+"\n")
  args.out.parent.mkdir(parents=True,exist_ok=True)
  subprocess.run(["dpkg-deb","--build","--root-owner-group",str(stage),str(args.out)],check=True)
  assert command("dpkg-deb","-f",str(args.out),"Version")==VERSION
  assert command("dpkg-deb","-f",str(args.out),"Architecture")=="iphoneos-arm64"
  report={"status":"NATIVE16_FIXED_APP_PICKER_HOST_INJECTION_QA_CANDIDATE",
    "package":"com.duoface.independent","version":VERSION,
    "published_native15_base_sha256":BASE_SHA,"native16_sha256":sha(args.out.read_bytes()),
    "changed_payload_paths":sorted(changed),"preserved_legacy_payload_count":len(original)-len(changed),
    "preserved_original_host_sha256":dict(zip(HOSTS,SHA_HOSTS)),
    "preserved_smart_connection_dylib_sha256":current[ROOT+"DuoFaceSmartConnection.dylib"],
    "new_picker_dylib_sha256":current[MOD+".dylib"],
    "new_filter_sha256":current[MOD+".plist"],
    "injection_executables":sorted(expected),"injection_bundles":sorted(filt["Bundles"]),
    "native15_likely_missed_CarPlayApp_Dashboard_process":True,
    "same_original_preferences_policy_preserved":True,
    "dopamine_configuration_touched":False,"jailbreak_tweaks_run":False,
    "native12_and_native15_untouched":True,
    "device_tested":False,"sileo_published":False,
    "limitations":"Actual process, preferences location, and picker persistence must be tested on iPhone."}
  args.report.parent.mkdir(parents=True,exist_ok=True)
  args.report.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
  print(json.dumps(report,ensure_ascii=False,indent=2))
if __name__=="__main__":main()
