#!/usr/bin/env python3
"""Strict read-only binary diff: native6 -> native7 can ONLY hide 78 strings.

All Mach-O instructions/ObjC metadata and every unrelated payload file must
remain byte-identical. Native7 remains a trial pending device confirmation.
"""
from __future__ import annotations
import argparse, json, subprocess, tempfile
from pathlib import Path
from build_native5 import FILES, sections, sha
from build_native7 import SOURCE, EXPECTED, VERSION, UI_COPY

def verify_binary(name, old, new, masks):
    assert len(old)==len(new)
    original_sections={(seg,sec):(off,n) for seg,sec,off,n in sections(old)}
    modified_sections={(seg,sec):(off,n) for seg,sec,off,n in sections(new)}
    assert original_sections==modified_sections,(name,"Mach-O sections shifted")
    assert len(masks)==len(UI_COPY)==39
    intervals=set()
    for m in masks:
        start,length=m["file_offset"],m["byte_count"]
        stop=start+length
        assert m["binary"]==name
        assert sha(old[start:stop])==m["native6_sha256"]
        assert sha(new[start:stop])==m["native7_sha256"]
        assert new[start:stop]==b" "*length
        assert old[start:stop]==m["label"].encode("utf-8")
        assert (start,stop) not in intervals
        intervals.add((start,stop))
        assert any(sec=="__cstring" and off<=start<stop<=off+n
                   for (_,sec),(off,n) in original_sections.items())
    intervals=sorted(intervals)
    assert all(a[1]<=b[0] for a,b in zip(intervals,intervals[1:]))
    edited=0
    for (seg,sec),(off,size) in original_sections.items():
        left=old[off:off+size]
        right=new[off:off+size]
        spans=[(a-off,b-off) for a,b in intervals if off<=a and b<=off+size]
        assert (sec=="__cstring") or not spans
        for n,(x,y) in enumerate(zip(left,right)):
            if x!=y:
                assert sec=="__cstring" and any(a<=n<b for a,b in spans),(name,seg,sec,hex(off+n))
                edited+=1
        if sec=="__text":
            assert left==right,(name,"code modified")
        if sec.startswith("__objc") or sec=="__const" or sec=="__stubs":
            assert left==right,(name,sec,"ObjC runtime or ABI modified")
    assert edited==sum(m["byte_count"] for m in masks), (name,edited)
    return {"masked_strings":len(masks),"masked_bytes":edited,
            "machine_code_sections_identical":True,
            "all_other_sections_identical":True,
            "objc_runtime_metadata_identical":True}

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--deb",type=Path,required=True)
    ap.add_argument("--report",type=Path,required=True)
    ap.add_argument("--out",type=Path,required=True)
    args=ap.parse_args()
    report=json.loads(args.report.read_text())
    assert sha(SOURCE.read_bytes())==EXPECTED
    assert sha(args.deb.read_bytes())==report["deb_sha256"]
    assert report["version"]==VERSION
    assert len(report["masks"])==78
    with tempfile.TemporaryDirectory(prefix="duoface-native7-regression-") as folder:
        folder=Path(folder)
        a=folder/"native6"
        b=folder/"native7"
        subprocess.run(["dpkg-deb","-x",str(SOURCE),str(a)],check=True)
        subprocess.run(["dpkg-deb","-x",str(args.deb),str(b)],check=True)
        old={p.relative_to(a).as_posix():sha(p.read_bytes())
             for p in a.rglob("*") if p.is_file() and not p.is_symlink()}
        new={p.relative_to(b).as_posix():sha(p.read_bytes())
             for p in b.rglob("*") if p.is_file() and not p.is_symlink()}
        assert old.keys()==new.keys()
        assert sorted(k for k in old if old[k]!=new[k])==sorted(FILES.values())
        tests={}
        for name,rel in FILES.items():
            tests[name]=verify_binary(name,(a/rel).read_bytes(),(b/rel).read_bytes(),
                [m for m in report["masks"] if m["binary"]==name])
    out={
      "status":"NATIVE7_ONLY_WHITELISTED_PRESENTATION_COPY_HIDDEN_PASS",
      "source_native6_sha256":EXPECTED,
      "native7_sha256":report["deb_sha256"],
      "verified_binaries":tests,
      "unrelated_payload_files_identical":len(old)-2,
      "all_carplay_code_identical":True,
      "objc_class_and_selector_metadata_preserved":True,
      "all_dealloc_and_carplay_detection_code_identical":True,
      "native7_device_tested":False,
      "license_logic_proven_fully_removed":False}
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(out,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    print(json.dumps(out,indent=2,ensure_ascii=False))
if __name__=="__main__":main()
