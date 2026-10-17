#!/usr/bin/env python3
"""Losslessly preserve released Speed6zProbe1; append only read-only SpringBoard owner module."""
from __future__ import annotations
import argparse
import hashlib
import json
import pathlib
import shutil
import subprocess
import tempfile

BASE=pathlib.Path("dist/payload-migration/native12-speed6probe1/com.duoface.independent_0.1.0~native12+speed6zprobe1_iphoneos-arm64.deb")
PIN="42f7300463fa7aeecfb28342298e5faf3c77dcf0319e77964a6b35622eba722e"
VERSION="0.1.0~native12+speed6zzowner1"
DIR=pathlib.Path("var/jb/Library/MobileSubstrate/DynamicLibraries")
NEW=("DuoFaceSpeedOwner.dylib","DuoFaceSpeedOwner.plist")
BAN=("DuoFaceSpeedSources","WazeGMapHUDSource","GofaGMapHUDSource","VietMapGoogleMapsSource","GMapHUDPlacementRelay","GMapHUDOverspeedScreen","GoogleMapsVietMap")
def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def cmd(*args): subprocess.run([str(a) for a in args],check=True)
def inventory(root):
    return {str(p.relative_to(root)):digest(p) for p in root.rglob("*")
        if p.is_file() and not p.is_symlink() and p.relative_to(root).parts[0]!="DEBIAN"}

def main():
    parser=argparse.ArgumentParser()
    for field in ("owner","output","report"):
        parser.add_argument("--"+field,required=True,type=pathlib.Path)
    a=parser.parse_args()
    assert BASE.is_file() and digest(BASE)==PIN, "Released Speed6zProbe1 exact DEB SHA mismatch"
    assert a.owner.is_file() and a.owner.stat().st_size>3000, "Missing compiled arm64 owner module"
    assert not a.output.exists() and not a.report.exists(), "Do not overwrite prior package"
    with tempfile.TemporaryDirectory(prefix="duoface-ownerprobe-") as td:
        root=pathlib.Path(td)/"payload"
        cmd("dpkg-deb","-R",BASE,root)
        before=inventory(root)
        assert len(before)==41,len(before)
        assert not any(any(item in key for item in BAN) for key in before)
        lib=root/DIR
        for p in ("DuoFaceDashboard","DuoFaceFullscreenBridge","DuoFaceVisualHook","DuoFaceLogoGripOnly","DuoFaceSpeedHUD"):
            assert str(DIR/(p+".dylib")) in before,p
        assert str(DIR/"DuoFaceSpeedHUD.plist") in before
        assert "var/jb/Applications/DuoFaceUI.app/DuoFaceUI" in before
        owner=lib/NEW[0]
        plist=lib/NEW[1]
        assert owner.stem==plist.stem
        assert not owner.exists() and not plist.exists()
        shutil.copy2(a.owner,owner)
        owner.chmod(0o755)
        shutil.copy2("DuoFaceSpeedOwner.plist",plist)
        assert b"SpringBoard" in plist.read_bytes()
        assert b"Executables" in plist.read_bytes()
        assert b"CarPlayApp" not in plist.read_bytes()
        cmd("ldid","-S",owner)
        cmd("lipo",owner,"-verify_arch","arm64")
        cmd("plutil","-lint",plist)
        ctrl=root/"DEBIAN/control"
        original=ctrl.read_text()
        assert "Version: 0.1.0~native12+speed6zprobe1" in original
        ctrl.write_text(original.replace("Version: 0.1.0~native12+speed6zprobe1","Version: "+VERSION,1))
        after=inventory(root)
        assert set(after)-set(before)=={str(DIR/n) for n in NEW}
        assert all(after[p]==s for p,s in before.items()),"Original CarPlay HUD or Native12 changed"
        (root/"DEBIAN/md5sums").write_text("".join(
            hashlib.md5((root/p).read_bytes()).hexdigest()+"  "+p+"\n"
            for p in sorted(after)))
        a.output.parent.mkdir(parents=True,exist_ok=True)
        cmd("dpkg-deb","--build","--root-owner-group",root,a.output)
        appended={str(DIR/n):after[str(DIR/n)] for n in NEW}
    get=lambda f:subprocess.check_output(["dpkg-deb","-f",str(a.output),f],text=True).strip()
    assert (get("Package"),get("Version"),get("Architecture"))==(
        "com.duoface.independent",VERSION,"iphoneos-arm64")
    report={
        "status":"SPEED6ZZOWNER1_SPRINGBOARD_OWNER_QA_STATIC_PASS_NOT_DEVICE_TESTED",
        "input_released_speed6_sha256":PIN,
        "input_native12_lineage_sha256":"85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7",
        "output_sha256":digest(a.output),
        "preserved_file_count":len(before),
        "all_previous_speed6_payload_files_byte_identical":True,
        "new_module":appended,
        "new_module_count":len(NEW),
        "springboard_readonly":True,
        "no_springboard_uiwindow_creation_or_method_hooks":True,
        "carplay_hud_injection_and_gates_unchanged":True,
        "no_third_party_injection_or_waze_hooks":True,
        "springboard_probe_log":"/var/mobile/Library/Logs/DuoFaceSpeedOwner-SpringBoard.jsonl",
        "carplay_existing_log":"/var/mobile/Library/Logs/DuoFaceSpeed6-CarPlayApp.jsonl",
        "sileo_published":False,
        "device_tested":False,
    }
    a.report.parent.mkdir(parents=True,exist_ok=True)
    a.report.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n")
    print(json.dumps(report,ensure_ascii=False))

if __name__=="__main__":main()
