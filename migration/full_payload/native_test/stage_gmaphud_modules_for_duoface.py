#!/usr/bin/env python3
"""Stage byte-exact MIT GMapHUD 0.2.3 modules for the DuoFace Native12 candidate.

No new DEB, no signing, no Sileo, no device installation. These third-party
source-only adapters need a separate, verified bridge to DuoFace-owned IPC.
Only three real publishers (VietMap/Waze/GOFA) are staged. Google's\nGoogleMapsVietMap module also renders native Google Maps UI, so exclude it.\nDuoFace's own Google Maps GPS observer supplies only current speed until\na version-verified limit provider exists. Never stage GMapHUD's separate\noverlay/UI/placement modules, since the user requires exactly ONE GOFA-style\nbubble inside DuoFace. Users install only compatible map apps.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import plistlib
import shutil
import subprocess
import tempfile
from pathlib import Path

GMAP_SHA256 = "bc5a34cf2b6a8faa017beab725a3cb8adf4804a5b19275a9d7f95ed5732c1f64"
NATIVE12_SHA256 = "85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7"
DYLIB_DIR = Path("var/jb/Library/MobileSubstrate/DynamicLibraries")
# GMapHUD v0.2.3 upstream: https://github.com/bechou0410/gmaphud/tree/v0.2.3
# Source version is pinned; no original package manager registration is copied.
MODULE_FILTERS = {
    "WazeGMapHUDSource": {"com.waze.iphone"},
    "GofaGMapHUDSource": {"com.lumi.GOFA"},
    "VietMapGoogleMapsSource": {"vn.vietmap.live"},
}
SOURCE_DOC = Path("var/jb/usr/share/doc/com.chou.googlemaps.vietmap")
TARGET_DOC = Path("var/jb/usr/share/doc/com.duoface.independent")


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def field(path: Path, name: str) -> str:
    return subprocess.check_output(
        ["dpkg-deb", "-f", str(path), name], text=True
    ).strip()


def validate(path: Path, digest_expected: str, pkg: str, version: str) -> None:
    if not path.is_file() or digest(path) != digest_expected:
        raise ValueError("Wrong DEB SHA256: " + str(path))
    if field(path, "Package") != pkg or field(path, "Version") != version:
        raise ValueError("Unexpected DEB package/version: " + str(path))
    if field(path, "Architecture") != "iphoneos-arm64":
        raise ValueError("Not iPhone rootless ARM64: " + str(path))


def stage(source_deb: Path, output: Path, report_path: Path,
          native12_deb: Path | None) -> dict:
    if output.exists() or report_path.exists():
        raise FileExistsError("Refuse to overwrite staging/report")
    if output in report_path.parents:
        raise ValueError("Report must be outside staging directory")
    validate(source_deb, GMAP_SHA256, "com.chou.googlemaps.vietmap", "0.2.3")
    if native12_deb:
        validate(native12_deb, NATIVE12_SHA256,
                 "com.duoface.independent", "0.1.0~native12")
    report = {
        "status": "STAGED_BYTE_EXACT_GMAPHUD_NOT_BUILT_NOT_INSTALLED",
        "gmaphud_sha256": GMAP_SHA256,
        "native12_pinned_sha256": NATIVE12_SHA256,
        "original_native12_extracted": native12_deb is not None,
        "on_device_bubble_tested": False,
        "duoface_overlay_compatibility_verified": False,
        "built_deb": False,
        "sileo_published": False,
        "single_duoface_hud_only": True,
        "excluded_duplicate_renderers": [
            "GoogleMapsVietMap", "GMapHUDPlacementRelay",
            "GMapHUDOverspeedScreen"
        ],
        "copied": {},
    }
    with tempfile.TemporaryDirectory(prefix="duoface-gmap-reuse-") as temp:
        root = Path(temp)
        original = root / "gmap"
        stage_root = root / "stage"
        subprocess.run(["dpkg-deb", "-x", str(source_deb), str(original)],
                       check=True)
        if native12_deb:
            subprocess.run(["dpkg-deb", "-R", str(native12_deb), str(stage_root)],
                           check=True)
        else:
            stage_root.mkdir()
        for name, expected_bundles in MODULE_FILTERS.items():
            for ext in (".dylib", ".plist"):
                relative = DYLIB_DIR / (name + ext)
                src, dst = original / relative, stage_root / relative
                if not src.is_file() or src.is_symlink() or dst.exists():
                    raise ValueError("Missing or conflicting module " + str(relative))
                data = src.read_bytes()
                if ext == ".plist":
                    bundles = set(plistlib.loads(data)["Filter"]["Bundles"])
                    if bundles != expected_bundles:
                        raise ValueError("Changed upstream filter " + name)
                else:
                    if data[:4] not in (bytes.fromhex("cafebabe"),
                                        bytes.fromhex("cafebabf")):
                        raise ValueError("Unsupported Mach-O " + name)
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src, dst)
                if digest(src) != digest(dst):
                    raise AssertionError("Copy mismatch " + name)
                report["copied"][str(relative)] = {
                    "sha256": digest(dst), "size": dst.stat().st_size
                }
        for source_file, destination in (
            ("LICENSE", "GMapHUD-MIT-LICENSE"),
            ("DISCLAIMER", "GMapHUD-DISCLAIMER"),
        ):
            src = original / SOURCE_DOC / source_file
            dst = stage_root / TARGET_DOC / destination
            if not src.is_file() or dst.exists():
                raise ValueError("License/disclaimer missing/conflict: " + source_file)
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            report["copied"][str(dst.relative_to(stage_root))] = {
                "sha256": digest(dst), "size": dst.stat().st_size
            }
        if len(report["copied"]) != 8:
            raise AssertionError("Expected 6 true app-source module/filter files + 2 notices")
        output.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(stage_root), str(output))
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n",
                           encoding="utf-8")
    return report


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--gmaphud", type=Path, required=True)
    ap.add_argument("--native12", type=Path, default=None)
    ap.add_argument("--out-dir", type=Path, required=True)
    ap.add_argument("--report", type=Path, required=True)
    args = ap.parse_args()
    report = stage(args.gmaphud, args.out_dir, args.report, args.native12)
    print(json.dumps({
        "status": report["status"],
        "files": len(report["copied"]),
        "bytes": sum(f["size"] for f in report["copied"].values())
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()
