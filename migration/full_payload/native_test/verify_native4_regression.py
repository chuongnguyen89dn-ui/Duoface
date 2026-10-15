#!/usr/bin/env python3
"""Independent regression check of native4 vs immutable native3.

Verify that EVERY executable byte outside an explicitly enumerated removed
method implementation stays identical and that each affected method was filled
with a same-ABI return stub and ARM64 NOP instructions. Original picker, assets,
rootless filter and native2 runtime adapter must remain unchanged.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import pathlib
import struct
import subprocess
import tempfile

from audit_native4_license_code import slurp_slices

ROOT=pathlib.Path(__file__).resolve().parents[3]
OLD=ROOT/"dist/payload-migration/native3/com.duoface.independent_0.1.0~native3_iphoneos-arm64.deb"
NEW=ROOT/"dist/payload-migration/native4/com.duoface.independent_0.1.0~native4_iphoneos-arm64.deb"
REP=ROOT/"dist/payload-migration/native4/BAO_CAO.json"
NOP=struct.pack("<I",0xd503201f)
RET=struct.pack("<I",0xd65f03c0)
BINS={
"DuoFaceUI":"var/jb/Applications/DuoFaceUI.app/DuoFaceUI",
"DuoFaceDashboard":"var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib",
}
def digest(x:bytes)->str:return hashlib.sha256(x).hexdigest()

def executable_ranges(part:bytes):
    assert part[:4]==bytes.fromhex("cffaedfe")
    out={}
    p=32
    n=struct.unpack_from("<I",part,16)[0]
    for _ in range(n):
        cmd,size=struct.unpack_from("<II",part,p)
        assert size>=8
        if cmd==0x19:
            num=struct.unpack_from("<I",part,p+64)[0]
            for i in range(num):
                q=p+72+i*80
                assert q+80<=p+size
                seg=part[q+16:q+32].split(b"\0")[0]
                sec=part[q:q+16].split(b"\0")[0]
                if seg in (b"__TEXT",b"__TEXT_EXEC") and sec==b"__text":
                    length=struct.unpack_from("<Q",part,q+40)[0]
                    off=struct.unpack_from("<I",part,q+48)[0]
                    assert length>1000 and off+length<=len(part)
                    out[(seg.decode(),sec.decode())]=(off,length)
        p+=size
    assert out
    return out

def verify_method_segments(before:bytes,after:bytes,methods:list[dict]):
    old_sections=executable_ranges(before)
    new_sections=executable_ranges(after)
    assert old_sections==new_sections,(old_sections,new_sections)
    whole_count=0
    replacement_bytes=0
    proof=[]
    already_inert=[]
    for key,(off,size) in old_sections.items():
        mask=bytearray(size)
        inside=[m for m in methods if off<=m["file_offset"]<off+size]
        for m in inside:
            start=m["file_offset"]-off
            end=start+m["bytes_replaced"]
            assert end<=size
            assert not any(mask[start:end]),"overlapping replaced span"
            mask[start:end]=b"\x01"*(end-start)
            original=before[m["file_offset"]:m["file_offset"]+m["bytes_replaced"]]
            replacement=after[m["file_offset"]:m["file_offset"]+m["bytes_replaced"]]
            assert digest(original)==m["previous_span_sha256"],m["selector"]
            stub_bytes=m["stub_bytes"]
            assert stub_bytes>=4 and stub_bytes%4==0
            assert replacement[stub_bytes-4:stub_bytes]==RET,(key,m["selector"],"missing ret")
            assert replacement[stub_bytes:]==NOP*((len(replacement)-stub_bytes)//4),(key,m["selector"],"not fully erased")
            if original==replacement:
                already_inert.append({'class':m['class'],'selector':m['selector'],'offset':m['file_offset'],'bytes':m['bytes_replaced']})
            replacement_bytes+=len(replacement)
            proof.append({"class":m["class"],"method":m["selector"],"span_sha256":digest(replacement)})
        a=before[off:off+size]
        b=after[off:off+size]
        assert len(a)==len(b)
        for i,flag in enumerate(mask):
            if not flag and a[i]!=b[i]:
                raise AssertionError(f"Original CarPlay machine byte unexpectedly changed: {key} {off+i:#x}")
            if not flag:whole_count+=1
    assert len(proof)==len(methods),(len(proof),len(methods))
    return {
      "verified_method_count":len(proof),
      "already_identical_in_baseline_method_count":len(already_inert),
      "already_identical_in_baseline_methods":already_inert,
      "fully_replaced_original_method_bytes":replacement_bytes,
      "unmodified_executable_bytes_outside_target_functions":whole_count,
      "all_other_executable_instruction_bytes_identical":True,
      "all_removed_functions_return_using_original_ABI_stubs":True,
      "methods_new_span_sha256":proof,
    }

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--out",type=pathlib.Path,required=True)
    args=ap.parse_args()
    report=json.loads(REP.read_text())
    assert digest(OLD.read_bytes())==report["baseline_native3_sha256"]
    assert digest(NEW.read_bytes())==report["deb_sha256"]
    with tempfile.TemporaryDirectory() as work:
        root=pathlib.Path(work)
        a=root/"a";b=root/"b"
        subprocess.run(["dpkg-deb","-x",str(OLD),str(a)],check=True)
        subprocess.run(["dpkg-deb","-x",str(NEW),str(b)],check=True)
        all_old={p.relative_to(a).as_posix():digest(p.read_bytes())
                 for p in a.rglob("*") if p.is_file() and not p.is_symlink()}
        all_new={p.relative_to(b).as_posix():digest(p.read_bytes())
                 for p in b.rglob("*") if p.is_file() and not p.is_symlink()}
        assert all_old.keys()==all_new.keys(),"unexpected payload paths"
        actual_changed=sorted(k for k in all_old if all_old[k]!=all_new[k])
        assert actual_changed==sorted(BINS.values()),actual_changed
        evidence={}
        for name,path in BINS.items():
            original=(a/path).read_bytes()
            changed=(b/path).read_bytes()
            old=[x["bytes"] for x in slurp_slices(original) if x["arch"]=="arm64:0"]
            new=[x["bytes"] for x in slurp_slices(changed) if x["arch"]=="arm64:0"]
            assert len(old)==1 and len(new)==1
            methods=report["method_bodies"][name]["patched_methods"]
            evidence[name]=verify_method_segments(old[0],new[0],methods)
            assert evidence[name]["verified_method_count"]==report["method_bodies"][name]["method_body_count"]
            assert evidence[name]["fully_replaced_original_method_bytes"]==report["method_bodies"][name]["method_bytes_overwritten"]
    out={
        "status":"NATIVE4_ALL_NON_TARGET_MACHINE_INSTRUCTIONS_IDENTICAL",
        "source_native3_sha256":report["baseline_native3_sha256"],
        "native4_sha256":report["deb_sha256"],
        "original_payload_files_byte_identical_except_rewritten_binaries":len(all_old)-len(BINS),
        "correctly_modified_original_files":actual_changed,
        "executable_validation":evidence,
        "device_tested":False,
        "remaining_original_selectors_and_strings":True,
        "all_license_code_physically_removed":False,
        "note":"Even a rigorous executable diff cannot establish CarPlay behavior; this is an experimental DEB for test.",
    }
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(out,ensure_ascii=False,indent=2)+"\n")
    print(json.dumps({"status":out["status"],"unchanged_payload_files":out["original_payload_files_byte_identical_except_rewritten_binaries"],
        "code_checks":{k:{"methods":v["verified_method_count"],"bytes":v["fully_replaced_original_method_bytes"],
                           "other_code_bytes_unchanged":v["unmodified_executable_bytes_outside_target_functions"]} for k,v in evidence.items()}},ensure_ascii=False,indent=2))

if __name__=="__main__":main()
