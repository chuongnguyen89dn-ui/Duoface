#!/usr/bin/env python3
"""Small source-verifiable evidence from a 1.6 MiB ORIGINAL ARM64 machine dump.

The original binary has already been SHA checked and disassembled by Actions;
do not replay input, execute vendor code, or modify native CarPlay UI.
"""
from pathlib import Path
import json

BASE = Path(__file__).resolve().parent
source = BASE / "original-owner-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json"
out = BASE / "ORIGINAL_TOUCH_ATTACHMENT_CALLSITES.md"
data = json.loads(source.read_text())
assert data["original_native12_deb_sha256"] == (
    "2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
)
assert data["dashboard_macho_sha256"] == (
    "9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
)
assert len(data["methods"]) == 6

needles = (
    "CBTouchCloneView", "CBTouchPassThroughRootSceneWindow",
    "SBFTouchPassThroughWindow", "UIRootSceneWindow",
    "pointInside:withEvent:", "hitTest:withEvent:",
    "class_addMethod", "objc_allocateClassPair", "objc_registerClassPair",
    "class_createInstance", "addSubview", "addChildViewController",
    "setWindowLevel:", "setUserInteractionEnabled:", "setClipsToBounds:",
    "setRequestedMode:", "setAppScale:", "setFrame:",
)
lines = [
    "# ORIGINAL Native12 touch owner: attachment and override callsites",
    "",
    "- Evidence: original immutable DEB SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`",
    "- Original Dashboard Mach-O SHA256 `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`",
    "- Original 6 verified IMPs from CI run 40863967219; this is read-only disassembly, not runtime UI testing.",
    "- Context below is native Mach-O disassembly. A name or class reference alone is not a proven execution branch.",
    "",
]
for m in data["methods"]:
    ins = m["instructions"]
    matches = [i for i, v in enumerate(ins) if any(w in v for w in needles)]
    lines += [
        "## " + m["class"] + "." + m["selector"] + " @ " + m["imp"],
        f"- Original instructions: {len(ins)}; selected callsite markers: {len(matches)}",
        "",
    ]
    selected = set()
    for i in matches:
        selected.update(range(max(0, i-5), min(len(ins),i+9)))
    if not selected:
        lines.append("- No matching input-attachment selector/class marker observed in this IMP.")
    else:
        last = -2
        for i in sorted(selected):
            if i>last+1: lines.append("    ...")
            lines.append("    "+ins[i])
            last = i
    lines.append("")
out.write_text("\n".join(lines)+"\n")
print("ORIGINAL_TOUCH_HIERARCHY_CALLSITE_REPORT_OK",
      len(data["methods"]), sum("CBTouchCloneView" in ln for ln in lines))
