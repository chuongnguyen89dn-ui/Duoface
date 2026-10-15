#!/usr/bin/env python3
"""Byte-level QA of experimental native10 versus pinned, tested native9.

Distinguishes file/code layout and correct signing from device runtime safety.
Never claims that a valid 19-method stub is safe on CarPlay.
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
from build_native10_lifecycle_trial import SOURCE, SOURCE_SHA, PLAN, VERSION

def payload(root):
    return {p.relative_to(root).as_posix():sha(p.read_bytes())
            for p in root.rglob("*") if p.is_file() and not p.is_symlink()}

def verify():
    ap=argparse.ArgumentParser()
    ap.add_argument("--deb",required=True,type=Path)
    ap.add_argument("--report",required=True,type=Path)
    ap.add_argument("--out",required=True,type=Path)
    args=ap.parse_args()
    assert sha(SOURCE.read_bytes())==SOURCE_SHA
    build=json.loads(args.report.read_text(encoding="utf-8"))
    manifest=json.loads(PLAN.read_text(encoding="utf-8"))
    assert build["status"]=="NATIVE10_EXPERIMENTAL_ONLY_NOT_DEVICE_TESTED"
    assert build["source_sha256"]==SOURCE_SHA
    assert sha(args.deb.read_bytes())==build["deb_sha256"]
    assert build["version"]==VERSION and build["package"]=="com.duoface.independent"
    assert build["modified_method_count"]==19 and len(build["patches"])==19
    assert build["carplay_method_byte_guard_count"]==8
    assert not build["runtime_safety_proven"]
    assert not build["device_tested"] and not build["sileo_published"]
    for k,v in (("Package","com.duoface.independent"),("Version",VERSION),
                ("Architecture","iphoneos-arm64")):
        assert subprocess.check_output(["dpkg-deb","-f",str(args.deb),k],text=True).strip()==v
    with tempfile.TemporaryDirectory(prefix="native10-verified-") as temp:
        td=Path(temp)
        old=td/"native9"
        new=td/"native10"
        ctl=td/"control"
        subprocess.run(["dpkg-deb","-x",str(SOURCE),str(old)],check=True)
        subprocess.run(["dpkg-deb","-x",str(args.deb),str(new)],check=True)
        subprocess.run(["dpkg-deb","-e",str(args.deb),str(ctl)],check=True)
        prev=payload(old)
        curr=payload(new)
        assert prev.keys()==curr.keys()
        changes=sorted(p for p in prev if prev[p]!=curr[p])
        assert changes==sorted(FILES.values())
        assert build["modified_files"]==sorted([*FILES.values(),"DEBIAN/control","DEBIAN/md5sums"])
        for p in prev:
            if p not in changes:assert curr[p]==prev[p],p
        assert prev["var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib"]==curr["var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib"]
        assert prev["var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceLogoGripOnly.dylib"]==curr["var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceLogoGripOnly.dylib"]
        summary={}
        for name,rel in FILES.items():
            a=(old/rel).read_bytes()
            b=(new/rel).read_bytes()
            assert len(a)==len(b)
            x=[p for p in manifest["patch_rows"] if p["binary"]==name]
            assert len(x)==(15 if name=="DuoFaceUI" else 4)
            assert sorted((seg,sect,start,n) for seg,sect,start,n in sections(a))==sorted(
                (seg,sect,start,n) for seg,sect,start,n in sections(b))
            text_ranges=[(start,start+n) for seg,sect,start,n in sections(a)
                         if sect=="__text" and seg in ("__TEXT","__TEXT_EXEC")]
            assert text_ranges
            allowed=set()
            for p in x:
                begin=p["offset"];end=begin+p["span_length"]
                assert sha(a[begin:end])==p["original_span_sha256"]
                assert sha(b[begin:end])==p["preview_span_sha256"]
                assert any(t0<=begin<end<=t1 for t0,t1 in text_ranges)
                allowed.update(range(begin,end))
            actual_changes=0
            for st,en in text_ranges:
                for at in range(st,en):
                    if a[at]!=b[at]:
                        assert at in allowed,(name,hex(at))
                        actual_changes+=1
            assert actual_changes>0
            for seg,sect,st,n in sections(a):
                if sect.startswith("__objc_") or sect in (
                    "__cstring","__cfstring","__const","__stubs","__stub_helper"):
                    assert a[st:st+n]==b[st:st+n],(name,seg,sect)
            summary[name]={
                "patched_method_bodies":len(x),
                "actual_changed_text_bytes":actual_changes,
                "all_non_target_text_bytes_identical":True,
                "obj_c_and_visible_UI_literals_identical":True,
            }
        original_hashes={}
        updated_hashes={}
        for x in manifest["carplay_original_checksums"]:
            rel=FILES[x["binary"]]
            a=(old/rel).read_bytes()
            b=(new/rel).read_bytes()
            ref=next(z for z in
                json.loads((Path(__file__).resolve().parents[3]/
                    "audit/payload-migration/NATIVE9_19_LIFECYCLE_HIDE_PLAN_READONLY.json"
                ).read_text())["by_binary"][x["binary"]]["carplay_byte_exact_keep"]
                if z["file_offset"]==x["offset"])
            start=x["offset"];end=start+ref["length"]
            assert sha(a[start:end])==sha(b[start:end])==x["sha256_original_still_exact"]
            key=x["binary"]+"."+x["class"]+"."+x["selector"]+"@"+str(start)
            original_hashes[key]=sha(a[start:end])
            updated_hashes[key]=sha(b[start:end])
        assert len(original_hashes)==len(updated_hashes)==8
        assert original_hashes==updated_hashes
        lines=(ctl/"md5sums").read_text().splitlines()
        m={}
        for line in lines:
            h,k=line.split("  ",1)
            assert k not in m
            m[k]=h
        assert set(m)==set(curr)
        for k,h in m.items():
            assert hashlib.md5((new/k).read_bytes()).hexdigest()==h,k
    out={
        "status":"NATIVE10_STRUCTURE_CODE_SCOPE_AND_EIGHT_CARPLAY_SHA_PASS",
        "deb_sha256":build["deb_sha256"],
        "package":"com.duoface.independent",
        "version":VERSION,
        "changes_by_binary":summary,
        "all_8_carplay_code_bodies_byte_identical":True,
        "all_other_package_payload_files_byte_identical":True,
        "native9_visual_fullscreen_divider_logo_unchanged":True,
        "all_existing_objc_metadata_and_literals_identical":True,
        "all_19_target_methods_changed":True,
        "device_runtime_safety_proven":False,
        "may_crash_or_prevent_carplay_connecting":True,
        "device_tested":False,
        "sileo_published":False,
        "rollback_native9_sha256":SOURCE_SHA
    }
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(out,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    print(json.dumps(out,indent=2,ensure_ascii=False))

if __name__=="__main__":
    verify()
