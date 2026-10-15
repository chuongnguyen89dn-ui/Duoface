#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build native11 with 52 original license-only literal contents erased.

Real DEB artifact from a byte-pinned, user-tested native10; unlike the
prior in-memory audit this produces an actual new, separately versioned
rootless package and signs the two modified Mach-O binaries.

ONLY 52 exact audited literal byte ranges are erased to NUL in __cstring.
The 312 previously modified Objective-C method bodies, the eight CarPlay
routines, class/selector metadata and every other feature stay untouched.
Erasing strings is not the same as removing all license classes or methods.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

from build_native5 import FILES, cmd, preserve_entitlements_and_resign, sha
from build_native8 import files_and_digests
from remove_native11_license_literals import (
    SRC, EXPECTED, INVENTORY, PROTECTED,
    erase_binary, selected, CANDIDATE_TOTAL,
)

VERSION="0.1.0~native11"
ROOT=Path(__file__).resolve().parents[3]

def make():
    p=argparse.ArgumentParser()
    p.add_argument("--out",required=True,type=Path)
    p.add_argument("--report",required=True,type=Path)
    args=p.parse_args()
    assert sha(SRC.read_bytes())==EXPECTED,"User-tested native10 SHA mismatch"
    assert not args.out.exists(),"Never overwrite existing DEB"
    assert subprocess.check_output(["dpkg-deb","-f",str(SRC),"Package"],text=True).strip()=="com.duoface.independent"
    assert subprocess.check_output(["dpkg-deb","-f",str(SRC),"Version"],text=True).strip()=="0.1.0~native10"
    audit_catalog=json.loads(INVENTORY.read_text(encoding="utf-8"))
    guard=json.loads(PROTECTED.read_text(encoding="utf-8"))
    baseline=json.loads((ROOT/"audit/payload-migration/NATIVE11_LICENSE_LITERAL_REMOVAL_IN_MEMORY_ONLY.json").read_text(encoding="utf-8"))
    assert baseline["count_physically_erased_literal_contents"]==CANDIDATE_TOTAL==52
    assert baseline["total_erased_original_nonzero_bytes"]==1816
    assert baseline["source_native10_sha256"]==EXPECTED
    assert baseline["staged_unsigned_binaries_written"] is False
    saved=[]
    summaries={}
    signed={}
    with tempfile.TemporaryDirectory(prefix="duoface-native11-build-") as work:
        tmp=Path(work)
        stage=tmp/"stage"
        cmd("dpkg-deb","-R",SRC,stage)
        before=files_and_digests(stage)
        for name,relative in FILES.items():
            file=stage/relative
            original=file.read_bytes()
            removed,rows,stats=erase_binary(original,name,audit_catalog,guard)
            assert len(original)==len(removed)
            assert stats["unsigned_erased_sha256"]==baseline["per_binary"][name]["unsigned_erased_sha256"]
            assert stats["erased_string_count"]==baseline["per_binary"][name]["erased_string_count"]
            assert stats["changed_nonzero_bytes"]==baseline["per_binary"][name]["changed_nonzero_bytes"]
            file.write_bytes(removed)
            signed[name]=preserve_entitlements_and_resign(file,original,tmp,name)
            modified=file.read_bytes()
            # Re-signing may alter __LINKEDIT / CodeDirectory but not user data.
            for row in rows:
                begin=row["offset"];end=begin+row["length"]
                assert modified[begin:end]==bytes(row["length"]),(name,begin)
            summaries[name]={
                **stats,
                "signed_binary_sha256":sha(modified),
                "signature_action":signed[name],
                "erased_ranges_in_signed_output_verified":True,
            }
            saved.extend(rows)
        assert len(saved)==CANDIDATE_TOTAL
        control=stage/"DEBIAN/control"
        old=control.read_text(encoding="utf-8")
        assert "Version: 0.1.0~native10" in old
        control.write_text(old.replace("Version: 0.1.0~native10","Version: "+VERSION),encoding="utf-8")
        checks=[]
        for file in sorted(stage.rglob("*")):
            if file.is_file() and not file.is_symlink() and file.relative_to(stage).parts[0]!="DEBIAN":
                checks.append(hashlib.md5(file.read_bytes()).hexdigest()+"  "+file.relative_to(stage).as_posix())
        (stage/"DEBIAN/md5sums").write_text("\n".join(checks)+"\n")
        after=files_and_digests(stage)
        assert before.keys()==after.keys(),"No package entries may be removed/added"
        modified_paths=sorted(k for k in after if after[k]!=before[k])
        assert modified_paths==sorted([*FILES.values(),"DEBIAN/control","DEBIAN/md5sums"])
        for constant in (
            "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib",
            "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceLogoGripOnly.dylib",
            "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.plist",
            "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceLogoGripOnly.plist",
        ):
            assert before[constant]==after[constant],constant
        args.out.parent.mkdir(parents=True,exist_ok=True)
        cmd("dpkg-deb","--build","--root-owner-group",stage,args.out)
    assert subprocess.check_output(["dpkg-deb","-f",str(args.out),"Version"],text=True).strip()==VERSION
    assert subprocess.check_output(["dpkg-deb","-f",str(args.out),"Package"],text=True).strip()=="com.duoface.independent"
    assert subprocess.check_output(["dpkg-deb","-f",str(args.out),"Architecture"],text=True).strip()=="iphoneos-arm64"
    report={
        "status":"NATIVE11_SIGNED_DEB_52_OLD_LICENSE_STRING_CONTENTS_PHYSICALLY_ERASED",
        "source_tested_native10_sha256":EXPECTED,
        "version":VERSION,"package":"com.duoface.independent","architecture":"iphoneos-arm64",
        "byte_erased_count":sum(r["length"] for r in saved),
        "erased_string_count":len(saved),
        "category_counts":{
            "localization_lookup_key_preserve":40,
            "diagnostic_log_preserve":12
        },
        "modified_existing_paths":modified_paths,
        "baseline_package_entry_count":len(before),
        "all_non_target_payload_files_byte_identical":True,
        "all_8_carplay_detection_method_bodies_unchanged":True,
        "all_312_previous_neutralized_method_bodies_unchanged":True,
        "all_visual_logo_split_fullscreen_payload_unchanged":True,
        "objc_class_and_selector_metadata_not_removed":True,
        "all_license_data_and_metadata_fully_removed":False,
        "removed_original_literal_content_not_binary_section_layout":True,
        "signed_modified_macho":True,
        "signed_binaries":summaries,
        "removed_rows":saved,
        "runtime_localization_or_indirect_callers_unverified":True,
        "user_device_test_for_new_package":False,
        "sileo_published":False,
        "tested_native10_rollback_preserved":True,
        "deb_sha256":sha(args.out.read_bytes()),
        "deb_size":args.out.stat().st_size,
    }
    args.report.parent.mkdir(parents=True,exist_ok=True)
    args.report.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    print(json.dumps({k:v for k,v in report.items() if k!="removed_rows"},indent=2,ensure_ascii=False))

if __name__=="__main__":
    make()
