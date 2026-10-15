#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Đóng DEB THỬ DuoFace nguyên ruột: giữ toàn bộ UI/host/visual/function gốc.

Không thay thế hay chép đè bản gốc trên thiết bị; installer từ chối khi
có package kế thừa được cài. Cơ chế test thử chưa phải kết quả runtime.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import pathlib
import plistlib
import shutil
import stat
import subprocess
import tempfile
import os
import sys

ROOT=pathlib.Path(__file__).resolve().parents[3]
SRC=ROOT/"dist/candidates/menu-native1/com.duonavi.app_1.0.3-12_menu-native1_iphoneos-arm64.deb"
EXPECTED="ce971b42230d355421b2b1d99793a1f62ffb75008365ea74a3467d859cc1de3a"
MANIFEST=ROOT/"dist/payload-migration/EXACT_COPY_AUDIT.json"
VERSION="0.1.0~native1"
ID="com.duoface.independent"
LIB="var/jb/Library/MobileSubstrate/DynamicLibraries"
NATIVE="A_DuoFaceNativeNoLease"
NEW_FILES={f"{LIB}/{NATIVE}.dylib",f"{LIB}/{NATIVE}.plist"}

def hash_file(p:pathlib.Path)->str:
    return hashlib.sha256(p.read_bytes()).hexdigest()

def run(cmd:list[str])->None:
    subprocess.run(cmd,check=True)

