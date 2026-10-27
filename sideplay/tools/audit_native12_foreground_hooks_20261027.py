#!/usr/bin/env python3
"""Read-only audit of Native12 C hook registration, omitted from ObjC inventory.

Requires capstone==5.0.7 and the existing native12_objc_stub_decoder.py.
Never loads, modifies or executes the input Mach-O.
"""
import argparse
import hashlib
import json
import re
import struct
from pathlib import Path
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
from native12_objc_stub_decoder import sections_for_binary

PIN = '9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea'
RANGES = {
    'registration': (0x2c7c54, 0x2c7e08),
    'scene_update': (0x2c7e08, 0x2c8410),
    'scene_observer': (0x2c8ca8, 0x2c8ef8),
}

def inspect(path):
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    if digest != PIN:
        raise ValueError('Wrong immutable Native12 Dashboard SHA256: ' + digest)
    _, read = sections_for_binary(path)

    def cstr(addr):
        data = bytearray()
        for i in range(200):
            b = read(addr + i, 1)
            if not b or b == b'\0':
                return data.decode('ascii') if data and all(32 <= n < 127 for n in data) else None
            data += b
        return None

    def pointer(addr):
        raw = read(addr, 8)
        if raw is None:
            raise ValueError('Unmapped pointer')
        return struct.unpack('<Q', raw)[0]

    functions = {}
    for name, (lo, hi) in RANGES.items():
        raw = read(lo, hi-lo)
        if raw is None:
            raise ValueError('Unmapped function')
        instructions = list(Cs(CS_ARCH_ARM64, CS_MODE_ARM).disasm(raw, lo))
        assert len(instructions)*4 == hi-lo
        lines = []
        for ins in instructions:
            line = f'{ins.address:#x}: {ins.mnemonic} {ins.op_str}'
            match = re.fullmatch(r'x\d+, #(0x[0-9a-f]+)', ins.op_str)
            if match and ins.mnemonic in ('adr', 'ldr'):
                addr = int(match[1], 16)
                try:
                    value = cstr(addr) if ins.mnemonic == 'adr' else cstr(pointer(addr))
                    if value:
                        line += ' ; literal=' + repr(value)
                except (ValueError, UnicodeDecodeError):
                    pass
            lines.append(line)
        functions[name] = {'start': hex(lo), 'end': hex(hi), 'instructions': lines}

    # Decode the straight-line initializer's exact x0/x1/x2/x3 arguments.
    # No generalized symbolic-execution claim. Unknown instructions fail closed.
    registers = {}
    hooks = []
    lo, hi = RANGES['registration']
    for ins in Cs(CS_ARCH_ARM64, CS_MODE_ARM).disasm(read(lo, hi-lo), lo):
        op = ins.op_str
        if ins.mnemonic == 'adr':
            dst, value = op.split(', #')
            registers[dst] = int(value, 16)
        elif ins.mnemonic == 'ldr':
            match = re.fullmatch(r'(x\d+), #(0x[0-9a-f]+)', op)
            assert match, op
            registers[match[1]] = pointer(int(match[2], 16))
        elif ins.mnemonic == 'mov':
            dst, src = op.split(', ')
            registers[dst] = registers[src]
        elif ins.mnemonic in ('bl', 'b'):
            target = int(op.removeprefix('#'), 16)
            if target == 0x2eccd0:  # objc_getClass, corroborated by existing graph
                name = cstr(registers['x0'])
                assert name
                registers['x0'] = name
            elif target == 0x2ec9a0:  # MSHookMessageEx, existing named-symbol graph
                hooks.append({'call_pc': hex(ins.address), 'class': registers['x0'],
                    'selector': cstr(registers['x1']), 'replacement': hex(registers['x2']),
                    'original_imp_storage': hex(registers['x3'])})
                # ABI caller-saved registers have no valid values after call.
                for reg in list(registers):
                    if int(reg[1:]) < 19:
                        del registers[reg]
            else:
                raise ValueError('Unexpected initializer call: '+op)
        elif ins.mnemonic not in ('stp', 'ldp', 'add', 'nop'):
            raise ValueError('Unexpected initializer instruction: '+ins.mnemonic)
    assert len(hooks) == 11
    assert hooks[0]['class'] == 'FBScene'
    assert hooks[0]['selector'] == 'updateSettings:withTransitionContext:completion:'
    assert hooks[0]['replacement'] == '0x2c7e08'
    assert hooks[9]['class'] == 'SBAppViewController'
    assert hooks[9]['selector'] == 'sceneHandle:didUpdateSettingsWithDiff:previousSettings:'
    assert hooks[9]['replacement'] == '0x2c8ca8'
    assert hooks[9]['original_imp_storage'] == '0x382150'
    assert cstr(0x308e8b) == 'CBDuoFaceHosted'
    assert cstr(0x308e9b) == 'CBCarBridgeHosted'
    return {'status': 'STATIC_ONLY', 'dashboard_sha256': digest,
            'hooks': hooks, 'functions': functions, 'device_tested': False,
            'writer_of_failed_device_foreground_update_identified': False}

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--binary', required=True, type=Path)
    ap.add_argument('--out', required=True, type=Path)
    args = ap.parse_args()
    result = inspect(args.binary)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n')
    print('PASS immutable SHA, 11 registrations, exact crash-observer replacement and scene-update hook')
    print('NOT A DEVICE TEST; NOT A CRASH FIX')

if __name__ == '__main__':
    main()
