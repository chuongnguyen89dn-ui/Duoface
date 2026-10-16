#!/usr/bin/env python3
"""Build a single-bubble SPEEDHUD TEST candidate from EXACT user-tested Native12.

Native12 (sha256 pinned) stays byte-exact in every pre-existing payload file.
This does NOT integrate native13-21. Does not upload to Sileo on its own.
The GMapHUD v0.2.3 source-only publishers remain individually version guarded.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import subprocess
import tempfile

from stage_gmaphud_modules_for_duoface import (
    stage as stage_publishers, NATIVE12_SHA256, GMAP_SHA256, DYLIB_DIR,
)

BASE = Path("dist/payload-migration/native12/com.duoface.independent_0.1.0~native12_iphoneos-arm64.deb")
VERSION = "0.1.0~native12+speedhud1"
NEW = ("DuoFaceSpeedHUD", "DuoFaceSpeedSources")
FILTERS = {
    "DuoFaceSpeedHUD": {"com.apple.springboard"},
    "DuoFaceSpeedSources": {
        "com.google.Maps", "com.waze.iphone",
        "vn.vietmap.live", "com.lumi.GOFA",
    },
}
PROTECTED = (
    "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib",
    "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib",
    "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib",
    "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceLogoGripOnly.dylib",
    "var/jb/Applications/DuoFaceUI.app/DuoFaceUI",
)
FORBIDDEN = ("GMapHUDOverspeedScreen", "GMapHUDPlacementRelay",
             "GoogleMapsVietMap", "DuoFaceInCarAddApps", "DuoFaceSmartConnection")

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def run(*args: str) -> None:
    subprocess.run(args, check=True)

def dpkg_field(deb: Path, key: str) -> str:
    return subprocess.check_output(["dpkg-deb", "-f", str(deb), key], text=True).strip()

def snapshot(root: Path) -> dict:
    files = {}
    for p in root.rglob("*"):
        r = p.relative_to(root)
        if r.parts[0] == "DEBIAN":
            continue
        if p.is_symlink():
            files[r.as_posix()] = {"symlink": p.readlink().as_posix()}
        elif p.is_file():
            files[r.as_posix()] = {"sha256": sha(p), "mode": p.stat().st_mode & 0o7777}
    return files

def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--gmaphud", type=Path, required=True)
    ap.add_argument("--hud-dylib", type=Path, required=True)
    ap.add_argument("--source-dylib", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--report", type=Path, required=True)
    args = ap.parse_args()
    assert BASE.is_file() and sha(BASE)==NATIVE12_SHA256, "Wrong Native12! No native13+"
    assert args.gmaphud.is_file() and sha(args.gmaphud)==GMAP_SHA256, "Wrong GMapHUD"
    assert not args.out.exists() and not args.report.exists(), "Never overwrite an existing candidate"
    assert dpkg_field(BASE,"Package")=="com.duoface.independent"
    assert dpkg_field(BASE,"Architecture")=="iphoneos-arm64"
    assert dpkg_field(BASE,"Version")=="0.1.0~native12"
    run("dpkg","--compare-versions",VERSION,"gt","0.1.0~native12")
    run("dpkg","--compare-versions",VERSION,"lt","0.1.0~native13")
    with tempfile.TemporaryDirectory(prefix="duoface-native12-speed1-") as tmp:
        root = Path(tmp)
        stage = root/"stage"
        import_report = root/"import.json"
        import_data = stage_publishers(args.gmaphud,stage,import_report,BASE)
        assert import_data["single_duoface_hud_only"]
        assert len(import_data["copied"])==8
        before_root = root/"native12-ref"
        run("dpkg-deb","-R",str(BASE),str(before_root))
        original = snapshot(before_root)
        assert len(original)>30
        for protected in PROTECTED:
            assert protected in original, f"Native12 protected host missing: {protected}"
        newly_added = set(import_data["copied"])
        libdir = stage/DYLIB_DIR
        compiled = {}
        for name,compiled_path in zip(NEW,(args.hud_dylib,args.source_dylib)):
            assert compiled_path.is_file() and compiled_path.stat().st_size>2000
            relative = (DYLIB_DIR/(name+".dylib")).as_posix()
            filter_relative = (DYLIB_DIR/(name+".plist")).as_posix()
            dest = stage/relative
            f = stage/filter_relative
            assert not dest.exists() and not f.exists()
            dest.write_bytes(compiled_path.read_bytes())
            dest.chmod(0o755)
            f.write_bytes(Path(name+".plist").read_bytes())
            assert set(plistlib.loads(f.read_bytes())["Filter"]["Bundles"]) == FILTERS[name]
            run("ldid","-S",str(dest))
            run("lipo",str(dest),"-verify_arch","arm64")
            run("plutil","-lint",str(f))
            compiled[name] = {"dylib":relative,"dylib_sha256":sha(dest),
                              "plist":filter_relative,"plist_sha256":sha(f)}
            newly_added.update((relative,filter_relative))
        after = snapshot(stage)
        for bad in FORBIDDEN:
            assert not any(bad in p for p in after),f"Forbidden other-version/duplicate UI: {bad}"
        assert all(k in after and v==after[k] for k,v in original.items()), "Native12 file modified!"
        assert set(after)-set(original)==newly_added, (
            "Wrong set of added files",sorted(set(after)-set(original)),sorted(newly_added))
        assert not (libdir/"A_DuoFaceNativeNoLease.dylib").exists()
        control = stage/"DEBIAN/control"
        old_control=control.read_text(encoding="utf-8")
        assert "Version: 0.1.0~native12" in old_control
        control.write_text(old_control.replace("Version: 0.1.0~native12",
                              "Version: "+VERSION,1),encoding="utf-8")
        # No hidden full-app reprovisioning: all byte-identical baseline files remain.
        md5=[]
        for rel in sorted(after):
            f=stage/rel
            if f.is_file() and not f.is_symlink():
                md5.append(hashlib.md5(f.read_bytes()).hexdigest()+"  "+rel)
        (stage/"DEBIAN/md5sums").write_text("\n".join(md5)+"\n",encoding="utf-8")
        args.out.parent.mkdir(parents=True, exist_ok=True)
        run("dpkg-deb","--build","--root-owner-group",str(stage),str(args.out))
    assert dpkg_field(args.out,"Package")=="com.duoface.independent"
    assert dpkg_field(args.out,"Architecture")=="iphoneos-arm64"
    assert dpkg_field(args.out,"Version")==VERSION
    report={
        "status":"BUILT_NATIVE12_SPEEDHUD1_TEST_CANDIDATE_NOT_DEVICE_TESTED",
        "base":"dist/payload-migration/native12/com.duoface.independent_0.1.0~native12_iphoneos-arm64.deb",
        "base_sha256":NATIVE12_SHA256,
        "gmaphud_023_sha256":GMAP_SHA256,
        "version":VERSION,
        "candidate_sha256":sha(args.out),
        "candidate_size":args.out.stat().st_size,
        "all_original_payload_byte_identical":True,
        "original_payload_count":len(original),
        "added_exact_count":len(newly_added),
        "added_source_files":import_data["copied"],
        "added_duoface_tweaks":compiled,
        "no_second_hud_renderer":True,
        "google_maps_speed_limit_implemented":False,
        "user_installs_extra_hud_tweaks":False,
        "sileo_published":False,
        "device_tested":False,
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    print(json.dumps(report,indent=2,ensure_ascii=False))

if __name__=="__main__":
    main()
