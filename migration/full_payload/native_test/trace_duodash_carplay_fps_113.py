#!/usr/bin/env python3
"""Read-only native stub resolution + fps/perf key diagnostic for archived DuoDash.

No executable patch, install or Sileo change. This source is not a verified
binary-equivalent of the user's historical 1.1.3 repack. Printed method and
callsite names are hypotheses until instruction-level call semantics checked.
"""
import argparse,hashlib,json,re,struct,subprocess,tempfile
from pathlib import Path
from audit_duodash_perf_thermal_113 import (
    NormalizedMachO,fat_slices,text_disassembly,collect_vm_literals,
    relevant_xrefs,sha256,PINNED_GIT_BLOB,
)

WATCH=("perf_tweak_enabled","com.sensetechlab.carplay/fps",
       "maxFPS","encoderFPSFixed","settings.changed",
       "preferredFramesPerSecond","preferredFrameRateRange")
WINDOWS=[(0x4b4c8,0x4b710),(0x4b710,0x4c200)]
def parse_commands(data):
    n=struct.unpack_from("<I",data,16)[0]
    pos=32
    stub_sections=[]
    symbol_info=None
    indirect=None
    for _ in range(n):
        cmd,size=struct.unpack_from("<II",data,pos)
        assert size>=8 and pos+size<=len(data)
        if cmd==0x2: # LC_SYMTAB
            symbol_info=struct.unpack_from("<4I",data,pos+8)
        if cmd==0xb: # LC_DYSYMTAB
            indirect=struct.unpack_from("<2I",data,pos+8+12*4)
        if cmd==0x19:
            count=struct.unpack_from("<I",data,pos+64)[0]
            for i in range(count):
                at=pos+72+i*80
                section=data[at:at+16].split(b'\0')[0].decode("utf8","replace")
                segment=data[at+16:at+32].split(b'\0')[0].decode("utf8","replace")
                address,nbytes=struct.unpack_from("<QQ",data,at+32)
                foff=struct.unpack_from("<I",data,at+48)[0]
                res1,res2=struct.unpack_from("<II",data,at+68)
                if section in ("__stubs","__cfstring","__cstring","__objc_selrefs","__got","__la_symbol_ptr"):
                    stub_sections.append({"name":section,"segment":segment,"address":address,
                                          "size":nbytes,"file_offset":foff,"reserved1":res1,"reserved2":res2})
        pos+=size
    return symbol_info,indirect,stub_sections

