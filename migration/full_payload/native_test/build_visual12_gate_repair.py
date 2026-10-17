#!/usr/bin/env python3
"""Build a FUNCTIONAL three-getter VisualTest12 repair, not another log probe.

Source must be exact original VisualTest12, NOT mass-neutralized launchfix1 or
any independent Hub binary. Reversible candidate; real CarPlay QA pending.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import plistlib
import subprocess
import tempfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]
SOURCE=ROOT/"dist/visual-1.0.3-12/com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb"
PIN="8b7dedf77b9ec05465b83fdb6e2d7127800eac232a34ecf12f2c08b3983a481a"
OLD="1.0.3-12~visualtest"
VERSION="1.0.3-12~visualtest12repair1"
PACKAGE="com.duonavi.app"
INJECT="var/jb/Library/MobileSubstrate/DynamicLibraries"
SOURCE_PLIST=ROOT/"runtime/visualtest12/DFVisual12GateRepair.plist"
LIB="DFVisual12GateRepair.dylib"
PLIST="DFVisual12GateRepair.plist"
BUNDLES={"com.apple.springboard","com.apple.CarPlayApp",
         "com.duoface.duofaceui","com.duonavi.app"}

def sha(data:bytes)->str:
    return hashlib.sha256(data).hexdigest()

def run(*args:object)->None:
    subprocess.run([str(x) for x in args],check=True)

def dpkg_field(path:Path,key:str)->str:
    return subprocess.check_output(
        ["dpkg-deb","-f",str(path),key],text=True).strip()

def files(path:Path)->dict[str,str]:
    return {p.relative_to(path).as_posix():sha(p.read_bytes())
            for p in path.rglob("*") if p.is_file() and not p.is_symlink()}

def symlinks(path:Path)->dict[str,str]:
    return {p.relative_to(path).as_posix():str(p.readlink())
            for p in path.rglob("*") if p.is_symlink()}

def main()->None:
    ap=argparse.ArgumentParser()
    ap.add_argument("--dylib",required=True,type=Path)
    ap.add_argument("--out",required=True,type=Path)
    ap.add_argument("--report",required=True,type=Path)
    args=ap.parse_args()
    assert SOURCE.is_file() and sha(SOURCE.read_bytes())==PIN, "wrong VisualTest12 original"
    assert dpkg_field(SOURCE,"Package")==PACKAGE
    assert dpkg_field(SOURCE,"Version")==OLD
    assert dpkg_field(SOURCE,"Architecture")=="iphoneos-arm64"
    assert args.dylib.is_file() and args.dylib.stat().st_size>4000
    dylib=args.dylib.read_bytes()
    assert dylib[:4]==bytes.fromhex("cffaedfe"),"expected signed arm64 Mach-O dylib"
    cfg=plistlib.loads(SOURCE_PLIST.read_bytes())
    assert set(cfg["Filter"]["Bundles"])==BUNDLES
    assert args.out.resolve()!=SOURCE.resolve() and not args.out.exists()
    with tempfile.TemporaryDirectory(prefix="visual12-gate-repair-") as temp:
        stage=Path(temp)/"stage"
        run("dpkg-deb","-R",SOURCE,stage)
        before=files(stage)
        old_symlinks=symlinks(stage)
        targets={f"{INJECT}/{LIB}",f"{INJECT}/{PLIST}"}
        assert not (targets & set(before))
        dest=stage/INJECT
        dest.mkdir(parents=True,exist_ok=True)
        (dest/LIB).write_bytes(dylib)
        (dest/PLIST).write_bytes(SOURCE_PLIST.read_bytes())
        control=stage/"DEBIAN/control"
        ctrl=control.read_text(encoding="utf-8")
        pattern=f"Version: {OLD}\n"
        assert ctrl.count(pattern)==1
        control.write_text(ctrl.replace(pattern,f"Version: {VERSION}\n"),encoding="utf-8")
        md5=[]
        for path in sorted(stage.rglob("*")):
            if path.is_file() and not path.is_symlink():
                rel=path.relative_to(stage).as_posix()
                if not rel.startswith("DEBIAN/"):
                    md5.append(hashlib.md5(path.read_bytes()).hexdigest()+"  "+rel)
        (stage/"DEBIAN/md5sums").write_text("\n".join(md5)+"\n")
        after=files(stage)
        assert symlinks(stage)==old_symlinks
        assert not (set(before)-set(after)), "original file removed"
        new_files=set(after)-set(before)
        assert new_files-targets <= {"DEBIAN/md5sums"},new_files
        assert new_files & targets == targets
        modified=sorted(k for k in before if after[k]!=before[k])
        assert set(modified)<= {"DEBIAN/control","DEBIAN/md5sums"} and "DEBIAN/control" in modified
        preserved=[k for k in before if k.startswith("var/jb/")]
        assert preserved and all(before[k]==after[k] for k in preserved)
        args.out.parent.mkdir(parents=True,exist_ok=True)
        run("dpkg-deb","--build","--root-owner-group",stage,args.out)
    assert dpkg_field(args.out,"Package")==PACKAGE
    assert dpkg_field(args.out,"Version")==VERSION
    assert dpkg_field(args.out,"Architecture")=="iphoneos-arm64"
    report={
        "status":"VISUALTEST12_FUNCTIONAL_LICENSE_GATE_CANDIDATE_NOT_DEVICE_PROVEN",
        "package":PACKAGE,"version":VERSION,"original_source_sha256":PIN,
        "source_version":OLD,
        "added_files":sorted(targets),"changed_files":modified,
        "removed_original_files":[],
        "all_original_payload_files_byte_identical":True,
        "entire_original_scene_bridge_and_lifecycle_unmodified":True,
        "module":"runtime/visualtest12/DFVisual12GateRepair.m",
        "patched_getters":["CBLicenseSyncManager isLicenseCurrentlyValid",
                           "CBLicenseSyncManager remainingLicenseSeconds",
                           "CBLicenseSyncManager actualLicenseExpirationTimestamp"],
        "total_original_methods_neutralized":0,
        "duodash_binary_bundled":False,"airaw_binary_bundled":False,
        "hub_changed":False,"only_logging_probe":False,
        "device_tested":False,"sileo_published":False,
        "fallback_if_hooks_dont_load":"original behavior (unmodified source core)",
        "recovery_proven":False,
        "new_module_sha256":sha(dylib),
        "output_sha256":sha(args.out.read_bytes()),
        "output_bytes":args.out.stat().st_size,
    }
    args.report.parent.mkdir(parents=True,exist_ok=True)
    args.report.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n")
    print(json.dumps(report,indent=2,ensure_ascii=False))

if __name__=="__main__":
    main()
