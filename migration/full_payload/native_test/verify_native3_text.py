#!/usr/bin/env python3
"""Verify original executable instructions remain identical in native3.

Rebranding changes only same-width user-facing strings and re-signs Mach-O.
This test hashes every __TEXT,__text section before and after, across slices.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import tempfile

SOURCE_NATIVE2="0d48d13e4c5965f8d787d86fa4c7776145cd843e98e7cae0b516779271264e60"
NATIVE2="dist/payload-migration/native2/com.duoface.independent_0.1.0~native2_iphoneos-arm64.deb"
NATIVE3="dist/payload-migration/native3/com.duoface.independent_0.1.0~native3_iphoneos-arm64.deb"
PATHS=[
    "var/jb/Applications/DuoFaceUI.app/DuoFaceUI",
    "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib",
    "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib",
]
def sha(x:bytes):return hashlib.sha256(x).hexdigest()
def slices(blob):
    magic=blob[:4]
    if magic in (bytes.fromhex("cafebabe"),bytes.fromhex("cafebabf")):
        count=struct.unpack_from(">I",blob,4)[0]
        wide=(magic==bytes.fromhex("cafebabf"))
        assert 1<=count<=8
        for i in range(count):
            pos=8+i*(32 if wide else 20)
            cpu,sub=struct.unpack_from(">II",blob,pos)
            off,size=struct.unpack_from(">QQ" if wide else ">II",blob,pos+8)
            assert off+size<=len(blob)
            yield f"{cpu:x}/{sub:x}",blob[off:off+size]
    else:
        cpu,sub=struct.unpack_from("<II",blob,4)
        yield f"{cpu:x}/{sub:x}",blob

def text_sections(blob:bytes):
    report={}
    for ident,part in slices(blob):
        assert part[:4]==bytes.fromhex("cffaedfe"),"Expected little endian 64-bit MachO"
        ncmds=struct.unpack_from("<I",part,16)[0]
        cursor=32
        for _ in range(ncmds):
            cmd,size=struct.unpack_from("<II",part,cursor)
            assert size>=8 and cursor+size<=len(part)
            if cmd==0x19:
                nsects=struct.unpack_from("<I",part,cursor+64)[0]
                for j in range(nsects):
                    section=cursor+72+j*80
                    assert section+80<=cursor+size
                    secname=part[section:section+16].split(b"\0")[0].decode("ascii")
                    segname=part[section+16:section+32].split(b"\0")[0].decode("ascii")
                    length=struct.unpack_from("<Q",part,section+40)[0]
                    file_offset=struct.unpack_from("<I",part,section+48)[0]
                    if secname=="__text" and segname in ("__TEXT","__TEXT_EXEC"):
                        assert length>512 and file_offset+length<=len(part)
                        report[f"{ident}:{segname}/{secname}"]={
                            "sha256":sha(part[file_offset:file_offset+length]),"size":length,
                        }
            cursor+=size
    assert report,"No MachO instruction segments"
    return report

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--report",required=True,type=Path)
    args=ap.parse_args()
    source=Path(NATIVE2);current=Path(NATIVE3)
    assert sha(source.read_bytes())==SOURCE_NATIVE2
    with tempfile.TemporaryDirectory() as d:
        before=Path(d)/"native2"
        after=Path(d)/"native3"
        subprocess.run(["dpkg-deb","-x",str(source),str(before)],check=True)
        subprocess.run(["dpkg-deb","-x",str(current),str(after)],check=True)
        originals={}
        for p in PATHS:
            orig=(before/p).read_bytes()
            revised=(after/p).read_bytes()
            old_sections=text_sections(orig)
            new_sections=text_sections(revised)
            assert old_sections==new_sections,f"Compiled executable instruction changed: {p}"
            originals[p]={"old_sha256":sha(orig),"new_sha256":sha(revised),
                          "old_file_bytes":len(orig),"new_file_bytes":len(revised),
                          "instruction_sections":old_sections}
        # The native2 runtime adapter and all original branding/images must
        # remain byte-identical. The build report enumerates intended changes.
        baseline_paths={}
        for p in before.rglob("*"):
            if p.is_file() and not p.is_symlink():
                baseline_paths[p.relative_to(before).as_posix()]=sha(p.read_bytes())
        current_paths={}
        for p in after.rglob("*"):
            if p.is_file() and not p.is_symlink():
                current_paths[p.relative_to(after).as_posix()]=sha(p.read_bytes())
        assert baseline_paths.keys()==current_paths.keys()
        diffs=sorted(k for k in baseline_paths if baseline_paths[k]!=current_paths[k])
        assert diffs==sorted(PATHS),diffs
    result={
       "status":"NATIVE3_MACHO_INSTRUCTIONS_IDENTICAL_AND_ALL_OTHER_DATA_FILES_BYTE_IDENTICAL",
       "changed_macho_files":originals,
       "unchanged_other_payload_file_count":len(baseline_paths)-len(PATHS),
       "instruction_sections_byte_identical":True,
       "device_tested":False,
       "note":"Byte-identical instructions do not prove unchanged runtime behavior where display strings are accessed; test real CarPlay.",
    }
    args.report.parent.mkdir(parents=True,exist_ok=True)
    args.report.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print("NATIVE3_BYTE_IDENTICAL_MACHINE_INSTRUCTIONS_PASS",len(originals),
          "unchanged other files",result["unchanged_other_payload_file_count"])
if __name__=="__main__":main()
