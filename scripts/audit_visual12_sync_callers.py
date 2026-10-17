#!/usr/bin/env python3
"""Read-only selector-reference and exact function-range audit; no runtime claims."""
import argparse, bisect, hashlib, json, struct, subprocess, sys, tempfile
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'migration/full_payload/native_test'))
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
from capstone.arm64 import ARM64_OP_REG, ARM64_OP_IMM, ARM64_OP_MEM
from audit_native12_license_class_xrefs import MachO, select_arm64, BINARIES
from audit_native12_carplay_add_app_chain import methods, disassemble

EXPECTED = '8b7dedf77b9ec05465b83fdb6e2d7127800eac232a34ecf12f2c08b3983a481a'
TARGETS = {'forceSyncWithCompletion:', 'performSyncWithForce:isManualUserAction:completion:',
 'performSyncWithForce:isManualUserAction:source:completion:', 'syncQueue', 'setSyncQueue:',
 'isSyncing', 'setIsSyncing:', 'checkAndSyncLicenseIfNeeded',
 'checkAndSyncLicenseIfNeededWithSource:', 'isCarPlayScreenConnected',
 'isCarPlayScreenConnectedExcludingScreen:', 'isCarPlayScreen:'}

def imported_stubs(m):
    pos, stubs = 32, []
    sym = indirect = None
    for _ in range(m.ncmds):
        cmd, size = struct.unpack_from('<II', m.data, pos)
        if cmd == 2:
            sym = struct.unpack_from('<IIII', m.data, pos+8)
        if cmd == 0xb:
            indirect = struct.unpack_from('<II', m.data, pos+56)
        if cmd == 0x19:
            for j in range(m.u32(pos+64)):
                at = pos+72+j*80
                if m.u32(at+64) & 0xff == 8:  # S_SYMBOL_STUBS
                    addr, length = struct.unpack_from('<QQ',m.data,at+32)
                    stubs.append((addr,length,m.u32(at+68),m.u32(at+72)))
        pos += size
    result = {}
    if sym and indirect:
        symoff,nsyms,stroff,strsize = sym
        indoff,nind = indirect
        for addr,length,first,stride in stubs:
            if not stride: continue
            for j in range(length//stride):
                assert first+j<nind
                idx=m.u32(indoff+(first+j)*4)
                if idx & 0xc0000000: continue
                assert idx<nsyms
                si=m.u32(symoff+idx*16)
                assert si<strsize
                end=m.data.index(b'\0',stroff+si,stroff+strsize)
                result[addr+j*stride]=m.data[stroff+si:end].decode()
    return result

def function_starts(m):
    pos = 32
    for _ in range(m.ncmds):
        cmd, size = struct.unpack_from('<II', m.data, pos)
        if cmd == 0x26:
            off, length = struct.unpack_from('<II', m.data, pos + 8)
            break
        pos += size
    else:
        raise ValueError('LC_FUNCTION_STARTS missing')
    base = next(v for v, _, _, _, n in m.segments if n == '__TEXT')
    out, delta, shift = [], 0, 0
    for b in m.data[off:off+length]:
        delta |= (b & 127) << shift
        if b & 128:
            shift += 7
            continue
        if delta == 0:
            break
        base += delta
        out.append(base)
        delta, shift = 0, 0
    return out

def audit(raw):
    m = MachO(select_arm64(raw))
    starts = function_starts(m)
    start_set = set(starts)
    owners = {}
    for cls in m.classes():
        for sel, meta in methods(m, cls).items():
            owners.setdefault(meta['vm'], []).append({'class': cls, 'selector': sel, 'type': meta['type']})
    slots = {}
    for sec in m.sections:
        if sec['name'] == '__objc_selrefs':
            for vm in range(sec['vm'], sec['vm']+sec['size'], 8):
                name = m.cstr(m.ptr(vm))
                if name in TARGETS:
                    slots[vm] = name
    cs = Cs(CS_ARCH_ARM64, CS_MODE_ARM)
    cs.detail = True
    hits, dumps = [], {}
    for sec in m.sections:
        if sec['name'] != '__text':
            continue
        insns = list(cs.disasm(m.data[sec['fileoff']:sec['fileoff']+sec['size']], sec['vm']))
        pages = {}
        for idx, ins in enumerate(insns):
            if ins.address in start_set:
                pages.clear()
            operands = ins.operands
            hit = None
            if ins.mnemonic == 'ldr' and len(operands) == 2 and operands[1].type == ARM64_OP_IMM:
                slot = operands[1].imm
                if slot in slots:
                    hit = (slot, slots[slot])
            if ins.mnemonic in ('ldr', 'ldur') and len(operands) == 2 and operands[1].type == ARM64_OP_MEM:
                mem = operands[1].mem
                if mem.base in pages and not mem.index:
                    slot = pages[mem.base] + mem.disp
                    if slot in slots:
                        hit = (slot, slots[slot])
            if hit:
                k = bisect.bisect_right(starts, ins.address) - 1
                start = starts[k] if k >= 0 else sec['vm']
                end = starts[k+1] if k+1 < len(starts) else sec['vm']+sec['size']
                owner = owners.get(start, [])
                hits.append({'selector': hit[1], 'slot': hex(hit[0]), 'reference_vm': hex(ins.address),
                             'destination': ins.reg_name(operands[0].reg), 'function_start': hex(start),
                             'function_end': hex(end), 'exact_objc_owner': owner,
                             'context': [f'{x.address:#x}: {x.mnemonic} {x.op_str}' for x in insns[max(0,idx-5):idx+11] if start <= x.address < end]})
                dumps.setdefault(hex(start), {'owner': owner, 'end': hex(end), 'instructions': disassemble(m,start,end)})
            _, writes = ins.regs_access()
            for reg in writes:
                pages.pop(reg, None)
            if ins.mnemonic == 'adrp' and len(operands) == 2:
                pages[operands[0].reg] = operands[1].imm
            if ins.mnemonic in ('b','bl','blr','ret','br','cbz','cbnz','tbz','tbnz'):
                pages.clear()
    # Include the implementations even if no direct selector reference was found.
    for start, owner in owners.items():
        if any(o['class']=='CBLicenseSyncManager' and o['selector'][1:] in TARGETS for o in owner):
            k = bisect.bisect_right(starts,start)
            if start not in starts or k >= len(starts):
                raise ValueError('unbounded target method')
            dumps.setdefault(hex(start), {'owner': owner, 'end':hex(starts[k]), 'instructions':disassemble(m,start,starts[k])})
    imports = imported_stubs(m)
    for f in dumps.values():
        f['dump_may_be_truncated'] = len(f['instructions']) >= 1400 or int(f['end'],16)-int(f['instructions'][0].split(':')[0],16)>40000
        for i,line in enumerate(f['instructions']):
            for op in ('bl #','b #'):
                if op in line:
                    addr=int(line.split(op)[1].split()[0],16)
                    if addr in imports: f['instructions'][i] += ' ; IMPORT '+imports[addr]
    return {'binary_sha256':hashlib.sha256(raw).hexdigest(), 'selector_slots': {hex(k):v for k,v in slots.items()},
            'reference_hits':hits, 'functions':dumps}

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--deb',type=Path,required=True); ap.add_argument('--out',type=Path,required=True)
    args=ap.parse_args(); digest=hashlib.sha256(args.deb.read_bytes()).hexdigest()
    assert digest==EXPECTED, 'Wrong VisualTest12 baseline'
    with tempfile.TemporaryDirectory() as td:
        subprocess.run(['dpkg-deb','-x',str(args.deb),td],check=True)
        result={name:audit((Path(td)/rel).read_bytes()) for name,rel in BINARIES.items()}
    report={'status':'READ_ONLY_SELECTOR_REFERENCES', 'baseline_sha256':digest, 'binaries':result,
            'limitations':['References are not proof of receiver identity or runtime execution.',
             'Only literal LDR and local ADRP plus LDR/LDUR references; absence of hits does not prove absence of calls.',
             'Unknown function owners may be blocks/C helpers; not attributed to preceding ObjC method.',
             'Disassembly string annotations are hints, not a control-flow or data-flow proof.',
             'Block argument types, queue requirements and device failure cause not proven.'],
            'binary_modified':False,'device_tested':False}
    args.out.parent.mkdir(parents=True,exist_ok=True); args.out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({b:{'hits':len(v['reference_hits']),'functions':len(v['functions'])} for b,v in result.items()}))
if __name__=='__main__': main()
