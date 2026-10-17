#!/usr/bin/env python3
"""DuoFace VisualTest12 vs Native12 read-only Mach-O VM, architecture and ABI audit.

Compares matching addresses/sections of pinned arm64 slices, never raw fat-file
offsets. The report is NOT proof of runtime equivalence or license removal.
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

ROOT = Path(__file__).resolve().parents[3]
VISUAL = ROOT / "dist/visual-1.0.3-12/com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb"
NATIVE = ROOT / "dist/payload-migration/native12/com.duoface.independent_0.1.0~native12_iphoneos-arm64.deb"
LEDGER = ROOT / "dist/payload-migration/native4/BAO_CAO.json"
PIN_VISUAL = "8b7dedf77b9ec05465b83fdb6e2d7127800eac232a34ecf12f2c08b3983a481a"
PIN_NATIVE = "85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7"
WATCH = {
    "DuoFaceUI": {
        "XXRootViewController": ("-checkAndPresentLicenseModalIfNeeded",),
        "CBLicenseSyncManager": ("-isLicenseCurrentlyValid", "-checkAndSyncLicenseIfNeeded"),
    },
    "DuoFaceDashboard": {
        "CBBridgeManager": ("-requestStateChange:", "-loadNewAppFromCurrentRequest:",
                            "-shouldBridge:", "-syncDashboardPolicySignalToDisk"),
        "CBBridgeManagerDashboard": ("+isDashboardPolicySignalActive",
                                     "+shouldInterceptLaunchForApp:"),
        "CBLicenseSyncManager": ("-isLicenseCurrentlyValid", "-checkAndSyncLicenseIfNeeded"),
    },
}

def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def architectures(data: bytes) -> list[dict]:
    magic = data[:4]
    if magic == bytes.fromhex("cffaedfe"):
        cpu, sub = struct.unpack_from("<II", data, 4)
        rows = [(cpu, sub, 0, len(data))]
    elif magic in (bytes.fromhex("cafebabe"), bytes.fromhex("cafebabf")):
        wide = magic == bytes.fromhex("cafebabf")
        count, = struct.unpack_from(">I", data, 4)
        assert 1 <= count <= 12, "unexpected FAT arch count"
        rows = []
        stride = 32 if wide else 20
        for j in range(count):
            p = 8 + j * stride
            cpu, sub = struct.unpack_from(">II", data, p)
            offset, length = struct.unpack_from(">QQ" if wide else ">II", data, p + 8)
            assert offset > 0 and length > 32 and offset + length <= len(data)
            rows.append((cpu, sub, offset, length))
    else:
        raise ValueError("unsupported Mach-O magic " + magic.hex())
    seen = set()
    out = []
    for cpu, subtype, offset, length in rows:
        architecture = ("arm64e" if cpu == 0x0100000c and (subtype & 0xffffff) == 2
                        else "arm64" if cpu == 0x0100000c and (subtype & 0xffffff) == 0
                        else f"cpu_{cpu:08x}_sub_{subtype:08x}")
        assert (cpu, subtype) not in seen, "duplicate architecture"
        seen.add((cpu, subtype))
        chunk = data[offset:offset + length]
        out.append({"architecture": architecture, "cpu": hex(cpu),
                    "cpu_subtype": hex(subtype), "slice_bytes": length,
                    "slice_sha256": sha(chunk)})
    return out

def signature(m: MachO) -> dict:
    p = 32
    signatures = []
    for _ in range(m.ncmds):
        cmd, n = struct.unpack_from("<II", m.data, p)
        if cmd == 0x1d:  # LC_CODE_SIGNATURE
            offset, size = struct.unpack_from("<II", m.data, p + 8)
            signatures.append({"offset": offset, "size": size,
                               "inside_slice": 0 <= offset < len(m.data)
                                               and 0 < size <= len(m.data) - offset})
        p += n
    return {"present": bool(signatures), "commands": signatures,
            "signature_integrity_verified": False}

def method_table(m: MachO, name: str) -> dict:
    classes = m.classes()
    if name not in classes:
        return {}
    ptr = classes[name]["class_ptr"]
    out = {}
    for prefix, obj in (("-", ptr), ("+", m.ptr(ptr))):
        if not obj:
            continue
        head = m.ptr((m.ptr(obj + 32) & ~7) + 32)
        if not head:
            continue
        flags, count = m.p32(head), m.p32(head + 4)
        assert 0 <= count <= 500
        relative = bool(flags & 0x80000000)
        for i in range(count):
            entry = head + 8 + i * (12 if relative else 24)
            if relative:
                selector_ptr = entry + m.pi32(entry)
                selector_ptr = selector_ptr if flags & 0x40000000 else m.ptr(selector_ptr)
                type_ptr = entry + 4 + m.pi32(entry + 4)
                imp = entry + 8 + m.pi32(entry + 8)
            else:
                selector_ptr, type_ptr, imp = (m.ptr(entry), m.ptr(entry + 8), m.ptr(entry + 16))
            out[prefix + m.cstr(selector_ptr)] = {"type": m.cstr(type_ptr), "imp_vm": imp}
    return out

def readonly_methods(a: MachO, b: MachO, binary: str) -> dict:
    rows = {}
    for owner, watch in WATCH[binary].items():
        at, bt = method_table(a, owner), method_table(b, owner)
        for key in watch:
            av, bv = at.get(key), bt.get(key)
            if av is None or bv is None:
                rows[f"{owner}::{key}"] = {"present_on_both": False}
                continue
            aa = a.data[a.map(av["imp_vm"]):a.map(av["imp_vm"]) + 16]
            bb = b.data[b.map(bv["imp_vm"]):b.map(bv["imp_vm"]) + 16]
            rows[f"{owner}::{key}"] = {
                "present_on_both": True,
                "same_objc_type_encoding": av["type"] == bv["type"],
                "visual_type": av["type"], "native_type": bv["type"],
                "visual_imp_vm": hex(av["imp_vm"]), "native_imp_vm": hex(bv["imp_vm"]),
                "same_imp_vm": av["imp_vm"] == bv["imp_vm"],
                "same_first_16_instruction_bytes": aa == bb,
                "visual_first16_sha256": sha(aa),
                "native_first16_sha256": sha(bb),
            }
    return rows

def merge_spans(methods: list[dict]) -> list[tuple[int, int]]:
    intervals = sorted((int(x["file_offset"]), int(x["file_offset"]) + int(x["bytes_replaced"]))
                       for x in methods)
    result: list[list[int]] = []
    for start, end in intervals:
        if result and start <= result[-1][1]:
            result[-1][1] = max(end, result[-1][1])
        else:
            result.append([start, end])
    return [tuple(x) for x in result]

def address_section_audit(a: MachO, b: MachO, methods: list[dict]) -> dict:
    """Only compare sections with the same VM start; never assume offsets match."""
    x = {(s["segment"], s["name"]): s for s in a.sections}
    y = {(s["segment"], s["name"]): s for s in b.sections}
    ledger = merge_spans(methods)
    entries = []
    for key in sorted(set(x) | set(y)):
        sa, sb = x.get(key), y.get(key)
        if sa is None or sb is None:
            entries.append({"section": "/".join(key), "present_on_both": False})
            continue
        row = {"section": "/".join(key), "present_on_both": True,
               "same_vm_start": sa["vm"] == sb["vm"],
               "visual_vm": hex(sa["vm"]), "native_vm": hex(sb["vm"]),
               "visual_bytes": sa["size"], "native_bytes": sb["size"],
               "same_size": sa["size"] == sb["size"]}
        # Comparing offset-aligned bytes without an identical VM is misleading.
        same_address = sa["vm"] == sb["vm"]
        length = min(sa["size"], sb["size"])
        if (same_address and length and
                key[1] not in {"__bss", "__common", "__thread_bss", "__zerofill"} and
                sa["fileoff"] + length <= len(a.data) and
                sb["fileoff"] + length <= len(b.data)):
            left = a.data[sa["fileoff"]:sa["fileoff"] + length]
            right = b.data[sb["fileoff"]:sb["fileoff"] + length]
            row["same_vm_bytes_compared"] = length
            row["changed_bytes_at_same_vm"] = sum(i != j for i, j in zip(left, right))
            if key[1] == "__text":
                inside = outside = 0
                outside_addresses = []
                j = 0
                for i, (u, v) in enumerate(zip(left, right)):
                    if u == v:
                        continue
                    native_offset = sb["fileoff"] + i
                    while j < len(ledger) and ledger[j][1] <= native_offset:
                        j += 1
                    if j < len(ledger) and ledger[j][0] <= native_offset < ledger[j][1]:
                        inside += 1
                    else:
                        outside += 1
                        outside_addresses.append(sa["vm"] + i)
                clusters = []
                for address in outside_addresses:
                    if clusters and clusters[-1]["vm_end_exclusive"] == address:
                        clusters[-1]["vm_end_exclusive"] += 1
                        clusters[-1]["bytes"] += 1
                    else:
                        clusters.append({"vm_start": address, "vm_end_exclusive": address+1, "bytes": 1})
                row["outside_ledger_changed_clusters_total"] = len(clusters)
                row["outside_ledger_largest_changed_clusters"] = [
                    {"vm_start": hex(item["vm_start"]),
                     "vm_end_exclusive": hex(item["vm_end_exclusive"]),
                     "bytes": item["bytes"]}
                    for item in sorted(clusters, key=lambda q: (-q["bytes"], q["vm_start"]))[:40]
                ]
                row["text_changed_bytes_within_native4_stub_spans"] = inside
                row["text_changed_bytes_outside_native4_stub_spans"] = outside
                row["native4_ledger_scope_is_reference_only"] = True
        else:
            row["same_vm_bytes_compared"] = 0
            row["compare_reason"] = "different_VM_or_non_file_backed_or_zerofill_section"
        entries.append(row)
    text = [r for r in entries if r["section"].endswith("/__text")]
    return {"entries": entries, "text_summary": {
        "matched_text_sections": sum(r.get("same_vm_bytes_compared", 0) > 0 for r in text),
        "compared_text_bytes": sum(r.get("same_vm_bytes_compared", 0) for r in text),
        "changed_text_bytes": sum(r.get("changed_bytes_at_same_vm", 0) for r in text),
        "changed_text_inside_native4_ledger_spans":
            sum(r.get("text_changed_bytes_within_native4_stub_spans", 0) for r in text),
        "changed_text_outside_native4_ledger_spans":
            sum(r.get("text_changed_bytes_outside_native4_stub_spans", 0) for r in text),
    }}

def audit_binary(a: bytes, b: bytes, name: str, ledger: dict) -> dict:
    orig, native = MachO(select_arm64(a)), MachO(select_arm64(b))
    sections = address_section_audit(orig, native, ledger["patched_methods"])
    watched = readonly_methods(orig, native, name)
    return {
        "visual_raw_sha256": sha(a), "native12_raw_sha256": sha(b),
        "visual_architectures": architectures(a), "native12_architectures": architectures(b),
        "visual_arm64_signature": signature(orig),
        "native12_arm64_signature": signature(native),
        "visual_arm64_load_commands": orig.ncmds, "native12_arm64_load_commands": native.ncmds,
        "visual_arm64_segments": [{
            "name": seg[4], "vm": hex(seg[0]), "vmsize": seg[1],
            "fileoff": seg[2], "filesize": seg[3]} for seg in orig.segments],
        "native12_arm64_segments": [{
            "name": seg[4], "vm": hex(seg[0]), "vmsize": seg[1],
            "fileoff": seg[2], "filesize": seg[3]} for seg in native.segments],
        "sections": sections,
        "critical_method_abi_and_instruction_prefixes": watched,
        "native4_methods_in_historical_ledger": len(ledger["patched_methods"]),
        "rebuild_safe_proven": False,
        "runtime_compatibility_proven": False,
    }

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    assert sha(VISUAL.read_bytes()) == PIN_VISUAL
    assert sha(NATIVE.read_bytes()) == PIN_NATIVE
    for path, package, version in (
        (VISUAL, "com.duonavi.app", "1.0.3-12~visualtest"),
        (NATIVE, "com.duoface.independent", "0.1.0~native12"),
    ):
        for field, expected in (("Package", package), ("Version", version), ("Architecture", "iphoneos-arm64")):
            got = subprocess.check_output(["dpkg-deb", "-f", str(path), field], text=True).strip()
            assert got == expected, (path, field, got)
    ledger = json.loads(LEDGER.read_text())["method_bodies"]
    assert set(ledger) == set(BINARIES)
    with tempfile.TemporaryDirectory(prefix="duoface-vm-abi-") as temp:
        base = Path(temp)
        for key, package in (("visual", VISUAL), ("native", NATIVE)):
            subprocess.run(["dpkg-deb", "-x", str(package), str(base / key)], check=True)
        hosts = {name: audit_binary((base / "visual" / path).read_bytes(),
                                    (base / "native" / path).read_bytes(), name, ledger[name])
                 for name, path in BINARIES.items()}
    report = {
        "status": "VISUALTEST12_NATIVE12_VM_ABI_READONLY",
        "visual_deb_sha256": PIN_VISUAL, "native12_hub_deb_sha256_untouched": PIN_NATIVE,
        "hosts": hosts,
        "read_only": True, "binary_modified": False, "hub_modified": False,
        "deb_built": False, "sileo_deployed": False, "device_tested": False,
        "license_runtime_fully_removed": False, "source_equivalent_rebuild_available": False,
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    for name, info in hosts.items():
        print(name, "visual_archs", [x["architecture"] for x in info["visual_architectures"]],
              "native_archs", [x["architecture"] for x in info["native12_architectures"]],
              "text_summary", info["sections"]["text_summary"])
        for section in info["sections"]["entries"]:
            if section["section"].endswith("/__text"):
                print(name, "outside_ledger_top", section.get("outside_ledger_largest_changed_clusters", [])[:12])
    print("VISUALTEST12_VM_ABI_READONLY_COMPLETE_NO_RELEASE")

if __name__ == "__main__":
    main()
