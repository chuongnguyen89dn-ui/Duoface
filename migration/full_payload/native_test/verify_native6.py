#!/usr/bin/env python3
"""Independent native5 -> native6 byte-level regression of approved string erasure.

Assert every Mach-O section other than 26 zeroed display literal spans is exactly
equal to native5, including every instruction/selector/CarPlay lifecycle byte.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

from build_native5 import sections, FILES, sha
from build_native6 import SOURCE, SOURCE_HASH, LEDGER, VERSION

ROOT = Path(__file__).resolve().parents[3]


def map_sections(buf):
    result = {}
    for seg, sec, off, size in sections(buf):
        key = (seg, sec)
        assert key not in result, ("duplicate section", key)
        result[key] = (off, size)
    return result


def verify_binary(name, before, after, entries, methods):
    assert len(before) == len(after), (name, "binary size changed")
    old_sections = map_sections(before)
    new_sections = map_sections(after)
    assert old_sections == new_sections, (name, "section moved")
    assert len(entries) == 13
    intervals = []
    for row in entries:
        start, length = int(row["file_offset"]), int(row["byte_count"])
        stop = start + length
        assert sha(before[start:stop]) == row["after_sha256"], (name, row["label"])
        assert after[start:stop] == bytes(length), (name, row["label"])
        assert sha(after[start:stop]) == hashlib.sha256(bytes(length)).hexdigest()
        matches = [
            k for k, (off, n) in old_sections.items()
            if off <= start and stop <= off + n
        ]
        assert len(matches) == 1 and ",".join(matches[0]) == row["section"]
        intervals.append((start, stop))
    intervals.sort()
    assert all(a[1] <= b[0] for a, b in zip(intervals, intervals[1:]))
    mask_count = 0
    changed_count = 0
    for key, (offset, size) in old_sections.items():
        original = before[offset:offset + size]
        current = after[offset:offset + size]
        mask = bytearray(size)
        for start, stop in intervals:
            if offset <= start and stop <= offset + size:
                mask[start - offset:stop - offset] = bytes([1]) * (stop - start)
                mask_count += 1
        for idx, (left, right) in enumerate(zip(original, current)):
            if left != right:
                assert mask[idx], (name, key, hex(offset + idx),
                                  "unapproved changed section byte")
                changed_count += 1
        if key[1] == "__text":
            assert original == current, (name, "machine code changed")
        if key[1] in {"__objc_classlist", "__objc_selrefs", "__objc_methname",
                      "__objc_classname", "__objc_const", "__objc_data"}:
            assert original == current, (name, key, "ObjC metadata changed")
    assert mask_count == len(entries), (name, mask_count)
    assert changed_count == sum(int(x["byte_count"]) for x in entries)
    if name == "DuoFaceUI":
        assert len(methods) == 2
        for m in methods:
            s = int(m["file_offset"])
            e = s + int(m["byte_count"])
            assert before[s:e] == after[s:e], ("expired ABI modified", m["selector"])
            assert sha(after[s:e]) == m["after_sha256"]
    return {"erased_literals": len(entries), "erased_bytes": changed_count,
            "all_machine_code_identical": True,
            "all_other_macho_sections_byte_identical": True,
            "objc_metadata_preserved": True}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--deb", type=Path, required=True)
    ap.add_argument("--build-report", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()
    build = json.loads(args.build_report.read_text())
    ledger = json.loads(LEDGER.read_text())
    assert sha(SOURCE.read_bytes()) == SOURCE_HASH
    assert sha(args.deb.read_bytes()) == build["deb_sha256"]
    assert build["version"] == VERSION and build["zero_erased_presentation_literals"] == 26
    assert len(ledger["ui_literal_hidden_records"]) == 26
    assert len(ledger["method_hidden_records"]) == 2
    with tempfile.TemporaryDirectory(prefix="native6-check-") as temp:
        temp = Path(temp)
        old = temp / "native5"
        new = temp / "native6"
        subprocess.run(["dpkg-deb", "-x", str(SOURCE), str(old)], check=True)
        subprocess.run(["dpkg-deb", "-x", str(args.deb), str(new)], check=True)
        orig = {x.relative_to(old).as_posix(): sha(x.read_bytes())
                for x in old.rglob("*") if x.is_file() and not x.is_symlink()}
        revised = {x.relative_to(new).as_posix(): sha(x.read_bytes())
                   for x in new.rglob("*") if x.is_file() and not x.is_symlink()}
        assert orig.keys() == revised.keys()
        changes = sorted(k for k in orig if orig[k] != revised[k])
        assert changes == sorted(FILES.values()), changes
        checks = {}
        for name, rel in FILES.items():
            entry = [x for x in ledger["ui_literal_hidden_records"]
                     if x["binary"] == name]
            methods = [x for x in ledger["method_hidden_records"]
                       if x["binary"] == name]
            checks[name] = verify_binary(
                name, (old / rel).read_bytes(), (new / rel).read_bytes(),
                entry, methods)
    info = {
        "status": "NATIVE6_EXACT_ZERO_ERASURE_BINARY_REGRESSION_PASS",
        "source_native5_sha256": SOURCE_HASH,
        "native6_sha256": build["deb_sha256"],
        "verified": checks,
        "untouched_payload_file_count": len(orig) - len(FILES),
        "methods_removed_physically": 0,
        "objc_classes_and_selectors_removed_physically": 0,
        "presentation_literal_bytes_physically_zeroed": sum(
            x["erased_bytes"] for x in checks.values()),
        "machine_code_changed": False,
        "license_business_logic_proven_fully_removed": False,
        "device_tested": False
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(info, indent=2, ensure_ascii=False) + "\n")
    print(json.dumps(info, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
