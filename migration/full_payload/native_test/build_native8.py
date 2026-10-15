#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Native8: staged native7 39-label presentation hide + source-built 0.30s logo-grip hook.

Immutable source native6. EXACT two existing Mach-O binaries change in approved
__cstring literal ranges; all original code/CarPlay/ObjC metadata remains byte-identical.
The original DuoFaceVisualHook.dylib alone is replaced by source-compiled hook.
No other payload file or legacy package ID may change.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import subprocess
import tempfile
from pathlib import Path
from build_native5 import FILES, preserve_entitlements_and_resign, sha, cmd
from build_native7 import SOURCE, EXPECTED, AUDIT, UI_COPY, mask_selected
from audit_branding import hits

ROOT = Path(__file__).resolve().parents[3]
VERSION = "0.1.0~native8"
HOOK_REL = "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib"
HOOK_FILTER_REL = "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.plist"


def files_and_digests(stage):
    return {
        p.relative_to(stage).as_posix(): sha(p.read_bytes())
        for p in stage.rglob("*") if p.is_file() and not p.is_symlink()
    }


def build():
    parser = argparse.ArgumentParser()
    parser.add_argument("--hook", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--report", required=True, type=Path)
    args = parser.parse_args()
    assert sha(SOURCE.read_bytes()) == EXPECTED, "native6 baseline changed"
    catalog = json.loads(AUDIT.read_text(encoding="utf-8"))
    assert catalog["native6_sha256"] == EXPECTED and catalog["raw_deb_unchanged"]
    assert len(UI_COPY) == len(set(UI_COPY)) == 39
    assert args.hook.is_file() and args.hook.stat().st_size > 10000
    hook_source = ROOT / "src/DuoFaceVisualHook.m"
    grip_source = ROOT / "src/DFDividerLogoGrip.inc"
    hook_code = hook_source.read_text(encoding="utf-8")
    grip_code = grip_source.read_text(encoding="utf-8")
    assert '#include "DFDividerLogoGrip.inc"' in hook_code
    assert "DFInstallLogoGripHooks(hook, divider)" in hook_code
    assert "kDFLogoHoldThreshold = 0.30" in grip_code
    assert "DFLogoMoveWithHold" in grip_code
    assert "setSplitRatio:" not in grip_code
    assert subprocess.check_output(
        ["dpkg-deb", "-f", str(SOURCE), "Package"], text=True
    ).strip() == "com.duoface.independent"
    assert subprocess.check_output(
        ["dpkg-deb", "-f", str(SOURCE), "Version"], text=True
    ).strip() == "0.1.0~native6"

    records, signing = [], {}
    with tempfile.TemporaryDirectory(prefix="duoface-native8-") as td:
        root = Path(td)
        stage = root / "stage"
        cmd("dpkg-deb", "-R", SOURCE, stage)
        original = files_and_digests(stage)
        assert HOOK_REL in original and HOOK_FILTER_REL in original
        assert all(rel in original for rel in FILES.values())

        for name, rel in FILES.items():
            target = stage / rel
            before = target.read_bytes()
            result, masks = mask_selected(name, before, catalog["binaries"][name]["strings"])
            assert len(result) == len(before), "Mach-O length changed"
            target.write_bytes(result)
            signing[name] = preserve_entitlements_and_resign(target, before, root, name)
            assert not hits(target.read_bytes()), "Old brand present"
            records.extend(masks)
        assert len(records) == 78
        assert all(m["state"] == "temporarily_hidden_native7" for m in records)

        original_hook = (stage / HOOK_REL).read_bytes()
        new_hook = args.hook.read_bytes()
        assert new_hook[:4] == bytes.fromhex("cffaedfe"), "Hook not ARM64 Mach-O"
        (stage / HOOK_REL).write_bytes(new_hook)
        signing["DuoFaceVisualHook"] = preserve_entitlements_and_resign(
            stage / HOOK_REL, original_hook, root, "DuoFaceVisualHook"
        )
        assert sha((stage / HOOK_REL).read_bytes()) != sha(original_hook)
        assert (stage / HOOK_FILTER_REL).is_file()
        assert not hits((stage / HOOK_REL).read_bytes())

        control = stage / "DEBIAN/control"
        old_control = control.read_text(encoding="utf-8")
        assert "Package: com.duoface.independent" in old_control
        assert "Version: 0.1.0~native6" in old_control
        control.write_text(
            old_control.replace("Version: 0.1.0~native6", "Version: " + VERSION),
            encoding="utf-8",
        )
        md5sums = []
        for p in sorted(stage.rglob("*")):
            if p.is_file() and not p.is_symlink() and p.relative_to(stage).parts[0] != "DEBIAN":
                md5sums.append(
                    hashlib.md5(p.read_bytes()).hexdigest() + "  " +
                    p.relative_to(stage).as_posix()
                )
        (stage / "DEBIAN/md5sums").write_text("\n".join(md5sums) + "\n")
        updated = files_and_digests(stage)
        assert original.keys() == updated.keys(), "payload added or dropped files"
        changed = sorted(k for k in original if original[k] != updated[k])
        expected = sorted([
            "DEBIAN/control", "DEBIAN/md5sums", HOOK_REL, *FILES.values()
        ])
        assert changed == expected, (changed, expected)

        args.out.parent.mkdir(parents=True, exist_ok=True)
        assert not args.out.exists(), "Refusing to overwrite existing native8 DEB"
        cmd("dpkg-deb", "--build", "--root-owner-group", stage, args.out)

    assert subprocess.check_output(
        ["dpkg-deb", "-f", str(args.out), "Package"], text=True
    ).strip() == "com.duoface.independent"
    assert subprocess.check_output(
        ["dpkg-deb", "-f", str(args.out), "Version"], text=True
    ).strip() == VERSION
    assert subprocess.check_output(
        ["dpkg-deb", "-f", str(args.out), "Architecture"], text=True
    ).strip() == "iphoneos-arm64"
    result = {
        "status": "NATIVE8_TWO_SCOPE_STAGED_LICENSE_COPY_AND_LOGO_DRAG_NEEDS_DEVICE_QA",
        "baseline_native6_sha256": EXPECTED,
        "package": "com.duoface.independent",
        "version": VERSION,
        "target_rootless_architecture": "iphoneos-arm64",
        "license_ui_strings_selected": len(UI_COPY),
        "license_ui_literal_occurrences_hidden": len(records),
        "license_ui_selected_bytes": sum(x["byte_count"] for x in records),
        "actual_changed_literal_bytes_expected": sum(
            sum(v != 0x20 for v in m["label"].encode("utf-8")) for m in records
        ),
        "masks": records,
        "replaced_hook": HOOK_REL,
        "original_hook_sha256": sha(original_hook),
        "new_hook_sha256": sha((stage / HOOK_REL).read_bytes()) if stage.exists() else
            "sha_verified_during_build",
        "hook_compiled_input_sha256": sha(new_hook),
        "hook_source_sha256": sha(hook_source.read_bytes()),
        "grip_source_sha256": sha(grip_source.read_bytes()),
        "hold_duration_seconds": 0.30,
        "changed_payload_and_control_paths": changed,
        "unchanged_payload_files": len(original) - len(changed),
        "signing": signing,
        "carplay_host_and_detectors_modified": False,
        "native_host_code_modified": False,
        "objc_class_selector_metadata_modified": False,
        "license_full_removal_claimed": False,
        "device_tested": False,
        "sileo_published": False,
        "native6_rollback_preserved": True,
        "deb_sha256": sha(args.out.read_bytes()),
        "deb_size": args.out.stat().st_size,
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({k:v for k,v in result.items() if k != "masks"}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    build()
