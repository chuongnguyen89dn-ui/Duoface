#!/usr/bin/env python3
"""Read-only exact VisualTest12 vs proven Native12 byte-lineage/ABI census.

No build, host binary patch, entitlement change, deployment, or inferred device test.
The results isolate whether an existing Native12 runtime is a byte-level
compatible reference for VisualTest12, not a claim of license-free rebuild.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import pathlib
import subprocess
import tempfile
from audit_native12_license_class_xrefs import BINARIES, MachO, select_arm64

ROOT = pathlib.Path(__file__).resolve().parents[3]
VISUAL = ROOT / "dist/visual-1.0.3-12/com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb"
NATIVE = ROOT / "dist/payload-migration/native12/com.duoface.independent_0.1.0~native12_iphoneos-arm64.deb"
LEDGER = ROOT / "dist/payload-migration/native4/BAO_CAO.json"
VISUAL_SHA = "8b7dedf77b9ec05465b83fdb6e2d7127800eac232a34ecf12f2c08b3983a481a"
NATIVE_SHA = "85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7"

def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def metadata(path: pathlib.Path, key: str) -> str:
    return subprocess.check_output(["dpkg-deb", "-f", str(path), key], text=True).strip()

def spans(method_rows: list[dict], limit: int) -> list[tuple[int, int]]:
    raw = sorted((int(m["file_offset"]), int(m["file_offset"]) + int(m["bytes_replaced"]))
                 for m in method_rows)
    assert all(0 <= a < b <= limit for a, b in raw), "Original patch ledger outside Mach-O"
    merged: list[list[int]] = []
    for a, b in raw:
        if merged and a <= merged[-1][1]:
            merged[-1][1] = max(merged[-1][1], b)
        else:
            merged.append([a, b])
    return [(a, b) for a, b in merged]

def difference_ranges(a: bytes, b: bytes, maximum: int = 30) -> dict:
    """Report changed contiguous byte runs; do not produce binary patch instructions."""
    if len(a) != len(b):
        return {"equal_length": False, "left_bytes": len(a), "right_bytes": len(b)}
    changed = sum(x != y for x, y in zip(a, b))
    ranges = []
    i = 0
    while i < len(a):
        if a[i] == b[i]:
            i += 1
            continue
        start = i
        while i < len(a) and a[i] != b[i]:
            i += 1
        if len(ranges) < maximum:
            ranges.append({"start": start, "end_exclusive": i, "bytes": i-start})
    return {"equal_length": True, "changed_bytes": changed,
            "example_changed_intervals": ranges, "interval_sample_truncated": changed > 0 and len(ranges) == maximum}

def inspect(name: str, before: bytes, after: bytes, ledger: dict) -> dict:
    oa, na = select_arm64(before), select_arm64(after)
    om, nm = MachO(oa), MachO(na)
    original_classes = om.classes()
    native_classes = nm.classes()
    span = spans(ledger["patched_methods"], len(oa))
    # Inspect every differing byte in addition to method prefixes: all other
    # changes must be surfaced, never assumed to be only license cleanup.
    in_known, outside_known = 0, 0
    j = 0
    if len(oa) == len(na):
        for i, (x, y) in enumerate(zip(oa, na)):
            if x == y:
                continue
            while j < len(span) and i >= span[j][1]:
                j += 1
            if j < len(span) and span[j][0] <= i < span[j][1]:
                in_known += 1
            else:
                outside_known += 1
    else:
        outside_known = -1
    return {
        "visual_host_sha256": digest(before),
        "native12_host_sha256": digest(after),
        "same_host_size": len(before) == len(after),
        "same_arm64_size": len(oa) == len(na),
        "visual_objc_class_count": len(original_classes),
        "native_objc_class_count": len(native_classes),
        "same_objc_class_names": set(original_classes) == set(native_classes),
        "same_objc_method_names_per_class": (
            {k: sorted(v["methods"]) for k, v in original_classes.items()}
            == {k: sorted(v["methods"]) for k, v in native_classes.items()}
        ),
        "known_native4_stubbed_method_count": len(ledger["patched_methods"]),
        "bytes_different_inside_native4_ledger_spans": in_known,
        "bytes_different_outside_native4_ledger_spans": outside_known,
        "raw_host_diff": difference_ranges(before, after),
        "arm64_diff": difference_ranges(oa, na),
        "dynamic_dispatch_and_carplay_functionality_still_unverified": True,
    }

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=pathlib.Path, required=True)
    args = ap.parse_args()
    assert digest(VISUAL.read_bytes()) == VISUAL_SHA, "VisualTest12 baseline SHA mismatch"
    assert digest(NATIVE.read_bytes()) == NATIVE_SHA, "Hub Native12 baseline SHA mismatch"
    assert metadata(VISUAL, "Package") == "com.duonavi.app"
    assert metadata(VISUAL, "Version") == "1.0.3-12~visualtest"
    assert metadata(NATIVE, "Package") == "com.duoface.independent"
    assert metadata(NATIVE, "Version") == "0.1.0~native12"
    assert metadata(VISUAL, "Architecture") == metadata(NATIVE, "Architecture") == "iphoneos-arm64"
    ledger = json.loads(LEDGER.read_text(encoding="utf-8"))["method_bodies"]
    assert set(ledger) == set(BINARIES)
    with tempfile.TemporaryDirectory(prefix="visualtest12-lineage-") as td:
        root = pathlib.Path(td)
        for key, deb in [("visual", VISUAL), ("native", NATIVE)]:
            subprocess.run(["dpkg-deb", "-x", str(deb), str(root/key)], check=True)
        result = {}
        for binary, path in BINARIES.items():
            before = (root/"visual"/path).read_bytes()
            after = (root/"native"/path).read_bytes()
            result[binary] = inspect(binary, before, after, ledger[binary])
    report = {
        "status": "VISUALTEST12_NATIVE12_BYTE_LINEAGE_READONLY",
        "visual_deb_sha256": VISUAL_SHA,
        "native12_untouched_deb_sha256": NATIVE_SHA,
        "native12_ledger_method_count": sum(len(z["patched_methods"]) for z in ledger.values()),
        "hosts": result,
        "read_only": True,
        "binary_modified": False,
        "hub_modified": False,
        "deb_built": False,
        "sileo_deployed": False,
        "runtime_license_fully_removed": False,
        "core_source_available": False,
        "device_tested": False,
        "release_approved": False,
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    print(json.dumps({"status": report["status"], "ledger_count": report["native12_ledger_method_count"],
                      "hosts": {k: {"outside_known": v["bytes_different_outside_native4_ledger_spans"],
                                     "same_method_names": v["same_objc_method_names_per_class"],
                                     "inside_known": v["bytes_different_inside_native4_ledger_spans"]}
                                for k, v in result.items()}}, indent=2))

if __name__ == "__main__":
    main()
