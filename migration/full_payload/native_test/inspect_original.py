#!/usr/bin/env python3
"""Đọc thực tế hợp đồng cài đặt và dependency của DuoFace gốc; không chỉnh sửa binary.

Ưu tiên payload nguyên 100% thay vì viết lại nút, menu, tính năng.
Không đưa vào report dữ liệu cá nhân hay giấy phép của thiết bị.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import pathlib
import plistlib
import subprocess
import tempfile

EXPECTED_SOURCE="ce971b42230d355421b2b1d99793a1f62ffb75008365ea74a3467d859cc1de3a"
CHECK_PATHS=[
    "var/jb/Applications/DuoFaceUI.app/Info.plist",
    "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.plist",
    "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.plist",
    "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.plist",
]
BIN_PATHS=[
    "var/jb/Applications/DuoFaceUI.app/DuoFaceUI",
    "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib",
    "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib",
    "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib",
    "var/jb/usr/libexec/duoface_cboptimize_helper",
]
LOOKUP_STRINGS=[
    b"com.duonavi.app",b"com.duoface.duofaceui",b"com.duoface.independent",
    b"com.duonavi.sync",b"DuoFaceDashboard",b"DuoFaceFullscreenBridge",
    b"DuoFaceVisualHook",b"DuoFaceUI.app",b"/Library/Application Support/DuoFace",
    b"duoface-cboptimize",b"duoface_cboptimize_helper",
]
def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--deb",type=pathlib.Path,required=True)
    parser.add_argument("--out",type=pathlib.Path,required=True)
    args=parser.parse_args()
    deb=args.deb.resolve()
    sha=hashlib.sha256(deb.read_bytes()).hexdigest()
    assert sha==EXPECTED_SOURCE, (sha,EXPECTED_SOURCE)
    with tempfile.TemporaryDirectory() as td:
        root=pathlib.Path(td)/"root"
        subprocess.run(["dpkg-deb","-R",str(deb),str(root)],check=True)
        info={}
        for p in CHECK_PATHS:
            path=root/p
            pl=plistlib.loads(path.read_bytes())
            if p.endswith("Info.plist"):
                info[p]={key:pl.get(key) for key in (
                    "CFBundleIdentifier","CFBundleExecutable","CFBundleName",
                    "CFBundleDisplayName","LSBackgroundOnly","SBAppTags",
                    "UIRequiredDeviceCapabilities","CFBundleURLTypes","UIBackgroundModes"
                )}
            else:
                info[p]={"Filter":pl.get("Filter"),"Enabled":pl.get("Enabled")}
        binaries={}
        for p in BIN_PATHS:
            path=root/p
            raw=path.read_bytes()
            linked=[]
            try:
                r=subprocess.run(["otool","-L",str(path)],capture_output=True,text=True)
                if r.returncode==0:
                    linked=[x.strip() for x in r.stdout.splitlines()[1:]]
            except FileNotFoundError:
                pass
            binaries[p]={
                "sha256":hashlib.sha256(raw).hexdigest(),"bytes":len(raw),
                "exact_string_counts":{term.decode():raw.count(term) for term in LOOKUP_STRINGS if term in raw},
                "linked_libraries":linked,
            }
        out={
            "state":"ORIGINAL_CODE_UNCHANGED_READ_ONLY",
            "source_sha256":sha,
            "control":{
                field:subprocess.check_output(["dpkg-deb","-f",str(deb),field],text=True).strip()
                for field in ("Package","Version","Architecture","Depends","Conflicts","Replaces")
                if subprocess.run(["dpkg-deb","-f",str(deb),field],capture_output=True).returncode==0
            },
            "original_info_and_filters":info,
            "binary_contracts":binaries,
            "original_postinst_exists":(root/"DEBIAN/postinst").is_file(),
            "original_prerm_exists":(root/"DEBIAN/prerm").is_file(),
            "safe_coinstall_same_paths":False,
            "need_new_bundle_id_and_gating":True,
            "next_step":"Tạo bản thử nghiệm original UI + package ID riêng; không tự ghi đè binary/helper khi bản cũ còn cài; cần kiểm tra lifecycle trên iPhone.",
        }
        args.out.parent.mkdir(parents=True,exist_ok=True)
        args.out.write_text(json.dumps(out,indent=2,sort_keys=True,ensure_ascii=False)+"\n")
        print(json.dumps({
            "result":out["state"],"original_bundle":info[CHECK_PATHS[0]]["CFBundleIdentifier"],
            "filters":{k:v["Filter"] for k,v in info.items() if "Filter" in v},
            "binary_reference_counts":{k:v["exact_string_counts"] for k,v in binaries.items()},
        },ensure_ascii=False,indent=2))

if __name__=="__main__":
    main()
