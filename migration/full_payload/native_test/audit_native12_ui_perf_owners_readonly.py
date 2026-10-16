#!/usr/bin/env python3
"""Read-only Native12 UI cadence owner inventory.

Enumerate ObjC methods in the immutable signed Native12 DEB and sample their
ARM64 selector callsites for display links, redraws, animation and overlays.
This audit does not instrument actual CarPlay FPS, CPU or temperature and does
not modify/package/install the tweak.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import tempfile
from pathlib import Path

from audit_native12_license_class_xrefs import (
    MachO, select_arm64, BINARIES, NATIVE12_SHA,
)
from audit_native12_carplay_add_app_chain import methods, disassemble

EXPECTED_BINARY_SHA = {
    "DuoFaceUI": "cb40346d8ca504cb399abe31367847b4f980a01ba93810986ce1acf1fbe9eef9",
    "DuoFaceDashboard": "9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea",
}
OWNERS = {
    "DuoFaceUI": ["CBSplitSplashScreenView", "CBAppsManagerViewController"],
    "DuoFaceDashboard": [
        "CBBridgedPortalAppView", "CBMultitaskingOverlayView",
        "CBOverlayScrollView", "CBBridgedAssistantView",
        "CBBridgedSplitApp", "CBBridgedUIAppView",
        "CBDockSystemMonitorView", "CBDockMetricItemView",
        "CBWindow", "CBSplitSplashScreenView",
    ],
}
METHOD_RE = re.compile(
    r"displayLink|animat|render|draw|layout|update|refresh|monitor|"
    r"blink|pulse|timer|hidden|window|overlay|scroll|start|stop|"
    r"visibility|background|dealloc", re.I,
)
CALL_RE = re.compile(
    r"displayLink|addToRunLoop|invalidate|isPaused|setPaused|"
    r"scheduledTimer|startMonitoring|stopMonitoring|"
    r"setNeedsDisplay|setNeedsLayout|layoutIfNeeded|"
    r"setHidden|isHidden|viewDid|willMoveToWindow|"
    r"drawRect|setAlpha|startAnimating|stopAnimating|"
    r"animation|setFrame|CADisplayLink|updateMetrics|"
    r"performSelector|dispatch_source|refresh", re.I,
)
SIGNATURES = [
    "CADisplayLink", "displayLink", "setDisplayLink:",
    "scheduledTimerWithTimeInterval:", "setNeedsDisplay",
    "setNeedsLayout", "startAnimating", "stopAnimating",
    "startMonitoring", "stopMonitoring", "updateMetrics",
    "thermalState", "thermalStateDidChangeNotification",
]

def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def scan_one(name: str, raw: bytes) -> dict:
    assert sha256(raw) == EXPECTED_BINARY_SHA[name], name
    obj = MachO(select_arm64(raw))
    all_classes = obj.classes()
    out = {
        "binary_sha256": sha256(raw),
        "class_count": len(all_classes),
        "raw_string_occurrences": {
            s: len(list(re.finditer(re.escape(s.encode()), raw)))
            for s in SIGNATURES
        },
        "owners": {},
    }
    for owner in OWNERS[name]:
        if owner not in all_classes:
            out["owners"][owner] = {"present": False}
            continue
        catalog = methods(obj, owner)
        addresses = sorted({int(x["vm"]) for x in catalog.values() if x.get("vm")})
        owner_out = {
            "present": True,
            "method_count": len(catalog),
            "method_names": sorted(catalog.keys()),
            "candidate_methods": [],
        }
        for sel, spec in sorted(catalog.items()):
            begin = int(spec.get("vm") or 0)
            if not begin:
                continue
            end = next((v for v in addresses if v > begin), begin + 1024)
            # This is a bounded sample, not a full control-flow graph.
            lines = disassemble(obj, begin, min(end, begin + 2048))
            hints = []
            for n, line in enumerate(lines):
                if ("SEL_OR_LITERAL" not in line and "DIRECT_STRING" not in line):
                    continue
                if CALL_RE.search(line):
                    hints.append({
                        "selector_reference": line,
                        "nearby_calls": [
                            x for x in lines[n + 1:n + 9]
                            if "bl " in x or "blr " in x
                        ][:3],
                    })
            if METHOD_RE.search(sel) or hints:
                owner_out["candidate_methods"].append({
                    "name": sel,
                    "vm": hex(begin),
                    "objc_type": spec.get("type"),
                    "sampled_instructions": len(lines),
                    "method_end_estimate": hex(end),
                    "selector_hints": hints[:25],
                })
        out["owners"][owner] = owner_out
    return out

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--deb", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    original = args.deb.read_bytes()
    assert sha256(original) == NATIVE12_SHA, "original native12 immutable checksum mismatch"
    assert subprocess.check_output(
        ["dpkg-deb", "-f", str(args.deb), "Package"], text=True
    ).strip() == "com.duoface.independent"
    assert subprocess.check_output(
        ["dpkg-deb", "-f", str(args.deb), "Version"], text=True
    ).strip() == "0.1.0~native12"
    with tempfile.TemporaryDirectory(prefix="duoface-native12-ui-cadence-") as temp:
        subprocess.run(["dpkg-deb", "-x", str(args.deb), temp], check=True)
        binaries = {
            name: scan_one(name, (Path(temp) / rel).read_bytes())
            for name, rel in BINARIES.items()
        }
    assert binaries["DuoFaceDashboard"]["owners"]["CBBridgedPortalAppView"]["present"]
    assert binaries["DuoFaceDashboard"]["owners"]["CBMultitaskingOverlayView"]["present"]
    report = {
        "status": "NATIVE12_UI_PERF_OWNERS_STATIC_READONLY_PASS",
        "source_deb_sha256": NATIVE12_SHA,
        "source_branch": "feature/duoface-exact-payload-migration",
        "modifies_binary": False,
        "measures_runtime_cpu_or_fps_or_temperature": False,
        "disassembly_sampling_limit_bytes_per_method": 2048,
        "caveats": [
            "Selectors and sampled branch hints do not prove methods execute",
            "Dynamic dispatch and functions not exposed as ObjC can be missed",
            "Per-view displayLink property does not prove actual CarPlay FPS",
            "Actual UI hot path and CPU cost require iPhone/receiver instrumentation",
        ],
        "binaries": binaries,
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    for binary, content in binaries.items():
        print("SOURCE_BINARY", binary, content["binary_sha256"])
        for name, evidence in content["owners"].items():
            print("OWNER", name, "methods", evidence.get("method_count"),
                  "candidates", len(evidence.get("candidate_methods", [])))
    print("NATIVE12_UI_PERF_OWNERS_STATIC_READONLY_PASS")

if __name__ == "__main__":
    main()
