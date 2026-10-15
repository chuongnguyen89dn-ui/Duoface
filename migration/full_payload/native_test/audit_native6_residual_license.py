#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Read-only residual license inventory for DuoFace Mới native6.

Uses existing Mach-O section reader and Objective-C function inventory,
never edits CarPlay detection, lifecycle methods or the tested DEB.
Only short UI-safe literals are shown; URLs, keys, receipt IDs and PII
are reduced to checksums, offsets and lengths instead of being copied.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile

from audit_native4_license_code import inspect
from build_native5 import sections, FILES, sha
from build_native6 import SOURCE_HASH as NATIVE5_SHA

ROOT=Path(__file__).resolve().parents[3]
TARGET=ROOT/"dist/payload-migration/native6/com.duoface.independent_0.1.0~native6_iphoneos-arm64.deb"
LEDGER=ROOT/"dist/payload-migration/native5/DANH_SACH_CHO_XOA.json"
KEY=re.compile(r"licen[sc]|subscript|activat|gift.?code|expir|trial|renew|entitlement|receipt|payment|hardware.?id",re.I)
DANGEROUS=re.compile(r"https?://|[\\/@]|[0-9]{5,}|token|secret|password|keychain|payload|server|endpoint|receipt|hardware|device.?id",re.I)
CARPLAY={"isCarPlayScreenConnected","isCarPlayScreen:","isCarPlayScreenConnectedExcludingScreen:"}
LIFECYCLE={"dealloc",".cxx_destruct","init","sharedInstance"}
SIZE_LIMIT=2048


def scan_short_strings(blob: bytes, name: str):
    found=[]
    for seg,sec,off,sz in sections(blob):
        if (seg,sec) not in {("__TEXT","__cstring"),("__TEXT_EXEC","__cstring"),("__TEXT","__ustring")}:
            continue
        encoding="utf-16-le" if sec=="__ustring" else "utf-8"
        separator=b"\x00\x00" if encoding=="utf-16-le" else b"\x00"
        data=blob[off:off+sz]
        # Bound the traversal and do not store arbitrary raw Mach-O content.
        # UTF-16 section is scanned on two-byte aligned positions.
        if encoding=="utf-16-le":
            assert off%2==0
            cursor=0
            while cursor < len(data)-1:
                end=cursor
                while end+1<len(data) and data[end:end+2]!=separator:
                    end+=2
                if end+1>=len(data): break
                raw=data[cursor:end]
                if raw and len(raw)<=SIZE_LIMIT:
                    record_candidate(found,name,sec,off+cursor,raw,encoding)
                cursor=end+2
        else:
            cursor=0
            for raw in data.split(b"\x00"):
                if raw and len(raw)<=SIZE_LIMIT:
                    record_candidate(found,name,sec,off+cursor,raw,encoding)
                cursor+=len(raw)+1
    return found


def record_candidate(result,name,section,offset,raw,encoding):
    try: s=raw.decode(encoding)
    except UnicodeError: return
    if not KEY.search(s):return
    if any(ord(c)<32 or ord(c)>126 for c in s):return
    is_ui=(not DANGEROUS.search(s)) and len(s)<=90
    # No confidential data, keys or URLs are persisted.
    result.append({
        "binary":name,"section":section,"file_offset":offset,
        "byte_count":len(raw),"sha256":sha(raw),
        "short_presentation_candidate":bool(is_ui),
        "display_literal":s if is_ui else None,
        "state":"inventory_only_no_binary_patch",
    })


def main():
    p=argparse.ArgumentParser()
    p.add_argument("--out",type=Path,required=True)
    p.add_argument("--expected-sha",required=True)
    args=p.parse_args()
    assert TARGET.is_file()
    assert sha(TARGET.read_bytes())==args.expected_sha
    ledger=json.loads(LEDGER.read_text())
    assert len(ledger["all_method_inventory"])==320
    assert len(ledger["ui_literal_hidden_records"])==26
    with tempfile.TemporaryDirectory(prefix="duoface-native6-inventory-") as tmp:
        unpack=Path(tmp)
        subprocess.run(["dpkg-deb","-x",str(TARGET),str(unpack)],check=True)
        binaries={}
        for name,rel in FILES.items():
            data=(unpack/rel).read_bytes()
            meta=inspect(data)
            known=[m for m in ledger["all_method_inventory"] if m["binary"]==name]
            observed={(m["class"],m["selector"],m["kind"],m["type_encoding"])
                     for m in meta["license_named_methods"]}
            listed={(m["class"],m["selector"],m["kind"],m["method_type"])
                    for m in known}
            assert observed == listed, (name,"Objective-C method inventory drift",len(observed),len(listed))
            keep_carplay=[x for x in known if x["state"]=="retain_carplay_screen_detection"]
            keep_lifecycle=[x for x in known if x["state"]=="retain_runtime_lifecycle"]
            existing_inert=[x for x in known if x["state"]=="retained_compatibility_or_unverified"]
            expiry=[x for x in known if x["state"]=="temporarily_disabled_native5"]
            assert all(m["selector"] in CARPLAY for m in keep_carplay)
            assert all(m["selector"] in LIFECYCLE for m in keep_lifecycle)
            assert len(existing_inert)>0
            strings=scan_short_strings(data,name)
            binaries[name]={
                "binary_sha256":sha(data),
                "method_inventory_size":len(known),
                "neutralized_legacy_method_count":len(existing_inert),
                "neutralized_expiry_state_count":len(expiry),
                "retained_lifecycle_count":len(keep_lifecycle),
                "retained_carplay_method_count":len(keep_carplay),
                "still_named_metadata_method_count":len(observed),
                "objc_parser_warnings":meta["parser_warnings"],
                "residual_static_display_or_data_string_count":len(strings),
                "short_presentation_candidates":sum(s["short_presentation_candidate"] for s in strings),
                "strings":strings,
            }
    total= sum(b["residual_static_display_or_data_string_count"] for b in binaries.values())
    result={
        "status":"NATIVE6_READONLY_RESIDUAL_LICENSE_INVENTORY",
        "native6_sha256":args.expected_sha,
        "native5_sha256_for_reference":NATIVE5_SHA,
        "binaries":binaries,
        "observed_residual_strings_count":total,
        "caution":"A string/selector/class match does not imply active license enforcement.",
        "protection":"All CarPlay screen detection and object lifecycle remain untouched.",
        "safe_to_delete_lifecycle_without_call_graph":False,
        "safe_to_delete_dynamic_objc_metadata_without_call_graph":False,
        "raw_deb_unchanged":True,
        "next":"Classify exact residual text and references; stage only proven presentation-only strings; never patch CarPlay methods or unrelated object lifecycle."
    }
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(result,indent=2,ensure_ascii=False)+"\n")
    print(json.dumps({"status":result["status"],"residual_count":total,
                      "counts":{k:{m:v for m,v in x.items() if m not in ("strings","objc_parser_warnings")}
                                for k,x in binaries.items()}},ensure_ascii=False,indent=2))


if __name__=="__main__":
    main()
