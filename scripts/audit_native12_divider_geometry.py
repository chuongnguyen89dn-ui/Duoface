#!/usr/bin/env python3
"""Read-only Mach-O data probes for verified Native12 divider ARM64 literals.

Inputs must be the pinned immutable DuoFaceDashboard.dylib extracted by
scripts/audit_native12_original104_ui_debs.py. Never executes or patches code.
"""
from __future__ import annotations

import json
import math
from pathlib import Path
import struct
import sys

MH_MAGIC_64 = 0xFEEDFACF
LC_SEGMENT_64 = 0x19
# ARM64 ADRP+LDR cited in immutable Native12 updateGripLayout/pointInside.
LITERAL_VADDRS = {
    "divider_short_axis_threshold": 0x312488,  # ff4bc-ff4c4
    "divider_hit_region_constant": 0x311948,   # ff858-ff864
}

def read_double_vmaddr(path: Path, virtual_address: int) -> dict:
    raw = path.read_bytes()
    if len(raw) < 32:
        raise ValueError("truncated Mach-O header")
    magic, cpu, subtype, ftype, count, commands_length, flags, reserved = (
        struct.unpack_from("<IiiIIIII", raw, 0))
    if magic != MH_MAGIC_64:
        raise ValueError("expected a thin little-endian ARM64 Mach-O")
    command_start = 32
    command_limit = command_start + commands_length
    if command_limit > len(raw):
        raise ValueError("load command table truncated")
    offset = command_start
    matches = []
    for _ in range(count):
        if offset + 8 > command_limit:
            raise ValueError("load command truncated")
        kind, size = struct.unpack_from("<II", raw, offset)
        if size < 8 or offset + size > command_limit:
            raise ValueError("invalid load command size")
        if kind == LC_SEGMENT_64:
            if size < 72:
                raise ValueError("invalid 64-bit segment command")
            name = struct.unpack_from("<16s", raw, offset+8)[0].split(b"\0")[0]
            vm_start, vm_size, file_offset, file_size = struct.unpack_from(
                "<QQQQ", raw, offset+24)
            if vm_start <= virtual_address and virtual_address + 8 <= vm_start + file_size:
                position = file_offset + virtual_address - vm_start
                if position + 8 > len(raw):
                    raise ValueError("segment data missing")
                value = struct.unpack_from("<d", raw, position)[0]
                if not math.isfinite(value):
                    raise ValueError("nonfinite value at mapped virtual address")
                matches.append(dict(vmaddr=hex(virtual_address),
                                    segment=name.decode("ascii", "replace"),
                                    file_offset=hex(position), value=value,
                                    raw_little_endian=raw[position:position+8].hex()))
        offset += size
    if len(matches) != 1:
        raise ValueError(f"expected one mapped segment at {virtual_address:x}; got {len(matches)}")
    return matches[0]


def inspect_native12(path: Path) -> dict:
    literals={name:read_double_vmaddr(path, address)
              for name,address in LITERAL_VADDRS.items()}
    threshold=literals["divider_short_axis_threshold"]["value"]
    if not 0 < threshold < 1024:
        raise ValueError("native divider threshold outside plausible points range")
    return {
        "status":"NATIVE12_DIVIDER_LITERAL_MAPPING_STATIC_ONLY",
        "arch":"arm64",
        "code_executed":False,
        "device_tested":False,
        "method":"CBDividerView.updateGripLayout",
        "method_imp":"0xff460",
        "selector_point_inside_imp":"0xff728",
        "literals":literals,
        "button_geometry":{
            "short_axis_select":"isVertical ? bounds.width : bounds.height",
            "small_button_side_pt":28.0,
            "large_button_side_pt":30.0,
            "switch_condition": "short_axis < threshold ? 28pt : 30pt",
            "threshold_pt":threshold,
            "button_frame":"square CGRect; width == height == selected side",
            "frame_call_asm":"0xff6a8-0xff6c0 (d0,d1 coordinate; d2=d3=d8)"
        },
        "limitations":[
            "No live CarPlay bounds or layout modes measured",
            "Raw divider hit-test constants are not sufficient to infer all CGRect branches",
            "Owner of separate QA logo touch area remains to be tested on device"
        ]
    }


def self_test() -> None:
    import tempfile
    b=bytearray(0x3000)
    struct.pack_into("<IiiIIIII",b,0,MH_MAGIC_64,0x0100000c,0,6,1,72,0,0)
    struct.pack_into("<II16sQQQQiiII",b,32,
        LC_SEGMENT_64,72,b"__DATA_CONST".ljust(16,b"\0"),
        0x311000,0x2000,0x100,0x2000,7,3,0,0)
    struct.pack_into("<d",b,0x100+0x1488,32.0)
    struct.pack_into("<d",b,0x100+0x948,-12.0)
    with tempfile.TemporaryDirectory() as tmp:
        p=Path(tmp)/"fixture.dylib";p.write_bytes(b)
        got=inspect_native12(p)
        assert got["literals"]["divider_short_axis_threshold"]["value"]==32
        assert got["literals"]["divider_hit_region_constant"]["value"]==-12
        for addr in (0x500000, 0x313ffb):
            try:read_double_vmaddr(p,addr)
            except ValueError:pass
            else:raise AssertionError("invalid pointer mapping accepted")
    print("NATIVE12_DIVIDER_MACHO_VADDR_SELFTEST_PASS")


if __name__=="__main__":
    if sys.argv[1:]==["--self-test"]:
        self_test()
    elif len(sys.argv)==2:
        print(json.dumps(inspect_native12(Path(sys.argv[1])),indent=2))
    else:
        raise SystemExit("usage: python3 audit_native12_divider_geometry.py --self-test | path/to/DuoFaceDashboard.dylib")
