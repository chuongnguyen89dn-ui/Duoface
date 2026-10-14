#!/usr/bin/env python3
"""Read-only, hash-pinned Airaw 1.7.1k arm64 evidence recovery. Needs capstone.
Usage: python3 scripts/airaw_focus_recovery.py /path/to/Airaw.dylib
Only applies to the verified binary; no patching or device execution.
"""
import hashlib, struct, sys
from pathlib import Path
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM

raw = Path(sys.argv[1]).read_bytes()
expected = '46115c8f0a1d2d81cf4c003be58468d2a9b5c69e595f0f68d5fff5de53be4a9d'
assert hashlib.sha256(raw).hexdigest() == expected, 'Unexpected binary hash'
p = raw[0x4000:]
assert struct.unpack_from('<I',p)[0] == 0xfeedfacf
def u32(a): return struct.unpack_from('<I',p,a)[0]
def i32(a): return struct.unpack_from('<i',p,a)[0]
def u64(a): return struct.unpack_from('<Q',p,a)[0]
def ptr(a):
    v=u64(a)
    if v >> 63: return None  # bound external pointer, not a local rebase
    return v & ((1<<36)-1)  # DYLD_CHAINED_PTR_64 target for this exact image
def cstr(a):
    if a is None or a >= len(p): return '?'
    return p[a:p.find(b'\0',a)].decode('utf-8',errors='replace')
imports={}
off=32
for _ in range(u32(16)):
    cmd,size=u32(off),u32(off+4)
    if cmd==0x80000034:
        fix=u32(off+8)
        version,starts,imp_off,sym_off,count,fmt,symfmt=struct.unpack_from('<7I',p,fix)
        assert fmt==1 and symfmt==0, 'Unsupported chained import format'
        for j in range(count):
            item=u32(fix+imp_off+j*4)
            imports[j]=cstr(fix+sym_off+(item>>9))
    off+=size
def classref(a):
    value=u64(a)
    if value>>63: return imports.get(value&0xffffff,'?')
    cls=ptr(a)
    ro=ptr(cls+32) if cls else None
    return cstr(ptr(ro+24)) if ro else '?'
def label(a):
    if 0x81128 <= a < 0x81510: return 'CLASS '+classref(a)
    if 0x7d8b0 <= a < 0x81128: return 'SEL '+cstr(ptr(a))
    if 0x6d7b8 <= a < 0x723d8:
        return 'NSString '+repr(cstr(ptr(a+16)))
    if 0x56710 <= a < 0x6821a: return repr(cstr(a))
    if 0x6c518 <= a < 0x6d7b8:
        b=ptr(a)
        if b and 0x6d7b8 <= b < 0x723d8: return label(b)
    return ''
md=Cs(CS_ARCH_ARM64,CS_MODE_ARM);md.detail=True
stubs={}
for a in range(0x46f80,0x52820,32):
    ins=list(md.disasm(p[a:a+8],a))
    if len(ins)==2 and ins[0].mnemonic=='adrp' and ins[1].mnemonic=='ldr':
        slot=ins[0].operands[1].imm+ins[1].operands[1].mem.disp
        stubs[a]=cstr(ptr(slot))

print('BINARY SHA256',expected)
print('ARM64 slice 0x4000; source-bound rebases only; no runtime claims')
for a in [0x800ca0,0x80ca0,0x6f578]: print('CHECKPOINT POINTER',hex(a),label(a) if a<len(p) else 'OUTSIDE ARM64 VM DATA; likely checkpoint typo')
print('\nCLASS METHOD OWNERS')
for a in range(0x723d8,0x72528,8):
    cls=ptr(a)
    if not cls: continue
    ro=ptr(cls+32)
    if not ro: continue
    name=cstr(ptr(ro+24))
    for kind,owner in [('-',cls),('+',ptr(cls))]:
        if not owner: continue
        owner_ro=ptr(owner+32)
        if not owner_ro: continue
        methods=ptr(owner_ro+32)
        if not methods: continue
        flags,count=u32(methods),u32(methods+4)
        if flags & 0x80000000:
            for j in range(count):
                ent=methods+8+j*12
                slot=ent+i32(ent)
                sel=cstr(slot if flags&0x40000000 else ptr(slot))
                imp=ent+8+i32(ent+8)
                if any(k.lower() in sel.lower() for k in ['fullscreen','chromehidden','edgeinset','hostmenu']):
                    print(f'{kind}[{name} {sel}] IMP {imp:#x} entry {ent:#x}')

ranges=[(0x13db0,0x13dcc),(0x14208,0x14224),(0x14488,0x144a4),
        (0x14668,0x14684),(0x147e8,0x14804),(0x149d4,0x149f0),
        (0x14c94,0x15068),(0xc54c,0xc588),(0xd704,0xd740),
        (0xcb40,0xcd54),(0xdcf8,0xdf0c),(0x19c7c,0x19f44),
        (0x43a30,0x43b04),(0x451f0,0x45254),(0x45b50,0x45bf8),(0x45d20,0x45d90)]
for start,end in ranges:
    print(f'\nDISASSEMBLY {start:#x}-{end:#x}')
    regs={}
    for ins in md.disasm(p[start:end],start):
        note=''
        op=ins.operands
        if ins.mnemonic=='adrp': regs[op[0].reg]=op[1].imm
        elif ins.mnemonic=='add' and len(op)==3 and op[2].type==2:
            if op[1].reg in regs:
                addr=regs[op[1].reg]+op[2].imm;regs[op[0].reg]=addr;note=label(addr)
        elif ins.mnemonic=='ldr' and len(op)==2 and op[1].type==3:
            base=regs.get(op[1].mem.base)
            if base is not None:
                addr=base+op[1].mem.disp;note=f'[{addr:#x}] '+label(addr)
            regs.pop(op[0].reg,None)
        elif ins.mnemonic in ('bl','b') and op and op[0].type==2:
            note=stubs.get(op[0].imm,'')
        print(f'{ins.address:08x}: {ins.mnemonic:8s} {ins.op_str:45s} {note}')
