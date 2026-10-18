#!/usr/bin/env python3
"""Read-only Native12/original104 ARM64 UI startup / placeholder / window callchain.

Do not execute, modify or link reference dylibs in the independent QA package.
Static instructions/selector references are *not* a runtime CarPlay observation.
"""
import argparse
from bisect import bisect_left
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile

NATIVE_SHA = "2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
ORIG_SHA = "f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd"
DASH = {"native12": "DuoFaceDashboard.dylib", "original104": "DuoNaviDashboard.dylib"}
METHODS = {
    "CBWindow": ["createWindows", "resizeWindows", "show", "hide:",
                 "carPlayContentInsets", "carPlayUsableBounds"],
    "CBSplitSplashScreenView": ["initWithFrame:", "layoutSubviews",
                                "startLoadingAnimation", "handleTap:",
                                "dismissAnimated:", "dismissAnimated:completion:"],
    "CBSlotPlaceholderView": ["initWithSlotIndex:", "updateLocalizedTexts",
                              "layoutSubviews", "placeholderTapped:"],
    "CBSplitContainerView": ["layoutSubviews", "hitTest:withEvent:",
                             "touchesBegan:withEvent:"],
    "CBUIAppContainerView": ["layoutSubviews", "hitTest:withEvent:",
                             "touchesBegan:withEvent:"],
    "CBMultitaskingOverlayView": ["setupCardContent",
                                  "setupAppPickerCardsInCardW:cardH:contentY:",
                                  "setupRecentAppsCardsInCardW:cardH:contentY:"],
    "CBDividerView": ["handlePan:", "handleMoveButtonLongPress:",
                      "gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:"],
}
CLASS_RE = re.compile(r"^\s*name\s+0x[0-9a-fA-F]+\s+([A-Za-z_][A-Za-z0-9_]*)\s*$")
METHOD_RE = re.compile(r"^\s*name\s+0x[0-9a-fA-F]+\s+\(0x[0-9a-fA-F]+\)\s+(.+?)\s*$")
IMP_RE = re.compile(r"^\s*imp\s+0x[0-9a-fA-F]+\s+\(0x([0-9a-fA-F]+)\)")
ASM_RE = re.compile(r"^\s*([0-9a-fA-F]+):")
SEL_RE = re.compile(r"Objc selector ref: ([^;]+)|Objc message: (.+)$")
GEO_RE = re.compile(r"\bfmov\b|\bfadd\b|\bfsub\b|\bfmul\b|\bfcmp\b|"
                     r"setFrame:|setBounds:|setWindowLevel:|setBackgroundColor:|"
                     r"colorWith(?:White|Red):|setCornerRadius:|safeAreaInsets")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def target_methods(meta):
    out = {k: {} for k in METHODS}
    cls = None
    active = False
    pending = None
    for line in meta.splitlines():
        name = CLASS_RE.match(line)
        if name:
            cls = name.group(1) if name.group(1) in out else None
            active = False
            pending = None
            continue
        if not cls:
            continue
        if re.match(r"^\s*baseMethods\s+0x", line):
            active = not bool(re.match(r"^\s*baseMethods\s+0x0\s*$", line))
            continue
        if active and re.match(r"^\s*baseProtocols\b", line):
            cls = None
            active = False
        if not active:
            continue
        mm = METHOD_RE.match(line)
        if mm:
            pending = mm.group(1)
        im = IMP_RE.match(line)
        if im and pending:
            out[cls][pending] = int(im.group(1), 16)
            pending = None
    return out


