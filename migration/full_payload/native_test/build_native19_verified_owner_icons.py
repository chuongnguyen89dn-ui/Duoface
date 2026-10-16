#!/usr/bin/env python3
"""Rebuild only direct AddApps module from published, hash-pinned native18.

The immutable source contains the native12 exact license core, native18
settings-only UI restoration and 10 second SmartConnection. No edits to those
files, original media, CarPlay menu layout or tweak filters.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

BASE=Path("dist/payload-migration/native18/com.duoface.independent_0.1.0~native18_iphoneos-arm64.deb")
BASE_SHA="dfbcde5a309f7e90c414c2a10385e96aab3f17ebab0c7dd491313c9ef6a63503"
VERSION="0.1.0~native19"
PREF="var/jb/Library/MobileSubstrate/DynamicLibraries/"
MODULE=PREF+"DuoFaceInCarAddApps.dylib"
DASH=PREF+"DuoFaceDashboard.dylib"
UI="var/jb/Applications/DuoFaceUI.app/DuoFaceUI"
SMART=PREF+"DuoFaceSmartConnection.dylib"
UI_RESTORE=PREF+"DuoFaceSettingsUIRestore.dylib"
REQUIRED_HASHES={
 UI:"cb40346d8ca504cb399abe31367847b4f980a01ba93810986ce1acf1fbe9eef9",
 DASH:"9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea",
 SMART:"0986cf70b4c613ad011520204337e1e2b403d24111f39f14f70628fb57e61d50",
 UI_RESTORE:"680f79a1bb4d58a3bf277f7ed253f88627459390599a0818660f89dabe2e629f",
}
def sha(raw):return hashlib.sha256(raw).hexdigest()
def check(*args):return subprocess.check_output(args,text=True,stderr=subprocess.STDOUT).strip()
def entries(root):
 return {f.relative_to(root).as_posix():sha(f.read_bytes()) for f in root.rglob("*")
         if f.is_file() and not f.is_symlink() and f.relative_to(root).parts[0]!="DEBIAN"}
def main():
 ap=argparse.ArgumentParser()
 ap.add_argument("--dylib",required=True,type=Path)
 ap.add_argument("--out",required=True,type=Path)
 ap.add_argument("--report",required=True,type=Path)
 args=ap.parse_args()
 assert BASE.is_file() and sha(BASE.read_bytes())==BASE_SHA
 assert check("dpkg-deb","-f",str(BASE),"Package")=="com.duoface.independent"
 assert check("dpkg-deb","-f",str(BASE),"Version")=="0.1.0~native18"
 assert check("dpkg-deb","-f",str(BASE),"Architecture")=="iphoneos-arm64"
 assert args.dylib.is_file() and len(args.dylib.read_bytes())>3000
 assert not args.out.exists() and not args.report.exists(), "No overwrite of signed release"
 source=Path("runtime/appbridge/DFInCarAppPicker.xm").read_text()
 assert source.count("- (void)addMoreAppsTapped:(id)sender {") == 1
 assert "%orig" not in source, "Old modal fallback must never be reachable through new hook"
 assert 'dict[@"appSettings"]' in source and "kDFBridgedAppsKey" in source
 assert "DFInCarAppPicker" in source and "DFSaveToNativePreferences" in source
 assert 'com.duonavi.plist' in source and "DFInCarIconForBundle" in source
 assert "Dừng xe an toàn và mở DuoFace trên iPhone" not in source
 with tempfile.TemporaryDirectory(prefix="duoface-native19-app-picker-") as tmp:
  stage=Path(tmp)/"stage"
  subprocess.run(["dpkg-deb","-R",str(BASE),str(stage)],check=True)
  before=entries(stage)
  assert len(before)==45, len(before)
  assert all(before.get(k)==v for k,v in REQUIRED_HASHES.items())
  assert MODULE in before and PREF+"DuoFaceInCarAddApps.plist" in before
  assert not any("A_DuoFaceNativeNoLease" in x for x in before)
  shutil.copy2(args.dylib,stage/MODULE)
  subprocess.run(["ldid","-S",str(stage/MODULE)],check=True)
  subprocess.run(["lipo",str(stage/MODULE),"-verify_arch","arm64"],check=True)
  after=entries(stage)
  changed={p for p in before if before[p]!=after[p]}
  assert before.keys()==after.keys()
  assert changed=={MODULE},changed
  assert all(after[k]==v for k,v in REQUIRED_HASHES.items())
  filt=PREF+"DuoFaceInCarAddApps.plist"
  assert before[filt]==after[filt]
  control=stage/"DEBIAN/control"
  text=control.read_text()
  assert "Version: 0.1.0~native18" in text
  control.write_text(text.replace("Version: 0.1.0~native18","Version: "+VERSION,1))
  (stage/"DEBIAN/md5sums").write_text("\n".join(
       hashlib.md5((stage/f).read_bytes()).hexdigest()+"  "+f for f in sorted(after))+"\n")
  args.out.parent.mkdir(parents=True,exist_ok=True)
  subprocess.run(["dpkg-deb","--build","--root-owner-group",str(stage),str(args.out)],check=True)
  assert check("dpkg-deb","-f",str(args.out),"Version")==VERSION
  assert check("dpkg-deb","-f",str(args.out),"Package")=="com.duoface.independent"
  report={
   "status":"NATIVE19_DIRECT_CARPLAY_ADD_APP_NO_ORIGINAL_MODAL_COMPILED_CANDIDATE",
   "version":VERSION,"package":"com.duoface.independent",
   "source_native18_sha256":BASE_SHA,
   "native19_sha256":sha(args.out.read_bytes()),
   "native19_bytes":args.out.stat().st_size,
   "original_payload_files_preserved_count":len(before)-len(changed),
   "changed_payload_paths":sorted(changed),
   "every_other_native18_payload_byte_identical":True,
   "native12_exact_license_core_preserved":True,
   "required_preserved_hashes":REQUIRED_HASHES,
   "picker_filter_plist_unchanged_sha256":after[filt],
   "new_picker_sha256":after[MODULE],
   "old_carplay_alert_fallback_in_new_module_source":False,
   "old_alert_bytes_still_in_unmodified_legacy_Dashboard":True,
   "appSettings_and_bridgedApps_schema_from_native_disassembly":True,
   "shared_config_file_discovery_runtime_confirmed":False,
   "app_picker_device_tested":False,
   "sileo_published":False,
   "dopamine_touched":False,
   "notes":"native19 uses exact native12 decoded legacy preference pathname, validates live list, and provides icon fallback; not yet tested on iPhone or CarPlay. Auto Resume and layout unchanged."
  }
 args.report.parent.mkdir(parents=True,exist_ok=True)
 args.report.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
 print(json.dumps(report,ensure_ascii=False,indent=2))
if __name__=="__main__":main()
