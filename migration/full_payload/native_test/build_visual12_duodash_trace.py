#!/usr/bin/env python3
"""Package a reversible DuoDash-focused activation trace on top of VisualTest12.

This is NOT an activation fix. No DuoDash/Airaw/proprietary binary is bundled.
The preserved VisualTest12 UI/Dashboard, all baseline assets, and separate Hub
are byte-identical. Only two diagnostic files and package metadata are added.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import plistlib
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = ROOT / ("dist/visualtest12-connectprobe1/"
               "com.duonavi.app_1.0.3-12~visualtest12launch2probe1_iphoneos-arm64.deb")
BASE_SHA256 = "43c7ffbaae23fa39a19c63e276f50cfd35c66ce1ea7ab887f9a78cc077738841"
PACKAGE = "com.duonavi.app"
OLD_VERSION = "1.0.3-12~visualtest12launch2probe1"
VERSION = "1.0.3-12~visualtest12launch3ddtrace1"
LIB_NAME = "DFDuoDashActivationTrace.dylib"
PLIST_NAME = "DFDuoDashActivationTrace.plist"
INJECT = "var/jb/Library/MobileSubstrate/DynamicLibraries"
FILTER = ROOT / "runtime/visualtest12/DFDuoDashActivationTrace.plist"
EXPECTED_BUNDLES = {
    "com.apple.springboard",
    "com.apple.CarPlayApp",
    "com.duoface.duofaceui",
    "com.duonavi.app",
}

def sha(blob: bytes) -> str:
    return hashlib.sha256(blob).hexdigest()

def field(package: Path, name: str) -> str:
    return subprocess.check_output(
        ["dpkg-deb", "-f", str(package), name], text=True
    ).strip()

def all_regular_files(root: Path) -> dict[str, str]:
    return {
        p.relative_to(root).as_posix(): sha(p.read_bytes())
        for p in root.rglob("*") if p.is_file() and not p.is_symlink()
    }

def all_symlinks(root: Path) -> dict[str, str]:
    return {
        p.relative_to(root).as_posix(): str(p.readlink())
        for p in root.rglob("*") if p.is_symlink()
    }

def run(*args: object) -> None:
    subprocess.run([str(s) for s in args], check=True)

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dylib", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()

    assert BASE.is_file(), f"Missing exact baseline: {BASE}"
    assert sha(BASE.read_bytes()) == BASE_SHA256, "baseline DEB fingerprint changed"
    assert field(BASE, "Package") == PACKAGE
    assert field(BASE, "Version") == OLD_VERSION
    assert field(BASE, "Architecture") == "iphoneos-arm64"
    assert args.dylib.is_file() and args.dylib.stat().st_size > 4000
    dylib = args.dylib.read_bytes()
    assert dylib[:4] == bytes.fromhex("cffaedfe"), "expected signed ARM64 Mach-O"
    filters = plistlib.loads(FILTER.read_bytes())
    assert set(filters["Filter"]["Bundles"]) == EXPECTED_BUNDLES
    assert not args.out.exists(), "refuse accidental overwrite"
    assert args.out.resolve() != BASE.resolve()

    with tempfile.TemporaryDirectory(prefix="duoface-ddtrace-") as dirname:
        root = Path(dirname) / "payload"
        run("dpkg-deb", "-R", BASE, root)
        before = all_regular_files(root)
        before_links = all_symlinks(root)
        targets = {f"{INJECT}/{LIB_NAME}", f"{INJECT}/{PLIST_NAME}"}
        assert not (targets & set(before)), "diagnostic already in source package"

        output = root / INJECT
        output.mkdir(parents=True, exist_ok=True)
        (output / LIB_NAME).write_bytes(dylib)
        (output / PLIST_NAME).write_bytes(FILTER.read_bytes())

        control = root / "DEBIAN/control"
        text = control.read_text(encoding="utf-8")
        oldline = f"Version: {OLD_VERSION}\n"
        assert text.count(oldline) == 1
        control.write_text(text.replace(oldline, f"Version: {VERSION}\n"),
                           encoding="utf-8")
        checksums = []
        for file in sorted(root.rglob("*")):
            if file.is_file() and not file.is_symlink():
                relative = file.relative_to(root).as_posix()
                if not relative.startswith("DEBIAN/"):
                    checksums.append(hashlib.md5(file.read_bytes()).hexdigest()
                                     + "  " + relative)
        (root / "DEBIAN/md5sums").write_text("\n".join(checksums) + "\n")

        after = all_regular_files(root)
        assert all_symlinks(root) == before_links, "original symlinks changed"
        assert set(after) - set(before) == targets
        assert not set(before) - set(after), "source file disappeared"
        changed = sorted(k for k in before if before[k] != after[k])
        assert changed == ["DEBIAN/control", "DEBIAN/md5sums"], changed
        # Original payload and existing connection probe are untouched.
        original_payload = [k for k in before if k.startswith("var/jb/")]
        assert all(before[k] == after[k] for k in original_payload)

        args.out.parent.mkdir(parents=True, exist_ok=True)
        run("dpkg-deb", "--build", "--root-owner-group", root, args.out)

    assert field(args.out, "Package") == PACKAGE
    assert field(args.out, "Version") == VERSION
    assert field(args.out, "Architecture") == "iphoneos-arm64"
    report = {
        "status": "VISUALTEST12_DUODASH_ACTIVATION_TRACE_BUILD",
        "package": PACKAGE, "version": VERSION,
        "baseline_package_sha256": BASE_SHA256,
        "baseline_version": OLD_VERSION,
        "added_files": sorted(targets),
        "modified_files": changed,
        "removed_files": [],
        "original_visualtest12_core_unchanged": True,
        "existing_connection_probe_unchanged": True,
        "airaw_code_or_binary_bundled": False,
        "duodash_binary_bundled": False,
        "duodash_process_events_targeted": [
            "CBBridgeManagerDashboard.requestActivation:",
            "CBBridgeManagerDashboard.startBridging:",
            "CBBridgeManagerDashboard.prepareAndRequestActivation:",
            "CBBridgeManagerDashboard.bridgeDidActivate:",
            "CBBridgeManager.requestStateChange:",
            "CBBridgeManager.loadNewAppFromCurrentRequest:",
            "CBBridgeManager.handleCarPlayConnectionChanged:",
        ],
        "separate_hub_modified": False,
        "activation_fixed": False,
        "app_bridge_fixed": False,
        "device_tested": False,
        "sileo_published": False,
        "log_location": "/var/mobile/Documents/DuoFaceDuoDashTrace/{SpringBoard,CarPlayApp,DuoFaceUI}.jsonl",
        "new_dylib_sha256": sha(dylib),
        "new_filter_sha256": sha(FILTER.read_bytes()),
        "output_deb_sha256": sha(args.out.read_bytes()),
        "output_deb_bytes": args.out.stat().st_size,
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n",
                           encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