def resolve_import_stubs(data):
    symtab,dysym,sections=parse_commands(data)
    summary={"symbol_count":0,"indirect_count":0,"stubs":{},"sections":sections,
             "imported_symbol_excerpt":[]}
    if not symtab or not dysym:return summary
    symoff,nsyms,stroff,strsize=symtab
    indexoff,nindirect=dysym
    assert symoff+nsyms*16<=len(data)
    assert stroff+strsize<=len(data)
    assert indexoff+nindirect*4<=len(data)
    symnames=[]
    for i in range(nsyms):
        strx,typ,section,desc,value=struct.unpack_from("<IBBHQ",data,symoff+i*16)
        if strx>=strsize: symnames.append("<unknown>");continue
        b=data[stroff+strx:stroff+strsize]
        symnames.append(b[:b.index(b'\0')].decode("utf8","replace") if b'\0' in b else "<missing>")
    ind=struct.unpack_from("<"+"I"*nindirect,data,indexoff)
    summary["symbol_count"]=nsyms
    summary["indirect_count"]=nindirect
    for sec in sections:
        if sec["name"]=="__stubs":
            chunk=sec["reserved2"]
            if not chunk:continue
            for j in range(sec["size"]//chunk):
                idx=sec["reserved1"]+j
                if idx>=len(ind):break
                sym_idx=ind[idx]
                if sym_idx>=len(symnames):continue
                summary["stubs"][hex(sec["address"]+j*chunk)]=symnames[sym_idx]
    summary["imported_symbol_excerpt"]=[x for x in symnames if
        any(y in x.lower() for y in ("notify_","cfpreference","carplay","fps",
                  "thermal","frame","encoder","display","sysctl","os_log"))][:180]
    return summary

def nearby_names(m, raw, key, before=20, after=30):
    source=[]
    for sec in m.sections:
        if sec["name"]!="__cstring":continue
        data=raw[sec["fileoff"]:sec["fileoff"]+sec["size"]]
        for mo in re.finditer(rb"[\x20-\x7e]{3,}\x00",data):
            txt=mo.group()[:-1].decode("ascii","replace")
            source.append({"vm":hex(sec["vm"]+mo.start()),"name":txt})
    ids=[i for i,z in enumerate(source) if key.lower() in z["name"].lower()]
    return [{"hit_index":i,"neighbors":source[max(0,i-before):i+after]} for i in ids[:15]]

def codewindows(m, raw, stubs):
    rows=text_disassembly(m,raw)
    output={}
    for begin,end in WINDOWS:
        output[f"{begin:#x}..{end:#x}"]=[]
        for z in rows:
            if not begin<=z["at"]<end:continue
            label=""
            if z["m"] in ("bl","b"):
                q=re.match(r"#(0x[0-9a-f]+)",z["o"])
                if q: label=stubs.get(hex(int(q.group(1),16)),"")
            output[f"{begin:#x}..{end:#x}"].append(
                "%#x: %s %s%s"%(z["at"],z["m"],z["o"],
                                "  ; IMPORT "+label if label else ""))
    return output

def any_raw_ptr_refs(m, raw, string_addr):
    """For relevant string, print direct or rebased offset pointers in nontext,
    including 4-byte chained fixup lower-32 references."""
    out=[]
    for sec in m.sections:
        if sec["name"] in ("__cstring","__text"):continue
        b=raw[sec["fileoff"]:sec["fileoff"]+sec["size"]]
        candidates=(struct.pack("<I",string_addr & 0xffffffff),
                    struct.pack("<Q",string_addr),struct.pack("<Q",string_addr | 0x1000000000000))
        for needle in candidates:
            off=0;steps=0
            while True:
                loc=b.find(needle,off)
                if loc<0:break
                out.append({"section":sec["name"],"vm":hex(sec["vm"]+loc),
                            "width":len(needle),"candidate_hex":needle.hex()})
                off=loc+max(1,len(needle));steps+=1
                if steps>=80:break
    return out[:120]

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--deb",type=Path,required=True)
    p.add_argument("--out",type=Path,required=True)
    args=p.parse_args()
    assert subprocess.check_output(["git","hash-object",str(args.deb)],text=True).strip()==PINNED_GIT_BLOB
    with tempfile.TemporaryDirectory(prefix="duodash-fps-xref-") as t:
        root=Path(t)
        subprocess.run(["dpkg-deb","-x",str(args.deb),t],check=True)
        filepath=root/"var/jb/usr/lib/TweakInject/DuoDash.dylib"
        original=filepath.read_bytes()
        outcome={}
        for arch,raw in fat_slices(original).items():
            if arch not in ("arm64","arm64e"):continue
            m=NormalizedMachO(raw)
            syms=resolve_import_stubs(raw)
            liter=collect_vm_literals(m,raw)
            names={item:nearby_names(m,raw,item) for item in WATCH}
            pointers={}
            for item in WATCH:
                for vm,s in liter.items():
                    if s==item:
                        pointers[item]=any_raw_ptr_refs(m,raw,vm)
                        break
            # A CFString literal in __DATA,__cfstring usually contains the
            # cstring VM at structure+0x10. Pointer fixups may carry only the
            # low 32-bit VM offset in this on-disk archived artifact.
            targets={}
            for term,refs in pointers.items():
                for ptr in refs:
                    if ptr["section"]=="__cfstring":
                        targets[int(ptr["vm"],16)-16]="CFSTRING:"+term
            rows=text_disassembly(m,raw)
            direct_perf_cfstring_sites=relevant_xrefs(rows,targets,220)
            for site in direct_perf_cfstring_sites:
                site["nearby_disassembly"]=[
                    ("%s  ; CALL %s"%(line,syms["stubs"].get(hex(int(line.split("bl #",1)[1].split()[0],16)),"")))
                    if "bl #0x" in line and
                       re.search(r"bl #0x[0-9a-f]+",line) else line
                    for line in site["nearby_disassembly"]
                ]
            outcome[arch]={
               "sha256":sha256(raw),
               "performance_cfstring_code_xrefs":direct_perf_cfstring_sites,
               "indirect_imports":syms,
               "nearby_string_tables":names,
               "direct_string_pointer_candidates":pointers,
               "selected_fps_code_disassembly":codewindows(m,raw,syms["stubs"]),
            }
    data={"status":"DUODASH_FPS_ARCHIVED_DEB_INSTRUMENTED_STATIC_TRACE",
          "original_user_stock_repack_identical":False,
          "native12_touched":False,"deb_mutated":False,"runtime_tested":False,
          "source_git_blob":PINNED_GIT_BLOB,
          "source_package_sha256":sha256(args.deb.read_bytes()),
          "arch_data":outcome}
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(data,ensure_ascii=False,indent=2)+"\n")
    for arch,d in outcome.items():
        print("ARCH",arch,"STUB_IMPORTS",d["indirect_imports"]["imported_symbol_excerpt"])
        print("FPS_CODE_4B4C8_4B710",d["selected_fps_code_disassembly"].get("0x4b4c8..0x4b710",[])[:170])
        for s in WATCH[:4]:
            print("STRING_CONTEXT",s,d["nearby_string_tables"][s][:2])
            print("DATA_PTRS",s,d["direct_string_pointer_candidates"].get(s,[])[:15])
    print("DUODASH_FPS_STUBS_AND_STRING_TABLE_READONLY_COMPLETE")

if __name__=="__main__":main()
