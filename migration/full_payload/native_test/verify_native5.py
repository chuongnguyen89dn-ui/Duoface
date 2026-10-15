#!/usr/bin/env python3
"""Independent byte-level regression native4 -> native5.

Prove only two expired-modal methods can change __text, and that static strings
are masked ONLY where the build ledger explicitly records. No binary, icon,
picker, native hook, CarPlay resource or other payload may differ unexpectedly.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import tempfile
from audit_native4_license_code import inspect

ROOT=Path(__file__).resolve().parents[3]
BASE=ROOT/"dist/payload-migration/native4/com.duoface.independent_0.1.0~native4_iphoneos-arm64.deb"
CAND=ROOT/"dist/payload-migration/native5/com.duoface.independent_0.1.0~native5_iphoneos-arm64.deb"
REPORT=ROOT/"dist/payload-migration/native5/BAO_CAO.json"
LEDGER=ROOT/"dist/payload-migration/native5/DANH_SACH_CHO_XOA.json"
EXE={
 "DuoFaceUI":"var/jb/Applications/DuoFaceUI.app/DuoFaceUI",
 "DuoFaceDashboard":"var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib",
}
def sha(b:bytes)->str:return hashlib.sha256(b).hexdigest()
def sections(blob:bytes):
    assert blob[:4]==bytes.fromhex("cffaedfe")
    cursor=32
    n=struct.unpack_from("<I",blob,16)[0]
    result={}
    for _ in range(n):
        command,length=struct.unpack_from("<II",blob,cursor)
        assert length>=8 and cursor+length<=len(blob)
        if command==0x19:
            count=struct.unpack_from("<I",blob,cursor+64)[0]
            for i in range(count):
                q=cursor+72+i*80
                assert q+80<=cursor+length
                sec=blob[q:q+16].split(b"\x00")[0].decode("ascii")
                seg=blob[q+16:q+32].split(b"\x00")[0].decode("ascii")
                size=struct.unpack_from("<Q",blob,q+40)[0]
                offset=struct.unpack_from("<I",blob,q+48)[0]
                if size and offset+size<=len(blob):
                    result[f"{seg},{sec}"]=(offset,size)
        cursor+=length
    return result

def verify_edited_binary(binary,original,current,data):
    prior=sections(original)
    post=sections(current)
    expected=[];seen=[]
    masked=[]
    for m in data["masked_ui_literals"]:
        expected.append((m["file_offset"],m["byte_count"],"presentation_literal"))
        span=original[m["file_offset"]:m["file_offset"]+m["byte_count"]]
        revised=current[m["file_offset"]:m["file_offset"]+m["byte_count"]]
        assert sha(span)==m["before_sha256"]
        assert sha(revised)==m["after_sha256"]
        assert span!=revised
        assert all(x in (0x20,0x00) for x in revised)
        masked.append(m["label"])
    for m in data["method_flags"]:
        expected.append((m["file_offset"],m["byte_count"],"expiry_accessor"))
        span=original[m["file_offset"]:m["file_offset"]+m["byte_count"]]
        revised=current[m["file_offset"]:m["file_offset"]+m["byte_count"]]
        assert sha(span)==m["before_sha256"]
        assert sha(revised)==m["after_sha256"]
        assert span!=revised
    assert len(data["method_flags"])==(2 if binary=="DuoFaceUI" else 0)
    for part in ["__TEXT,__text","__TEXT_EXEC,__text","__TEXT,__cstring","__TEXT,__ustring"]:
        if part not in prior:continue
        assert prior[part]==post[part],(binary,part,"section offsets moved")
        off,length=prior[part]
        affected=[(start,start+size,kind) for start,size,kind in expected if off<=start<off+length]
        if part.endswith("__text"):
            assert all(kind=="expiry_accessor" for _,_,kind in affected)
        else:
            assert all(kind=="presentation_literal" for _,_,kind in affected)
        mask=bytearray(length)
        for start,end,kind in affected:
            assert end<=off+length
            a=start-off;b=end-off
            assert not any(mask[a:b]),"overlap"
            mask[a:b]=b"\x01"*(b-a)
            seen.append((start,end,kind))
        old=original[off:off+length]
        new=current[off:off+length]
        for i,(a,b) in enumerate(zip(old,new)):
            if not mask[i] and a!=b:
                raise AssertionError(f"Undeclared change in {binary} {part} at {hex(off+i)}")
    assert len(seen)==len(expected),(binary,len(seen),len(expected))
    # All Objective-C method definitions still available after reversible trial.
    a=inspect(original)["license_named_methods"]
    b=inspect(current)["license_named_methods"]
    assert sorted((m["class"],m["selector"],m["type_encoding"]) for m in a)==sorted(
           (m["class"],m["selector"],m["type_encoding"]) for m in b)
    return {"masked_presentation_literals":len(masked),
            "temporary_expiry_methods":len(data["method_flags"]),
            "verified_edited_byte_intervals":len(seen),
            "text_code_outside_expiry_methods_byte_identical":True,
            "objc_classes_and_selectors_preserved":True}

def main():
    a=argparse.ArgumentParser()
    a.add_argument("--out",type=Path,required=True)
    arg=a.parse_args()
    info=json.loads(REPORT.read_text())
    ledger=json.loads(LEDGER.read_text())
    assert sha(BASE.read_bytes())==info["source_native4_sha256"]
    assert sha(CAND.read_bytes())==info["deb_sha256"]
    assert len(ledger["method_hidden_records"])==2
    with tempfile.TemporaryDirectory(prefix="native5-regression-") as temp:
        p=Path(temp);old=p/"old";new=p/"new"
        subprocess.run(["dpkg-deb","-x",str(BASE),str(old)],check=True)
        subprocess.run(["dpkg-deb","-x",str(CAND),str(new)],check=True)
        ob={v.relative_to(old).as_posix():sha(v.read_bytes()) for v in old.rglob("*") if v.is_file() and not v.is_symlink()}
        nb={v.relative_to(new).as_posix():sha(v.read_bytes()) for v in new.rglob("*") if v.is_file() and not v.is_symlink()}
        assert ob.keys()==nb.keys()
        changed=sorted(k for k in ob if ob[k]!=nb[k])
        assert changed==sorted(EXE.values()),changed
        results={}
        for name,path in EXE.items():
            orig=(old/path).read_bytes()
            cand=(new/path).read_bytes()
            results[name]=verify_edited_binary(name,orig,cand,info["changed_binaries"][name])
    report={
        "status":"NATIVE5_NATIVE_CARPLAY_CODE_AND_UNRELATED_ASSETS_BYTE_IDENTICAL",
        "source_native4_sha256":info["source_native4_sha256"],
        "native5_sha256":info["deb_sha256"],
        "unchanged_all_other_payload_file_count":len(ob)-len(EXE),
        "target_binary_checks":results,
        "no_extra_machine_code_changed":True,
        "no_deletion_of_selectors_or_class_lifecycle":True,
        "device_tested":False,
        "approval_required_before_physical_delete":True,
    }
    arg.out.parent.mkdir(parents=True,exist_ok=True)
    arg.out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
    print(json.dumps({k:v for k,v in report.items() if k!="target_binary_checks"},ensure_ascii=False))
if __name__=="__main__":main()
