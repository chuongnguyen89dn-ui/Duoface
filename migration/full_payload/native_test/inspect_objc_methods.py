#!/usr/bin/env python3
"""Inspect Objective-C method selectors from the original arm64 Mach-O binaries.

Read-only and architecture-aware. No executable bytes or license/device data
are exported. Used to locate the UI-only date/license section accurately.
"""
from __future__ import annotations
import argparse, hashlib, json, pathlib, struct, subprocess, tempfile

def inspect(path: pathlib.Path):
    full=path.read_bytes()
    data=full
    if full[:4] not in (b"\xcf\xfa\xed\xfe",b"\xfe\xed\xfa\xcf"):
        raise ValueError("Expected thin 64-bit Mach-O; do not guess fat slice")
    le=full[:4]==b"\xcf\xfa\xed\xfe"
    if not le:raise ValueError("Not little-endian Mach-O arm64")
    def rd(fmt,offset):
        if offset<0 or offset+struct.calcsize(fmt)>len(data):raise ValueError(f"out of range {offset:#x}")
        return struct.unpack_from(fmt,data,offset)[0]
    ncmds=rd("<I",16)
    segs=[]
    sections={}
    cur=32
    for _ in range(ncmds):
        cmd=rd("<I",cur);sz=rd("<I",cur+4)
        if sz<8 or cur+sz>len(data):raise ValueError("bad load command")
        if cmd==0x19:
            segname=data[cur+8:cur+24].split(b"\0")[0].decode("ascii","replace")
            vm,vs,fo,fs=struct.unpack_from("<QQQQ",data,cur+24)
            segs.append((vm,vs,fo,fs))
            nsects=rd("<I",cur+64)
            for j in range(nsects):
                ent=cur+72+80*j
                if ent+80>cur+sz:break
                name=data[ent:ent+16].split(b"\0")[0].decode("ascii","replace")
                seg=data[ent+16:ent+32].split(b"\0")[0].decode("ascii","replace")
                vmaddr,size=struct.unpack_from("<QQ",data,ent+32)
                off=rd("<I",ent+48)
                sections[(seg,name)]=(vmaddr,size,off)
        cur+=sz
    def off(vm):
        for lo,sz,fo,fs in segs:
            if lo<=vm<lo+fs:return fo+(vm-lo)
        raise ValueError(f"Cannot map vmaddr {vm:#x}")
    def p32(vm):return rd("<I",off(vm))
    def p64(vm):return rd("<Q",off(vm))
    def pi32(vm):return rd("<i",off(vm))
    def pstring(vm):
        if not vm:return ""
        start=off(vm)
        end=data.find(b"\0",start,min(len(data),start+260))
        return data[start:end if end>=0 else start+260].decode("utf-8","replace")
    meta=sections.get(("__DATA","__objc_classlist")) or sections.get(("__DATA_CONST","__objc_classlist"))
    if not meta:
        for (seg,name),t in sections.items():
            if name=="__objc_classlist":meta=t;break
    if not meta:raise ValueError("Missing Objective-C classlist")
    address,length,_=meta
    all_classes={}
    all_count=0
    invalid=0
    for vm in range(address,address+length,8):
        try:
            cls=p64(vm)
            data_pointer=p64(cls+32)&~7
            cname=pstring(p64(data_pointer+24))
            if not cname or len(cname)>90:continue
            entries=[]
            for kind,cl in (("-",cls),("+",p64(cls))):
                methods=p64((p64(cl+32)&~7)+32)
                if not methods:continue
                entsize=p32(methods)
                count=p32(methods+4)
                relative=bool(entsize&0x80000000)
                step=12 if relative else 24
                if count>450:continue
                for j in range(count):
                    entry=methods+8+step*j
                    if relative:
                        reference=entry+pi32(entry)
                        sel=pstring(reference if entsize&0x40000000 else p64(reference))
                    else:
                        sel=pstring(p64(entry))
                    if sel and len(sel)<140:entries.append(kind+sel)
            all_count+=len(entries)
            all_classes[cname]=sorted(set(entries))
        except (ValueError,struct.error):
            invalid+=1
    interest={name:selectors for name,selectors in sorted(all_classes.items()) if any(
      k in name.lower() for k in ("settings","subscription","license","appdelegate","main","home","root")
    )}
    return {
      "sha256":hashlib.sha256(data).hexdigest(),
      "class_count":len(all_classes),
      "method_count":all_count,
      "invalid_class_entries":invalid,
      "classes_of_interest":interest,
      "names_all":sorted(all_classes),
      "binary_modified":False,
    }

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--deb",type=pathlib.Path,required=True)
    ap.add_argument("--out",type=pathlib.Path,required=True)
    a=ap.parse_args()
    assert hashlib.sha256(a.deb.read_bytes()).hexdigest()=="ce971b42230d355421b2b1d99793a1f62ffb75008365ea74a3467d859cc1de3a"
    with tempfile.TemporaryDirectory() as tmp:
        root=pathlib.Path(tmp)/"payload"
        subprocess.run(["dpkg-deb","-x",str(a.deb),str(root)],check=True)
        binaries={
          "DuoFaceUI":root/"var/jb/Applications/DuoFaceUI.app/DuoFaceUI",
          "DuoFaceDashboard":root/"var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib",
        }
        audits={name:inspect(path) for name,path in binaries.items()}
    report={"status":"OBJC_CLASS_METHOD_MAP_READONLY","source_modified":False,"binaries":audits}
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n")
    print(json.dumps({k:{"classes":v["class_count"],"methods":v["method_count"],"candidate_classes":list(v["classes_of_interest"])} for k,v in audits.items()},indent=2))

if __name__=="__main__":main()
