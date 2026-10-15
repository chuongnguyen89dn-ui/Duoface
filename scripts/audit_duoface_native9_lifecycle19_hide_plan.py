#!/usr/bin/env python3
"""DuoFace native9 user-directed 19 lifecycle hide plan, source-only audit.

User request: keep ONLY eight CarPlay detection methods as permanent exceptions
to the LICENSE-RELATED METHOD ledger; continue HIDE of 19 lifecycle methods.
This script records exact native9 IMP/method-span/ABI and proves whether the
19 proposed code-body edits are *structurally isolated*. It does NOT claim
that no-op init/dealloc/sharedInstance are behaviorally safe. In particular,
ARC ivar destruction and shared singleton construction may be needed even
though the license user interface is already hidden.

No DEB, binary edit, runtime hook, Sileo publish, or device behavior change.
"""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from audit_duoface_native9_activate_callsite_owners import MachObjC  # noqa: E402

DEB = ROOT / "dist/payload-migration/native9/com.duoface.independent_0.1.0~native9_iphoneos-arm64.deb"
SHA = "e4e1122a494d32af6ec42c97c4288f6effb6716fbb81cb52b81b746280d4d97e"
LEDGER = ROOT / "dist/payload-migration/native5/DANH_SACH_CHO_XOA.json"
NATIVE3 = ROOT / "audit/payload-migration/NATIVE3_RUNTIME_METHODS.json"
NATIVE4 = ROOT / "dist/payload-migration/native4/BAO_CAO.json"
BINARIES = {
    "DuoFaceUI": "var/jb/Applications/DuoFaceUI.app/DuoFaceUI",
    "DuoFaceDashboard": "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib",
}
KEEP_CARPLAY = frozenset({
    "isCarPlayScreenConnected", "isCarPlayScreen:",
    "isCarPlayScreenConnectedExcludingScreen:",
})
SELECTORS = {"init", "sharedInstance", "dealloc", ".cxx_destruct"}


def digest(buf: bytes) -> str:
    return hashlib.sha256(buf).hexdigest()


def key(item: dict) -> tuple[str,str,str,str]:
    return (item["class"], item["kind"], item["selector"],
            item.get("method_type", item.get("signature")))


def ivars_for_class(macho: MachObjC, cls_name: str) -> dict:
    sec = next(s for s in macho.sections if s[1] == "__objc_classlist")
    _,_,vm,nbytes,_=sec
    for p in range(vm,vm+nbytes,8):
        try:
            cls=macho.val("<Q",p)
            if not cls:continue
            ro=macho.val("<Q",cls+32)&~7
            name=macho.name(macho.val("<Q",ro+24))
            if name!=cls_name:continue
            ivars=macho.val("<Q",ro+48)
            if not ivars:
                return {"known_ivar_count":0,"ivar_metadata_available":True}
            stride=macho.val("<I",ivars)
            count=macho.val("<I",ivars+4)
            if stride < 32 or count>500:
                return {"known_ivar_count":None,"ivar_metadata_available":False}
            return {"known_ivar_count":count,"ivar_metadata_available":True}
        except (ValueError,struct.error):
            continue
    return {"known_ivar_count":None,"ivar_metadata_available":False}


