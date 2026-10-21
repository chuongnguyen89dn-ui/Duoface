#!/usr/bin/env python3
"""SHA-pinned, read-only original Native12 ARM64 double constants.
Addresses come from verified 0x103ee0 original divider-pan disassembly.
Never execute or transplant original vendor binaries.
"""
import argparse, hashlib, json, pathlib, struct
EXPECTED_SHA="9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
# From 103fd8/103fe8 clamp; 104078 snap tolerance; 104068/1040b0 snap offset.
ADDRS={"drag_min":0x30fb18, "drag_max":0x30fb20,
       "snap_threshold":0x3116c8, "snap_offset_a":0x3124b8,
       "snap_offset_b":0x3124c0}
def main():
    p=argparse.ArgumentParser()
    p.add_argument("--macho",required=True,type=pathlib.Path)
    p.add_argument("--out",required=True,type=pathlib.Path)
    a=p.parse_args()
    data=a.macho.read_bytes()
    sha=hashlib.sha256(data).hexdigest()
    if sha!=EXPECTED_SHA:raise ValueError("Native12 dashboard immutable binary SHA mismatch")
    if len(data)<32 or struct.unpack_from("<I",data,0)[0]!=0xfeedfacf:
        raise ValueError("Expected little-endian 64-bit Mach-O")
    ncmds=struct.unpack_from("<I",data,16)[0]
    off=32;segments=[]
    for _ in range(ncmds):
        cmd,size=struct.unpack_from("<II",data,off)
        if size<8 or off+size>len(data):raise ValueError("Bad Mach-O load command")
        if cmd==0x19:
            if size<72:raise ValueError("Bad LC_SEGMENT_64")
            name,vmaddr,vmsize,fileoff,filesize=struct.unpack_from("<16sQQQQ",data,off+8)
            segments.append((name.rstrip(b"\\0").decode("ascii"),vmaddr,vmsize,fileoff,filesize))
        off+=size
    constants={}
    for name,addr in ADDRS.items():
        matches=[(label,fileoff+addr-vmaddr) for label,vmaddr,vmsize,fileoff,filesize in segments
                 if vmaddr<=addr and addr+8<=vmaddr+min(vmsize,filesize)]
        if len(matches)!=1:raise ValueError(f"Address mapping ambiguous: {name} {addr:#x} {matches}")
        segment,index=matches[0]
        if index+8>len(data):raise ValueError("File offset beyond binary")
        raw=data[index:index+8]
        value=struct.unpack("<d",raw)[0]
        constants[name]={"address":hex(addr),"segment":segment,"file_offset":index,
                         "raw_hex":raw.hex(),"double":value}
    mn=constants["drag_min"]["double"];mx=constants["drag_max"]["double"]
    tol=constants["snap_threshold"]["double"]
    if not (0<=mn<.5<mx<=1 and 0<tol<.3):
        raise ValueError(f"Decoded constants not plausible, analyze before code change: {mn} {mx} {tol}")
    result={"evidence":"ORIGINAL_NATIVE12_IMMUTABLE_MACHO_VALUE_NOT_RUNTIME",
            "macho_sha256":sha,"source_method":"CBBridgedSplitApp.handleDividerPan:isVertical:state:",
            "source_imp":"0x103ee0","constants":constants,
            "confidence":"DOUBLE_VALUES_FROM_VM_MAPPING;BRANCH_SEMANTICS_REQUIRE_REVIEW",
            "compiled_new_layout_patched":False,"runtime_parity_proven":False}
    a.out.mkdir(parents=True,exist_ok=True)
    (a.out/"DIVIDER_CONSTANTS.json").write_text(json.dumps(result,indent=2)+"\n")
    print("NATIVE12_ORIGINAL_DIVIDER_CONSTANTS",json.dumps(constants))
if __name__=="__main__":main()
