#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Physically ERASE selected obsolete license-only string CONTENT from Mach-O.

Native10 has user-confirmed CarPlay device QA PASS. Its 312 neutralized methods
no longer require the old presentation text. This script replaces chosen
literal bytes with zeros; it does not pretend to remove Objective-C metadata,
shrink Mach-O, or prove all dynamic callsites are dead.

Two supported uses:
  --audit-out JSON             verify exact 52 candidates in memory, no DEB
  --audit-out JSON --stage DIR  additionally write two *unsigned* replacement
                                Mach-O files for later code signing/packaging

The 52 candidates: 40 license-only localization keys, 12 license-only debug
messages. Retain 2 CFString "Activate" labels whose callers remain uncertain;
retain all runtime/state keys, CarPlay logs, ObjC class/selector names, and all
88 opaque strings. User must test any future DEB separately.

Do not change the published native10 package. No license server responses
are altered or spoofed by this source utility.
"""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

from build_native5 import FILES, sections, sha

ROOT = Path(__file__).resolve().parents[3]
SRC = ROOT/"dist/payload-migration/native10/com.duoface.independent_0.1.0~native10_iphoneos-arm64.deb"
EXPECTED = "3d39b181d0089ae9a7797eb1ca05790155d1b242e50ca2cff362e0a818ff8d29"
INVENTORY = ROOT/"audit/payload-migration/NATIVE9_LICENSE_KEEP_VS_HIDE_READONLY.json"
PROTECTED = ROOT/"audit/payload-migration/NATIVE9_19_LIFECYCLE_HIDE_PLAN_READONLY.json"
CANDIDATE_TOTAL = 52

# Only logs dedicated to obsolete license sync/expiry/deactivation. Exclude
# generic "activated", CarPlay disconnect, system and status-bar diagnostics.
LOG_MARKERS = (
    "[DuoFaceLicense] ",
    "[DuoFaceSB] [LICENSE_KILL_TRACE] ",
    "Failed writing tmp license file",
)


def selected(record: dict) -> bool:
    group = record["group"]
    literal = record["literal"]
    if group == "localization_lookup_key_preserve":
        assert isinstance(literal, str)
        assert literal.startswith(("PLAN_", "SUB_", "MODAL_", "KEY_LICENSE_",
                                   "SECTION_SUBSCRIPTION", "ROW_SUBSCRIPTION_TITLE"))
        return True
    if group == "diagnostic_log_preserve":
        return isinstance(literal,str) and literal.startswith(LOG_MARKERS)
    return False


def erase_binary(original:bytes, binary:str, inventory:dict, protected:dict):
    assert original[:4] == bytes.fromhex("cffaedfe")
    allowed_sections = [
        (o,o+n) for seg,sect,o,n in sections(original)
        if sect=="__cstring" and seg in ("__TEXT","__TEXT_EXEC")
    ]
    assert len(allowed_sections)>=1
    candidates=[r for r in inventory["string_rows"]
                if r["binary"]==binary and selected(r)]
    expected_by_binary = {"DuoFaceUI": 23, "DuoFaceDashboard": 29}
    assert len(candidates)==expected_by_binary[binary],(binary,len(candidates))
    assert len({r["file_offset"] for r in candidates})==len(candidates)
    mutable=bytearray(original)
    intervals=[]
    audit=[]
    for rec in sorted(candidates,key=lambda x:x["file_offset"]):
        at=rec["file_offset"]
        n=rec["byte_count"]
        end=at+n
        data=original[at:end]
        literal=rec["literal"].encode("utf-8")
        assert data==literal,("string moved or changed",binary,rec["literal"],at)
        assert sha(data)==rec["original_sha256"]
        assert original[end]==0,("not null-terminated",binary,at)
        assert any(a<=at<end<=z for a,z in allowed_sections)
        assert all(end<=a or at>=z for a,z in intervals)
        intervals.append((at,end))
        mutable[at:end]=bytes(n)  # physical removal of the original text
        assert mutable[at:end]==bytes(n)
        audit.append({
            "binary":binary,
            "group":rec["group"],
            "offset":at,
            "length":n,
            "old_sha256":sha(data),
            "new_sha256":sha(bytes(n)),
            "label":rec["literal"],
            "original_string_content_physically_present_after":False,
            "objc_metadata_or_binary_layout_removed":False,
        })
    assert len(audit)==expected_by_binary[binary]
    candidate=bytes(mutable)
    assert len(candidate)==len(original)
    changes={i for i,(x,y) in enumerate(zip(original,candidate)) if x!=y}
    permitted=set()
    for a,z in intervals:permitted.update(range(a,z))
    assert changes and changes<=permitted
    # **Not just no overlap**: all machine code, ObjC metadata and all
    # non-string file bytes must be unchanged byte-for-byte before signing.
    for seg,sect,at,n in sections(original):
        if sect=="__cstring":continue
        assert original[at:at+n]==candidate[at:at+n],(seg,sect)
    all_cp=[v for v in protected["by_binary"][binary]["carplay_byte_exact_keep"]]
    assert len(all_cp)==4
    for obj in all_cp:
        at=obj["file_offset"];n=obj["length"]
        assert sha(original[at:at+n])==obj["sha256_in_native9"]
        assert original[at:at+n]==candidate[at:at+n]
    # Verify **every byte** modified is exactly one of 26 selected strings.
    assert sum(rec["length"] for rec in audit)==len(permitted)
    assert sum(rec["length"] for rec in audit)==len(changes)
    return candidate,audit,{
        "before_sha256":sha(original),
        "unsigned_erased_sha256":sha(candidate),
        "changed_nonzero_bytes":len(changes),
        "erased_string_count":len(audit),
        "carplay_method_count_byte_identical":len(all_cp),
        "all_machine_code_and_objc_metadata_byte_identical":True,
        "mach_o_size_preserved":True,
    }


def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--audit-out",required=True,type=Path)
    ap.add_argument("--stage",type=Path,default=None)
    args=ap.parse_args()
    assert sha(SRC.read_bytes())==EXPECTED
    inventory=json.loads(INVENTORY.read_text(encoding="utf-8"))
    guard=json.loads(PROTECTED.read_text(encoding="utf-8"))
    assert inventory["native9_deb_sha256"] == guard["source_deb_sha256"]
    assert inventory["string_count"]==256
    assert inventory["string_counts"]["localization_lookup_key_preserve"]==40
    assert inventory["string_counts"]["diagnostic_log_preserve"]==18
    assert guard["eight_carplay_permanently_retained"]==8
    records=[]
    per_binary={}
    with tempfile.TemporaryDirectory(prefix="duoface-native11-erase-audit-") as tmp:
        root=Path(tmp)
        subprocess.run(["dpkg-deb","-x",str(SRC),str(root)],check=True)
        for name,relative in FILES.items():
            content=(root/relative).read_bytes()
            scrubbed,audit,summary=erase_binary(content,name,inventory,guard)
            records.extend(audit)
            per_binary[name]=summary
            if args.stage is not None:
                args.stage.mkdir(parents=True,exist_ok=True)
                (args.stage/name).write_bytes(scrubbed)
                assert sha((args.stage/name).read_bytes())==summary["unsigned_erased_sha256"]
    assert len(records)==CANDIDATE_TOTAL
    categories=Counter(x["group"] for x in records)
    assert categories=={
        "localization_lookup_key_preserve":40,
        "diagnostic_log_preserve":12
    },categories
    assert all("Activate"!=rec["label"] for rec in records)
    expected_count=inventory["string_count"]-inventory["string_counts"]["39_ui_literals_already_masked_in_native9"]
    assert expected_count==178
    report={
        "status":"NATIVE11_EXACT_52_LICENSE_STRINGS_ERASED_IN_UNSIGNED_MEMORY_ONLY",
        "source_native10_sha256":EXPECTED,
        "native10_device_pass_confirmed_by_user":True,
        "count_physically_erased_literal_contents":len(records),
        "category_counts":dict(categories),
        "total_erased_original_nonzero_bytes":sum(r["length"] for r in records),
        "total_unmasked_residual_catalog_entries_before":178,
        "remaining_catalog_entries_not_erased_by_this_step":178-len(records),
        "the_8_carplay_detection_method_bodies_unchanged":True,
        "all_original_312_method_code_bodies_unchanged":True,
        "original_visual_drag_fullscreen_files_unchanged":True,
        "objc_class_method_metadata_remains":True,
        "objc_metadata_physically_removed":False,
        "binary_file_size_reduced":False,
        "full_license_subsystem_removed":False,
        "two_Activate_cfstring_literals_retained_pending_caller_proof":True,
        "unresolved_runtime_state_keys_and_opaque_data_retained":True,
        "may_break_runtime_localization_lookup":True,
        "requires_device_test_before_release":True,
        "signed":False,"deb_built":False,"sileo_changed":False,
        "staged_unsigned_binaries_written":args.stage is not None,
        "per_binary":per_binary,
        "erased_literal_records":records,
        "sha256_sources":{
            "inventory":sha(INVENTORY.read_bytes()),
            "protected":sha(PROTECTED.read_bytes())
        },
    }
    args.audit_out.parent.mkdir(parents=True,exist_ok=True)
    args.audit_out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({k:v for k,v in report.items() if k not in
        ("erased_literal_records","sha256_sources")},ensure_ascii=False,indent=2))


if __name__=="__main__":
    main()
