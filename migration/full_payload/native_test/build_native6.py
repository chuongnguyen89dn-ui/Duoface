#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""DuoFace Mới native6: erase ONLY 26 native5-hidden presentation literals.

This is targeted string-data excision, NOT full license-subsystem removal.
Do not remove ObjC class/selector metadata, lifecycle routines or CarPlay code.
The 2 expiry-modal method implementations were already inert in native5.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

from build_native5 import FILES, sections, preserve_entitlements_and_resign, sha, cmd
from audit_branding import hits

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "dist/payload-migration/native5/com.duoface.independent_0.1.0~native5_iphoneos-arm64.deb"
SOURCE_HASH = "9b0b45cb4f9f26ae7c16d9aea8366d032e337f262397e253e0078958d5a46a26"
LEDGER = ROOT / "dist/payload-migration/native5/DANH_SACH_CHO_XOA.json"
VERSION = "0.1.0~native6"


def erase_approved_display_strings(name: str, original: bytes, entries: list[dict]):
    data = bytearray(original)
    allowed_sections = {
        (seg + "," + sec, offset, offset + size)
        for seg, sec, offset, size in sections(original)
        if (seg, sec) in {("__TEXT", "__cstring"), ("__TEXT", "__ustring"),
                          ("__TEXT_EXEC", "__cstring")}
    }
    assert len(entries) == 13, (name, len(entries))
    used = set()
    removed = []
    for row in entries:
        start = int(row["file_offset"])
        count = int(row["byte_count"])
        end = start + count
        assert count > 0 and (start, end) not in used
        assert any(s == row["section"] and lo <= start < end <= hi
                   for s, lo, hi in allowed_sections), (name, row)
        used.add((start, end))
        old = bytes(data[start:end])
        # Native5 wrote only space bytes (UTF8 or UTF16); verify exact old SHA.
        assert sha(old) == row["after_sha256"], (name, row["label"])
        assert old == (" " * len(row["label"])).encode(row["encoding"])
        assert sha(row["label"].encode(row["encoding"])) == row["before_sha256"]
        # In native6 the old placeholder DATA BYTES are erased, not hidden
        # behind printable blanks. NUL termination remains safe for C pointers.
        new = bytes(count)
        data[start:end] = new
        removed.append({
            "binary": name, "file_offset": start, "byte_count": count,
            "original_label": row["label"], "section": row["section"],
            "encoding": row["encoding"], "native5_sha256": sha(old),
            "native6_sha256": sha(new), "operation": "zeroed_presentation_data"
        })
    intervals = sorted(used)
    assert all(a[1] <= b[0] for a, b in zip(intervals, intervals[1:]))
    return bytes(data), removed


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--out", type=Path, required=True)
    p.add_argument("--report", type=Path, required=True)
    args = p.parse_args()
    assert sha(SOURCE.read_bytes()) == SOURCE_HASH, "Unknown native5 baseline"
    ledger = json.loads(LEDGER.read_text(encoding="utf-8"))
    literals = ledger["ui_literal_hidden_records"]
    methods = ledger["method_hidden_records"]
    assert len(literals) == 26 and len(methods) == 2
    assert all(m["state"] == "temporarily_disabled_native5" for m in methods)
    assert {m["selector"] for m in methods} == {
        "isShowingExpiredModal", "setIsShowingExpiredModal:"}
    with tempfile.TemporaryDirectory(prefix="duoface-native6-") as temp:
        tmp = Path(temp)
        stage = tmp / "stage"
        cmd("dpkg-deb", "-R", SOURCE, stage)
        original = {
            f.relative_to(stage).as_posix(): sha(f.read_bytes())
            for f in stage.rglob("*") if f.is_file() and not f.is_symlink()
        }
        operations = []
        signatures = {}
        for name, rel in FILES.items():
            f = stage / rel
            before = f.read_bytes()
            selected = [x for x in literals if x["binary"] == name]
            revised, erased = erase_approved_display_strings(name, before, selected)
            if name == "DuoFaceUI":
                for m in methods:
                    st = int(m["file_offset"])
                    end = st + int(m["byte_count"])
                    assert sha(before[st:end]) == m["after_sha256"]
                    assert before[st:end] == revised[st:end], "Must retain expiry ABI"
            assert len(revised) == len(before)
            f.write_bytes(revised)
            signatures[name] = preserve_entitlements_and_resign(f, before, tmp, name)
            assert not hits(f.read_bytes()), ("Old brand reintroduced", name)
            operations.extend(erased)
        assert len(operations) == 26
        control = stage / "DEBIAN/control"
        old_control = control.read_text(encoding="utf-8")
        assert "Package: com.duoface.independent" in old_control
        assert "Version: 0.1.0~native5" in old_control
        control.write_text(old_control.replace(
            "Version: 0.1.0~native5", "Version: " + VERSION), encoding="utf-8")
        md5sums = []
        for f in sorted(stage.rglob("*")):
            if f.is_file() and not f.is_symlink() and f.relative_to(stage).parts[0] != "DEBIAN":
                md5sums.append(hashlib.md5(f.read_bytes()).hexdigest()
                               + "  " + f.relative_to(stage).as_posix())
        (stage / "DEBIAN/md5sums").write_text("\n".join(md5sums) + "\n")
        current = {
            f.relative_to(stage).as_posix(): sha(f.read_bytes())
            for f in stage.rglob("*") if f.is_file() and not f.is_symlink()
        }
        assert original.keys() == current.keys()
        changed = sorted(k for k in original if original[k] != current[k])
        assert changed == sorted([
            "DEBIAN/control", "DEBIAN/md5sums", *FILES.values()
        ]), changed
        args.out.parent.mkdir(parents=True, exist_ok=True)
        cmd("dpkg-deb", "--build", "--root-owner-group", stage, args.out)
    assert subprocess.check_output(
        ["dpkg-deb", "-f", str(args.out), "Package"], text=True
    ).strip() == "com.duoface.independent"
    assert subprocess.check_output(
        ["dpkg-deb", "-f", str(args.out), "Version"], text=True
    ).strip() == VERSION
    report = {
        "status": "NATIVE6_ZERO_ERASED_DISPLAY_LITERALS_PENDING_CI_AND_DEVICE_TEST",
        "source_native5_sha256": SOURCE_HASH,
        "package": "com.duoface.independent", "version": VERSION,
        "zero_erased_presentation_literals": len(operations),
        "zero_erased_data_bytes": sum(x["byte_count"] for x in operations),
        "changes": operations, "changed_paths": changed,
        "untouched_files": len(original) - len(changed),
        "signatures": signatures,
        "expired_accessor_implementations": "Retained native5 inert ABI stubs",
        "license_class_selector_metadata_still_present": True,
        "all_embedded_license_code_proven_removed": False,
        "native5_and_native4_rollback_preserved": True,
        "carplay_executable_sections_modified": False,
        "device_tested": False, "sileo_published": False,
        "deb_sha256": sha(args.out.read_bytes()),
        "deb_size": args.out.stat().st_size
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n",
                           encoding="utf-8")
    print(json.dumps({k: v for k, v in report.items() if k != "changes"},
                     indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
