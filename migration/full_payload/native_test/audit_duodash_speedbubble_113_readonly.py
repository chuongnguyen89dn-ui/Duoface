#!/usr/bin/env python3
"""Read-only exact pinned DuoDash 1.1.3 HUD + speed source method inventory.

Do not equate this DauDat fullscreen427 archive to original stock DuoDash.
Do not execute, repackage, import or install any DuoDash binary.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import tempfile
from pathlib import Path

from audit_duodash_perf_thermal_113 import (
    NormalizedMachO, fat_slices, PINNED_GIT_BLOB,
)
from audit_native12_carplay_add_app_chain import methods, disassemble

OWNERS = [
    "CNABBubbleView", "CNABGpsSpeed", "CNABNavData",
    "CNABCarPlayObserver", "CNABSpringBoardObserver",
    "DataRouter", "CNABUIRootView",
]
SELECTOR_HINT = re.compile(
    r"speed|limit|bubble|gps|location|"
    r"update|frame|layout|attach|window|carplay|"
    r"show|hide|style|draw|refresh|dealloc|start|stop|"
    r"setNeeds|isHidden|display|timer|app", re.I
)
LITERAL_HINT = re.compile(
    r"speed|limit|bubble|GPS|route|location|carplay|"
    r"notify|shared|window|source|km/h|mph", re.I
)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--deb", required=True, type=Path)
    ap.add_argument("--out", required=True, type=Path)
    args = ap.parse_args()

    original = args.deb.read_bytes()
    blob = subprocess.check_output(
        ["git", "hash-object", str(args.deb)], text=True
    ).strip()
    assert blob == PINNED_GIT_BLOB, (blob, PINNED_GIT_BLOB)
    report = {
        "status": "DUODASH_113_BUBBLE_READONLY_OWNER_AUDIT",
        "package_sha256": hashlib.sha256(original).hexdigest(),
        "git_blob": blob,
        "source_repo": "chuongnguyen89dn-ui/DauDat-CarPlay",
        "source_commit": "5f683ad16a2c4f2b37e333e891cfb8f7ba3e0d6b",
        "source_path": "DuoDash_1.1.3_Fullscreen427_iphoneos-arm64.deb",
        "reference_is_original_stock_113_verified": False,
        "modified_deb": False,
        "runtime_tested": False,
        "notes": [
            "Methods and callsites are static metadata + bounded instruction samples",
            "Must not import this third-party binary into DuoFace",
            "Use owner geometry/lifecycle as research, implement independent module",
        ],
        "architecture": {},
    }
    with tempfile.TemporaryDirectory(prefix="duodash-speed-readonly-") as td:
        subprocess.run(["dpkg-deb", "-x", str(args.deb), td], check=True)
        dylib = Path(td) / "var/jb/usr/lib/TweakInject/DuoDash.dylib"
        raw = dylib.read_bytes()
        report["tweak_dylib_sha256"] = hashlib.sha256(raw).hexdigest()
        for arch, data in fat_slices(raw).items():
            if arch not in ("arm64", "arm64e"):
                continue
            obj = NormalizedMachO(data)
            all_classes = obj.classes()
            result = {
                "class_count": len(all_classes),
                "owners": {},
                "candidate_text_literals": [],
            }
            for sec in obj.sections:
                if sec["name"] not in ("__cstring", "__objc_methname"):
                    continue
                payload = data[sec["fileoff"]:sec["fileoff"]+sec["size"]]
                for match in re.finditer(rb"[\x20-\x7e]{4,}\x00", payload):
                    s = match.group()[:-1].decode("ascii", "replace")
                    if len(s) < 130 and LITERAL_HINT.search(s):
                        result["candidate_text_literals"].append(s)
            result["candidate_text_literals"] = sorted(set(
                result["candidate_text_literals"]))[:350]
            for owner in OWNERS:
                if owner not in all_classes:
                    result["owners"][owner] = {"present": False}
                    continue
                catalog = methods(obj, owner)
                addresses = sorted({
                    int(entry["vm"]) for entry in catalog.values()
                    if entry.get("vm")
                })
                entries = []
                for name, spec in sorted(catalog.items()):
                    address = int(spec["vm"])
                    if not address:
                        continue
                    next_address = next(
                        (v for v in addresses if v>address), address+768
                    )
                    if not SELECTOR_HINT.search(name):
                        continue
                    instructions = disassemble(
                        obj, address, min(next_address, address+512)
                    )
                    hits = [
                        ins for ins in instructions
                        if "SEL_OR_LITERAL" in ins or "DIRECT_STRING" in ins
                    ]
                    entries.append({
                        "method": name,
                        "imp": hex(address),
                        "objc_type": spec.get("type"),
                        "bounded_instruction_count": len(instructions),
                        "selector_or_literal_hints": hits[:18],
                    })
                result["owners"][owner] = {
                    "present": True,
                    "method_count": len(catalog),
                    "all_methods": sorted(catalog),
                    "high_signal_methods": entries,
                }
            report["architecture"][arch] = result
    assert report["architecture"], "No valid DuoDash ARM64 slices"
    assert any(
        "CNABBubbleView" in part["owners"]
        and part["owners"]["CNABBubbleView"]["present"]
        for part in report["architecture"].values()
    ), "DuoDash bubble view not present; wrong source"
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(
        json.dumps(report, ensure_ascii=False, indent=2)+"\n",
        encoding="utf-8",
    )
    print("DUODASH_SPEED_BUBBLE_OWNER_READONLY_AUDIT_PASS")
    print("architectures", list(report["architecture"]))
    for arch, data in report["architecture"].items():
        print(arch, {k: v.get("method_count")
                     for k, v in data["owners"].items()})
    print("NO_DEB_NO_DEVICE_QA")


if __name__ == "__main__":
    main()
