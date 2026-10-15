#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Map real executable Objective-C license functions in *native3* (read-only).

Before deleting compiled code, locate the class/selector, signed method type,
IMP, function-start boundary, and actual machine-code bytes for each ARM64
slice. Never infer safe deletion merely because selector contains 'license'.
"""
from __future__ import annotations
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
import tempfile

DEB_SHA="7040338f37ebb1d1d2bee5adffd9cc0558b595b1ebcb9283169ab8d7f71bf2df"
BINARIES={
    "DuoFaceUI":"var/jb/Applications/DuoFaceUI.app/DuoFaceUI",
    "DuoFaceDashboard":"var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib",
}
OWNER_RE=re.compile(r"licens|subscription|expir|trial|entitlement",re.I)
METHOD_RE=re.compile(r"licens|subscription|expir|trial|entitlement|^openSubscriptionScreen$|^checkAndPresentLicenseModalIfNeeded$",re.I)
# Do not remove generic lifecycle handlers solely by class name.
PRESERVE={"init","dealloc","class","description","copy","hash","isEqual:","viewDidLoad","viewWillAppear:",
          "viewDidAppear:","viewWillDisappear:","viewDidDisappear:","loadView","tableView:numberOfRowsInSection:",
          "tableView:cellForRowAtIndexPath:","tableView:didSelectRowAtIndexPath:"}

def digest(x:bytes)->str:return hashlib.sha256(x).hexdigest()
def slurp_slices(original:bytes):
    magic=original[:4]
    if magic in (bytes.fromhex("cafebabe"),bytes.fromhex("cafebabf")):
        wide=magic==bytes.fromhex("cafebabf")
        count=struct.unpack_from(">I",original,4)[0]
        assert 1<=count<=12
        for i in range(count):
            pos=8+i*(32 if wide else 20)
            cpu,sub=struct.unpack_from(">II",original,pos)
            off,size=struct.unpack_from(">QQ" if wide else ">II",original,pos+8)
            assert off>0 and size>50000 and off+size<=len(original)
            if cpu==0x0100000c:
                yield {"arch":f"arm64:{sub:x}","file_offset":off,"size":size,
                       "bytes":original[off:off+size]}
    else:
        cpu,sub=struct.unpack_from("<II",original,4)
        assert cpu==0x0100000c
        yield {"arch":f"arm64:{sub:x}","file_offset":0,"size":len(original),"bytes":original}

def inspect(part:bytes):
    assert part[:4]==bytes.fromhex("cffaedfe")
    def read(fmt,offset):
        if offset<0 or offset+struct.calcsize(fmt)>len(part):raise ValueError(f"out of slice {offset:x}")
        return struct.unpack_from(fmt,part,offset)[0]
    segments=[];sections={};starts_loc=None
    at=32
    for _ in range(read("<I",16)):
        cmd,size=struct.unpack_from("<II",part,at)
        assert size>=8 and at+size<=len(part)
        if cmd==0x19:
            name=part[at+8:at+24].split(b"\0")[0].decode("ascii","replace")
            vm,vs,fo,fs=struct.unpack_from("<QQQQ",part,at+24)
            segments.append({"seg":name,"vm":vm,"vmsize":vs,"file":fo,"filesize":fs})
            for n in range(read("<I",at+64)):
                q=at+72+n*80
                assert q+80<=at+size
                sn=part[q:q+16].split(b"\0")[0].decode("ascii","replace")
                sg=part[q+16:q+32].split(b"\0")[0].decode("ascii","replace")
                va,ln=struct.unpack_from("<QQ",part,q+32)
                offset=read("<I",q+48)
                sections[(sg,sn)]={"vm":va,"size":ln,"file":offset}
        if cmd==0x26:
            starts_loc=struct.unpack_from("<II",part,at+8)
        at+=size
    assert segments and starts_loc and len(segments)>1
    def vm_to_off(vm):
        for s in segments:
            if s["vm"]<=vm<s["vm"]+s["filesize"]:
                return s["file"]+(vm-s["vm"])
        raise ValueError(f"unmapped pointer vm {vm:x}")
    def rdvm(fmt,vm):return read(fmt,vm_to_off(vm))
    def cstring(vm):
        if not vm:return ""
        p=vm_to_off(vm)
        hi=part.find(b"\0",p,min(len(part),p+400))
        return part[p:hi if hi!=-1 else min(len(part),p+400)].decode("utf-8","replace")
    meta=next((v for (sg,sn),v in sections.items() if sn=="__objc_classlist"),None)
    assert meta
    textsec=next((v for (sg,sn),v in sections.items() if sg in ("__TEXT","__TEXT_EXEC") and sn=="__text"),None)
    assert textsec
    # LC_FUNCTION_STARTS offsets are ULEB128 deltas from start of __TEXT segment.
    base=next(s["vm"] for s in segments if s["seg"]=="__TEXT")
    startoff,startlen=starts_loc
    block=part[startoff:startoff+startlen]
    funstarts=[];i=0;delta_total=0
    while i<len(block):
        n=0;bits=0
        while True:
            byte=block[i];i+=1
            n|=(byte&0x7f)<<bits
            if byte&0x80==0:break
            bits+=7
            assert bits<70 and i<len(block)
        if n==0:break
        delta_total+=n
        funstarts.append(base+delta_total)
    starts_set=set(funstarts)
    all_methods=[];warnings=[]
    for clsaddr in range(meta["vm"],meta["vm"]+meta["size"],8):
        try:
            cls=rdvm("<Q",clsaddr)
            ro=rdvm("<Q",cls+32)&~7
            owner=cstring(rdvm("<Q",ro+24))
            if not owner or len(owner)>130:continue
            for kind,which in (("-",cls),("+",rdvm("<Q",cls))):
                method_list=rdvm("<Q",(rdvm("<Q",which+32)&~7)+32)
                if not method_list:continue
                flags=rdvm("<I",method_list)
                count=rdvm("<I",method_list+4)
                relative=bool(flags&0x80000000)
                if count>1000:raise ValueError("class too large")
                stride=12 if relative else 24
                for n in range(count):
                    pos=method_list+8+n*stride
                    if relative:
                        selector_pointer=pos+rdvm("<i",pos)
                        sel=cstring(selector_pointer if flags&0x40000000 else rdvm("<Q",selector_pointer))
                        type_str=cstring(pos+4+rdvm("<i",pos+4))
                        imp=pos+8+rdvm("<i",pos+8)
                    else:
                        sel=cstring(rdvm("<Q",pos))
                        type_str=cstring(rdvm("<Q",pos+8))
                        imp=rdvm("<Q",pos+16)
                    if not sel or not type_str:continue
                    related=bool(METHOD_RE.search(sel) or OWNER_RE.search(owner))
                    if not related:continue
                    insidemethod=textsec["vm"]<=imp<textsec["vm"]+textsec["size"]
                    entry={
                       "class":owner,"selector":sel,"kind":kind,
                       "type_encoding":type_str[:120],"return_type":type_str[:1],
                       "imp_vm":hex(imp),"imp_file_offset":hex(vm_to_off(imp)) if insidemethod else None,
                       "method_metadata_vm":hex(pos),
                       "license_name_match":bool(METHOD_RE.search(sel)),
                       "license_class_match":bool(OWNER_RE.search(owner)),
                       "preserve_core_or_lifecycle":sel in PRESERVE,
                       "inside_executable_text":insidemethod,
                       "listed_in_lc_function_starts":imp in starts_set,
                    }
                    if insidemethod:
                        ends=[v for v in funstarts if v>imp]
                        stop=min(ends) if ends else textsec["vm"]+textsec["size"]
                        stop=min(stop,textsec["vm"]+textsec["size"])
                        entry["estimated_function_span"]=stop-imp
                        entry["first_32_instruction_bytes_sha256"]=digest(part[vm_to_off(imp):vm_to_off(imp)+32])
                        entry["function_span_guess_only"]=imp not in starts_set
                    all_methods.append(entry)
        except (ValueError,struct.error) as ex:
            warnings.append(str(ex)[:140])
    return {
      "sha256":digest(part),"slice_bytes":len(part),
      "function_starts_count":len(funstarts),
      "text_section_vm":hex(textsec["vm"]),"text_section_bytes":textsec["size"],
      "license_named_methods":all_methods,
      "method_count_license_related":len(all_methods),
      "methods_without_safe_text_start":[f'{v["class"]}.{v["selector"]}' for v in all_methods
              if not v["inside_executable_text"] or not v["listed_in_lc_function_starts"]],
      "parser_warnings":warnings[:15],
    }

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--deb",type=Path,required=True)
    ap.add_argument("--out",type=Path,required=True)
    a=ap.parse_args()
    assert digest(a.deb.read_bytes())==DEB_SHA,"Do not analyze wrong native3 binary"
    with tempfile.TemporaryDirectory() as d:
        dest=Path(d)
        subprocess.run(["dpkg-deb","-x",str(a.deb),str(dest)],check=True)
        reports={}
        for name,p in BINARIES.items():
            content=(dest/p).read_bytes()
            slices=list(slurp_slices(content))
            assert slices,f"No ARM64 slice {name}"
            reports[name]={
              "full_sha256":digest(content),
              "slices":{sl["arch"]:inspect(sl["bytes"]) for sl in slices},
            }
    data={"status":"NATIVE4_READONLY_LICENSE_FUNCTION_INVENTORY",
          "source_native3_sha256":DEB_SHA,
          "binaries":reports,
          "code_modified":False,"safe_to_remove_every_license_method":False,
          "next":"Classify IMP boundaries and dynamic callers before stripping embedded code; preserve original UI and CarPlay."}
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(data,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    for name,b in reports.items():
        for arch,s in b["slices"].items():
            grouped={}
            for m in s["license_named_methods"]:
                grouped.setdefault(m["class"],[]).append(m["selector"])
            print(json.dumps({"binary":name,"arch":arch,"related_methods":len(s["license_named_methods"]),
                "classes":grouped,"not_at_function_start":s["methods_without_safe_text_start"][:20]},ensure_ascii=False))
if __name__=="__main__":main()
