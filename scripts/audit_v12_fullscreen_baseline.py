#!/usr/bin/env python3
"""Read-only v12 package baseline audit for true CarPlay system-sidebar fullscreen.

This does NOT implement fullscreen, modify package contents or license state.
Run: python3 scripts/audit_v12_fullscreen_baseline.py path/to/v12.deb --out audit/v12_fullscreen_baseline.json
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

EXPECTED = "com.duonavi.app"
VERSION = "1.0.3-12~visualtest"

def run(*cmd):
    return subprocess.run(cmd, check=True, text=True, capture_output=True).stdout

def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("deb", type=Path)
    ap.add_argument("--out", type=Path, default=Path("audit/v12_fullscreen_baseline.json"))
    args = ap.parse_args()
    assert args.deb.is_file(), args.deb
    package = run("dpkg-deb", "-f", str(args.deb), "Package").strip()
    version = run("dpkg-deb", "-f", str(args.deb), "Version").strip()
    assert (package, version) == (EXPECTED, VERSION), (package, version)
    with tempfile.TemporaryDirectory() as d:
        root = Path(d)
        run("dpkg-deb", "-x", str(args.deb), str(root))
        files = {str(p.relative_to(root)): {"size": p.stat().st_size, "sha256": sha256(p)}
                 for p in root.rglob("*") if p.is_file()}
        binary_candidates = [p for p in files if p.endswith((".dylib", "/DuoFaceUI"))]
        for name in ("DuoFaceDashboard.dylib", "DuoFaceVisualHook.dylib"):
            assert any(p.endswith("/" + name) for p in binary_candidates), name
        report = {"source": str(args.deb), "deb_sha256": sha256(args.deb),
                  "package": package, "version": version, "files": files,
                  "binary_candidates": binary_candidates,
                  "true_system_sidebar_fullscreen_verified": False,
                  "carplay_device_tested": False,
                  "modified_package": False}
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(f"PASS baseline: {len(files)} files; {package} {version}; {args.out}")

if __name__ == "__main__":
    main()
