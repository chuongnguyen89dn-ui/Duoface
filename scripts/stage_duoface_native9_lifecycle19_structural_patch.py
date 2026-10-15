#!/usr/bin/env python3
"""PREVIEW ONLY: 19 requested lifecycle stubs, 8 original CarPlay methods pinned.

Produces a lossless source-patch manifest for exactly the 19 preverified
function bodies in the user-tested native9. Applies modifications ONLY to
temporary in-memory bytearrays and discards the results; no executable,
DEB, signing, installer or Sileo changes. The original byte SHA, desired
ABI-shaped stub bytes and proposed SHA are saved for reproducibility.

DANGER: a valid Objective-C ABI return is NOT safe behavior. init must
initialize the superclass; sharedInstance must construct a valid singleton
for CarPlay screen detection; dealloc/.cxx_destruct must dispose owned ivars.
All 19 entries are therefore BLOCKED_FROM_RELEASE until graph/runtime proof.
Never pass this manifest to the published build workflow without an explicit
independent safety gate and CarPlay device testing.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[1]
AUDIT=ROOT/"audit/payload-migration/NATIVE9_19_LIFECYCLE_HIDE_PLAN_READONLY.json"
DEB=ROOT/"dist/payload-migration/native9/com.duoface.independent_0.1.0~native9_iphoneos-arm64.deb"
EXPECTED="e4e1122a494d32af6ec42c97c4288f6effb6716fbb81cb52b81b746280d4d97e"
FILES={
    "DuoFaceUI":"var/jb/Applications/DuoFaceUI.app/DuoFaceUI",
    "DuoFaceDashboard":"var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib",
}
ARM64_RET=bytes.fromhex("c0035fd6")
ARM64_NOP=bytes.fromhex("1f2003d5")
ARM64_MOV_X0_ZERO=bytes.fromhex("000080d2")

def sha(b:bytes)->str:
    return hashlib.sha256(b).hexdigest()

def stub(item:dict)->tuple[bytes,str]:
    selector=item["selector"]
    abi=item["abi"]
    if selector in ("dealloc",".cxx_destruct"):
        assert abi=="v16@0:8"
        return ARM64_RET,"VOID_RET_NO_IVAR_CLEANUP_BREAKS_LIFECYCLE"
    if selector=="init":
        assert abi=="@16@0:8"
        return ARM64_RET,"RET_SELF_WITHOUT_SUPER_INIT_BREAKS_LIFECYCLE"
    if selector=="sharedInstance":
        assert abi=="@16@0:8"
        return ARM64_MOV_X0_ZERO+ARM64_RET,"RET_NIL_SINGLETON_BREAKS_CARPLAY_POTENTIALLY"
    raise ValueError(selector)

def main(out:Path):
    assert DEB.is_file() and sha(DEB.read_bytes())==EXPECTED
    report=json.loads(AUDIT.read_text(encoding="utf-8"))
    assert report["source_deb_sha256"]==EXPECTED
    assert report["nineteen_lifecycle_now_targeted_for_further_hide"]==19
    assert report["eight_carplay_permanently_retained"]==8
    assert report["structural_disjoint_from_8_carplay"]
    all_patches=[]
    total_mutations=0
    protected=[]
    with tempfile.TemporaryDirectory(prefix="duoface-native9-19-stub-preflight-") as td:
        root=Path(td)
        subprocess.run(["dpkg-deb","-x",str(DEB),str(root)],check=True)
        for binary,relative in FILES.items():
            original=(root/relative).read_bytes()
            audit=report["by_binary"][binary]
            assert sha(original)==audit["native9_binary_sha256"]
            staged=bytearray(original)
            touched=set()
            for item in audit["lifecycle_targets"]:
                at=item["file_offset"]
                count=item["length"]
                assert count%4==0 and count>0
                old=original[at:at+count]
                assert sha(old)==item["sha256_in_native9"]
                prefix,risk=stub(item)
                assert len(prefix)<=count
                proposed=prefix+ARM64_NOP*((count-len(prefix))//4)
                assert len(proposed)==count and old!=proposed
                staged[at:at+count]=proposed
                touched.update(range(at,at+count))
                changed=sum(x!=y for x,y in zip(old,proposed))
                total_mutations+=changed
                all_patches.append({
                    "binary":binary,"class":item["class"],
                    "kind":item["kind"],"selector":item["selector"],
                    "method_abi":item["abi"],
                    "offset":at,"span_length":count,
                    "original_span_sha256":sha(old),
                    "preview_stub_prefix_hex":prefix.hex(),
                    "preview_tail_arm64_nop_repeat":(count-len(prefix))//4,
                    "preview_span_sha256":sha(proposed),
                    "candidate_structurally_disjoint_from_carplay":True,
                    "ABI_return_shape_matches_signature":True,
                    "runtime_behavior_preserved":False,
                    "release_blocker":risk,
                    "allowed_for_deployment":False,
                })
            for item in audit["carplay_byte_exact_keep"]:
                at=item["file_offset"]
                size=item["length"]
                assert not any(i in touched for i in range(at,at+size))
                assert sha(bytes(staged[at:at+size]))==item["sha256_in_native9"]
                protected.append({
                    "binary":binary,"class":item["class"],
                    "selector":item["selector"],"offset":at,
                    "sha256_original_still_exact":item["sha256_in_native9"],
                })
            after=bytes(staged)
            assert len(after)==len(original)
            actual={i for i,(v,w) in enumerate(zip(original,after)) if v!=w}
            assert actual and actual<=touched
            assert all(original[i]==after[i] for i in range(len(original)) if i not in touched)
            # Crucial: NOT writing stage files, even into repo.
            del staged,after
    assert len(all_patches)==19 and len(protected)==8
    assert len({(x["binary"],x["offset"]) for x in all_patches})==19
    assert all(x["allowed_for_deployment"] is False for x in all_patches)
    d={
        "status":"NATIVE9_19_LIFECYCLE_PREVIEW_ABI_PATCHES_STRUCTURAL_PASS_UNSAFE_FOR_RELEASE",
        "operation":"SIMULATED_IN_MEMORY_ONLY",
        "source_version":"0.1.0~native9",
        "source_sha256":EXPECTED,
        "preserved_original_carplay_count":len(protected),
        "all_requested_lifecycle_body_candidates":len(all_patches),
        "estimated_changed_bytes_preview":total_mutations,
        "patch_rows":all_patches,
        "carplay_original_checksums":protected,
        "method_return_shapes_pass":True,
        "method_runtime_lifecycle_safe":False,
        "carplay_runtime_safe_after_preview":False,
        "requires_allocation_and_dispatch_callgraph":True,
        "proposed_binary_written":False,
        "deb_built":False,
        "sileo_changed":False,
        "native9_published_binary_unchanged":True,
        "explanation":"Only raw instruction-level disjointness is proven. Do not deploy these naive RET/NIL stubs: suppressing initializer/singleton/destructors can crash CarPlay or leak ObjC objects.",
        "next":"Trace sharedInstance/init caller relationships and 13 destructor ivar owners; replace only license-specific subpaths while preserving actual object lifecycle behavior.",
    }
    out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(d,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({k:v for k,v in d.items() if k not in ("patch_rows","carplay_original_checksums")},ensure_ascii=False,indent=2))

if __name__=="__main__":
    arg=argparse.ArgumentParser()
    arg.add_argument("--out",type=Path,required=True)
    a=arg.parse_args()
    main(a.out)
