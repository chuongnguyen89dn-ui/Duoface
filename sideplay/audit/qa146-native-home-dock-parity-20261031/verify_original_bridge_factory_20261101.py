#!/usr/bin/env python3
"""Read-only SHA-pinned audit of ONE genuine DuoNavi 1.0.4 app factory.

Reports bounded ARM64 branch sites and pointer-table references, NOT vendor
instructions/code or a claim that a runtime branch was executed. No licensing
functions, names, offsets or selectors are followed into any other method.
"""
import argparse
import hashlib
import json
import re
from pathlib import Path
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
from audit_native12_license_class_xrefs import MachO, select_arm64
from audit_native12_carplay_add_app_chain import methods

BINARY_SHA = "44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15"
CLASS = "CBBridgeManager"
SELECTOR = "-appForBundleIdentifier:frame:"
START = 0x1bf25c
END = 0x1bf37c
# No vendor license/copy or function-wide disassembly in the committed report.
def section_at(m, addr):
    for s in m.sections:
        if s["vm"] <= addr < s["vm"] + s["size"]:
            return s["name"]
    return None

def inspect(path):
    raw = path.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == BINARY_SHA, "wrong original dylib"
    m = MachO(select_arm64(raw))
    entry = methods(m, CLASS).get(SELECTOR)
    assert entry and entry["vm"] == START, "original factory IMP changed"
    assert END - START == 288
    classes = m.classes()
    ownclasses = {v["class_ptr"]: k for k, v in classes.items()}
    cs = Cs(CS_ARCH_ARM64, CS_MODE_ARM)
    # Exact-size bounded decoding; never follow calls into other methods.
    insns = list(cs.disasm(m.data[m.map(START):m.map(START) + END - START], START))
    assert len(insns) == (END - START) // 4, "incomplete original factory decoding"
    pages, refs, branches = {}, [], []
    for ins in insns:
        opcode, operands = ins.mnemonic, ins.op_str
        if opcode in ("adrp", "adr"):
            match = re.fullmatch(r"(x\d+), #(0x[0-9a-f]+)", operands)
            if match:
                pages[match.group(1)] = int(match.group(2), 16)
        target = None
        if opcode in ("ldr", "add"):
            match = re.fullmatch(r"(x\d+), \[(x\d+), #(0x[0-9a-f]+)\]", operands) if opcode == "ldr" else re.fullmatch(r"(x\d+), (x\d+), #(0x[0-9a-f]+)", operands)
            if match and match.group(2) in pages:
                target = pages[match.group(2)] + int(match.group(3), 16)
        if target is not None:
            kind = section_at(m, target)
            if kind in ("__objc_selrefs", "__objc_classrefs", "__cfstring"):
                try:
                    if kind == "__objc_selrefs":
                        value = m.cstr(m.ptr(target))
                    elif kind == "__objc_classrefs":
                        pointer = m.ptr(target)
                        value = ownclasses.get(pointer, "external-or-unresolved-class")
                    else:
                        value = m.cstr(m.ptr(target + 16))
                    # Explicitly exclude license/security/payment internals.
                    if any(k in value.lower() for k in ("license", "receipt", "purchase", "trial", "subscription", "auth", "premium")):
                        continue
                    refs.append({"pc": hex(ins.address), "table": kind, "target": hex(target),
                                 "name": value, "class_pointer": hex(pointer) if kind == "__objc_classrefs" and value != "external-or-unresolved-class" else None})
                except (ValueError, IndexError, KeyError):
                    pass
        if opcode in ("b", "b.eq", "b.ne", "b.ge", "b.gt", "b.le", "b.lt", "cbz", "cbnz", "tbz", "tbnz"):
            # Preserve a branch site only; target may point outside bounded function.
            branches.append({"pc": hex(ins.address), "kind": opcode, "target": operands.split(",")[-1].strip()})
    return {
        "scope": "one-sha-pinned-original-factory-method-only",
        "original_dylib_sha256": BINARY_SHA,
        "class": CLASS, "selector": SELECTOR, "method_start": hex(START),
        "method_end": hex(END), "decoded_instructions": len(insns),
        "actual_metadata_imp_verified": True,
        "pointer_table_references": refs,
        "branch_sites_only": branches,
        "runtime_branch_or_concrete_app_class_verified": False,
        "original_source_copied": False,
        "original_license_code_inspected": False,
        "next": "Correlate original runtime CBBridgeManager.currentApp class+window and isSplit state in observer on real device; class refs alone do not select taken branch.",
    }

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--binary", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    result = inspect(args.binary)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print("ORIGINAL_FACTORY_SINGLE_METHOD_SCOPED_SHA_VERIFIED")
    print("original classrefs:", [(r["pc"], r["name"]) for r in result["pointer_table_references"] if r["table"] == "__objc_classrefs"])
    print("original branch count:", len(result["branch_sites_only"]))
