#!/usr/bin/env python3
"""Minimal dependency-free arm64 Mach-O integrity guard after ldid.
Detect LC_CODE_SIGNATURE overlap with actual stored section content. No OCR.
"""
from pathlib import Path
import struct
import sys
p=Path(sys.argv[1]);b=p.read_bytes()
assert len(b)>64 and struct.unpack_from("<I",b)[0]==0xfeedfacf, "expected arm64 Mach-O 64-bit little-endian"
_,cputype,_,_,ncmds,sizeofcmds,_,_=struct.unpack_from("<IiiIIIII",b,0)
assert cputype==0x0100000c, "arm64 expected"
assert 0<ncmds<200 and 0<sizeofcmds<len(b)-32
limit=32+sizeofcmds
assert limit<len(b), "load commands exceed file"
off=32;sections=[];signatures=[]
for _ in range(ncmds):
    assert off+8<=limit,"truncated load command"
    cmd,size=struct.unpack_from("<II",b,off)
    assert size>=8 and off+size<=limit,"invalid load command size"
    if cmd==0x19:
        assert size>=72,"segment64 truncated"
        nsects=struct.unpack_from("<I",b,off+64)[0]
        assert 72+nsects*80<=size,"section table truncated"
        for i in range(nsects):
            start=off+72+i*80
            sectname=b[start:start+16].split(b"\0",1)[0].decode("ascii","replace")
            secsize=struct.unpack_from("<Q",b,start+40)[0]
            secoff=struct.unpack_from("<I",b,start+48)[0]
            # Zero-fill or virtual-only sections legitimately have no file data.
            flags=struct.unpack_from("<I",b,start+64)[0]
            if secsize>0 and secoff>0 and (flags&0xff) not in (0x1,0xc,0x12):
                assert secoff>=limit, f"{sectname} begins inside load commands"
                assert secoff+secsize<=len(b),f"{sectname} beyond file"
                sections.append((secoff,secoff+secsize,sectname))
    if cmd==0x1d:
        assert size>=16,"codesign command truncated"
        so,ss=struct.unpack_from("<II",b,off+8)
        assert ss>0 and so>=limit and so+ss<=len(b),"signature outside file/header"
        signatures.append((so,so+ss))
    off+=size
assert off==limit,"load command table size mismatch"
assert signatures,"ldid signature missing"
assert any(name=="__text" for _,_,name in sections),"no executable text section"
for so,se in signatures:
    for start,end,name in sections:
        assert not (start<se and so<end),f"signature overlaps {name}: {so:x}-{se:x} vs {start:x}-{end:x}"
print(f"GATE1_MACHO_SIGNATURE_NONOVERLAP_PASS sections={len(sections)} file_size={len(b)}")
