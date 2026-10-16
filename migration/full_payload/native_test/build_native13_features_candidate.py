#!/usr/bin/env python3
"""Build an UNPUBLISHED native13 QA candidate from immutable native12 and two
separately compiled/signature-checked DuoFace-only connection and picker hooks.

Never claims license metadata was removed; physical excision has its own QA gate.
No Sileo publishing, no change to native12 and no implicit destructive cleanup.
"""
import argparse, hashlib, json, os, pathlib, shutil, subprocess, tempfile

BASE=pathlib.Path("dist/payload-migration/native12/com.duoface.independent_0.1.0~native12_iphoneos-arm64.deb")
SHA="85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7"
VERSION="0.1.0~native13"
ROOT="var/jb/Library/MobileSubstrate/DynamicLibraries"
ADDED=("DuoFaceSmartConnection","DuoFaceInCarAddApps")
PROTECTED=(
  "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib",
  "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib",
  "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib",
  "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceLogoGripOnly.dylib",
  "var/jb/Applications/DuoFaceUI.app/DuoFaceUI",
)
def run(*args):
    subprocess.run(args,check=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
def digest(data):return hashlib.sha256(data).hexdigest()
def collect(stage):
    return {f.relative_to(stage).as_posix():digest(f.read_bytes()) for f in stage.rglob("*")
            if f.is_file() and not f.is_symlink() and f.relative_to(stage).parts[0]!="DEBIAN"}
def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--smart-dylib",required=True,type=pathlib.Path)
    ap.add_argument("--app-dylib",required=True,type=pathlib.Path)
    ap.add_argument("--out",required=True,type=pathlib.Path)
    ap.add_argument("--report",required=True,type=pathlib.Path)
    args=ap.parse_args()
    assert digest(BASE.read_bytes())==SHA,"immutable native12 DEB hash mismatch"
    assert not args.out.exists(),"native13 candidate must not overwrite"
    assert subprocess.check_output(["dpkg-deb","-f",str(BASE),"Package"],text=True).strip()=="com.duoface.independent"
    assert subprocess.check_output(["dpkg-deb","-f",str(BASE),"Version"],text=True).strip()=="0.1.0~native12"
    with tempfile.TemporaryDirectory(prefix="duoface-native13-qa-only-") as tmp:
        root=pathlib.Path(tmp)/"root"
        run("dpkg-deb","-R",str(BASE),str(root))
        orig=collect(root)
        for rel in PROTECTED:
            assert rel in orig,rel
        libdir=root/ROOT
        added={}
        for name,src in zip(ADDED,(args.smart_dylib,args.app_dylib)):
            assert src.is_file() and len(src.read_bytes())>2000,src
            dylib=libdir/(name+".dylib")
            filt=libdir/(name+".plist")
            assert not dylib.exists() and not filt.exists(),(dylib,filt)
            shutil.copy2(src,dylib)
            shutil.copy2(pathlib.Path(name+".plist"),filt)
            # Standalone Theos outputs need valid iOS code signature to inject.
            run("ldid","-S",str(dylib))
            run("lipo",str(dylib),"-verify_arch","arm64")
            run("plutil","-lint",str(filt))
            added[name]={"dylib":f"{ROOT}/{name}.dylib","plist":f"{ROOT}/{name}.plist",
                         "sha256":digest(dylib.read_bytes()),"filter_sha256":digest(filt.read_bytes())}
        control=root/"DEBIAN/control"
        s=control.read_text(encoding="utf-8")
        assert "Version: 0.1.0~native12" in s
        control.write_text(s.replace("Version: 0.1.0~native12",f"Version: {VERSION}",1),encoding="utf-8")
        current=collect(root)
        unexpected=set(current)-set(orig)-{f"{ROOT}/{n}.{ext}" for n in ADDED for ext in ("dylib","plist")}
        assert not unexpected,unexpected
        assert all(current[k]==v for k,v in orig.items()),"native12 legacy file modified"
        assert all(current.get(rel)==orig[rel] for rel in PROTECTED)
        assert f"{ROOT}/A_DuoFaceNativeNoLease.dylib" not in current
        # Rebuild package member checksum list with the exact updated payload.
        md5=[]
        for path in sorted(current):
            payload=(root/path).read_bytes()
            md5.append(f"{hashlib.md5(payload).hexdigest()}  {path}")
        (root/"DEBIAN/md5sums").write_text("\n".join(md5)+"\n")
        args.out.parent.mkdir(parents=True,exist_ok=True)
        run("dpkg-deb","--build","--root-owner-group",str(root),str(args.out))
        report={
         "status":"NATIVE13_TWO_FEATURES_SIGNED_COMBINED_QA_CANDIDATE_NOT_PUBLISHED",
         "package":"com.duoface.independent","version":VERSION,
         "input_native12_sha256":SHA,"candidate_sha256":digest(args.out.read_bytes()),
         "added_modules":added,"existing_payload_entries_unchanged":len(orig),
         "all_original_payload_byte_identical":True,
         "all_five_carplay_and_visual_hosts_byte_identical":True,
         "old_license_hook_still_absent":True,
         "remaining_license_class_metadata_physically_removed":False,
         "full_license_excision_verified":False,
         "sileo_published":False,"device_tested":False,
         "must_not_publish_as_complete_license_excision":True
        }
        args.report.parent.mkdir(parents=True,exist_ok=True)
        args.report.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
        print(json.dumps(report,indent=2))
if __name__=="__main__":main()
