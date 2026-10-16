#!/usr/bin/env python3
"""DuoDash 1.1.3+fullscreen1 reference: locate bubble creation/mount/lifecycle
by complete class method inventory plus bounded ARM64 disassembly.
READONLY. Does not infer actual CarPlay injection runtime from ABI alone.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import plistlib
import re
import subprocess
import struct
import tempfile
from pathlib import Path
from audit_duodash_perf_thermal_113 import NormalizedMachO, fat_slices, PINNED_GIT_BLOB
from audit_native12_carplay_add_app_chain import methods, disassemble

SHA256="ea0d3bb8c8b9da2b45c3f158f390a7966419e84899f820d06f45cd51401fa465"
SELECTOR_RE=re.compile(r"bubble|pane|host|window|view|controller|layout|open|split|init|show|hide|start|stop|connect|attach|scene|root|render|refresh|sync|display|speed|nav|setting|snap|rebuild|mount|toggle|reconcile",re.I)
HINT_RE=re.compile(r"addSubview:|insertSubview:|bringSubviewToFront:|initWithFrame:|CNABBubbleView|paneRect|makeKeyAndVisible|setHidden:|setAlpha:|windowLevel|windowScene|rootViewController|setView:|setFrame:|startSpeedReadout|stopSpeedReadout|bubblePane|bubblePosition|bubble|Bubble|setNeedsLayout|layoutSubviews|shared|carPlay",re.I)

def indirect_stub_symbols(raw):
    """Decode Mach-O LC_SYMTAB + LC_DYSYMTAB and __stubs index. Static names only."""
    ncmds=struct.unpack_from("<I",raw,16)[0]
    pos=32; symtab=None; ind_table=None; stub_sections=[]
    for _ in range(ncmds):
        cmd,size=struct.unpack_from("<II",raw,pos)
        if size<8 or pos+size>len(raw): raise ValueError("invalid MachO load command")
        if cmd==0x2:
            symtab=struct.unpack_from("<IIII",raw,pos+8)
        if cmd==0xb:
            ind_table=struct.unpack_from("<II",raw,pos+56)
        if cmd==0x19:
            sec_count=struct.unpack_from("<I",raw,pos+64)[0]
            for j in range(sec_count):
                off=pos+72+j*80
                if off+80>pos+size:break
                name=raw[off:off+16].split(b"\\0")[0].decode("ascii","replace")
                if name in ("__stubs","__auth_stubs","__objc_stubs"):
                    addr,sz=struct.unpack_from("<QQ",raw,off+32)
                    reserved1,reserved2=struct.unpack_from("<II",raw,off+68)
                    stub_sections.append((name,addr,sz,reserved1,reserved2))
        pos+=size
    if not symtab or not ind_table:return {}
    symoff,nsyms,stroff,strsize=symtab
    indirectoff,nindirect=ind_table
    if symoff+16*nsyms>len(raw) or stroff+strsize>len(raw):return {}
    if indirectoff+4*nindirect>len(raw):return {}
    result={}
    for section,addr,size,first,stride in stub_sections:
        if stride<4 or stride>64:continue
        for k in range(min(size//stride,30000)):
            index=first+k
            if index>=nindirect:break
            symidx=struct.unpack_from("<I",raw,indirectoff+4*index)[0]
            if symidx>=nsyms:continue
            off=struct.unpack_from("<I",raw,symoff+16*symidx)[0]
            if off>=strsize:continue
            end=raw.find(b"\\0",stroff+off,stroff+strsize)
            if end<0:continue
            result[addr+k*stride]=raw[stroff+off:end].decode("utf-8","replace")
    return result

def audit(root):
    dy=root/"var/jb/usr/lib/TweakInject/DuoDash.dylib"
    assert dy.is_file(),dy
    raw=dy.read_bytes()
    slices=fat_slices(raw)
    out={"dylib_sha256":hashlib.sha256(raw).hexdigest(),"plist_filters":[],"architecture":{}}
    for path in sorted((root/"var/jb").rglob("*DuoDash*.plist")):
        try:
            q=plistlib.loads(path.read_bytes())
            out["plist_filters"].append({"path":path.relative_to(root).as_posix(),"filter":q.get("Filter"),"keys":list(q.keys())[:18]})
        except Exception as e:
            out["plist_filters"].append({"path":path.relative_to(root).as_posix(),"error":type(e).__name__})
    for arch,data in slices.items():
        if arch not in ("arm64","arm64e"): continue
        obj=NormalizedMachO(data)
        all_classes=obj.classes()
        stub_symbols=indirect_stub_symbols(data)
        # ARM64 stubs may use dyld chained fixups, so record bounded raw instructions
        # rather than claim symbol identity from an unresolved stub.
        from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
        decoder=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
        selected_stubs={}
        for vm in (0x6d4a0,0x6cdb4,0x6cc94,0x6f5a0,0x71980,0x728c0,
                   0x71c40,0x722a0,0x6fba0,0x721a0,0x720c0,0x720a0,
                   0x729c0,0x72000,0x73840):
            try:
                off=obj.map(vm)
                decoded=[f"{i.address:#x}: {i.mnemonic} {i.op_str}" for i in decoder.disasm(data[off:off+48],vm)]
                selected_stubs[hex(vm)]=decoded
            except Exception as e:
                selected_stubs[hex(vm)]={"error":type(e).__name__}
        selref_probes={}
        for vm in (0xd8bc0,0xd9400,0xd9cf8,0xdac8,0xd9da8,0xd9f40,
                   0xd9ec8,0xd9ec0,0xda108,0xda0c8,0xda4a8):
            try:
                rawv=obj.u64(obj.map(vm))
                candidates=[rawv,rawv & ((1<<48)-1),rawv & ((1<<40)-1),rawv & ((1<<36)-1),rawv & ((1<<32)-1)]
                names={}
                for x in candidates:
                    try:
                        name=obj.cstr(x)
                        if name and len(name)<120:names[hex(x)]=name
                    except Exception:pass
                selref_probes[hex(vm)]={"raw":hex(rawv),"candidate_names":names,
                   "segment_matches":[s["name"] for s in obj.sections
                      if s["vm"]<=vm<s["vm"]+s["size"]]}
            except Exception as e:
                selref_probes[hex(vm)]={"error":str(e)}
        entries={}
        for cl in sorted(all_classes):
            try: catalog=methods(obj,cl)
            except Exception as e:
                entries[cl]={"error":type(e).__name__};continue
            ordered=sorted({int(q["vm"]) for q in catalog.values() if q.get("vm")})
            items={}
            for sel,q in sorted(catalog.items()):
                if not SELECTOR_RE.search(sel): continue
                begin=int(q["vm"]); end=next((v for v in ordered if v>begin),begin+1200)
                asm=disassemble(obj,begin,min(end,begin+(5200 if cl in ("DDz4","DDz1","DDz2") else 1800)))
                annotated=[]
                for line in asm:
                    mm=re.search(r"\\bbl #0x([0-9a-f]+)",line)
                    if mm:
                        symbol=stub_symbols.get(int(mm.group(1),16))
                        if symbol:line+="  ; STUB "+symbol
                    annotated.append(line)
                asm=annotated
                hints=[s for s in asm if ("SEL_OR_LITERAL" in s or "DIRECT_STRING" in s) and HINT_RE.search(s)]
                if not (HINT_RE.search(sel) or hints or cl in ("DDz4","DDz1","DDz2") or (cl=="DDz3" and "Bubble" in sel)): continue
                items[sel]={
                    "imp":hex(begin),"abi":q.get("type"),
                    "refs":hints[:65],
                    "disasm":asm[:1200] if (hints or cl in ("DDz4","DDz1","DDz2","DDz3") or re.search("bubble|pane|host|window|view|controller|split",cl,re.I)) else [],
                }
            entries[cl]={"method_count":len(catalog),"all_methods":sorted(catalog),
                        "interesting":items}
        out["architecture"][arch]={"classes":entries,"total_classes":len(all_classes),"stub_symbol_count":len(stub_symbols),"target_stub_probes":selected_stubs,"selector_ref_probes":selref_probes}
    return out

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--deb",type=Path,required=True)
    ap.add_argument("--out",type=Path,required=True)
    a=ap.parse_args()
    original=a.deb.read_bytes()
    assert hashlib.sha256(original).hexdigest()==SHA256
    assert subprocess.check_output(["git","hash-object",str(a.deb)],text=True).strip()==PINNED_GIT_BLOB
    with tempfile.TemporaryDirectory(prefix="duodash-bubble-owner-chain-") as td:
        subprocess.run(["dpkg-deb","-x",str(a.deb),td],check=True)
        report=audit(Path(td))
    report.update({
      "status":"DUODASH_NAVBUBBLE_MOUNT_STATIC_CHAIN_READONLY",
      "package_sha256":SHA256,
      "git_blob":PINNED_GIT_BLOB,
      "source_variant":"DuoDash 1.1.3+fullscreen1 from DauDat-CarPlay; not proven stock byte-identical",
      "runtime_visible_on_carplay_tested":False,
      "modified_deb":False,
      "sileo_touched":False,
      "scope":"static class-method references and bounded instructions, not definitive ObjC control flow",
    })
    assert report["architecture"].get("arm64",{}).get("total_classes",0)>=35
    assert "CNABBubbleView" in report["architecture"]["arm64"]["classes"]
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
    print("DUODASH_NAVBUBBLE_MOUNT_STATIC_CHAIN_READONLY_PASS")
    print("INJECTION_FILTERS",report["plist_filters"])
    for cl,details in report["architecture"]["arm64"]["classes"].items():
        interesting=details.get("interesting",{})
        if interesting or "CNAB" in cl:
            print("CLASS",cl,"METHODS",details.get("method_count"),
                  "INTERESTING",list(interesting)[:35])
    print("NO_DEB_NO_DEVICE_TEST")

if __name__=="__main__":main()
