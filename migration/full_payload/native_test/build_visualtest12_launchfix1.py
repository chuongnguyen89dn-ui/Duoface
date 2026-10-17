#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build actual com.duonavi.app VisualTest12 launch recovery test candidate.

Source is EXACT original VisualTest12 DEB, never the independent Hub binary.
Apply previously device-tested Native4 291 license method stubs and the
Native5 two expiry-state methods to its own ARM64 slices. Preserve all other
original package files including original CarPlay hook and asset bundle.
This is an installable recovery TEST, not runtime-proven/full-source rewrite.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import tempfile

from audit_native4_license_code import inspect, slurp_slices
from build_native4 import eligible, original_abi_stub, NOP
from build_native5 import FLAG_METHODS, preserve_entitlements_and_resign

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "dist/visual-1.0.3-12/com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb"
SOURCE_SHA = "8b7dedf77b9ec05465b83fdb6e2d7127800eac232a34ecf12f2c08b3983a481a"
VERSION = "1.0.3-12~visualtest12launch1"
PACKAGE = "com.duonavi.app"
FILES = {
    "DuoFaceUI": "var/jb/Applications/DuoFaceUI.app/DuoFaceUI",
    "DuoFaceDashboard": "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib",
}
EXPECTED_COUNTS = {"DuoFaceUI": 248, "DuoFaceDashboard": 43}

def digest(blob: bytes) -> str:
    return hashlib.sha256(blob).hexdigest()

def getfield(package: Path, key: str) -> str:
    return subprocess.check_output(["dpkg-deb", "-f", str(package), key], text=True).strip()

