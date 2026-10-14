#!/usr/bin/env python3
"""Read-only hash-pinned v12 ObjC host metadata and ARM64 disassembly.
Usage: python3 scripts/v12_host_recovery.py Dashboard.dylib [0xSTART:0xEND ...]
Requires capstone==5.0.7. No binary patching; no device claims.
"""
import hashlib, struct, sys
from pathlib import Path
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM

raw = Path(sys.argv[1]).read_bytes()
expected = 'bc1df854ec7a2ddfeec4cb81b080ead34b54df80143d4a8f6254bb8b618003ce'
assert hashlib.sha256(raw).hexdigest() == expected, 'Unexpected v12 dashboard'
p = raw[0x4000:0x4000+3741760]
def u32(a): return struct.unpack_from('<I', p, a)[0]
def i32(a): return struct.unpack_from('<i', p, a)[0]
def u64(a): return struct.unpack_from('<Q', p, a)[0]
def string(a):
    if not 0 < a < len(p): return '?'
    return p[a:p.find(b'\0', a)].decode('utf-8', errors='replace')

sections = {}
o = 32
for _ in range(u32(16)):
    cmd, size = u32(o), u32(o+4)
    if cmd == 0x19:
        vm, vs, fileoff, fs = struct.unpack_from('<4Q', p, o+24)
        assert vm == fileoff, 'This inspector requires identity file/VM mapping'
        for j in range(u32(o+64)):
            e = o+72+80*j
            name = p[e:e+16].split(b'\0')[0].decode()
            sections[name] = (u64(e+32), u64(e+40), u32(e+68), u32(e+72))
    elif cmd == 2: symoff, nsyms, stroff, strsize = struct.unpack_from('<4I', p, o+8)
    elif cmd == 0xb: indirect = u32(o+56)
    o += size
symbols = [string(stroff+u32(symoff+16*j)) for j in range(nsyms)]
start, size, first, stride = sections['__stubs']
stubs = {start+j*stride: symbols[u32(indirect+4*(first+j))] for j in range(size//stride)}
def within(a, section):
    start, size, _, _ = sections[section]
    return start <= a < start+size
def label(a):
    if within(a, '__objc_selrefs'): return 'SEL '+string(u64(a))
    if within(a, '__cfstring') and (a-sections['__cfstring'][0]) % 32 == 0:
        target, count = u64(a+16), u64(a+24)
        if u32(a+8) & 0x10:
            return 'NSString '+repr(p[target:target+count*2].decode('utf-16le', errors='replace'))
        return 'NSString '+repr(string(target))
    if within(a, '__cstring') or within(a, '__objc_methname'): return repr(string(a))
    if within(a, '__objc_classrefs'):
        cls = u64(a)
        if cls and cls+40 < len(p): return 'CLASS '+string(u64(u64(cls+32)+24))
    return ''

print('V12 DASHBOARD SHA256', expected)
print('ARM64 slice 0x4000; static metadata/disassembly only')
methods = []
ivars = []
start, size, _, _ = sections['__objc_classlist']
for a in range(start, start+size, 8):
    cls = u64(a)
    name = string(u64(u64(cls+32)+24))
    table = u64(u64(cls+32)+48)
    if table:
        stride, count = u32(table), u32(table+4)
        for j in range(count):
            e = table+8+j*stride
            ivars.append((name, string(u64(e+8)), u32(u64(e))))
    for kind, owner in [('-', cls), ('+', u64(cls))]:
        m = u64(u64(owner+32)+32)
        if not m: continue
        flags, count = u32(m), u32(m+4)
        for j in range(count):
            e = m+8+j*(12 if flags & 0x80000000 else 24)
            if flags & 0x80000000:
                target = e+i32(e)
                sel = string(target if flags & 0x40000000 else u64(target))
                imp = e+8+i32(e+8)
            else: sel, imp = string(u64(e)), u64(e+16)
            methods.append((name, kind, sel, imp))
focus = {'CBWindow', 'CBBridgeManager', 'CBBridgeManagerDashboard', 'CBDashboardShared',
         'CBSplitContainerView', 'CBBridgedSplitApp', 'CBBridgedUIAppView'}
for name, kind, sel, imp in methods:
    if name in focus and 'license' not in sel.lower():
        print(f'{kind}[{name} {sel}] IMP {imp:#x}')
for name, field, offset in ivars:
    if name in focus: print(f'IVAR {name}.{field} offset {offset:#x}')

md = Cs(CS_ARCH_ARM64, CS_MODE_ARM); md.detail = True
for item in sys.argv[2:]:
    begin, end = (int(x, 0) for x in item.split(':'))
    assert 0 <= begin < end <= sections['__text'][0]+sections['__text'][1]
    print(f'\nDISASSEMBLY {begin:#x}-{end:#x}')
    regs = {}
    for ins in md.disasm(p[begin:end], begin):
        note = ''; op = ins.operands
        def key(r):
            n = ins.reg_name(r)
            return 'x'+n[1:] if n.startswith('w') else n
        old = dict(regs)
        for reg in ins.regs_access()[1]: regs.pop(key(reg), None)
        if ins.mnemonic in ('adrp', 'adr'):
            regs[key(op[0].reg)] = op[1].imm
            if ins.mnemonic == 'adr': note = label(op[1].imm)
        elif ins.mnemonic == 'add' and len(op) == 3 and op[2].type == 2:
            if key(op[1].reg) in old:
                addr = old[key(op[1].reg)]+op[2].imm
                regs[key(op[0].reg)] = addr; note = label(addr)
        elif ins.mnemonic == 'ldr' and len(op) == 2 and op[1].type == 2:
            note = label(op[1].imm)
        elif ins.mnemonic == 'ldr' and len(op) == 2 and op[1].type == 3:
            base = old.get(key(op[1].mem.base))
            if base is not None:
                addr = base+op[1].mem.disp
                note = f'[{addr:#x}] '+label(addr)
        elif ins.mnemonic in ('bl','b') and op and op[0].type == 2: note = stubs.get(op[0].imm, '')
        if ins.mnemonic in ('bl','blr'):
            for j in range(19): regs.pop('x'+str(j), None)
        elif ins.mnemonic in ('b','br','ret','cbz','cbnz','tbz','tbnz') or ins.mnemonic.startswith('b.'):
            regs.clear()
        print(f'{ins.address:08x}: {ins.mnemonic:8s} {ins.op_str:45s} {note}')
