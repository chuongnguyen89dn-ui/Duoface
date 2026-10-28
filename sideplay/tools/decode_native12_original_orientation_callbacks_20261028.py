#!/usr/bin/env python3
"""Read-only ARM64 decompilation of original Native12 app-process hook callbacks.

Never patches or packages vendor binaries. Inputs are cryptographically pinned
original .deb, original ObjC+LC_FUNCTION_STARTS index, and a historical original
installer disassembly. Report records REAL method installer->ADR callback PC,
exact function boundaries, raw instructions and state-related direct calls.
"""
from __future__ import annotations
import argparse
import bisect
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ORIGINAL_DEB = "2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
ORIGINAL_IMAGE = "9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
ORIGINAL_INDEX_BLOB = "efa45df59bc3c16887cc979bf3aedc0c93c92111"
INSTALLER_START = 0x2ac688
INSTALLER_END = 0x2acc04
INSN = re.compile(r"^\s*(?:0x)?([a-fA-F0-9]+):\s+(.+)$")
ADR_RE = re.compile(r"^adr\s+x2,\s*#(0x[0-9a-fA-F]+|\d+)(?:\s|$)")
BRANCH_RE = re.compile(r"^bl\s+(0x[0-9a-fA-F]+)")
CLASS_NAMES = [
    "UIViewController", "UIWindow", "UIApplication", "UIWindowScene",
    "UIDevice", "UIScreen", "UIScreenMode", "UIWindowSceneGeometry",
]
CHECK_CALLBACKS = {
    "UIViewController.supportedInterfaceOrientations": "0x2acc04",
    "UIViewController.__supportedInterfaceOrientations": "0x2acc60",
    "UIWindow.setFrame:": "0x2accbc",
    "UIWindow.setBounds:": "0x2acdd8",
    "UIWindowScene.interfaceOrientation": "0x2ad7f0",
    "UIDevice.orientation": "0x2ad8d0",
    "UIScreen.bounds": "0x2ada20",
    "UIScreen.nativeBounds": "0x2adaec",
    "UIScreen._referenceBounds": "0x2adbfc",
}


def sha(buf: bytes) -> str:
    return hashlib.sha256(buf).hexdigest()


def blob(buf: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(buf)).encode() + b"\0" + buf).hexdigest()


def parse_installer(body: list[dict]) -> list[dict]:
    current_class = None
    pending_class = None
    current_selector = None
    found = []
    for i, row in enumerate(body):
        pc = int(row["pc"], 16)
        text = row["asm"]
        if not (INSTALLER_START <= pc < INSTALLER_END):
            raise RuntimeError("Unexpected source outside actual original installer")
        if 'literal pool for: "' in text:
            literal = text.split('literal pool for: "', 1)[1].split('"', 1)[0]
            if literal in CLASS_NAMES:
                pending_class = literal
        if "_objc_getClass" in text and pending_class is not None:
            current_class = pending_class
            pending_class = None
        if "Objc selector ref:" in text:
            current_selector = text.split("Objc selector ref:", 1)[1].strip()
        if "_MSHookMessageEx" not in text or text.split(None, 1)[0] not in ("bl", "b"):
            continue
        previous = body[max(0, i - 22):i]
        last_hook_pc = int(found[-1]["installer_pc"], 16) if found else INSTALLER_START
        choices = []
        for nearby in previous:
            addr = int(nearby["pc"], 16)
            match = ADR_RE.match(nearby["asm"])
            if addr > last_hook_pc and match:
                # MachO llvm-objdump renders ADR's signed displacement in
                # decimal even though the PC is in hexadecimal.
                displacement = int(match.group(1), 0)
                choices.append((addr, displacement))
        if len(choices) != 1:
            raise RuntimeError(f"Hook {hex(pc)} lacks ONE x2 target ADR: {choices}")
        addr, delta = choices[0]
        target = addr + delta
        if target < INSTALLER_END:
            raise RuntimeError(f"Hook callback computed inside installer: {hex(target)}")
        found.append({
            "class": current_class,
            "selector": current_selector,
            "installer_pc": hex(pc),
            "replacement_adr_pc": hex(addr),
            "replacement_callback_pc": hex(target),
        })
    if len(found) != 36:
        raise RuntimeError(f"Found {len(found)} original MSHookMessageEx sites, expected 36")
    for selector, target in CHECK_CALLBACKS.items():
        matches = [r for r in found if r["class"] + "." + r["selector"] == selector]
        if len(matches) != 1 or matches[0]["replacement_callback_pc"] != target:
            raise RuntimeError(f"Original known callback PC drift: {selector} => {matches}")
    return found


