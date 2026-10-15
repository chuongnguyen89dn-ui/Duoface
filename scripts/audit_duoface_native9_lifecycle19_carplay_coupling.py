#!/usr/bin/env python3
"""Exact 19 lifecycle-class coupling to 8 CarPlay selectors (READ ONLY).

This follows the user's instruction to TARGET all 19 license-related
lifecycle methods for further hiding, with ONLY 8 CarPlay method exceptions.
The existing archive is user-tested-good: DO NOT null init, sharedInstance,
dealloc or .cxx_destruct without proving callers and cleanup semantics.
The report isolates 13 UI-only teardown methods and 6 shared-manager methods
and records each affected class's license code already neutralized from
native4. None of these operations writes a Mach-O or builds a DEB.
"""
from __future__ import annotations
import argparse
from collections import Counter, defaultdict
from hashlib import sha256
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
LIFECYCLE=ROOT/"audit/payload-migration/NATIVE9_19_LIFECYCLE_HIDE_PLAN_READONLY.json"
LEDGER=ROOT/"dist/payload-migration/native5/DANH_SACH_CHO_XOA.json"
STAGED=ROOT/"audit/payload-migration/NATIVE9_LICENSE_KEEP_VS_HIDE_READONLY.json"
DEB_SHA="e4e1122a494d32af6ec42c97c4288f6effb6716fbb81cb52b81b746280d4d97e"

