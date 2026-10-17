#!/usr/bin/env python3
"""DIAG2 replaces only the separate diagnostic package, never com.duoface.independent."""
from __future__ import annotations
import argparse,hashlib,json,pathlib,shutil,subprocess,tempfile
PACKAGE="com.duoface.diagnostic"
VERSION="0.2.0~diag2"
ARCH="iphoneos-arm64"
ROOT=pathlib.Path("var/jb/Library/MobileSubstrate/DynamicLibraries")
PLIST=pathlib.Path("DuoFaceDiagnostic2.plist")
SPEED8=pathlib.Path("dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb")
PIN="2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def run(*args):subprocess.run([str(x) for x in args],check=True)
def main():
    a=argparse.ArgumentParser()
    for x in ("dylib","output","report"):a.add_argument("--"+x,required=True,type=pathlib.Path)
    args=a.parse_args()
    assert SPEED8.is_file() and sha(SPEED8)==PIN,"Speed8 baseline modified/missing"
    assert args.dylib.is_file() and args.dylib.stat().st_size>1000
    assert PLIST.read_text().strip()=='{ Filter = { Executables = ("SpringBoard", "CarPlayApp", "CarPlay", "DashBoard"); }; }'
    assert not args.output.exists() and not args.report.exists()
    with tempfile.TemporaryDirectory(prefix="duoface-diag2-") as t:
        pkg=pathlib.Path(t)/"pkg"
        target=pkg/ROOT
        target.mkdir(parents=True)
        lib=target/"DuoFaceDiagnostic2.dylib"
        dst=target/"DuoFaceDiagnostic2.plist"
        shutil.copyfile(args.dylib,lib)
        shutil.copyfile(PLIST,dst)
        lib.chmod(0o755)
        run("ldid","-S",lib)
        run("lipo",lib,"-verify_arch","arm64")
        run("plutil","-lint",dst)
        files=sorted(p.relative_to(pkg).as_posix() for p in target.iterdir() if p.is_file())
        assert files==sorted([str(ROOT/"DuoFaceDiagnostic2.dylib"),str(ROOT/"DuoFaceDiagnostic2.plist")])
        debian=pkg/"DEBIAN"
        debian.mkdir()
        (debian/"control").write_text(
            f"Package: {PACKAGE}\nName: DuoFace Diagnostic DIAG2\nVersion: {VERSION}\nArchitecture: {ARCH}\n"
            "Maintainer: DuoFace Project\nSection: Tweaks\nPriority: optional\n"
            "Depends: com.duoface.independent\n"
            "Description: Optional DuoFace CarPlay-Dashboard/SpringBoard trace for iPhone X; ABI-guarded and no UI changes.\n"
        )
        (debian/"md5sums").write_text("".join(hashlib.md5((pkg/x).read_bytes()).hexdigest()+"  "+x+"\n" for x in files))
        args.output.parent.mkdir(parents=True,exist_ok=True)
        run("dpkg-deb","--build","--root-owner-group",pkg,args.output)
    def field(s):return subprocess.check_output(["dpkg-deb","-f",str(args.output),s],text=True).strip()
    assert tuple(field(s) for s in ("Package","Version","Architecture","Depends"))==(PACKAGE,VERSION,ARCH,"com.duoface.independent")
    assert sha(SPEED8)==PIN
    report={
       "status":"BUILT_STATIC_QA_NOT_DEVICE_TESTED",
       "package":PACKAGE,"version":VERSION,"architecture":ARCH,
       "replaces_diag1_package_on_install":True,
       "depends":"com.duoface.independent",
       "file_count":len(files),"files":files,
       "output_sha256":sha(args.output),
       "speed8_baseline_sha256_unchanged":PIN,
       "signature_guarded_message_hooks":True,
       "no_duoface_independent_files":True,
       "creates_uiwindow":False,
       "forces_activation":False,
       "log_files":["/var/mobile/Library/Logs/DuoFaceDiagnostic2-SpringBoard.jsonl","/var/mobile/Library/Logs/DuoFaceDiagnostic2-CarPlay.jsonl"],
       "carplay_executable_names_are_candidates_only":True,
       "sileo_published":False,"device_tested":False
    }
    args.report.parent.mkdir(parents=True,exist_ok=True)
    args.report.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n")
    print(json.dumps(report))
if __name__=="__main__":main()
