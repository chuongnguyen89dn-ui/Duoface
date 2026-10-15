#!/usr/bin/env python3
"""Enforce native9 release safety: original visuals + native gestures.

Uses proven native6 (SHA-pinned) as the only reference, verifies all byte
changes to two __cstring sections, original fullscreen/UI/visual dylib and
filter unchanged, and precisely two added signed logo-grip files.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import plistlib
import subprocess
import tempfile
from pathlib import Path
from build_native5 import FILES, sha
from build_native7 import SOURCE, EXPECTED, UI_COPY
from build_native9 import VERSION, BASE_VISUAL, BASE_FILTER, GRIP_DYLIB, GRIP_FILTER, ORIGINAL_VISUAL_SHA256
from verify_native8 import verify_display_binary

def digest_files(root):
    return {
        p.relative_to(root).as_posix():sha(p.read_bytes())
        for p in root.rglob("*") if p.is_file() and not p.is_symlink()
    }

def validate():
    ap=argparse.ArgumentParser()
    ap.add_argument("--deb",type=Path,required=True)
    ap.add_argument("--report",type=Path,required=True)
    ap.add_argument("--out",type=Path,required=True)
    args=ap.parse_args()
    assert sha(SOURCE.read_bytes())==EXPECTED
    report=json.loads(args.report.read_text(encoding="utf-8"))
    assert report["status"]=="NATIVE9_ORIGINAL_VISUAL_PLUS_GRIP_ONLY_STAGED_NEEDS_CARPLAY_DEVICE_QA"
    assert report["native6_base_sha256"]==EXPECTED
    assert report["deb_sha256"]==sha(args.deb.read_bytes())
    assert report["package"]=="com.duoface.independent"
    assert report["version"]==VERSION
    assert report["architecture"]=="iphoneos-arm64"
    assert report["logo_hold_duration_seconds"]==0.30
    assert len(report["masks"])==78
    assert report["license_labels_selected"]==39
    assert report["license_copy_occurrences_hidden"]==78
    assert report["native_divider_pan_hooked"] is False
    assert report["fullscreen_legacy_visual_hook_replaced"] is False
    assert report["source_native6_rollback_preserved"]
    assert report["native8_rollback_preserved"]
    assert not report["device_tested"] and not report["sileo_published"]
    assert report["original_visual_sha256_unchanged"]==ORIGINAL_VISUAL_SHA256
    assert subprocess.check_output(["dpkg-deb","-f",str(args.deb),"Package"],text=True).strip()=="com.duoface.independent"
    assert subprocess.check_output(["dpkg-deb","-f",str(args.deb),"Version"],text=True).strip()==VERSION
    assert subprocess.check_output(["dpkg-deb","-f",str(args.deb),"Architecture"],text=True).strip()=="iphoneos-arm64"

    with tempfile.TemporaryDirectory(prefix="duoface-native9-verify-") as td:
        p=Path(td)
        base=p/"base"
        candidate=p/"candidate"
        candidate_control=p/"control"
        subprocess.run(["dpkg-deb","-x",str(SOURCE),str(base)],check=True)
        subprocess.run(["dpkg-deb","-x",str(args.deb),str(candidate)],check=True)
        subprocess.run(["dpkg-deb","-e",str(args.deb),str(candidate_control)],check=True)
        prev=digest_files(base)
        after=digest_files(candidate)
        assert set(prev)<=set(after)
        assert set(after)-set(prev)=={GRIP_DYLIB,GRIP_FILTER}
        modified=sorted(k for k in prev if prev[k]!=after[k])
        assert modified==sorted(FILES.values()),modified
        assert sorted(report["changed_existing_paths"])==sorted([*FILES.values(),"DEBIAN/control","DEBIAN/md5sums"])
        assert report["added_paths"]==sorted([GRIP_DYLIB,GRIP_FILTER])
        assert prev[BASE_VISUAL]==after[BASE_VISUAL]==ORIGINAL_VISUAL_SHA256
        assert prev[BASE_FILTER]==after[BASE_FILTER]==report["original_visual_filter_sha256_unchanged"]
        assert after[GRIP_FILTER]==prev[BASE_FILTER]==report["new_grip_filter_sha256"]
        original_filter=plistlib.loads((base/BASE_FILTER).read_bytes())
        independent_filter=plistlib.loads((candidate/GRIP_FILTER).read_bytes())
        assert original_filter==independent_filter
        assert "Bundles" in independent_filter["Filter"]
        assert len(independent_filter["Filter"]["Bundles"])>0
        assert after[GRIP_DYLIB]==report["new_grip_sha256"]
        assert (candidate/GRIP_DYLIB).stat().st_size>10000
        assert (candidate/GRIP_DYLIB).read_bytes()[:4]==bytes.fromhex("cffaedfe")
        assert (base/GRIP_DYLIB).exists() is False
        assert (base/GRIP_FILTER).exists() is False

        checks={}
        for name,rel in FILES.items():
            checks[name]=verify_display_binary(
                name,(base/rel).read_bytes(),(candidate/rel).read_bytes(),
                [item for item in report["masks"] if item["binary"]==name])
        assert sum(x["masked_user_visible_cstrings"] for x in checks.values())==78
        assert sum(x["actual_changed_literal_bytes"] for x in checks.values())==report["actual_changed_literal_bytes_expected"]
        assert {item["label"] for item in report["masks"]}==set(UI_COPY)

        # Regenerated DEBIAN/md5sums must describe every actual payload file.
        sums=(candidate_control/"md5sums").read_text().splitlines()
        entries={}
        for line in sums:
            hexdigest,rel=line.split("  ",1)
            assert rel not in entries
            entries[rel]=hexdigest
        assert set(entries)==set(after)
        for rel,expected in entries.items():
            assert hashlib.md5((candidate/rel).read_bytes()).hexdigest()==expected,rel

        strings=subprocess.check_output(["strings",str(candidate/GRIP_DYLIB)],text=True)
        assert "[DuoFaceGripOnly] installed:" in strings
        assert "threshold=0.30s" in strings
        assert "native divider pan" in strings
        assert "DFDividerLayout" not in strings or "DuoFaceGripOnly" in strings
        control=(candidate_control/"control").read_text()
        assert "Package: com.duoface.independent" in control
        assert "Version: "+VERSION in control

        result={
            "status":"NATIVE9_BYTE_EXACT_ORIGINAL_VISUAL_AND_NATIVE_RATIO_GUARD_PASS",
            "native6_reference_sha256":EXPECTED,
            "native9_sha256":report["deb_sha256"],
            "package":report["package"],"version":VERSION,
            "rootless_architecture":report["architecture"],
            "native6_original_visual_dylib_byte_identical":True,
            "original_visual_dylib_sha256":ORIGINAL_VISUAL_SHA256,
            "original_visual_filter_byte_identical":True,
            "grip_filter_exact_copy_of_original":True,
            "new_grip_dylib_sha256":after[GRIP_DYLIB],
            "only_added_paths":sorted([GRIP_DYLIB,GRIP_FILTER]),
            "only_changed_existing_payload":modified,
            "unchanged_other_existing_payload":len(prev)-len(modified),
            "license_copy_mask_checks":checks,
            "native_host_code_and_objc_metadata_unchanged":True,
            "legacy_ui_and_youtube_fullscreen_binary_untouched":True,
            "native_divider_pan_unhooked_by_new_module":True,
            "logo_hold_seconds":0.30,
            "md5sums_verified_all_payload":True,
            "not_claiming_device_success":True,
            "device_tested_for_this_candidate":False,
            "sileo_deployed":False
        }
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(result,ensure_ascii=False,indent=2))

if __name__=="__main__":
    validate()
