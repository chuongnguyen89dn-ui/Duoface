#!/usr/bin/env python3
"""READ-ONLY inspection of the existing DuoFace Dashboard divider/logo controls.

No packaging, signing, binary patch, Sileo change or device interaction.
Usage:
  python3 scripts/audit_duoface_divider_mobility.py EXISTING_DASHBOARD_DYLIB \
      --report audit/divider-mobility-20261015.json \
      --disassembly audit/divider-mobility-20261015.txt
Requires macholib and capstone. Reads Objective-C method tables (including
relative method lists), and prints targeted ARM64 disassembly for follow-up.
"""
import argparse
import hashlib
import json
import struct
from pathlib import Path
from macholib.MachO import MachO
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM

SELECTED_CLASSES = {"CBDividerView", "CBDividerButtonInfo", "CBBridgedSplitApp"}
RELEVANT_METHODS = {
    "CBDividerView": {
        "initWithFrame:isVertical:", "configureWithButtonConfigs:",
        "layoutSubviews", "updateGripLayout", "handleMoveButtonLongPress:",
        "moveButtonTouchDown:", "moveButtonTouchUp:", "moveButtonTouchCancelled:",
        "gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:",
        "pointInside:withEvent:", "hitTest:withEvent:"
    },
    "CBDividerButtonInfo": {"setRelativePos:", "relativePos", "setIconName:", "iconName"},
    "CBBridgedSplitApp": {
        "configureDividerButtons", "handleDividerPan:isVertical:state:",
        "handleDividerSwapPressed:", "layoutSplitViews"
    },
}

def inspect(binary: Path):
    raw = binary.read_bytes()
    mach = MachO(str(binary)).headers
    assert len(mach) == 1, "Use native6 original arm64-only candidate"
    h = mach[0]
    data = raw[h.offset:]
    commands = [(lc, c, sections) for lc, c, sections in h.commands]
    segments = [c for lc, c, _ in commands if lc.cmd == 25]
    def offset(addr):
        for seg in segments:
            if seg.vmaddr <= addr < seg.vmaddr + seg.filesize:
                return int(addr - seg.vmaddr + seg.fileoff)
        raise ValueError("not file-backed vmaddr: " + hex(addr))
    def num(addr, fmt="<Q"):
        return struct.unpack_from(fmt, data, offset(addr))[0]
    def str_at(addr):
        o = offset(addr)
        return data[o:data.index(b"\x00", o)].decode("utf-8", errors="replace")
    md = Cs(CS_ARCH_ARM64, CS_MODE_ARM)
    results = {}
    full_disasm = []
    for lc, c, sections in commands:
        if lc.cmd != 25:
            continue
        for section in sections:
            if section.sectname.rstrip(b"\x00") != b"__objc_classlist":
                continue
            for entry in range(section.addr, section.addr + section.size, 8):
                cls = num(entry)
                ro = num(cls + 32) & ~7
                try:
                    class_name = str_at(num(ro + 24))
                except (ValueError, IndexError):
                    continue
                if class_name not in SELECTED_CLASSES:
                    continue
                ivar_names = []
                ivars = num(ro + 48)
                if ivars:
                    stride = num(ivars, "<I")
                    count = num(ivars+4, "<I")
                    for j in range(count):
                        iv = ivars+8+stride*j
                        ivar_names.append({
                            "name": str_at(num(iv+8)),
                            "offset": num(num(iv), "<I")
                        })
                methods = num(ro + 32)
                stride_raw = num(methods, "<I")
                count = num(methods + 4, "<I")
                method_entries = []
                for j in range(count):
                    slot = methods + 8 + (stride_raw & 0xffff) * j
                    if stride_raw & 0x80000000:
                        name_addr = slot + num(slot, "<i")
                        if not stride_raw & 0x40000000:
                            name_addr = num(name_addr)
                        imp = slot+8+num(slot+8, "<i")
                        type_addr = slot+4+num(slot+4, "<i")
                    else:
                        name_addr, imp = num(slot), num(slot+16)
                        type_addr = num(slot+8)
                    method_entries.append({
                        "name": str_at(name_addr),
                        "imp": imp,
                        "signature": str_at(type_addr)
                    })
                focused = []
                for method in method_entries:
                    name, imp = method["name"], method["imp"]
                    if name not in RELEVANT_METHODS.get(class_name, set()):
                        continue
                    later = [x["imp"] for x in method_entries if x["imp"] > imp]
                    span = min(later or [imp + 4096]) - imp
                    span = max(0, min(span, 4096))
                    instructions = [
                        f"{ins.address:08x}: {ins.mnemonic:8} {ins.op_str}"
                        for ins in md.disasm(data[offset(imp):offset(imp)+span], imp)
                    ]
                    full_disasm += [
                        f"\nCLASS {class_name} -[{name}] IMP {hex(imp)} "
                        f"signature={method['signature']} bytes={span}",
                        *instructions
                    ]
                    focused.append({
                        "name": name, "imp": hex(imp), "signature": method["signature"],
                        "span_bytes_inspected": span, "instruction_count": len(instructions)
                    })
                results[class_name] = {
                    "ivars": ivar_names,
                    "method_names": [m["name"] for m in method_entries],
                    "target_method_details": focused
                }
    assert "CBDividerView" in results, "Native divider class missing"
    div = results["CBDividerView"]
    assert any(x["name"] == "_moveButtons" for x in div["ivars"])
    assert any(x["name"] == "_buttonConfigs" for x in div["ivars"])
    assert any(x["name"] == "updateGripLayout" for x in div["target_method_details"])
    note = {
        "status": "READ_ONLY_STATIC_AUDIT_NOT_DEVICE_TEST",
        "binary_name": binary.name,
        "binary_sha256": hashlib.sha256(raw).hexdigest(),
        "binary_bytes": len(raw),
        "classes": results,
        "strings_found": {
            s: raw.count(s.encode("utf-8")) for s in [
                "handleMoveButtonLongPress:", "setRelativePos:", "relativePos",
                "updateGripLayout", "onPanChanged", "setFrame:",
                "moveButtonTouchUp:", "UIPanGestureRecognizer"
            ]
        },
        "user_intent": "Allow DuoFace logo/drag-grip to slide vertically along split divider to uncover underlying content, without changing two-pane resize behavior",
        "safety": "Observation only. An Objective-C selector or long-press recognizer does not itself prove drag-to-reposition exists. Verify exact setter/reference chain, and test on CarPlay before using."
    }
    return note, "\n".join(full_disasm)+"\n"

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("binary", type=Path)
    parser.add_argument("--report", required=True, type=Path)
    parser.add_argument("--disassembly", required=True, type=Path)
    a=parser.parse_args()
    report, text=inspect(a.binary)
    a.report.parent.mkdir(parents=True, exist_ok=True)
    a.disassembly.parent.mkdir(parents=True, exist_ok=True)
    a.report.write_text(json.dumps(report, indent=2, ensure_ascii=False)+"\n")
    a.disassembly.write_text(text)
    print("DIVIDER_MOBILITY_READ_ONLY_AUDIT_OK")
    for cls, item in report["classes"].items():
        print(cls, "target_methods", [m["name"] for m in item["target_method_details"]])
    print("binary_sha256", report["binary_sha256"])

if __name__ == "__main__":
    main()
