#!/usr/bin/env python3
"""Read-only native9 Mach-O reference tracing of two remaining 'Activate' literals.

Do NOT equate a string occurrence with visible UIKit, do NOT rewrite binary.
Maps exact native6 inventory offsets onto SHA-pinned native9 Mach-O sections,
scans pointer/CFString/ObjC selector references and recognizes ARM64 ADRP+ADD
or ADR direct string-address loads as *heuristic static references*. Other
dynamic callsites are NOT proven absent by this analysis.

Run: python3 scripts/audit_duoface_native9_activate_refs.py \
  --out audit/payload-migration/NATIVE9_ACTIVATE_REFS_READONLY.json
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
DEB = ROOT / "dist/payload-migration/native9/com.duoface.independent_0.1.0~native9_iphoneos-arm64.deb"
EXPECTED_DEB = "e4e1122a494d32af6ec42c97c4288f6effb6716fbb81cb52b81b746280d4d97e"
CATALOG = ROOT / "audit/payload-migration/NATIVE6_REMAINING_LICENSE_READONLY.json"
CURRENT_AUDIT = ROOT / "audit/payload-migration/NATIVE9_LICENSE_KEEP_VS_HIDE_READONLY.json"
BINARIES = {
    "DuoFaceUI": "var/jb/Applications/DuoFaceUI.app/DuoFaceUI",
    "DuoFaceDashboard":
        "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib",
}


def sha(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def sections(raw: bytes) -> list[dict]:
    assert raw[:4] == bytes.fromhex("cffaedfe"), "expected arm64 Mach-O thin"
    cursor = 32
    results = []
    ncmds = struct.unpack_from("<I", raw, 16)[0]
    assert 10 < ncmds < 250
    for _ in range(ncmds):
        cmd, length = struct.unpack_from("<II", raw, cursor)
        assert length >= 8 and cursor+length <= len(raw)
        if cmd == 0x19:
            nsects = struct.unpack_from("<I", raw, cursor+64)[0]
            assert cursor + 72 + nsects*80 <= cursor + length
            for i in range(nsects):
                at = cursor+72+i*80
                sec = raw[at:at+16].split(b"\0")[0].decode("ascii")
                seg = raw[at+16:at+32].split(b"\0")[0].decode("ascii")
                vm, size = struct.unpack_from("<QQ", raw, at+32)
                off = struct.unpack_from("<I", raw, at+48)[0]
                if off + size <= len(raw):
                    results.append({
                        "segment":seg,"section":sec,
                        "virtual_address":vm,"file_offset":off,"size":size,
                    })
        cursor += length
    assert results
    return results


def decode_refs(text: bytes, text_vm: int, target_vm: int) -> list[dict]:
    assert len(text) % 4 == 0
    prior_pages = {}
    results = []
    for i in range(0,len(text),4):
        w = struct.unpack_from("<I", text, i)[0]
        pc = text_vm + i
        if (w & 0x9F000000) == 0x90000000:  # ADRP Xd, target page
            rd = w & 31
            immlo = (w>>29)&3
            immhi = (w>>5)&0x7ffff
            signed = (immhi<<2)|immlo
            if signed & (1<<20):
                signed -= 1<<21
            page = (pc & ~0xfff) + (signed<<12)
            prior_pages[rd] = (page,pc,i)
        elif (w & 0xFF000000)==0x91000000:  # ADD Xd, Xn, #imm
            rd = w & 31
            rn = (w>>5)&31
            item = prior_pages.get(rn)
            if item and i-item[2] <= 12*4:
                shift=(w>>22)&3
                if shift in (0,1):
                    offset=((w>>10)&0xfff)<<(12 if shift else 0)
                    if item[0]+offset == target_vm:
                        results.append({
                            "kind":"ADRP_ADD_STATIC_ADDRESS_CANDIDATE",
                            "adrp_pc_hex":hex(item[1]),
                            "add_pc_hex":hex(pc),
                            "virtual_literal_hex":hex(target_vm),
                        })
            if rd in prior_pages and rd!=rn:
                del prior_pages[rd]
        elif (w & 0x9F000000) == 0x10000000:  # ADR Xd, pc-relative address
            immlo=(w>>29)&3
            immhi=(w>>5)&0x7ffff
            signed=(immhi<<2)|immlo
            if signed & (1<<20):
                signed-=1<<21
            if pc+signed == target_vm:
                results.append({
                    "kind":"ADR_STATIC_ADDRESS_CANDIDATE",
                    "adr_pc_hex":hex(pc),
                    "virtual_literal_hex":hex(target_vm),
                })
        # No register-flow proof across branches or indirect dispatch; report
        # raw candidates only. This is NOT a reliable absence-of-calls proof.
    return results[:80]


def analyze(raw: bytes, expected_offset: int, expected_sha: str) -> dict:
    maps = sections(raw)
    section = next((
        x for x in maps if x["section"]=="__cstring" and
        x["file_offset"]<=expected_offset<
        x["file_offset"]+x["size"]
    ),None)
    assert section is not None
    label = b"Activate"
    assert raw[expected_offset:expected_offset+len(label)]==label
    assert raw[expected_offset+len(label)]==0
    assert sha(label)==expected_sha
    target = section["virtual_address"] + (expected_offset-section["file_offset"])

    pointer_sections = []
    for s in maps:
        if not (
            s["section"] in {
                "__cfstring", "__objc_selrefs", "__objc_const",
                "__const", "__data", "__data_const",
            } or s["section"].startswith("__objc_")
        ):
            continue
        buf=raw[s["file_offset"]:s["file_offset"]+s["size"]]
        hits=[]
        for i in range(0,len(buf)-7,8):
            if struct.unpack_from("<Q",buf,i)[0] == target:
                hits.append({
                    "pointer_file_offset_hex": hex(s["file_offset"]+i),
                    "pointer_vm_hex":hex(s["virtual_address"]+i),
                })
        if hits:
            pointer_sections.append({
                "segment":s["segment"],
                "section":s["section"],
                "references":hits[:50],
                "count":len(hits)
            })

    executable = [s for s in maps if s["section"]=="__text" and
                  s["segment"] in ("__TEXT","__TEXT_EXEC")]
    assert executable
    direct=[]
    for s in executable:
        data=raw[s["file_offset"]:s["file_offset"]+s["size"]]
        # Only 4-byte complete ARM64 instructions.
        data=data[:len(data)//4*4]
        direct.extend(decode_refs(data,s["virtual_address"],target))
    return {
        "text_literal": "Activate",
        "literal_file_offset":expected_offset,
        "literal_sha256":expected_sha,
        "macho_literal_virtual_address_hex":hex(target),
        "section":section["segment"]+","+section["section"],
        "pointer_reference_section_groups":pointer_sections,
        "pointer_reference_count":sum(x["count"] for x in pointer_sections),
        "objc_selrefs_pointer_count":sum(x["count"] for x in pointer_sections
                                           if x["section"]=="__objc_selrefs"),
        "cfstring_pointer_count":sum(x["count"] for x in pointer_sections
                                      if x["section"]=="__cfstring"),
        "candidate_direct_arm64_address_loads":direct,
        "candidate_direct_arm64_address_load_count":len(direct),
        "proven_unused_or_safe_to_mask":False,
        "proven_user_visible_UI":False,
        "runtime_dynamic_callers_checked":False,
    }


def main(out: Path) -> None:
    assert DEB.is_file() and sha(DEB.read_bytes())==EXPECTED_DEB
    original=json.loads(CATALOG.read_text(encoding="utf-8"))
    audit=json.loads(CURRENT_AUDIT.read_text(encoding="utf-8"))
    assert audit["native9_deb_sha256"]==EXPECTED_DEB
    assert audit["string_counts"]["possible_visible_activate_label_unverified"]==2
    with tempfile.TemporaryDirectory(prefix="duoface-activate-refs-") as t:
        root=Path(t)
        subprocess.run(["dpkg-deb","-x",str(DEB),str(root)],check=True)
        rows={}
        for binary,relative in BINARIES.items():
            candidates=[
                x for x in original["binaries"][binary]["strings"]
                if x["display_literal"]=="Activate"
            ]
            assert len(candidates)==1,(binary,len(candidates))
            item=candidates[0]
            data=(root/relative).read_bytes()
            rows[binary]={
                "binary_sha256":sha(data),
                **analyze(data,int(item["file_offset"]),item["sha256"]),
            }
    report={
        "status":"NATIVE9_ACTIVATE_LITERAL_STATIC_REFERENCE_MAP_READONLY",
        "native9_deb_sha256":EXPECTED_DEB,
        "method_audit":audit["status"],
        "results":rows,
        "selective_mask_is_approved":False,
        "not_proven_safe_to_delete_apple_objc_or_localization_metadata":True,
        "carplay_host_or_split_pan_modified":False,
        "deb_built":False,
        "sileo_changed":False,
        "limits":[
            "Only direct raw pointers and plausible ADR/ADRP+ADD pairs are detected",
            "Chained fixups, indirect registers, formatting/localization and runtime ObjC lookup remain untraced",
            "A zero reference count does NOT prove a dead string or permission to mask",
            "No connected-device touch/license behavior is inferred from this static report",
        ],
        "next":"Use results to trace real UIKit/localization callsites before staging a new text-only patch; keep native9 unchanged.",
    }
    out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"status":report["status"],
        "results":{k:{
            "literal_file_offset":v["literal_file_offset"],
            "pointer_reference_count":v["pointer_reference_count"],
            "objc_selrefs_pointer_count":v["objc_selrefs_pointer_count"],
            "cfstring_pointer_count":v["cfstring_pointer_count"],
            "arm64_ref_candidates":v["candidate_direct_arm64_address_load_count"],
        } for k,v in rows.items()},
        "deb_built":False,"sileo_changed":False},ensure_ascii=False,indent=2))


if __name__=="__main__":
    ap=argparse.ArgumentParser()
    ap.add_argument("--out",type=Path,required=True)
    a=ap.parse_args()
    main(a.out)
