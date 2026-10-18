#!/usr/bin/env python3
"""Read-only DuoNavi 1.0.4 *original* UI call-chain evidence.

Extract bounded Objective-C selectors and relative method addresses from a
pinned original .deb. No vendor code is patched, embedded, or executed.
A selector-ref or message annotation is NOT dynamic-call proof.
"""
from __future__ import annotations

import argparse
from bisect import bisect_right
import hashlib
import json
import re
from pathlib import Path
from audit_original104_scene_lifecycle import inventory, checksum

DEB_SHA = "f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd"
DASH_SHA = "44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15"

# Audit these six relevant interface/scene owner families, not license APIs.
TARGETS = {
    "CBWindow": [
        "createWindows", "show", "resizeWindows",
        "showAppPickerForSlot:", "showLayoutChooser", "showRecentApps",
        "destroyWindows",
    ],
    "CBBridgedSplitApp": [
        "handleDividerPan:isVertical:state:", "layoutSplitViews",
        "focusSlot:animated:", "restoreSplitAnimated:",
        "toggleFocusForSlot:", "configureDividerButtons",
        "swapSlot:withSlot:", "updateScale:forSlot:",
        "closeSlot:", "stop",
    ],
    "CBBridgedUIAppView": [
        "calculateNativeSizeForSlotRect:", "updateLayout",
        "updateSceneSettingsFrame", "updateSceneFrame",
        "refreshSceneLayout", "startInParentViewController:",
        "hitTest:withEvent:", "dismiss",
    ],
}
EXTRA = re.compile(
    r"Objc selector ref: (.+)$|Objc message: (.+)$|"
    r"bl\s+0x[0-9a-fA-F]+|\b(cbz|cbnz|tbnz|tbz|b\.eq|b\.ne)\b"
)
ADDRESS = re.compile(r"^\s*([0-9a-fA-F]+):")


def disassembly_map(path: Path) -> dict[int, str]:
    result = {}
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        found = ADDRESS.match(line)
        if found:
            result[int(found.group(1), 16)] = line.strip()
    return result


def run(deb: Path, dashboard: Path, metadata: Path, disasm: Path) -> dict:
    assert checksum(deb) == DEB_SHA, "Original 1.0.4 DEB SHA mismatch"
    assert checksum(dashboard) == DASH_SHA, "Original 1.0.4 dashboard SHA mismatch"
    methods = inventory(metadata.read_text(encoding="utf-8", errors="replace"))
    byclass = {(c, m): addr for c, m, addr in methods}
    ordered = sorted(byclass.values())
    code = disassembly_map(disasm)
    addresses = sorted(code)
    results = []
    for cls, names in TARGETS.items():
        for method in names:
            key = (cls, method)
            if key not in byclass:
                raise AssertionError(f"Missing verified original method: {cls}::{method}")
            start = byclass[key]
            nxt = min((v for v in ordered if v > start), default=start + 0x1200)
            end = min(nxt, start + 0x1200)
            left, right = bisect_right(addresses, start - 1), bisect_right(addresses, end - 1)
            rows = [code[v] for v in addresses[left:right]][:1000]
            if len(rows) < 2:
                raise AssertionError(f"No original disassembly at {cls}::{method} 0x{start:x}")
            matching = [line for line in rows if EXTRA.search(line)]
            selectors = []
            for line in matching:
                matched = re.search(r"Objc selector ref: (.+)$|Objc message: (.+)$", line)
                if matched:
                    name = matched.group(1) or matched.group(2)
                    if name not in selectors:
                        selectors.append(name)
            results.append({
                "class": cls, "method": method,
                "original104_imp": f"0x{start:x}",
                "bounded_end": f"0x{end:x}",
                "inspected_instruction_count": len(rows),
                "selectors_and_calls": selectors,
                "important_instructions": matching[:110],
                "static_only_not_runtime": True,
            })
    return {
        "status": "ORIGINAL104_UI_CALLCHAINS_READONLY_STATIC_PASS",
        "original104_deb_sha256": DEB_SHA, "original104_dashboard_sha256": DASH_SHA,
        "source": "Original DuoNavi 1.0.4 ARM64 metadata + llvm-objdump; not Native12",
        "dynamic_objc_dispatch_proven": False,
        "license_gate_runtime_proven": False,
        "native12_byte_or_callback_parity_proven": False,
        "total_methods": len(results), "methods": results,
    }


def markdown(result: dict) -> str:
    out = [
        "# DuoNavi 1.0.4 — read-only original UI method/call-chain audit", "",
        f"Original DEB SHA256: \`{DEB_SHA}\`.",
        f"Original Dashboard SHA256: \`{DASH_SHA}\`.", "",
        "**Static metadata/assembly only.** Calls in other branches, objc runtime dispatch, "
        "actual event order and Native12 matching are **not** established by this output.", "",
    ]
    for row in result["methods"]:
        out.append(f"## {row['class']}::{row['method']} — {row['original104_imp']}")
        out.append(f"Instructions sampled: {row['inspected_instruction_count']} "
                   f"to {row['bounded_end']}.")
        out.append("")
        for sel in row["selectors_and_calls"][:55]:
            out.append("- \`" + sel.replace("\n", " ") + "\`")
        if not row["selectors_and_calls"]:
            out.append("- No resolvable selector refs in this bounded assembly window")
        out += ["", "<details omitted: raw bounded refs preserved in JSON>", ""]
    out += [
        "## Next implementation gate", "",
        "Compare individual picker, focus, divider and native-size paths with Native12 "
        "same-method evidence, then reconnect independent QA controller/scene-host "
        "interfaces. Do not import vendor CBBridgeManager, license validation or original "
        "postinst. Test on iPhone before claiming visual or functional parity.", ""
    ]
    return "\n".join(out)


def main() -> None:
    ap = argparse.ArgumentParser()
    for name in ("deb", "dashboard", "metadata", "disasm", "json", "report"):
        ap.add_argument("--" + name, type=Path, required=True)
    args = ap.parse_args()
    result = run(args.deb, args.dashboard, args.metadata, args.disasm)
    args.json.parent.mkdir(parents=True, exist_ok=True)
    args.json.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n",
                         encoding="utf-8")
    args.report.write_text(markdown(result), encoding="utf-8")
    print(f"ORIGINAL104_UI_METHODS_PASS={result['total_methods']}")
    print(f"ORIGINAL104_UI_REPORT={args.report}")
    print(f"ORIGINAL104_UI_JSON={args.json}")


if __name__ == "__main__":
    main()
