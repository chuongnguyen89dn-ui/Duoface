#!/usr/bin/env python3
"""Read-only ARM64 ObjC metadata/disassembly for the visual control callbacks.
Usage: python scripts/inspect_visual_methods.py unpacked/DuoFaceDashboard.dylib
Requires macholib and capstone; no binary rewriting.
"""
import struct
import sys
from pathlib import Path
from macholib.MachO import MachO
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM

p = Path(sys.argv[1])
h = MachO(str(p)).headers[0]
data = p.read_bytes()[h.offset:]
segments = [c for lc, c, _ in h.commands if lc.cmd == 25]
def offset(addr):
    for s in segments:
        if s.vmaddr <= addr < s.vmaddr + s.filesize:
            return int(addr - s.vmaddr + s.fileoff)
    raise ValueError(hex(addr))
def num(addr, fmt='<Q'):
    return struct.unpack_from(fmt, data, offset(addr))[0]
def string(addr):
    o = offset(addr)
    return data[o:data.index(b'\0', o)].decode(errors='replace')
md = Cs(CS_ARCH_ARM64, CS_MODE_ARM)
for lc, c, sections in h.commands:
    if lc.cmd != 25:
        continue
    for section in sections:
        if section.sectname.rstrip(b'\0') != b'__objc_classlist':
            continue
        for a in range(section.addr, section.addr + section.size, 8):
            cls = num(a)
            ro = num(cls + 32) & ~7
            name = string(num(ro + 24))
            if name not in ('CBDividerView', 'CBSlotPillView', 'CBSplitSplashScreenView'):
                continue
            print('CLASS', name)
            ivars = num(ro + 48)
            if ivars:
                size, count = num(ivars, '<I'), num(ivars + 4, '<I')
                for k in range(count):
                    v = ivars + 8 + size*k
                    print(' IVAR', string(num(v+8)), 'offset', num(num(v), '<I'))
            methods = num(ro + 32)
            size, count = num(methods, '<I'), num(methods+4, '<I')
            entries = []
            for k in range(count):
                e = methods + 8 + (size & 0xffff)*k
                if size & 0x80000000:
                    n = e + num(e, '<i')
                    if not size & 0x40000000:
                        n = num(n)
                    imp = e + 8 + num(e+8, '<i')
                else:
                    n, imp = num(e), num(e+16)
                entries.append((string(n), imp))
            for selector, imp in entries:
                print(' METHOD', selector, hex(imp))
                if selector in ('moveButtonTouchUp:', 'moveButtonTouchDown:', 'moveButtonTouchCancelled:', 'handleMoveButtonLongPress:'):
                    end = min([i for _,i in entries if i>imp] or [imp+1024])
                    for ins in md.disasm(data[offset(imp):offset(imp)+min(end-imp,2048)], imp):
                        print('  %x: %s %s' % (ins.address, ins.mnemonic, ins.op_str))