def file_inventory(stage:pathlib.Path)->dict[str,str]:
    out={}
    for p in stage.rglob("*"):
        if p.is_file() and not p.is_symlink() and not str(p.relative_to(stage)).startswith("DEBIAN/"):
            out[p.relative_to(stage).as_posix()]=hash_file(p)
    return out

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--policy",type=pathlib.Path,required=True)
    parser.add_argument("--out",type=pathlib.Path,required=True)
    parser.add_argument("--report",type=pathlib.Path,required=True)
    arg=parser.parse_args()
    assert SRC.exists() and hash_file(SRC)==EXPECTED, "Sai nguồn DuoFace gốc"
    assert arg.policy.is_file() and arg.policy.read_bytes()[:4] in (
        bytes.fromhex("cffaedfe"),bytes.fromhex("cafebabe"),
        bytes.fromhex("bebafeca")), "Thiếu dylib ARM64 Mach-O cho bản thử"
    old=json.loads(MANIFEST.read_text(encoding="utf-8"))
    assert old["source_sha256"]==EXPECTED
    wanted={k:v["sha256"] for k,v in old["all_staged_entries"].items() if v["kind"]=="file" and not k.startswith("DEBIAN/")}
    with tempfile.TemporaryDirectory(prefix="duoface-native-test-") as d:
        stage=pathlib.Path(d)/"root"
        run(["dpkg-deb","-R",str(SRC),str(stage)])
        srcmap=file_inventory(stage)
        assert srcmap==wanted | {"var/mobile/Library/Preferences/com.duonavi.sync.plist":
              hash_file(stage/"var/mobile/Library/Preferences/com.duonavi.sync.plist")}, "Baseline payload khác bản đã được kiểm kê"
        (stage/"var/mobile/Library/Preferences/com.duonavi.sync.plist").unlink()
        assert file_inventory(stage)==wanted, "Làm thay đổi UI/host gốc trước khi cài shim"

        # Original UI, Dashboard, geometry and full assets kept BYTE-FOR-BYTE
        # including CFBundleIdentifier com.duoface.duofaceui (host code depends on it).
        addon=stage/LIB/f"{NATIVE}.dylib"
        shutil.copyfile(arg.policy,addon)
        os.chmod(addon,0o755)
        filters={
            "Filter":{"Bundles":[
                "com.apple.springboard","com.apple.SpringBoard",
                "com.apple.CarPlay","com.apple.CarPlayApp","com.apple.dashboard",
                "com.duoface.duofaceui",
            ]}
        }
        plist=(stage/LIB/f"{NATIVE}.plist")
        plist.write_bytes(plistlib.dumps(filters,fmt=plistlib.FMT_XML))

        metadata=stage/"DEBIAN/control"
        lines=metadata.read_text(encoding="utf-8").splitlines()
        replace={
            "Package":ID,"Version":VERSION,
            "Name":"DuoFace Mới (Native thử nghiệm)",
            "Description":"DuoFace UI va loi goc, thuc nghiem khong dong bo cap phep. Can thiet bi test va khong cai dong thoi goi cu.",
            "Maintainer":"DuoFace Independent",
        }
        has=set()
        result=[]
        for line in lines:
            key=line.split(":",1)[0] if ":" in line else ""
            if key in ("Conflicts","Replaces","Provides","Breaks","Pre-Depends"):
                continue
            if key in replace:
                result.append(f"{key}: {replace[key]}");has.add(key)
            else:result.append(line)
        for key,value in replace.items():
            if key not in has:result.append(f"{key}: {value}")
        metadata.write_text("\n".join(result)+"\n",encoding="utf-8")

        # Prevent overwriting paths belonging to existing legacy DuoFace/DuoNavi.
        # No dpkg Conflicts or automatic removal. User must consciously migrate.
        pre=stage/"DEBIAN/preinst"
        pre.write_text("""#!/bin/sh
set -eu
for legacy in com.duonavi.app com.duoface.app; do
    status="$(dpkg-query -W -f='${Status}' "$legacy" 2>/dev/null || true)"
    if [ "$status" = "install ok installed" ]; then
        echo "DuoFace Native TEST: goi cu $legacy dang cai. Tu choi ghi de. KHONG xoa goi cu." >&2
        exit 1
    fi
done
exit 0
""")
        post=stage/"DEBIAN/postinst"
        post.write_text("""#!/bin/sh
set -eu
if command -v uicache >/dev/null 2>&1; then uicache -a || true; fi
echo "DuoFace Native TEST installed. Restart SpringBoard/CarPlay before device testing."
exit 0
""")
        prem=stage/"DEBIAN/prerm"
        prem.write_text("#!/bin/sh\nexit 0\n")
        for p in (pre,post,prem):os.chmod(p,0o755)

        # Regenerate every checksum after the staging transition.
        md5lines=[]
        for p in sorted(stage.rglob("*")):
            if p.is_file() and not p.is_symlink() and not p.relative_to(stage).parts[0]=="DEBIAN":
                md5lines.append(f"{hashlib.md5(p.read_bytes()).hexdigest()}  {p.relative_to(stage).as_posix()}")
        (stage/"DEBIAN/md5sums").write_text("\n".join(md5lines)+"\n")
        os.chmod(stage/"DEBIAN/md5sums",0o644)
        checked=file_inventory(stage)
        assert set(checked)-set(wanted)==NEW_FILES
        assert {k:checked[k] for k in wanted}==wanted, "Payload không còn nguyên byte!"
        assert not any("sync.plist" in key for key in checked)
        assert plistlib.loads((stage/"var/jb/Applications/DuoFaceUI.app/Info.plist").read_bytes())["CFBundleIdentifier"]=="com.duoface.duofaceui"
        assert plistlib.loads(plist.read_bytes())==filters
        arg.out.parent.mkdir(parents=True,exist_ok=True)
        run(["dpkg-deb","--build","--root-owner-group",str(stage),str(arg.out)])

    package_id=subprocess.check_output(["dpkg-deb","-f",str(arg.out),"Package"],text=True).strip()
    ver=subprocess.check_output(["dpkg-deb","-f",str(arg.out),"Version"],text=True).strip()
    assert (package_id,ver)==(ID,VERSION)
    report={
        "status":"ORIGINAL_UI_NATIVE_TRIAL_PACKAGE_BUILT_NOT_DEVICE_TESTED",
        "package":ID,"version":VERSION,
        "source_original_sha256":EXPECTED,
        "original_unchanged_payload_file_count":len(wanted),
        "original_unchanged_payload_sha256":wanted,
        "removed_files":["var/mobile/Library/Preferences/com.duonavi.sync.plist"],
        "added_runtime_files":sorted(NEW_FILES),
        "license_checks":"native trial redirects Objective-C license entrypoints; original embedded code remains present, not proven unused",
        "side_by_side":False,
        "installer_refuses_legacy_installed":True,
        "legacy_package_automatically_removed":False,
        "original_app_info_bundle_id_preserved":True,
        "original_dashboard_binary_unchanged":True,
        "original_ui_source_rewritten":False,
        "original_postinst_reused":False,
        "device_tested":False,
        "sileo_published":False,
        "deb_sha256":hash_file(arg.out),"deb_size":arg.out.stat().st_size,
    }
    arg.report.parent.mkdir(parents=True,exist_ok=True)
    arg.report.write_text(json.dumps(report,ensure_ascii=False,indent=2,sort_keys=True)+"\n")
    print(json.dumps({k:v for k,v in report.items() if k not in ("original_unchanged_payload_sha256",)},
                     ensure_ascii=False,indent=2))

if __name__=="__main__":
    main()
