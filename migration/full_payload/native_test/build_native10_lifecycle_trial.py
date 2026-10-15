#!/usr/bin/env python3
"""Isolated, explicitly user-authorized native10 device trial from tested native9.

WARNING: this is experimental. Objective-C constructor, singleton and ivar
cleanup changes can prevent CarPlay from loading. This build has no runtime
safety guarantee. The tested native9 DEB is immutable and available to restore.

Exactly 19 previously fingerprinted method bodies are modified. Eight
CarPlay-screen methods and every other native9 payload file must be retained.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import subprocess
import tempfile
from pathlib import Path

from build_native5 import FILES, cmd, preserve_entitlements_and_resign, sha
from build_native8 import files_and_digests

ROOT=Path(__file__).resolve().parents[3]
SOURCE=ROOT/"dist/payload-migration/native9/com.duoface.independent_0.1.0~native9_iphoneos-arm64.deb"
SOURCE_SHA="e4e1122a494d32af6ec42c97c4288f6effb6716fbb81cb52b81b746280d4d97e"
VERSION="0.1.0~native10"
PLAN=ROOT/"audit/payload-migration/NATIVE9_19_LIFECYCLE_INMEMORY_PATCH_PREVIEW.json"
NOP=bytes.fromhex("1f2003d5")

def build():
    p=argparse.ArgumentParser()
    p.add_argument("--out",required=True,type=Path)
    p.add_argument("--report",required=True,type=Path)
    args=p.parse_args()
    assert sha(SOURCE.read_bytes())==SOURCE_SHA
    assert not args.out.exists(),"Cannot overwrite any existing candidate"
    plan=json.loads(PLAN.read_text())
    assert plan["source_sha256"]==SOURCE_SHA
    assert len(plan["patch_rows"])==19
    assert len(plan["carplay_original_checksums"])==8
    assert plan["method_runtime_lifecycle_safe"] is False
    assert plan["proposed_binary_written"] is False
    assert subprocess.check_output(["dpkg-deb","-f",str(SOURCE),"Package"],text=True).strip()=="com.duoface.independent"
    assert subprocess.check_output(["dpkg-deb","-f",str(SOURCE),"Version"],text=True).strip()=="0.1.0~native9"
    with tempfile.TemporaryDirectory(prefix="duoface-native10-") as td:
        tmp=Path(td)
        stage=tmp/"stage"
        cmd("dpkg-deb","-R",SOURCE,stage)
        before=files_and_digests(stage)
        signatures={}
        patches=[]
        for binary,rel in FILES.items():
            target=stage/rel
            original=target.read_bytes()
            mutable=bytearray(original)
            intervals=[]
            for entry in [x for x in plan["patch_rows"] if x["binary"]==binary]:
                start=entry["offset"]
                end=start+entry["span_length"]
                prev=original[start:end]
                assert sha(prev)==entry["original_span_sha256"]
                new=bytes.fromhex(entry["preview_stub_prefix_hex"])+NOP*entry["preview_tail_arm64_nop_repeat"]
                assert len(new)==len(prev)
                assert sha(new)==entry["preview_span_sha256"]
                assert prev!=new
                for a,b in intervals: assert end<=a or start>=b
                intervals.append((start,end))
                mutable[start:end]=new
                patches.append({
                    "binary":binary,"class":entry["class"],"selector":entry["selector"],
                    "offset":start,"span_length":len(new),"before_sha256":sha(prev),
                    "after_sha256":sha(new),
                    "may_break_runtime":entry["release_blocker"]
                })
            for cp in (x for x in plan["carplay_original_checksums"] if x["binary"]==binary):
                a=cp["offset"];size=next(m["length"] for m in
                    [*json.loads((ROOT/"audit/payload-migration/NATIVE9_19_LIFECYCLE_HIDE_PLAN_READONLY.json").read_text())["by_binary"][binary]["carplay_byte_exact_keep"]]
                    if m["file_offset"]==a)
                assert sha(bytes(mutable[a:a+size]))==cp["sha256_original_still_exact"]
            assert len(mutable)==len(original)
            target.write_bytes(mutable)
            signatures[binary]=preserve_entitlements_and_resign(target,original,tmp,binary)
        assert len(patches)==19
        control=stage/"DEBIAN/control"
        text=control.read_text(encoding="utf-8")
        assert "Version: 0.1.0~native9" in text
        control.write_text(text.replace("Version: 0.1.0~native9","Version: "+VERSION),encoding="utf-8")
        sums=[]
        for file in sorted(stage.rglob("*")):
            if file.is_file() and not file.is_symlink() and file.relative_to(stage).parts[0]!="DEBIAN":
                sums.append(hashlib.md5(file.read_bytes()).hexdigest()+"  "+file.relative_to(stage).as_posix())
        (stage/"DEBIAN/md5sums").write_text("\n".join(sums)+"\n")
        after=files_and_digests(stage)
        assert before.keys()==after.keys()
        modified=sorted(k for k in before if before[k]!=after[k])
        assert modified==sorted([*FILES.values(),"DEBIAN/control","DEBIAN/md5sums"]),modified
        assert before["var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib"]==after["var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib"]
        assert before["var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceLogoGripOnly.dylib"]==after["var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceLogoGripOnly.dylib"]
        args.out.parent.mkdir(parents=True,exist_ok=True)
        cmd("dpkg-deb","--build","--root-owner-group",stage,args.out)
    report={
        "status":"NATIVE10_EXPERIMENTAL_ONLY_NOT_DEVICE_TESTED",
        "source_sha256":SOURCE_SHA,
        "version":VERSION,
        "package":"com.duoface.independent",
        "architecture":"iphoneos-arm64",
        "modified_method_count":len(patches),
        "carplay_method_byte_guard_count":8,
        "modified_files":modified,
        "unchanged_other_payload_files":len(before)-len(modified),
        "patches":patches,
        "preserved_signing":signatures,
        "native9_rollback_preserved":True,
        "runtime_safety_proven":False,
        "device_tested":False,
        "sileo_published":False,
        "deb_sha256":sha(args.out.read_bytes()),
        "deb_size":args.out.stat().st_size
    }
    args.report.parent.mkdir(parents=True,exist_ok=True)
    args.report.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    print(json.dumps({k:v for k,v in report.items() if k!="patches"},indent=2))

if __name__=="__main__":
    build()
