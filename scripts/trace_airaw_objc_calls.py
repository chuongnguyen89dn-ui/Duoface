#!/usr/bin/env python3
"""Resolve Airaw arm64 Objective-C stubs to selectors, then report callsites.
Requires llvm-objdump and disassembled __TEXT,__text; read-only.
Usage: python3 scripts/trace_airaw_objc_calls.py Airaw.dylib airaw_text_disasm.txt
"""
import argparse
import json
import re
import struct
import subprocess
from pathlib import Path

TARGETS = [
    "setDefaultAppChromeHidden:", "setNativeChromeHidden:",
    "setIsFull:", "setSavedRect:", "setSavedEdgeInsets:",
    "setFrame:", "setBounds:", "setTransform:", "isNativeSplit", "setHidden:",
]

def trace(binary, disassembly):
    blob = Path(binary).read_bytes()
    # Airaw 1.7.1k fat Mach-O arm64 slice starts at 0x4000.
    slice_offset = 0x4000
    stubs = subprocess.check_output(
        ["llvm-objdump", "--macho", "--arch=arm64",
         "--section=__TEXT,__objc_stubs", "--disassemble", str(binary)],
        text=True,
    ).splitlines()
    body = Path(disassembly).read_text()
    result = {name: [] for name in TARGETS}
    for i, line in enumerate(stubs[:-1]):
        start = re.match(r"\s*([0-9a-f]+):.*adrp\s+x1,.*; 0x([0-9a-f]+)", line)
        if not start:
            continue
        load = re.search(r"ldr\s+x1, \[x1, #0x([0-9a-f]+)\]", stubs[i + 1])
        if not load:
            continue
        selref = (int(start.group(2), 16) & ~0xfff) + int(load.group(1), 16)
        if slice_offset + selref + 8 > len(blob):
            continue
        pointer = struct.unpack_from("<Q", blob, slice_offset + selref)[0] & 0xffffffff
        selector = blob[slice_offset + pointer:slice_offset + pointer + 120].split(b"\0")[0].decode("ascii", "replace")
        if selector not in result:
            continue
        stub_address = int(start.group(1), 16)
        callsites = re.findall(
            r"^\s*([0-9a-f]+):\s+bl\s+0x" + format(stub_address, "x") + r"\b",
            body, re.M,
        )
        result[selector].append({"stub": hex(stub_address), "calls": [hex(int(x, 16)) for x in callsites]})
    return result

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("dylib")
    parser.add_argument("disassembly")
    args = parser.parse_args()
    print(json.dumps(trace(args.dylib, args.disassembly), indent=2))