def main(out:Path):
    whole=json.loads(LIFECYCLE.read_text(encoding="utf-8"))
    ledger=json.loads(LEDGER.read_text(encoding="utf-8"))["all_method_inventory"]
    previous=json.loads(STAGED.read_text(encoding="utf-8"))
    assert whole["source_deb_sha256"]==previous["native9_deb_sha256"]==DEB_SHA
    assert whole["eight_carplay_permanently_retained"]==8
    assert whole["nineteen_lifecycle_now_targeted_for_further_hide"]==19
    assert whole["structural_disjoint_from_8_carplay"]
    assert whole["code_patched"] is False and whole["deb_built"] is False
    targets=[m for x in whole["by_binary"].values() for m in x["lifecycle_targets"]]
    guards=[m for x in whole["by_binary"].values() for m in x["carplay_byte_exact_keep"]]
    assert len(targets)==19 and len(guards)==8
    assert Counter(m["selector"] for m in targets)=={
        ".cxx_destruct":13,"dealloc":2,"init":2,"sharedInstance":2
    }
    assert all(m["head32_matches_native3"] and
               m["native9_function_span_matches_native3"] for m in targets)

    by_class=defaultdict(list)
    for item in ledger:
        by_class[(item["binary"],item["class"])].append(item)
    target_rows=[]
    manager_count=0
    for m in targets:
        cls=(m["binary"],m["class"])
        related=by_class[cls]
        neutralized=[x for x in related
                     if x["state"]=="retained_compatibility_or_unverified"]
        modal_inert=[x for x in related
                     if x["state"]=="temporarily_disabled_native5"]
        cp=[x for x in related
            if x["state"]=="retain_carplay_screen_detection"]
        ivars=m["ivars"].get("known_ivar_count")
        assert m["ivars"]["ivar_metadata_available"] and ivars is not None
        assert ivars>=0
        owner=m["class"]=="CBLicenseSyncManager"
        if owner:
            manager_count+=1
            assert len(cp)==4,cls
            assert m["selector"] in ("init","sharedInstance",".cxx_destruct")
            mode="SHARED_CARPLAY_INFRASTRUCTURE_REQUIRES_REPLACEMENT_BEFORE_HIDE"
            suggestion=("First migrate CarPlay screen detection and all singleton"
                        " callsites to a proven independent implementation;"
                        " maintain constructor and cleanup invariants.")
        else:
            assert not cp,cls
            assert m["selector"] in ("dealloc",".cxx_destruct")
            assert len(neutralized)>0,cls
            mode="UI_ONLY_CLEANUP_DOES_NOT_DISPLAY_LICENSE_KEEP_UNTIL_LIVENESS_PROOF"
            suggestion=("Entry-point methods in this license/subscription"
                        " owner are already neutralized. Keep ARC deallocation"
                        " and strong ivar destruction while proving that no"
                        " objects are constructed before any code-body deletion.")
        target_rows.append({
            "binary":m["binary"],"class":m["class"],"kind":m["kind"],
            "selector":m["selector"],"abi":m["abi"],
            "native9_imp_vm":m["imp_vm"],
            "native9_file_offset":m["file_offset"],
            "native9_function_bytes":m["length"],
            "native9_body_sha256":m["sha256_in_native9"],
            "class_ivar_count":ivars,
            "same_class_body_neutralized_since_native4":len(neutralized),
            "same_class_modal_accessor_neutralized_since_native5":len(modal_inert),
            "same_class_carplay_methods_protected":len(cp),
            "hide_plan":mode,
            "proof_required":suggestion,
            "safe_to_patch_ret_or_nil_without_device_validation":False,
            "method_body_currently_modified":False
        })
    assert manager_count==6
    assert len([x for x in target_rows if x["same_class_carplay_methods_protected"]])==6
    assert len([x for x in target_rows if not x["same_class_carplay_methods_protected"]])==13
    assert len(guards)==8
    assert all(m["approved_state"]=="KEEP_EXACT_NATIVE9_BINARY_BYTE_IDENTICAL" for m in guards)
    assert all(m["selector"].startswith("isCarPlayScreen") for m in guards)
    report={
        "status":"NATIVE9_LIFECYCLE19_CARPLAY_CLASS_COUPLING_STATIC_PASS_NO_BINARY_EDITS",
        "native9_qa_reference_sha256":DEB_SHA,
        "workflow_scope":"READ_ONLY_DEPENDENCY_CLASSIFICATION",
        "user_request":"Retain 8 CarPlay detection methods only as permanent exception, target 19 lifecycle methods for hiding.",
        "all_19_targeted":True,
        "lifecycle_count":19,
        "carplay_detection_immutability_guard_count":8,
        "shared_manager_lifecycle_methods_with_8_carplay_routines":6,
        "license_ui_only_teardown_methods":13,
        "native4_inert_license_business_body_count":291,
        "native5_inert_expired_accessors":2,
        "all_19_have_exact_fingerprinted_IMP_and_safe_function_boundaries":True,
        "all_19_have_final_proof_of_no_runtime_callers":False,
        "all_19_can_safely_be_removed_now":False,
        "zeroing_dealloc_or_objc_strong_cleanup_is_approved":False,
        "zeroing_init_or_singleton_method_is_approved":False,
        "carplay_and_visual_paths_modified":False,
        "new_binary_created":False,"deb_built":False,"sileo_modified":False,
        "target_rows":target_rows,
        "immutable_carplay_methods":guards,
        "next_action":"Trace the 6 shared-manager lifecycle callsites to all 8 CarPlay detection getters; keep 13 UI-only ARC cleanup routines while proving no instances remain, then stage a reversible ABI-safe source-only change instead of rewriting native9.",
        "source_sha256":{
            str(LIFECYCLE.relative_to(ROOT)):sha256(LIFECYCLE.read_bytes()).hexdigest(),
            str(LEDGER.relative_to(ROOT)):sha256(LEDGER.read_bytes()).hexdigest(),
            str(STAGED.relative_to(ROOT)):sha256(STAGED.read_bytes()).hexdigest(),
        },
    }
    out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    print(json.dumps({k:v for k,v in report.items() if k not in
        ("target_rows","immutable_carplay_methods","source_sha256")},
        indent=2,ensure_ascii=False))

if __name__=="__main__":
    p=argparse.ArgumentParser()
    p.add_argument("--out",required=True,type=Path)
    args=p.parse_args()
    main(args.out)
