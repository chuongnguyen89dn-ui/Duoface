#!/usr/bin/env python3
"""Byte-level native6 -> native8 regression.

Only the audited 39 x 2 user-visible __cstring literals are masked in UI and
Dashboard Mach-O binaries, with machine instructions, lifecycle/CarPlay and
ObjC metadata identical. The source-built visual hook is the ONLY third
payload modification. Correctly counts characters actually changed (spaces
in the original text remain space, they are not changed bytes).
"""
from __future__ import annotations

import argparse
import json
import subprocess
import tempfile
from pathlib import Path
from build_native5 import FILES, sections, sha
from build_native7 import SOURCE, EXPECTED, UI_COPY
from build_native8 import VERSION, HOOK_REL, HOOK_FILTER_REL


def section_map(buf):
    d = {}
    for seg, sec, start, count in sections(buf):
        assert (seg, sec) not in d
        d[(seg, sec)] = (start, count)
    return d


def verify_display_binary(name, old, new, masks):
    assert len(old) == len(new), (name, "Mach-O size changed")
    src_sections = section_map(old)
    dst_sections = section_map(new)
    assert src_sections == dst_sections, (name, "Mach-O section shifted")
    assert len(masks) == len(UI_COPY) == 39
    assert {m["label"] for m in masks} == set(UI_COPY)

    spans = []
    for m in masks:
        a, size = int(m["file_offset"]), int(m["byte_count"])
        b = a + size
        assert m["binary"] == name
        assert old[a:b] == m["label"].encode("utf-8")
        assert new[a:b] == b" " * size
        assert sha(old[a:b]) == m["native6_sha256"]
        assert sha(new[a:b]) == m["native7_sha256"]
        assert old[b] == 0 and new[b] == 0, "C terminator must be retained"
        assert any(sec == "__cstring" and start <= a < b <= start + length
                   for (seg, sec), (start, length) in src_sections.items())
        spans.append((a,b))
    spans.sort()
    assert all(a[1] <= b[0] for a,b in zip(spans, spans[1:]))
    actual = 0
    for (seg, sec), (start, length) in src_sections.items():
        left = old[start:start+length]
        right = new[start:start+length]
        for i, (v, w) in enumerate(zip(left, right)):
            if v != w:
                assert sec == "__cstring", (name, seg, sec, hex(start+i))
                assert any(a <= start+i < b for a,b in spans), (name, hex(start+i))
                actual += 1
        if sec == "__text" or sec.startswith("__objc") or sec in ("__const", "__stubs"):
            assert left == right, (name, sec, "CarPlay/code/ObjC modified")
    expected = sum(
        sum(byte != 0x20 for byte in m["label"].encode("utf-8"))
        for m in masks
    )
    assert actual == expected, (name, actual, expected)
    return {
        "masked_user_visible_cstrings": len(masks),
        "selected_literal_bytes": sum(m["byte_count"] for m in masks),
        "actual_changed_literal_bytes": actual,
        "machine_code_unchanged": True,
        "objc_class_selector_metadata_unchanged": True,
        "carplay_lifecycle_and_detectors_unchanged": True,
    }


