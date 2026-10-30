#!/usr/bin/env python3
"""Verify two original archived DEBs and collect read-only CarPlay/Home markers."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile

PINS={
 "DuoNavi104":("f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd","DuoNaviDashboard.dylib","44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15"),
 "Native12Reference":("2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad","DuoFaceDashboard.dylib","9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea")
}
KEYS=["CARApplication","DBApplicationController","DBApplicationInfo","LSBundleProxy",
      "FBSApplicationInfo","LSBundleInfoCachedValues","_newApplicationLibrary",
      "_allInstalledApplications","entitlementValueForKey:ofClass:valuesOfClass:",
      "entitlementValuesForKeys:","SBStarkCapable","CARCapableApp",
      "CRSIconLayoutService","homeScreenShownApps","homeScreenHiddenApps",
      "bridgedApps","appBridgeApps","setApp:enabled:","showAppPickerForSlot:",
      "addMoreAppsTapped:","appSelected:","prepareHomeScreenForBridge:",
      "homeButtonUp:","MSHookMessageEx"]
def sha(path):
 return hashlib.sha256(path.read_bytes()).hexdigest()
def scan(name,source,tmp):
 pin,dylib,digest=PINS[name]
 assert sha(source)==pin,(name,"wrong DEB SHA256")
 target=tmp/name
 subprocess.run(["dpkg-deb","-x",str(source),str(target)],check=True)
 found=list(target.rglob(dylib))
 assert len(found)==1 and sha(found[0])==digest,(name,"wrong primary dylib")
 bins=[]
 for file in sorted(target.rglob("*")):
  if not file.is_file():continue
  if file.open("rb").read(4) not in (bytes.fromhex("cffaedfe"),bytes.fromhex("cafebabe"),bytes.fromhex("cafebabf")):continue
  strings=subprocess.check_output(["strings","-a","-n","5",str(file)],text=True,errors="replace").splitlines()
  matches=sorted(set(x for x in strings if any(term.lower() in x.lower() for term in KEYS) and len(x)<180))
  bins.append({"path":str(file.relative_to(target)),"sha256":sha(file),"markers":matches[:160],"total_matches":len(matches)})
 return {"DEB_SHA256":pin,"primary_image":str(found[0].relative_to(target)),
         "primary_SHA256":digest,"MachO_count":len(bins),"binaries":bins}
def main():
 p=argparse.ArgumentParser()
 p.add_argument("--duonavi",type=Path,required=True)
 p.add_argument("--native12",type=Path,required=True)
 p.add_argument("--out",type=Path,required=True)
 a=p.parse_args()
 with tempfile.TemporaryDirectory() as t:
  out={"evidence":"SHA-pinned original DEB byte scan; strings alone do not prove execution",
       "native12_note":"derived reference; NOT untouched stock original",
       "DuoNavi104":scan("DuoNavi104",a.duonavi,Path(t)),
       "Native12Reference":scan("Native12Reference",a.native12,Path(t))}
 a.out.parent.mkdir(parents=True,exist_ok=True)
 a.out.write_text(json.dumps(out,indent=2,ensure_ascii=False)+"\n")
 print("ORIGINAL_HOME_MARKER_REAL_DEB_SCAN_PASS",out["DuoNavi104"]["MachO_count"],out["Native12Reference"]["MachO_count"])
if __name__=="__main__":main()