def write_patched_arm64(original: bytes, name: str) -> tuple[bytes, list[dict], list[dict], dict]:
    slices = list(slurp_slices(original))
    generic = [x for x in slices if x["arch"] == "arm64:0"]
    assert len(generic) == 1, (name, [s["arch"] for s in slices])
    raw = bytearray(generic[0]["bytes"])
    inventory = inspect(bytes(raw))
    assert not inventory["parser_warnings"], (name, inventory["parser_warnings"])
    assert not inventory["methods_without_safe_text_start"], (name, inventory["methods_without_safe_text_start"][:7])
    selected, expired, spans = [], [], []
    found_flags = set()
    for method in inventory["license_named_methods"]:
        key = (method["class"], method["selector"])
        is_license_method = eligible(*key)
        is_expiry_state_method = name == "DuoFaceUI" and key in FLAG_METHODS
        if not (is_license_method or is_expiry_state_method):
            continue
        assert method["listed_in_lc_function_starts"] and method["inside_executable_text"], key
        off = int(method["imp_file_offset"], 16)
        size = method["estimated_function_span"]
        assert isinstance(size, int) and 4 <= size < 100000 and size % 4 == off % 4 == 0, key
        if is_expiry_state_method:
            expected_sig, stub = FLAG_METHODS[key]
            assert method["type_encoding"] == expected_sig, (key, method["type_encoding"])
            found_flags.add(key)
        else:
            stub = original_abi_stub(method)
        assert 0 < len(stub) <= size and len(stub) % 4 == 0
        spans.append((off, off + size, key))
        original_span = bytes(raw[off:off + size])
        assert len(original_span) == size
        result = {
            "class": method["class"],
            "selector": method["selector"],
            "signature": method["type_encoding"],
            "offset_in_original_arm64": off, "size": size,
            "before_sha256": digest(original_span),
            "first_32_before_hex": original_span[:32].hex(),
            "stub_hex": stub.hex(),
        }
        if is_expiry_state_method:
            expired.append(result)
        else:
            selected.append(result)
        raw[off:off + size] = stub + NOP * ((size - len(stub)) // 4)
    spans.sort()
    for last, now in zip(spans, spans[1:]):
        assert last[1] <= now[0], ("overlap", name, last, now)
    assert len(selected) == EXPECTED_COUNTS[name], (name, len(selected), EXPECTED_COUNTS[name])
    assert len(expired) == (2 if name == "DuoFaceUI" else 0), (name, expired)
    assert found_flags == (set(FLAG_METHODS) if name == "DuoFaceUI" else set())
    after = inspect(bytes(raw))
    assert (after["method_count_license_related"]
            == inventory["method_count_license_related"])
    assert [m["class"] for m in after["license_named_methods"]] == [
        m["class"] for m in inventory["license_named_methods"]
    ], name
    return bytes(raw), selected, expired, {
        "source_archs": [s["arch"] for s in slices],
        "target_archs": ["arm64"],
        "related_class_method_metadata_retained": True,
        "source_raw_host_sha256": digest(original),
        "source_arm64_sha256": digest(generic[0]["bytes"]),
    }

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True, type=Path)
    ap.add_argument("--report", required=True, type=Path)
    args = ap.parse_args()
    assert SOURCE.is_file() and digest(SOURCE.read_bytes()) == SOURCE_SHA
    assert getfield(SOURCE, "Package") == PACKAGE
    assert getfield(SOURCE, "Version") == "1.0.3-12~visualtest"
    assert getfield(SOURCE, "Architecture") == "iphoneos-arm64"
    assert args.out != SOURCE and not args.out.exists(), "Do not overwrite baseline"

    args.out.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="visual12-launch1-") as dirname:
        root = Path(dirname)
        stage = root / "stage"
        subprocess.run(["dpkg-deb", "-R", str(SOURCE), str(stage)], check=True)
        before = {p.relative_to(stage).as_posix(): digest(p.read_bytes())
                  for p in stage.rglob("*") if p.is_file() and not p.is_symlink()}
        result = {}
        for name, rel in FILES.items():
            file = stage / rel
            original = file.read_bytes()
            patched, methods, flags, meta = write_patched_arm64(original, name)
            # ldid signs only generic ARM64; the previously unmodified arm64e
            # slice is intentionally not shipped and must not run stale logic.
            file.write_bytes(patched)
            meta.update({
                "methods_neutralized": len(methods),
                "expired_flags_neutralized": len(flags),
                "patched_methods": methods,
                "expired_flags": flags,
                "entitlements": preserve_entitlements_and_resign(
                    file, original, root, name),
                "signed_host_sha256": digest(file.read_bytes()),
            })
            assert len(file.read_bytes()) >= len(patched)
            result[name] = meta
        control = stage / "DEBIAN/control"
        original_control = control.read_text(encoding="utf-8")
        assert "Package: com.duonavi.app\n" in original_control
        assert "Version: 1.0.3-12~visualtest\n" in original_control
        control.write_text(original_control.replace(
            "Version: 1.0.3-12~visualtest\n",
            "Version: " + VERSION + "\n"), encoding="utf-8")
        md5lines = []
        for f in sorted(stage.rglob("*")):
            if f.is_file() and not f.is_symlink() and f.relative_to(stage).parts[0] != "DEBIAN":
                md5lines.append(hashlib.md5(f.read_bytes()).hexdigest()
                                + "  " + f.relative_to(stage).as_posix())
        (stage / "DEBIAN/md5sums").write_text("\n".join(md5lines) + "\n")
        after = {p.relative_to(stage).as_posix(): digest(p.read_bytes())
                 for p in stage.rglob("*") if p.is_file() and not p.is_symlink()}
        removed = set(before) - set(after)
        added = set(after) - set(before)
        # Original VisualTest12 package may omit DEBIAN/md5sums; generating
        # its standard manifest is allowed but removing any original is not.
        assert not removed, ("Original payload removed", removed)
        assert added <= {"DEBIAN/md5sums"}, ("Unexpected added payload", added)
        changed = sorted(k for k in after if before.get(k) != after[k])
        expected = sorted(list(FILES.values()) + ["DEBIAN/control", "DEBIAN/md5sums"])
        assert changed == expected, (changed, expected)
        assert sum(x["methods_neutralized"] for x in result.values()) == 291
        assert sum(x["expired_flags_neutralized"] for x in result.values()) == 2
        subprocess.run(["dpkg-deb", "--build", "--root-owner-group",
                        str(stage), str(args.out)], check=True)

    assert getfield(args.out, "Package") == PACKAGE
    assert getfield(args.out, "Version") == VERSION
    assert getfield(args.out, "Architecture") == "iphoneos-arm64"
    report = {
        "status": "VISUALTEST12_ORIGINAL_PACKAGE_LAUNCH_RECOVERY_SIGNED_DEB_CANDIDATE",
        "original_visualtest12_sha256": SOURCE_SHA,
        "package": PACKAGE, "version": VERSION, "arch": "iphoneos-arm64",
        "patched": result, "changed_original_paths": changed,
        "untouched_file_count": sum(before[k] == after[k] for k in before),
        "manifest_newly_created_if_missing": "DEBIAN/md5sums" not in before,
        "original_visualhook_files_unchanged": all(
            before[k] == after[k] for k in before
            if "DuoFaceVisualHook" in k),
        "source_original_package_retained": True,
        "hub_modified": False,
        "legacy_class_and_selector_metadata_retained": True,
        "not_proven_every_license_dependency_physically_removed": True,
        "launch_test_on_expired_device": "PENDING_REAL_DEVICE",
        "carplay_device_test": "PENDING_REAL_DEVICE",
        "sileo_published": False,
        "rollback_source_sha256": SOURCE_SHA,
        "output_sha256": digest(args.out.read_bytes()),
        "output_bytes": args.out.stat().st_size,
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({
        "status": report["status"], "package": PACKAGE, "version": VERSION,
        "patched": {k: {"license_methods": len(v["patched_methods"]),
                        "expiry_flags": len(v["expired_flags"])}
                    for k, v in result.items()},
        "deb_sha256": report["output_sha256"],
        "device_launch_not_yet_tested": True,
    }, indent=2))

if __name__ == "__main__":
    main()