def main(out: Path) -> None:
    assert digest(DEB.read_bytes())==SHA, "Unexpected native9, NEVER audit unknown binary"
    ledger=json.loads(LEDGER.read_text(encoding="utf-8"))["all_method_inventory"]
    old=json.loads(NATIVE3.read_text(encoding="utf-8"))
    patched=json.loads(NATIVE4.read_text(encoding="utf-8"))
    lifecycle=[x for x in ledger if x["state"]=="retain_runtime_lifecycle"]
    carplay=[x for x in ledger if x["state"]=="retain_carplay_screen_detection"]
    neutralized=[x for x in ledger if x["state"]=="retained_compatibility_or_unverified"]
    modal=[x for x in ledger if x["state"]=="temporarily_disabled_native5"]
    assert len(ledger)==320
    assert len(lifecycle)==19 and len(carplay)==8
    assert len(neutralized)==291 and len(modal)==2
    assert all(x["selector"] in SELECTORS for x in lifecycle)
    assert all(x["selector"] in KEEP_CARPLAY for x in carplay)
    assert not (set(map(key,lifecycle))&set(map(key,carplay)))
    labels=Counter(x["selector"] for x in lifecycle)
    assert sum(labels.values())==19

    groups={}
    all_candidates=[]
    preserve=[]
    with tempfile.TemporaryDirectory(prefix="duoface-native9-lifecycle19-readonly-") as td:
        root=Path(td)
        subprocess.run(["dpkg-deb","-x",str(DEB),str(root)],check=True)
        for binary,rel in BINARIES.items():
            blob=(root/rel).read_bytes()
            macho=MachObjC(blob)
            methods,warnings=macho.all_objc_methods()
            by_identity={}
            for x in methods:
                by_identity.setdefault(key(x),[]).append(x)
            starts=macho.function_starts
            candidate_entries=[]
            preserved_entries=[]
            candidate_spans=[]
            preserved_spans=[]

            for x in [z for z in lifecycle if z["binary"]==binary]:
                matches=by_identity.get(key(x),[])
                assert len(matches)==1,(binary,key(x),len(matches))
                m=matches[0]
                imp=m["imp_vm"]
                assert imp in starts,(binary,x["class"],x["selector"],hex(imp))
                idx=starts.index(imp)
                assert idx+1<len(starts)
                end=starts[idx+1]
                assert end>imp
                startoff=macho.vm_off(imp)
                endoff=macho.vm_off(end-4)+4
                span=blob[startoff:endoff]
                assert len(span)>0 and len(span)%4==0
                old_meta=[
                    row for row in old["binaries"][binary]["slices"]["arm64:0"]["license_named_methods"]
                    if row["class"]==x["class"] and row["kind"]==x["kind"] and
                    row["selector"]==x["selector"] and row["type_encoding"]==x["method_type"]
                ]
                assert len(old_meta)==1,(binary,x)
                old_row=old_meta[0]
                baseline_head_matches=(digest(blob[startoff:startoff+32])==
                                      old_row["first_32_instruction_bytes_sha256"])
                # No-object stubbing is not yet approved because return/ivar
                # semantics cannot be established by static tests alone.
                risk=({
                    "init":"HIGH: must initialize superclass and return valid self",
                    "sharedInstance":"CRITICAL: singleton may be required by CarPlay screen detection",
                    "dealloc":"HIGH: release resources and preserve ObjC runtime invariants",
                    ".cxx_destruct":"HIGH: ARC strong-ivar cleanup and object teardown",
                })[x["selector"]]
                obj={
                    "binary":binary,"class":x["class"],"kind":x["kind"],
                    "selector":x["selector"],"abi":x["method_type"],
                    "imp_vm":hex(imp),
                    "file_offset":startoff,
                    "length":len(span),
                    "sha256_in_native9":digest(span),
                    "head32_matches_native3":baseline_head_matches,
                    "native3_original_method_span":old_row["estimated_function_span"],
                    "native9_function_span_matches_native3":
                        len(span)==old_row["estimated_function_span"],
                    "ivars":ivars_for_class(macho,x["class"]),
                    "lifecycle_body_referenced_or_allocated_proven_unreachable":False,
                    "proposed_state":"TARGET_HIDE_REQUIRES_ALLOCATOR_AND_CALLER_PROOF",
                    "naive_ret_or_nil_patch_allowed":False,
                    "runtime_risk":risk,
                    "not_ignored":True,
                }
                candidate_spans.append((startoff,endoff))
                candidate_entries.append(obj)
                all_candidates.append(obj)

            for x in [z for z in carplay if z["binary"]==binary]:
                matches=by_identity.get(key(x),[])
                assert len(matches)==1,(binary,key(x),len(matches))
                m=matches[0]
                imp=m["imp_vm"]
                assert imp in starts
                idx=starts.index(imp)
                assert idx+1<len(starts)
                startoff=macho.vm_off(imp)
                endoff=macho.vm_off(starts[idx+1]-4)+4
                segment=blob[startoff:endoff]
                preserved_spans.append((startoff,endoff))
                preserved_entries.append({
                    "binary":binary,"class":x["class"],"kind":x["kind"],
                    "selector":x["selector"],"abi":x["method_type"],
                    "imp_vm":hex(imp),"file_offset":startoff,
                    "length":len(segment),"sha256_in_native9":digest(segment),
                    "approved_state":"KEEP_EXACT_NATIVE9_BINARY_BYTE_IDENTICAL",
                })
                preserve.append(preserved_entries[-1])

            ranges=sorted(candidate_spans)
            assert all(a[1]<=b[0] for a,b in zip(ranges,ranges[1:])),binary
            assert not any(a[0]<b[1] and b[0]<a[1]
                           for a in candidate_spans for b in preserved_spans)
            # No native9 byte is changed or emitted by this report.
            groups[binary]={
                "native9_binary_sha256":digest(blob),
                "objc_method_count":len(methods),
                "function_start_count":len(starts),
                "objc_parser_warnings":warnings,
                "lifecycle_hide_target_count":len(candidate_entries),
                "carplay_exact_keep_count":len(preserved_entries),
                "lifecycle_targets":candidate_entries,
                "carplay_byte_exact_keep":preserved_entries,
                "no_candidate_carplay_span_overlap":True,
            }
    assert len(all_candidates)==19 and len(preserve)==8
    assert all(x["head32_matches_native3"] for x in all_candidates), "Native9 lifecycle body unexpectedly modified"
    assert all(x["native9_function_span_matches_native3"] for x in all_candidates), "Native9 lifecycle span mismatch"
    assert all(x["proposed_state"]=="TARGET_HIDE_REQUIRES_ALLOCATOR_AND_CALLER_PROOF"
               for x in all_candidates)
    report={
        "status":"NATIVE9_19_LIFECYCLE_HIDE_REQUEST_REGISTERED_8_CARPLAY_ONLY_PERMANENT_EXCEPTION",
        "scope":"STRUCTURAL_READONLY_19_METHOD_HIDE_CANDIDATE_AUDIT",
        "source_deb_sha256":SHA,
        "source_version":"0.1.0~native9",
        "user_instruction":"Only 8 CarPlay detection methods permanently kept; continue to hide 19 license/subscription lifecycle methods.",
        "license_ledger_count":len(ledger),
        "already_neutralized_native4":len(neutralized),
        "already_neutralized_native5":len(modal),
        "eight_carplay_permanently_retained":len(preserve),
        "nineteen_lifecycle_now_targeted_for_further_hide":len(all_candidates),
        "nineteen_lifecycle_selector_counts":dict(labels),
        "structural_disjoint_from_8_carplay":True,
        "nineteen_lifecycle_safe_to_noop_without_runtime_proof":False,
        "permission_to_physically_remove_objc_abi_metadata":False,
        "user_tested_good_baseline_untouched":True,
        "code_patched":False,
        "deb_built":False,
        "sileo_changed":False,
        "by_binary":groups,
        "next_steps":[
            "Trace allocations and callers of all 19 lifecycle methods; specifically prove sharedInstance/init required by retained CarPlay detection are not broken",
            "Only after caller and class ownership proof, stage precise reversible ABI-safe changes on an isolated candidate while preserving 8 CarPlay methods and all unrelated UI/split code",
            "Run static binary QA; ask for DEB publication only when authorized and ready for genuine CarPlay testing",
        ],
    }
    out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    print(json.dumps({
        "status":report["status"],
        "target_count":len(all_candidates),
        "carplay_keep_count":len(preserve),
        "selector_types":dict(labels),
        "risk_and_caller_proof_needed":True,
        "deb_built":False,
        "sileo_changed":False
    },indent=2,ensure_ascii=False))


if __name__=="__main__":
    ap=argparse.ArgumentParser()
    ap.add_argument("--out",required=True,type=Path)
    args=ap.parse_args()
    main(args.out)
