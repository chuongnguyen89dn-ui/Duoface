#!/usr/bin/env python3
"""Read-only map of native9 NSString Activate ARM64 loads to actual functions.

Previous audit established exact CFString objects and 13 static address
references per binary, all outside 291 inert license method spans. This pass
parses Objective-C class/method metadata and LC_FUNCTION_STARTS from the
signed SHA-pinned native9 Mach-O to map each reference to the surrounding
function and, if available, exact class/selector/ABI owner.

This DOES NOT run/patch license logic or infer a UI view was shown. Preserve
class lifecycle, CarPlay screen detection and original native9 DEB.
"""
from __future__ import annotations

import argparse
import bisect
from collections import Counter
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
REFS = ROOT/"audit/payload-migration/NATIVE9_ACTIVATE_REFS_READONLY.json"
LEDGER = ROOT/"dist/payload-migration/native5/DANH_SACH_CHO_XOA.json"
DEB = ROOT/"dist/payload-migration/native9/com.duoface.independent_0.1.0~native9_iphoneos-arm64.deb"
EXPECTED = "e4e1122a494d32af6ec42c97c4288f6effb6716fbb81cb52b81b746280d4d97e"
BINARIES = {
    "DuoFaceUI": "var/jb/Applications/DuoFaceUI.app/DuoFaceUI",
    "DuoFaceDashboard": "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib",
}


class MachObjC:
    def __init__(self, blob: bytes):
        self.blob=blob
        assert blob[:4]==bytes.fromhex("cffaedfe")
        self.sections=[]
        self.segments=[]
        self.starts_info=None
        self.symtab_info=None
        cur=32
        for _ in range(struct.unpack_from("<I",blob,16)[0]):
            cmd,size=struct.unpack_from("<II",blob,cur)
            assert size>=8 and cur+size<=len(blob)
            if cmd==0x19:
                seg=blob[cur+8:cur+24].split(b"\0")[0].decode("ascii","replace")
                vm,vmsize,off,filesize=struct.unpack_from("<QQQQ",blob,cur+24)
                self.segments.append((seg,vm,vmsize,off,filesize))
                count=struct.unpack_from("<I",blob,cur+64)[0]
                for i in range(count):
                    at=cur+72+80*i
                    sec=blob[at:at+16].split(b"\0")[0].decode("ascii","replace")
                    sg=blob[at+16:at+32].split(b"\0")[0].decode("ascii","replace")
                    va,length=struct.unpack_from("<QQ",blob,at+32)
                    fo=struct.unpack_from("<I",blob,at+48)[0]
                    self.sections.append((sg,sec,va,length,fo))
            elif cmd==0x26:
                self.starts_info=struct.unpack_from("<II",blob,cur+8)
            elif cmd==0x2:
                self.symtab_info=struct.unpack_from("<IIII",blob,cur+8)
            cur+=size
        assert self.segments and self.starts_info
        self.function_starts=self.read_function_starts()

    def vm_off(self, vm: int) -> int:
        for _,v,_,fo,filesize in self.segments:
            if v<=vm<v+filesize:
                return fo+vm-v
        raise ValueError(f"Invalid VM pointer {vm:x}")

    def val(self, fmt: str, vm: int) -> int:
        off=self.vm_off(vm)
        return struct.unpack_from(fmt,self.blob,off)[0]

    def name(self, vm: int) -> str:
        if not vm:return ""
        off=self.vm_off(vm)
        stop=self.blob.find(b"\0",off,min(len(self.blob),off+220))
        if stop<off: return ""
        s=self.blob[off:stop].decode("utf-8","replace")
        return s if all(32<=ord(c)<127 for c in s) else ""

    def read_function_starts(self) -> list[int]:
        base=next(v for name,v,_,_,_ in self.segments if name=="__TEXT")
        off,size=self.starts_info
        buf=self.blob[off:off+size]
        result=[]
        cursor=0
        delta_sum=0
        while cursor<len(buf):
            n=0;shift=0
            while cursor<len(buf):
                c=buf[cursor]
                cursor+=1
                n|=(c&0x7f)<<shift
                if c&0x80==0:break
                shift+=7
                assert shift<70
            if n==0:break
            delta_sum+=n
            result.append(base+delta_sum)
        assert len(result)>100
        return result

    def function_symbols(self) -> dict[int,list[str]]:
        if self.symtab_info is None:
            return {}
        symoff,nsyms,stroff,strsize=self.symtab_info
        if symoff+nsyms*16>len(self.blob) or stroff+strsize>len(self.blob):
            return {}
        result={}
        for i in range(nsyms):
            at=symoff+i*16
            strx,kind,section,desc,vm=struct.unpack_from("<IBBHQ",self.blob,at)
            if (kind&0x0e)!=0x0e or not vm or strx>=strsize:
                continue
            a=stroff+strx
            b=self.blob.find(b"\0",a,stroff+strsize)
            if b<0:continue
            name=self.blob[a:b].decode("utf-8","replace")
            if 0<len(name)<=150 and all(32<=ord(c)<127 for c in name):
                result.setdefault(vm,[]).append(name)
        return result

    def all_objc_methods(self) -> tuple[list[dict],list[str]]:
        slots=next((s for s in self.sections if s[1]=="__objc_classlist"),None)
        assert slots
        _,_,vm,size,_=slots
        results=[]
        warnings=[]
        seen=set()
        for addr in range(vm,vm+size,8):
            try:
                cls=self.val("<Q",addr)
                if not cls:continue
                ro=self.val("<Q",cls+32)&~7
                class_name=self.name(self.val("<Q",ro+24))
                if not class_name:continue
                for kind,owner in (("-",cls),("+",self.val("<Q",cls))):
                    owner_ro=self.val("<Q",owner+32)&~7
                    method_list=self.val("<Q",owner_ro+32)
                    if not method_list:continue
                    flags=self.val("<I",method_list)
                    count=self.val("<I",method_list+4)
                    assert count<900
                    relative=bool(flags&0x80000000)
                    stride=12 if relative else 24
                    for idx in range(count):
                        pos=method_list+8+idx*stride
                        if relative:
                            target=pos+self.val("<i",pos)
                            selvm=target if flags&0x40000000 else self.val("<Q",target)
                            sigvm=pos+4+self.val("<i",pos+4)
                            imp=pos+8+self.val("<i",pos+8)
                        else:
                            selvm=self.val("<Q",pos)
                            sigvm=self.val("<Q",pos+8)
                            imp=self.val("<Q",pos+16)
                        selector=self.name(selvm)
                        signature=self.name(sigvm)
                        if not selector or not signature:continue
                        entry={
                            "class":class_name,"kind":kind,
                            "selector":selector,"signature":signature,
                            "imp_vm":imp,
                        }
                        token=(class_name,kind,selector,signature,imp)
                        if token in seen:continue
                        seen.add(token)
                        results.append(entry)
            except (ValueError,struct.error,AssertionError) as e:
                warnings.append(str(e)[:120])
        assert len(results)>250,(len(results),warnings[:10])
        return results,warnings[:12]