def inspect_binary(path):
    meta = subprocess.run(["xcrun", "llvm-objdump", "--macho",
                           "--objc-meta-data", str(path)],
                          check=True, stdout=subprocess.PIPE).stdout.decode("utf-8", "replace")
    asm = subprocess.run(["xcrun", "llvm-objdump", "--macho",
                          "--disassemble", str(path)],
                         check=True, stdout=subprocess.PIPE).stdout.decode("utf-8", "replace")
    entries = []
    for line in asm.splitlines():
        m = ASM_RE.match(line)
        if m:
            entries.append((int(m.group(1), 16), line.strip()))
    entries.sort(key=lambda z: z[0])
    addresses = [i for i, _ in entries]
    catalog = target_methods(meta)
    report = {}
    for name, requested in METHODS.items():
        methods = {}
        for method in requested:
            imp = catalog[name].get(method)
            if imp is None:
                methods[method] = {"present": False}
                continue
            a = bisect_left(addresses, imp)
            instr = [line for addr, line in entries[a:]
                     if addr < imp + 0x1600][:1050]
            selectors = sorted({m.group(1) or m.group(2)
                                for row in instr
                                for m in [SEL_RE.search(row)] if m})
            windows = [{"asm_index": i, "arm64": instr[max(0, i-5):i+6]}
                       for i, row in enumerate(instr) if GEO_RE.search(row)]
            methods[method] = {
                "present": True, "imp": hex(imp), "instruction_count": len(instr),
                "selector_refs": selectors[:140],
                "arithmetic_and_uikit_windows": windows[:100],
                "arm64": instr,
                "disassembly_window_note": "Bounded to 0x1600 bytes/1050 instructions; not necessarily the exact method end",
            }
        report[name] = {"metadata_catalog_method_count": len(catalog[name]), "methods": methods}
    return report


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--native", type=Path, required=True)
    ap.add_argument("--original", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    a = ap.parse_args()
    all_results = {}
    with tempfile.TemporaryDirectory(prefix="read-only-cb-ui-") as tmp:
        for key, source, wanted in (("native12", a.native, NATIVE_SHA),
                                    ("original104", a.original, ORIG_SHA)):
            if sha(source) != wanted:
                raise RuntimeError(key + " signed DEB SHA changed")
            root = Path(tmp) / key
            root.mkdir()
            subprocess.run(["dpkg-deb", "-x", str(source), str(root)], check=True)
            matched = list(root.rglob(DASH[key]))
            if len(matched) != 1:
                raise RuntimeError(f"{key} expected one Dashboard binary, got {len(matched)}")
            binary = matched[0]
            target = binary
            head = int.from_bytes(binary.read_bytes()[:4], "big")
            if head in (0xCAFEBABE, 0xBEBAFECA, 0xCAFEBABF, 0xBFBAFECA):
                target = root / "arm64-only.dylib"
                subprocess.run(["xcrun", "lipo", "-thin", "arm64", str(binary),
                                "-output", str(target)], check=True)
            all_results[key] = {
                "deb_sha256": wanted, "dashboard_sha256": sha(binary),
                "classes": inspect_binary(target),
            }
    assert all_results["native12"]["classes"]["CBWindow"]["methods"]["createWindows"]["present"]
    assert all_results["native12"]["classes"]["CBSplitSplashScreenView"]["methods"]["layoutSubviews"]["present"]
    assert all_results["native12"]["classes"]["CBSlotPlaceholderView"]["methods"]["layoutSubviews"]["present"]
    a.out.parent.mkdir(parents=True, exist_ok=True)
    a.out.write_text(json.dumps({
        "status": "READONLY_NATIVE12_104_STARTUP_PLACEHOLDER_WINDOW_ARM64_STATIC_PASS",
        "device_proven": False,
        "original_binary_reused_in_qa": False,
        "native12": all_results["native12"],
        "original104": all_results["original104"],
    }, ensure_ascii=False, indent=2) + "\n")
    print("STARTUP_PLACEHOLDER_WINDOW_ORIGINAL104_NATIVE12_ARM64_READONLY_PASS")
    for key in all_results:
        for cls, data in all_results[key]["classes"].items():
            print(key, cls, "catalog_methods=", data["metadata_catalog_method_count"],
                  "requested_present=", sum(x["present"] for x in data["methods"].values()))


if __name__ == "__main__":
    main()
