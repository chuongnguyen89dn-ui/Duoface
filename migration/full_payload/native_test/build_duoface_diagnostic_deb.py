#!/usr/bin/env python3
"""Package a separate read-only DuoFace SpringBoard diagnostic for Dopamine rootless."""
from __future__ import annotations
import argparse, hashlib, json, pathlib, shutil, subprocess, tempfile

PACKAGE="com.duoface.diagnostic"
VERSION="0.1.0~diag1"
ARCH="iphoneos-arm64"
DEST=pathlib.Path("var/jb/Library/MobileSubstrate/DynamicLibraries")
FILTER=pathlib.Path("DuoFaceDiagnostic.plist")
PREVIOUS=pathlib.Path("dist/payload-migration/native12-speed8compact/com.duoface.independent_0.1.0~native12+speed8compact_iphoneos-arm64.deb")
PREVIOUS_SHA="2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"

def sha(p: pathlib.Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()

def run(*args: object) -> None:
    subprocess.run([str(v) for v in args],check=True)

def main() -> None:
    p=argparse.ArgumentParser()
    p.add_argument("--dylib",type=pathlib.Path,required=True)
    p.add_argument("--output",type=pathlib.Path,required=True)
    p.add_argument("--report",type=pathlib.Path,required=True)
    opts=p.parse_args()
    assert PREVIOUS.is_file() and sha(PREVIOUS)==PREVIOUS_SHA, "Speed8 baseline must be preserved"
    assert opts.dylib.is_file() and opts.dylib.stat().st_size>1000
    assert FILTER.is_file() and FILTER.read_text().strip()==(
        '{ Filter = { Executables = ("SpringBoard"); }; }')
    assert not opts.output.exists() and not opts.report.exists()
    with tempfile.TemporaryDirectory(prefix="duoface-diagnostic-") as temp:
        root=pathlib.Path(temp)/"pkg"
        target=root/DEST
        target.mkdir(parents=True)
        dylib=target/"DuoFaceDiagnostic.dylib"
        plist=target/"DuoFaceDiagnostic.plist"
        shutil.copyfile(opts.dylib,dylib)
        dylib.chmod(0o755)
        shutil.copyfile(FILTER,plist)
        run("ldid","-S",dylib)
        run("lipo",dylib,"-verify_arch","arm64")
        run("plutil","-lint",plist)
        control=root/"DEBIAN"/"control"
        control.parent.mkdir(parents=True)
        control.write_text(
            f"Package: {PACKAGE}\n"
            "Name: DuoFace Diagnostic Log\n"
            f"Version: {VERSION}\n"
            f"Architecture: {ARCH}\n"
            "Maintainer: DuoFace Project\n"
            "Section: Tweaks\n"
            "Priority: optional\n"
            "Depends: com.duoface.independent\n"
            "Description: Independent read-only CarPlay state logger for DuoFace; no change to DuoFace itself.\n"
        )
        relative=[p.relative_to(root).as_posix() for p in root.rglob("*")
                  if p.is_file() and p.relative_to(root).parts[0]!="DEBIAN"]
        assert sorted(relative)==sorted([str(DEST/"DuoFaceDiagnostic.dylib"),
                                         str(DEST/"DuoFaceDiagnostic.plist")])
        (root/"DEBIAN/md5sums").write_text("".join(
            hashlib.md5((root/x).read_bytes()).hexdigest()+"  "+x+"\n"
            for x in sorted(relative)))
        opts.output.parent.mkdir(parents=True,exist_ok=True)
        run("dpkg-deb","--build","--root-owner-group",root,opts.output)
    def field(key: str) -> str:
        return subprocess.check_output(
            ["dpkg-deb","-f",str(opts.output),key],text=True).strip()
    assert (field("Package"),field("Version"),field("Architecture"))==(PACKAGE,VERSION,ARCH)
    assert field("Depends")=="com.duoface.independent"
    assert sha(PREVIOUS)==PREVIOUS_SHA, "No changes to existing DuoFace archive"
    info={
        "status":"BUILT_STATIC_QA_DEVICE_UNTESTED",
        "package":PACKAGE,"version":VERSION,"architecture":ARCH,
        "depends":"com.duoface.independent",
        "dylib_only_springboard":True,
        "no_replacement_of_duoface_files":True,
        "file_count":len(relative),
        "files":sorted(relative),
        "speed8_baseline_sha256_unchanged":PREVIOUS_SHA,
        "output_sha256":sha(opts.output),
        "runtime_log":"/var/mobile/Library/Logs/DuoFaceDiagnostic-SpringBoard.jsonl",
        "uikit_events_observed_not_carplay_icon_tap_hook":True,
        "has_method_hooks":False,"creates_uiwindow":False,
        "sileo_published":False,"device_tested":False
    }
    opts.report.parent.mkdir(parents=True,exist_ok=True)
    opts.report.write_text(json.dumps(info,ensure_ascii=False,indent=2)+"\n")
    print(json.dumps(info))
if __name__=="__main__":main()