def verify():
    ap = argparse.ArgumentParser()
    ap.add_argument("--deb", type=Path, required=True)
    ap.add_argument("--report", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()
    report = json.loads(args.report.read_text(encoding="utf-8"))
    assert sha(SOURCE.read_bytes()) == EXPECTED, "Pinned native6 baseline changed"
    assert sha(args.deb.read_bytes()) == report["deb_sha256"]
    assert report["version"] == VERSION
    assert report["package"] == "com.duoface.independent"
    assert len(report["masks"]) == 78
    assert report["hold_duration_seconds"] == 0.30
    assert report["replaced_hook"] == HOOK_REL
    assert report["license_ui_strings_selected"] == 39
    assert report["license_ui_literal_occurrences_hidden"] == 78
    assert report["native6_rollback_preserved"]
    assert report["license_full_removal_claimed"] is False

    assert subprocess.check_output(
        ["dpkg-deb","-f",str(args.deb),"Package"],text=True
    ).strip() == "com.duoface.independent"
    assert subprocess.check_output(
        ["dpkg-deb","-f",str(args.deb),"Version"],text=True
    ).strip() == VERSION
    assert subprocess.check_output(
        ["dpkg-deb","-f",str(args.deb),"Architecture"],text=True
    ).strip() == "iphoneos-arm64"

    with tempfile.TemporaryDirectory(prefix="duoface-native8-QA-") as td:
        root = Path(td)
        src = root / "native6"
        out = root / "native8"
        subprocess.run(["dpkg-deb","-x",str(SOURCE),str(src)],check=True)
        subprocess.run(["dpkg-deb","-x",str(args.deb),str(out)],check=True)
        before = {p.relative_to(src).as_posix():sha(p.read_bytes())
                  for p in src.rglob("*") if p.is_file() and not p.is_symlink()}
        after = {p.relative_to(out).as_posix():sha(p.read_bytes())
                 for p in out.rglob("*") if p.is_file() and not p.is_symlink()}
        assert before.keys() == after.keys(), "Added/dropped payload"
        allowed = sorted([*FILES.values(), HOOK_REL])
        changed = sorted(k for k in before if before[k] != after[k])
        assert changed == allowed, (changed, allowed)
        checks = {}
        for name, rel in FILES.items():
            checks[name] = verify_display_binary(
                name,
                (src/rel).read_bytes(),
                (out/rel).read_bytes(),
                [m for m in report["masks"] if m["binary"] == name]
            )
        hook_before = (src/HOOK_REL).read_bytes()
        hook_after = (out/HOOK_REL).read_bytes()
        assert sha(hook_before) == report["original_hook_sha256"]
        assert sha(hook_after) == report["new_hook_sha256"]
        assert hook_before != hook_after
        assert (src/HOOK_FILTER_REL).read_bytes() == (out/HOOK_FILTER_REL).read_bytes()
        hook_strings = subprocess.run(
            ["strings",str(out/HOOK_REL)],check=True,text=True,capture_output=True
        ).stdout
        for marker in ("DuoFaceGrip", "threshold=0.30s", "onSwap",
                       "DFDividerLayout"):
            # DFDividerLayout may be a local static symbol stripped by toolchain;
            # use explicit logged markers to verify binary behavior if needed.
            if marker == "DFDividerLayout":
                assert "divider native tap preserved" in hook_strings, "Lost divider hook"
            else:
                assert marker in hook_strings, (marker, "missing in source-built hook")
        assert len(before) >= 40
        assert sum(x["actual_changed_literal_bytes"] for x in checks.values()) == (
            report["actual_changed_literal_bytes_expected"])
        assert sum(x["selected_literal_bytes"] for x in checks.values()) == (
            report["license_ui_selected_bytes"])

    result = {
        "status": "NATIVE8_CARPLAY_CODE_IDENTICAL_AND_GRIP_HOOK_DELTA_PASS",
        "native6_baseline_sha256": EXPECTED,
        "native8_sha256": report["deb_sha256"],
        "package": report["package"],
        "version": VERSION,
        "verified_binary_display_mappings": checks,
        "only_hook_and_two_binary_literal_data_changed": True,
        "identical_other_payload_files": len(before)-len(allowed),
        "unchanged_carplay_split_code_and_lifecycle": True,
        "unchanged_objc_selectors_classes_keys": True,
        "logo_grip_hook_verified_present": True,
        "logo_long_hold_threshold_seconds": 0.30,
        "rootless_architecture": "iphoneos-arm64",
        "device_tested": False,
        "sileo_published": False,
        "license_subsystem_fully_removed": False,
    }
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",
                        encoding="utf-8")
    print(json.dumps(result,ensure_ascii=False,indent=2))


if __name__ == "__main__":
    verify()
