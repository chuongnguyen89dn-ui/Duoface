#!/usr/bin/env python3
"""Read-only native1.0.4 Mach-O layout evidence (never execute package binaries)."""
import hashlib
import io
import json
import re
import shutil
import struct
import subprocess
import tarfile
import tempfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]
DEB=ROOT/"dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb"
OUT=ROOT/"sideplay/native104-geometry/audit/original104-geometry-methods.json"
EXPECTED="f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd"
WANTED=[
"carPlayScreenBounds","carPlayContentInsets","carPlayUsableBounds",
"resizeWindows","layoutSplitViews","handleDividerPan:isVertical:state:",
"setSplitRatio:","splitRatio","layoutSubviews","updateBoundsSize",
"carPlayUIScreen","carPlayCADisplay","carPlayScreenScale",
"receivedMetricsUpdatedNotification:","switchToSplitWithLeft:right:ratio:",
]
def sha(data):
    return hashlib.sha256(data).hexdigest()
def grab_binary(path):
    tarbytes=subprocess.run(["dpkg-deb","--fsys-tarfile",str(path)],
        check=True,capture_output=True).stdout
    matches=[]
    with tarfile.open(fileobj=io.BytesIO(tarbytes),mode="r:") as tf:
        for item in tf.getmembers():
            if item.isfile() and item.name.endswith("/DuoNaviDashboard.dylib"):
                matches.append((item.name,tf.extractfile(item).read()))
    if len(matches)!=1:
        raise ValueError("Expected exactly one DuoNaviDashboard.dylib; found "+str([x[0] for x in matches]))
    return matches[0]
def thin_arm64(data):
    magic=struct.unpack_from(">I",data)[0]
    if magic in (0xcafebabe,0xcafebabf):
        n=struct.unpack_from(">I",data,4)[0]
        size=32 if magic==0xcafebabf else 20
        for i in range(min(n,64)):
            off=8+i*size
            if size==32:
                cpu,subcpu,start,count,align,reserved=struct.unpack_from(">IIQQII",data,off)
            else:
                cpu,subcpu,start,count,align=struct.unpack_from(">IIIII",data,off)
            if cpu==0x100000c and (subcpu&0x00ffffff)==0:
                assert start+count<=len(data)
                return data[start:start+count],{"fat":True,"cpu":cpu,"subcpu":subcpu,"offset":start}
        raise ValueError("No arm64 slice")
    if data.startswith(b"\xcf\xfa\xed\xfe"):
        cpu,subcpu=struct.unpack_from("<II",data,4)
        if cpu!=0x100000c: raise ValueError("Not arm64 MachO")
        return data,{"fat":False,"cpu":cpu,"subcpu":subcpu,"offset":0}
    raise ValueError("Not MachO")
def run(tool,opts,path):
    p=subprocess.run([tool,*opts,str(path)],capture_output=True,text=True,errors="replace")
    return {"exit":p.returncode,"stdout":p.stdout,"stderr":p.stderr[:2000]}
def method_entries(meta):
    lines=meta.splitlines()
    entries=[]
    for i,ln in enumerate(lines):
        if re.search(r"\bname\s+0x[0-9a-fA-F]+\s+",ln):
            wanted=next((x for x in WANTED if re.search(r"\b"+re.escape(x)+r"\s*$",ln)),None)
            if wanted:
                chunk=lines[i:min(i+6,len(lines))]
                imp=None
                for line in chunk[1:]:
                    m=re.search(r"\bimp\s+0x([0-9a-fA-F]+)",line)
                    if m:
                        imp=int(m.group(1),16)
                        break
                entries.append({"name":wanted,"imp":hex(imp) if imp is not None else None,"meta_excerpt":chunk[:4]})
    return entries
def main():
    if not DEB.exists(): raise SystemExit("Original1.0.4 DEB missing")
    actual=sha(DEB.read_bytes())
    if actual!=EXPECTED: raise SystemExit(f"Original DEB hash mismatch {actual} != {EXPECTED}")
    member,binary=grab_binary(DEB)
    arm,info=thin_arm64(binary)
    llvm=next((shutil.which(x) for x in
        ("llvm-objdump","llvm-objdump-22","llvm-objdump-21","llvm-objdump-20",
         "llvm-objdump-19","llvm-objdump-18","llvm-objdump-17","llvm-objdump-16",
         "llvm-objdump-15","llvm-objdump-14") if shutil.which(x)),None)
    if not llvm: raise SystemExit("llvm-objdump missing")
    with tempfile.TemporaryDirectory() as td:
        path=Path(td)/"Native104-Dashboard-arm64"
        path.write_bytes(arm)
        meta=run(llvm,["--macho","--objc-meta-data"],path)
        if meta["exit"]!=0: raise ValueError("metadata failed "+meta["stderr"])
        entries=method_entries(meta["stdout"])
        for x in entries:
            if not x["imp"]: continue
            imp=int(x["imp"],16)
            out=run(llvm,["--macho","--disassemble",
                          "--start-address="+hex(imp),
                          "--stop-address="+hex(imp+0x280)],path)
            x["disasm_exit"]=out["exit"]
            x["disasm"]=out["stdout"][:18000]
            x["disasm_error"]=out["stderr"][:600]
        report={
          "kind":"STATIC ORIGINAL DUONAVI104 GEOMETRY REFERENCE; NOT SOURCE",
          "original_deb_sha256":actual,"dashboard_member":member,
          "dashboard_bytes":len(binary),"dashboard_sha256":sha(binary),
          "arm64_slice_bytes":len(arm),"arm64_slice_sha256":sha(arm),
          "arch_info":info,"llvm":llvm,"metadata_lines":len(meta["stdout"].splitlines()),
          "entries":entries,"wanted":WANTED,
          "method_class_mapping_not_yet_confirmed":True,
          "runtime_verified":False,"license_code_copied":False}
        OUT.parent.mkdir(parents=True,exist_ok=True)
        OUT.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
        print(json.dumps({"dashboard":member,"deb_hash":actual,"dashboard_hash":sha(binary),
                         "slice_bytes":len(arm),"metadata_lines":report["metadata_lines"],
                         "found":[{"name":e["name"],"imp":e["imp"],"exit":e.get("disasm_exit"),
                                   "bytes":len(e.get("disasm",""))} for e in entries]},ensure_ascii=False,indent=2))
if __name__=="__main__":main()