def main(out: Path) -> None:
    rawdeb=DEB.read_bytes()
    assert hashlib.sha256(rawdeb).hexdigest()==EXPECTED
    refs=json.loads(REFS.read_text(encoding="utf-8"))
    ledger=json.loads(LEDGER.read_text(encoding="utf-8"))
    assert refs["native9_deb_sha256"]==EXPECTED
    state={
        (m["binary"],m["class"],m["kind"],m["selector"],m["method_type"]):m["state"]
        for m in ledger["all_method_inventory"]
    }
    with tempfile.TemporaryDirectory(prefix="native9-cfstring-owners-") as td:
        folder=Path(td)
        subprocess.run(["dpkg-deb","-x",str(DEB),str(folder)],check=True)
        result={}
        for binary,rel in BINARIES.items():
            original=(folder/rel).read_bytes()
            parser=MachObjC(original)
            methods,warnings=parser.all_objc_methods()
            function_symbols=parser.function_symbols()
            owners={}
            for m in methods:
                owners.setdefault(m["imp_vm"],[]).append(m)
            starts=parser.function_starts
            xrefs=[]
            for obj in refs["results"][binary]["cfstring_object_reference_candidates"]:
                for ref in obj["direct_arm64_address_loads_to_cfstring_object"]:
                    vm=int(ref.get("add_pc_hex",ref.get("ldr_pc_hex",
                           ref.get("adr_pc_hex"))),16)
                    idx=bisect.bisect_right(starts,vm)-1
                    if idx<0: continue
                    start=starts[idx]
                    end=starts[idx+1] if idx+1<len(starts) else start
                    # Methods beginning at the containing LC_FUNCTION_STARTS VM
                    # indicate *one possible* Objective-C caller. Other
                    # compiler helpers/lazy wrappers are separately tagged.
                    funcs=owners.get(start,[])
                    owner_rows=[{
                        "class":m["class"],"kind":m["kind"],
                        "selector":m["selector"],"signature":m["signature"],
                        "native5_ledger_state":state.get((
                            binary,m["class"],m["kind"],m["selector"],
                            m["signature"]), "not_in_license_related_ledger")
                    } for m in funcs]
                    xrefs.append({
                        "pc_vm_hex":hex(vm),
                        "code_file_offset_hex":ref["candidate_code_file_offset_hex"],
                        "function_start_vm_hex":hex(start),
                        "function_end_vm_hex":hex(end),
                        "inside_function_start_interval":start<=vm<end,
                        "source_instruction_kind":ref["kind"],
                        "owners":owner_rows,
                        "symbols_at_function_start":function_symbols.get(start,[])[:12],
                        "symbol_table_function_exact_match":bool(function_symbols.get(start)),
                        "owner_mapping_is_complete":bool(owner_rows),
                        "native4_inert_span":ref["overlaps_native4_neutralized_method_span"],
                    })
            assert len(xrefs)==refs["results"][binary]["cfstring_arm64_reference_heuristics_total"]
            assert len(xrefs)==13,(binary,len(xrefs))
            assert all(not x["native4_inert_span"] for x in xrefs)
            result[binary]={
                "binary_sha256":hashlib.sha256(original).hexdigest(),
                "all_objc_methods_seen":len(methods),
                "function_starts_seen":len(starts),
                "all_named_symbol_addresses_seen":len(function_symbols),
                "callsite_symbols_exact":sum(
                    bool(x["symbols_at_function_start"]) for x in xrefs),
                "warnings":warnings,
                "source_reference_count":len(xrefs),
                "mapped_to_an_objc_owner":sum(bool(x["owners"]) for x in xrefs),
                "unmapped_native_or_helper_function":sum(not x["owners"] for x in xrefs),
                "function_owner_group_counts":dict(Counter(
                    owner["native5_ledger_state"] if row["owners"] else
                    "unnamed_non_objc_or_compiler_function"
                    for row in xrefs
                    for owner in (row["owners"] or [{}])
                )),
                "callsite_candidates":xrefs,
            }
    output={
        "status":"NATIVE9_ACTIVATE_CFSTRING_CODE_OWNER_MAP_STATIC_ONLY",
        "sha256_native9_deb":EXPECTED,
        "inputs":{
            "string_reference_report_sha256":hashlib.sha256(REFS.read_bytes()).hexdigest(),
            "method_ledger_sha256":hashlib.sha256(LEDGER.read_bytes()).hexdigest(),
        },
        "binaries":result,
        "total_cfstring_address_load_candidates":sum(
            x["source_reference_count"] for x in result.values()),
        "not_proven_exclusively_visible_ui":True,
        "not_proven_unused_or_safe_to_mask":True,
        "original_package_modified":False,
        "sileo_changed":False,
        "deb_built":False,
        "limits":[
            "Objective-C method owner is assigned only if its IMP exactly matches LC_FUNCTION_STARTS function boundary",
            "Static ARM64 address loads do not prove runtime code execution, correct xref semantics or view visibility",
            "Unknown helpers, dyld chained fixups, localization lookup and dynamic dispatch require further study",
            "No class or selector may be removed merely because its name contains License",
        ],
    }
    out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(output,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({
        "status":output["status"],
        "total_candidates":output["total_cfstring_address_load_candidates"],
        "summary":{k:{n:v[n] for n in (
            "all_objc_methods_seen","function_starts_seen",
            "source_reference_count","mapped_to_an_objc_owner",
            "unmapped_native_or_helper_function","function_owner_group_counts"
        )} for k,v in result.items()},
        "deb_built":False,"sileo_changed":False},indent=2,ensure_ascii=False))


if __name__=="__main__":
    ap=argparse.ArgumentParser()
    ap.add_argument("--out",type=Path,required=True)
    args=ap.parse_args()
    main(args.out)
