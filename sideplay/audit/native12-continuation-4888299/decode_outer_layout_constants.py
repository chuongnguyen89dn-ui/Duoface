#!/usr/bin/env python3
"""Read-only, SHA-pinned Native12 outer chooser CGRect literals.

Source: original DuoFaceDashboard.dylib, CBMultitaskingOverlayView.layoutSubviews
@0xa28e8. ARM64 callsites: 0xa2980, 0xa2998, 0xa29b4, 0xa29c4.
Do not import vendor runtime or infer pixel parity from four constants.
"""
import argparse
import json
import math
import pathlib
import runpy
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
ASSEMBLY = HERE / "gallery-media-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json"
LITERALS = {
    "outer_width_breakpoint": 0x311740,   # a297c..a2984
    "outer_height_breakpoint": 0x311748,  # a2998..a299c
    "outer_max_card_width": 0x311758,     # a29b4..a29b8
    "outer_max_card_height": 0x311760,    # a29c4..a29c8
}
CALLSITE = {
    "a2980:", "a2998:", "a29b4:", "a29c4:",
    "a2988:\tfmov\td0, #24.00000000",
    "a298c:\tfmov\td1, #10.00000000",
    "a29a0:\tfmov\td1, #18.00000000",
    "a29a4:\tfmov\td2, #8.00000000",
    "a29d4:", "a29ec:", "a2a3c:",
}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--macho", required=True)
    parser.add_argument("--out", type=pathlib.Path, required=True)
    args = parser.parse_args()
    report = json.loads(ASSEMBLY.read_text())
    method = next(m for m in report["methods"]
                  if m["class"] == "CBMultitaskingOverlayView"
                  and m["selector"] == "layoutSubviews" and m["imp"] == "0xa28e8")
    lines = method["instructions"]
    for marker in CALLSITE:
        if not any(marker in line for line in lines):
            raise ValueError("Original assembly no longer matches: " + marker)
    decoder = runpy.run_path(str(ROOT / "audit/native12-layout-forensic-20261021/decode_layout_constants.py"))
    decoder["main"].__globals__["ADDRS"].update(LITERALS)
    original_argv = sys.argv
    try:
        with tempfile.TemporaryDirectory() as tmp:
            sys.argv = [original_argv[0], "--macho", args.macho, "--out", tmp]
            decoder["main"]()
            decoded = json.loads((pathlib.Path(tmp) / "DIVIDER_CONSTANTS.json").read_text())
    finally:
        sys.argv = original_argv
    values = {key: decoded["constants"][key] for key in LITERALS}
    numbers = {key: val["double"] for key, val in values.items()}
    if not all(math.isfinite(v) and v > 0 for v in numbers.values()):
        raise ValueError("Invalid original size literal; do not infer")
    if numbers["outer_max_card_width"] < 300 or numbers["outer_max_card_height"] < 100:
        raise ValueError("Original max dimensions unexpected; stop for review")
    result = {
        "status": "ORIGINAL_MACHO_CONSTANTS_ONLY_NOT_DEVICE_VERIFIED",
        "original_macho_sha256": decoded["macho_sha256"],
        "class": "CBMultitaskingOverlayView",
        "method": "layoutSubviews",
        "imp": "0xa28e8",
        "callsite_addresses": sorted(CALLSITE),
        "literals": values,
        "observed_arm64_math": {
            "horizontal_subtract_when_width_lt_breakpoint": 10,
            "horizontal_subtract_otherwise": 24,
            "vertical_subtract_when_height_lt_breakpoint": 8,
            "vertical_subtract_otherwise": 18,
            "width": "fminnm(originalWidth - horizontalSubtract, maxCardWidth)",
            "height": "fminnm(originalHeight - verticalSubtract, maxCardHeight)",
            "origin": "frinta(float((originalDimension - chosenDimension)*0.5))",
        },
        "vendor_source_copied": False,
        "runtime_modified": False,
        "device_tested": False,
    }
    args.out.mkdir(parents=True, exist_ok=True)
    dest = args.out / "ORIGINAL_OUTER_LAYOUT_CONSTANTS.json"
    dest.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
    print("NATIVE12_OUTER_LAYOUT_ORIGINAL_BYTES_VERIFIED", dest)
if __name__ == "__main__":
    main()
