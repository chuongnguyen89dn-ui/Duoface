#!/usr/bin/env python3
"""Independent native12 DEB removal QA: exact two files missing, nothing else.

This is only a package/reference invariant, not real-world CarPlay QA.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

from build_native5 import FILES,sha
from build_native12_without_lease_bridge import BASE,BASE_SHA,VERSION,REMOVALS

def file_hashes(root:Path)->dict:
    return {
        file.relative_to(root).as_posix():sha(file.read_bytes())
        for file in root.rglob("*") if file.is_file() and not file.is_symlink()
    }

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--deb",required=True,type=Path)
    ap.add_argument("--report",required=True,type=Path)
    ap.add_argument("--out",required=True,type=Path)
    args=ap.parse_args()
    rep=json.loads(args.report.read_text(encoding="utf-8"))
    assert sha(BASE.read_bytes())==BASE_SHA
    assert rep["status"]=="NATIVE12_WHOLE_OBSOLETE_LEASE_HOOK_LIBRARY_AND_FILTER_REMOVED_FROM_REAL_DEB"
    assert rep["source_native11_sha256"]==BASE_SHA
    assert rep["deb_sha256"]==sha(args.deb.read_bytes())
    assert rep["files_physically_removed"]==sorted(REMOVALS)
    assert rep["matching_hook_selector_count"]==10
    assert rep["all_8_carplay_method_bodies_byte_identical"]
    assert rep["all_app_and_dashboard_code_and_objc_metadata_byte_identical"]
    assert not rep["dynamic_objc_or_process_dependency_proven_absent"]
    assert not rep["all_license_code_and_metadata_fully_removed"]
    assert not rep["device_tested"] and not rep["new_deb_on_sileo"]
    for key,value in (("Version",VERSION),("Package","com.duoface.independent"),
                      ("Architecture","iphoneos-arm64")):
        assert subprocess.check_output(["dpkg-deb","-f",str(args.deb),key],text=True).strip()==value
    with tempfile.TemporaryDirectory(prefix="duoface-native12-verify-") as td:
        root=Path(td)
        original=root/"native11"
        cleaned=root/"native12"
        ctl=root/"control"
        subprocess.run(["dpkg-deb","-x",str(BASE),str(original)],check=True)
        subprocess.run(["dpkg-deb","-x",str(args.deb),str(cleaned)],check=True)
        subprocess.run(["dpkg-deb","-e",str(args.deb),str(ctl)],check=True)
        before=file_hashes(original)
        after=file_hashes(cleaned)
        assert set(before)-set(after)==REMOVALS
        assert not(set(after)-set(before))
        assert all(after[k]==before[k] for k in after)
        for file in REMOVALS:assert not(cleaned/file).exists()
        for binary in FILES.values():
            assert binary in before and binary in after
            assert (original/binary).read_bytes()==(cleaned/binary).read_bytes()
        assert not any(
            b"A_DuoFaceNativeNoLease" in p.read_bytes()
            for p in cleaned.rglob("*")
            if p.is_file() and not p.is_symlink()
        ),"Unexpected plugin filename reference"
        checksums={}
        for line in (ctl/"md5sums").read_text().splitlines():
            digest,path=line.split("  ",1)
            assert path not in checksums
            checksums[path]=digest
        assert set(checksums)==set(after)
        for path,digest in checksums.items():
            assert hashlib.md5((cleaned/path).read_bytes()).hexdigest()==digest
    result={
        "status":"NATIVE12_WHOLE_LICENSE_BRIDGE_FILE_REMOVAL_BYTE_EXACT_PASS",
        "native12_deb_sha256":rep["deb_sha256"],
        "baseline_sha256":BASE_SHA,
        "removed_exactly_two_files":sorted(REMOVALS),
        "removed_total_uncompressed_bytes":rep["bytes_removed_uncompressed"],
        "all_remaining_payload_file_bytes_identical":True,
        "all_8_carplay_method_bytes_identical":True,
        "all_312_license_method_stubs_identical":True,
        "all_visual_assets_and_fullscreen_identical":True,
        "all_other_code_and_ObjC_metadata_identical":True,
        "md5sums_verified":True,
        "rootless_package_id_and_architecture_verified":True,
        "remaining_original_license_metadata_erased":False,
        "static_QA_does_not_prove_runtime_safety":True,
        "device_tested":False,
        "sileo_deployed":False,
        "native10_rollback_preserved":True,
    }
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(result,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    print(json.dumps(result,indent=2,ensure_ascii=False))

if __name__=="__main__":
    main()