def decode(deb: Path, index: Path, original_report: Path):
    if sha(deb.read_bytes()) != ORIGINAL_DEB:
        raise RuntimeError("Original input DEB SHA mismatch")
    if blob(index.read_bytes()) != ORIGINAL_INDEX_BLOB:
        raise RuntimeError("Original LC_FUNCTION_STARTS index Git blob mismatch")
    old = json.loads(original_report.read_text(encoding="utf8"))
    if old["original_deb_sha256"] != ORIGINAL_DEB:
        raise RuntimeError("Archived original ARM64 provenance mismatch")
    installer = old["functions"]["app_scene_UIKit_orientation_reconciler"]
    if installer["actual_function_start"] != hex(INSTALLER_START):
        raise RuntimeError("Original function start was not exact")
    hooked = parse_installer(installer["original_arm64"])
    idx = json.loads(index.read_text(encoding="utf8"))
    image = next(x for x in idx["native12"] if x["filename"] == "DuoFaceDashboard.dylib")
    starts = sorted(int(x, 16) for x in image["lc_function_starts"])
    objc = {int(x["imp"], 16): x for x in image["objc_methods"]}
    with tempfile.TemporaryDirectory(prefix="native12-orig-hook-callbacks-") as d:
        out = Path(d) / "unpacked"
        subprocess.run(["dpkg-deb", "-x", str(deb), str(out)], check=True)
        image_path = out / "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib"
        payload = image_path.read_bytes()
        if sha(payload) != ORIGINAL_IMAGE:
            raise RuntimeError("Extracted actual original Dashboard SHA mismatch")
        sys.path.insert(0, os.environ["NATIVE_PARSER_DIR"])
        from audit_native12_license_class_xrefs import select_arm64
        thin = select_arm64(payload)
        thin_path = Path(d) / "dashboard.arm64"
        thin_path.write_bytes(thin)
        cmd = [os.environ.get("OBJDUMP", "llvm-objdump-18"), "--macho", "--disassemble",
               "--no-show-raw-insn", str(thin_path)]
        proc = subprocess.run(cmd, capture_output=True, text=True, encoding="utf8", errors="replace")
        if proc.returncode:
            raise RuntimeError("llvm-objdump failed: " + proc.stderr[-1500:])
        dis = []
        for line in proc.stdout.splitlines():
            m = INSN.match(line)
            if m:
                dis.append({"pc": int(m.group(1), 16), "asm": m.group(2).strip()})
        if len(dis) < 100000:
            raise RuntimeError("Original app is not fully disassembled")
        keys = [x["pc"] for x in dis]
        callbacks = []
        for hook in hooked:
            pc = int(hook["replacement_callback_pc"], 16)
            pos = bisect.bisect_right(starts, pc) - 1
            if pos < 0 or pos + 1 >= len(starts):
                raise RuntimeError("Original callback interval missing: " + hex(pc))
            lo, hi = starts[pos:pos+2]
            l, h = bisect.bisect_left(keys, lo), bisect.bisect_left(keys, hi)
            instructions = dis[l:h]
            if not instructions or instructions[0]["pc"] != lo:
                raise RuntimeError("Original callback code bytes missing: " + hex(lo))
            # Keep all instructions for exact decoding, not a selector-only
            # synopsis. Only functions actually referenced by original hooks.
            lines = [{"pc": hex(x["pc"]), "asm": x["asm"]} for x in instructions]
            calls = []
            for x in lines:
                mat = BRANCH_RE.search(x["asm"])
                if mat:
                    target = int(mat.group(1), 16)
                    owner = objc.get(target)
                    calls.append({
                        "pc": x["pc"], "target": hex(target),
                        "callee": ({"class": owner["class"], "selector": owner["selector"]}
                                   if owner is not None else None),
                        "is_function_start": target in starts,
                    })
            callbacks.append({
                **hook,
                "exact_start": hex(lo),
                "exact_end": hex(hi),
                "starts_at_callback": lo == pc,
                "objc_method": ({"class": objc[lo]["class"], "selector": objc[lo]["selector"]}
                                if lo in objc else None),
                "arm64_instruction_count": len(lines),
                "raw_arm64": lines,
                "direct_calls": calls,
            })
    return {
        "status": "NATIVE12_ORIGINAL_36_HOOK_CALLBACK_BODY_EXACT",
        "original_deb_sha256": ORIGINAL_DEB,
        "original_dashboard_sha256": ORIGINAL_IMAGE,
        "original_index_blob": ORIGINAL_INDEX_BLOB,
        "original_thin_sha256": sha(thin),
        "installer_function": [hex(INSTALLER_START), hex(INSTALLER_END)],
        "original_hooks_count": len(hooked),
        "callbacks": callbacks,
        "interpretation_limits": [
            "Actual original callback ARM64 extracted, but dynamic execution still unobserved",
            "ADR x2 identifies original callback by exact PC; symbolic names are inference from prior original selector refs",
            "Unidentified hook destinations/receiver semantics must not be guessed",
            "Do not copy original hook implementation, binary or licensing into independent DuoFace",
        ],
        "device_089": "DEVICE FAIL by user, video wrong orientation in split despite successful Sileo release",
    }


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--deb", type=Path, required=True)
    p.add_argument("--index", type=Path, required=True)
    p.add_argument("--original-report", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    args = p.parse_args()
    report = decode(args.deb, args.index, args.original_report)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    serialized = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    args.output.write_text(serialized, encoding="utf8")
    if args.output.read_text(encoding="utf8") != serialized:
        raise RuntimeError("Analysis artifact did not survive local readback")
    print("NATIVE12_ORIGINAL_36_EXACT_CALLBACKS_PASS",
          report["original_hooks_count"],
          len({x["exact_start"] for x in report["callbacks"]}))
    for x in report["callbacks"]:
        print("NATIVE12_ORIGINAL_CALLBACK", x["class"], x["selector"],
              x["replacement_callback_pc"], x["exact_start"], x["exact_end"],
              x["arm64_instruction_count"])


if __name__ == "__main__":
    main()
