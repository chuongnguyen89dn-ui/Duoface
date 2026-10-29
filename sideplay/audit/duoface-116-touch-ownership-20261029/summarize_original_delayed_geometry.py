#!/usr/bin/env python3
"""Original Native12 instruction evidence around delayed geometry and input.

Static disassembly only; selector receivers and runtime timing are unverified.
"""
from pathlib import Path
import json

HERE = Path(__file__).resolve().parent
source = HERE / "original-delayed-geometry-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json"
data = json.loads(source.read_text())
assert data["dashboard_macho_sha256"] == "9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
assert data["original_native12_deb_sha256"] == "2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
assert len(data["methods"]) == 13
assert all(m["instructions"] for m in data["methods"])
markers = (
    "layoutSubviews", "updateLayout", "updateSceneSettingsFrame",
    "refreshSceneLayout", "updateSceneFrame", "resizeWindows",
    "carPlayUsableBounds", "calculateNativeSizeForSlotRect:",
    "setFrame:", "setTransform:", "setBounds:", "setCenter:",
    "setContentReferenceSize:", "setContentReferenceSize:with",
    "setHidden:", "setWindowLevel:", "setUserInteractionEnabled:",
    "setClipsToBounds:", "hitTest:withEvent:", "pointInside:withEvent:",
    "noteUserActivity", "setAppScale:", "updateScale:",
    "scheduledTimer", "dispatch_after", "dispatch_async",
    "updateSettingsWithBlock:", "setNeedsLayout", "layoutIfNeeded",
    "setIgnoresOcclusions:", "setAutomatesLifecycle:", "UIScene",
)
lines = [
    "# Native12 original delayed touch: layout, window and scene callsites",
    "",
    "- 2026-10-29, read-only original binary ARM64 extraction, **not a real-car touch test**.",
    "- Original DEB SHA256: `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`.",
    "- Mach-O SHA256: `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`.",
    "- Selected 13 original method IMPs; exact disassembly in `original-delayed-geometry-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json`.",
    "- PC callsites establish selector invocation but not Objective-C receiver or temporal execution order across threads.",
    "",
]
for m in data["methods"]:
    relevant = [
        s for s in m["instructions"]
        if ("Objc message:" in s or "Objc selector ref:" in s or "symbol stub for:" in s)
        and any(marker in s for marker in markers)
    ]
    lines.extend([
        "## " + m["class"] + "." + m["selector"] + " @ " + m["imp"],
        "- Source boundary: `" + m["imp"] + ".." + m["end"] + "`; "
        + str(len(m["instructions"])) + " instructions, "
        + str(len(relevant)) + " matching callsites.",
        "",
    ])
    if not relevant:
        lines.append("- No matching named marker in this IMP (not evidence of no indirect call).")
    for site in relevant[:125]:
        lines.append("    " + site)
    if len(relevant) > 125:
        lines.append("- Truncated at 125 matching sites; inspect the JSON for all.")
    lines.append("")
out = HERE / "ORIGINAL_DELAYED_GEOMETRY_CALLSITES.md"
out.write_text("\n".join(lines) + "\n")
print("NATIVE12_ORIGINAL_DELAYED_TOUCH_CALLEE_EVIDENCE_OK",
      len(data["methods"]), data["instructions_collected"])
