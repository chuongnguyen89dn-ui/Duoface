#!/usr/bin/env python3
"""Pinned, read-only full bounded Objective-C method and direct BL call audit.

Compare VisualTest12 ARM64 slice with Native12 ARM64 at the same VM, preserve the
original VisualTest12 DEB and Hub untouched. An Objective-C next-IMP range is an
upper bound on method bytes (may include padding/helpers), not a proven CFG.
No binary modifications, signing, DEB build, Sileo deployment or device tests.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import tempfile

from audit_native12_license_class_xrefs import BINARIES, MachO, select_arm64
from audit_visualtest12_macho_vm_abi import method_table

ROOT = Path(__file__).resolve().parents[3]
VISUAL = ROOT / "dist/visual-1.0.3-12/com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb"
NATIVE = ROOT / "dist/payload-migration/native12/com.duoface.independent_0.1.0~native12_iphoneos-arm64.deb"
SHA_VISUAL = "8b7dedf77b9ec05465b83fdb6e2d7127800eac232a34ecf12f2c08b3983a481a"
SHA_NATIVE = "85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7"

# Existing 2026-10-17 app-picker audit targets plus stable bridge method anchors.
# Owner + selector are exact metadata identities, not guessed symbol names.
TARGETS = {
    "DuoFaceUI": {
        "CBGeneralSettingsViewController": (
            "-loadPreferences", "-savePreferences",
        ),
    },
    "DuoFaceDashboard": {
        "CBMultitaskingOverlayView": (
            "-addMoreAppsTapped:", "-dismissCustomAlert:",
            "-setupAppPickerCardsInCardW:cardH:contentY:", "-appSelected:",
        ),
        "CBDashboardSettings": (
            "-init", "-reload", "-reloadAppPrefs", "-bridgedApps", "-setBridgedApps:",
        ),
        "CBBridgeManager": (
            "-handleSettingsChanged", "-showAppPickerForSlot:", "-shouldBridge:",
            "-trackBridgedBundleID:", "-requestStateChange:",
            "-loadNewAppFromCurrentRequest:", "-syncDashboardPolicySignalToDisk",
        ),
        "CBBridgeManagerDashboard": (
            "-bridgedApps", "+isDashboardPolicySignalActive",
            "+shouldInterceptLaunchForApp:",
        ),
    },
}

def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def all_implementations(macho: MachO) -> dict:
    """Return registered ObjC method IMP addresses grouped by VM address."""
    result = {}
    for owner in macho.classes():
        for selector, info in method_table(macho, owner).items():
            addr = info["imp_vm"]
            if addr:
                result.setdefault(addr, []).append(f"{owner}::{selector}")
    return result

def bounded_slice(m: MachO, all_imp: dict, addr: int):
    text_sections = [s for s in m.sections if s["segment"] == "__TEXT" and s["name"] == "__text"]
    assert len(text_sections) == 1, "expected one __TEXT/__text section"
    s = text_sections[0]
    if not s["vm"] <= addr < s["vm"] + s["size"] or addr % 4:
        return None, "IMP not arm64-aligned within __TEXT/__text"
    next_methods = [x for x in all_imp if addr < x < s["vm"] + s["size"]]
    upper = min(next_methods, default=s["vm"] + s["size"])
    size = upper - addr
    if size <= 0 or size % 4 or size > 65536:
        return None, f"unbounded or unusually large ObjC IMP region: {size}"
    start = m.map(addr)
    if not (start >= s["fileoff"] and start + size <= s["fileoff"] + s["size"]):
        return None, "IMP segment mapping crosses section boundary"
    return m.data[start:start + size], None

def direct_bl_calls(code: bytes, start_vm: int, all_imp: dict) -> list:
    """Decode direct AArch64 BL immediate; indirect calls remain unknown."""
    rows = []
    for offset in range(0, len(code), 4):
        word, = struct.unpack_from("<I", code, offset)
        if word & 0xfc000000 != 0x94000000:
            continue
        rel = word & 0x03ffffff
        if rel & (1 << 25):
            rel -= (1 << 26)
        dest = start_vm + offset + rel * 4
        rows.append({"at": hex(start_vm + offset), "destination": hex(dest),
                     "exact_registered_objc_imp": all_imp.get(dest, [])[:5]})
    return rows

def evaluate(m1: MachO, m2: MachO, name: str) -> dict:
    all1, all2 = all_implementations(m1), all_implementations(m2)
    out = {}
    for owner, sels in TARGETS[name].items():
        original, native = method_table(m1, owner), method_table(m2, owner)
        for sel in sels:
            id = f"{owner}::{sel}"
            a, b = original.get(sel), native.get(sel)
            if a is None or b is None:
                out[id] = {"present_in_both": False, "error": "missing registered selector"}
                continue
            left, le = bounded_slice(m1, all1, a["imp_vm"])
            right, re = bounded_slice(m2, all2, b["imp_vm"])
            row = {
                "present_in_both": True,
                "visual_imp_vm": hex(a["imp_vm"]),
                "native_imp_vm": hex(b["imp_vm"]),
                "same_imp_vm": a["imp_vm"] == b["imp_vm"],
                "visual_type": a["type"],
                "native_type": b["type"],
                "same_type_encoding": a["type"] == b["type"],
                "range_model": "from IMP VM to next registered ObjC IMP or end of __TEXT/__text",
                "range_proven_exact_method_end": False,
                "visual_range_error": le, "native_range_error": re,
            }
            if left is not None and right is not None:
                calls1 = direct_bl_calls(left, a["imp_vm"], all1)
                calls2 = direct_bl_calls(right, b["imp_vm"], all2)
                row.update({
                    "visual_range_bytes": len(left), "native_range_bytes": len(right),
                    "same_compared_region_length": len(left) == len(right),
                    "entire_bounded_region_byte_equal": left == right,
                    "visual_range_sha256": sha(left), "native_range_sha256": sha(right),
                    "different_byte_count": (sum(x != y for x, y in zip(left, right))
                                             if len(left) == len(right) else None),
                    "visual_direct_bl_count": len(calls1),
                    "native_direct_bl_count": len(calls2),
                    "same_direct_bl_destinations": ([z["destination"] for z in calls1]
                                                     == [z["destination"] for z in calls2]),
                    "visual_first_40_direct_bl": calls1[:40],
                    "native_first_40_direct_bl": calls2[:40],
                    "unresolved_indirect_objc_msgsend_or_branches": True,
                })
            out[id] = row
    return out

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--output", required=True, type=Path)
    opts = ap.parse_args()
    assert sha(VISUAL.read_bytes()) == SHA_VISUAL, "VisualTest12 immutable input changed"
    assert sha(NATIVE.read_bytes()) == SHA_NATIVE, "Hub Native12 immutable input changed"
    for package, identity, version in (
        (VISUAL, "com.duonavi.app", "1.0.3-12~visualtest"),
        (NATIVE, "com.duoface.independent", "0.1.0~native12"),
    ):
        for key, wanted in (("Package", identity), ("Version", version),
                            ("Architecture", "iphoneos-arm64")):
            got = subprocess.check_output(["dpkg-deb", "-f", str(package), key], text=True).strip()
            assert got == wanted, (key, wanted, got)
    with tempfile.TemporaryDirectory(prefix="visualtest12-carplay-methods-") as temp:
        root = Path(temp)
        for version, package in (("visual", VISUAL), ("native", NATIVE)):
            subprocess.run(["dpkg-deb", "-x", str(package), str(root / version)], check=True)
        hosts = {}
        for name, relative in BINARIES.items():
            m1 = MachO(select_arm64((root / "visual" / relative).read_bytes()))
            m2 = MachO(select_arm64((root / "native" / relative).read_bytes()))
            hosts[name] = evaluate(m1, m2, name)
    summary = {
        name: {
            "selected": len(rows),
            "present_in_both": sum(bool(x.get("present_in_both")) for x in rows.values()),
            "fully_bounded": sum("entire_bounded_region_byte_equal" in x for x in rows.values()),
            "identical_bounded_bytes": sum(x.get("entire_bounded_region_byte_equal") is True
                                           for x in rows.values()),
            "changed_bounded_bytes": sum(x.get("entire_bounded_region_byte_equal") is False
                                         for x in rows.values()),
            "type_encoding_mismatch": sum(x.get("same_type_encoding") is False
                                          for x in rows.values()),
        } for name, rows in hosts.items()
    }
    result = {
        "status": "VISUALTEST12_NATIVE12_CARPLAY_BOUNDED_METHODS_STATIC",
        "input_visual_sha256": SHA_VISUAL, "input_native12_hub_sha256": SHA_NATIVE,
        "summary": summary, "hosts": hosts,
        "bounded_method_region_is_not_proven_cfg": True,
        "dynamic_dispatch_or_helper_runtime_parity_proven": False,
        "arm64e_slice_regression_proven": False,
        "carplay_device_functionality_proven": False,
        "read_only": True, "hub_modified": False, "visualtest_modified": False,
        "deb_built": False, "sileo_deployed": False,
        "runtime_license_fully_removed": False, "device_tested": False,
    }
    opts.output.parent.mkdir(parents=True, exist_ok=True)
    opts.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({"status": result["status"], "summary": summary}, indent=2))

if __name__ == "__main__":
    main()
