#!/usr/bin/env python3
"""Fail-closed preflight for DuoFace visual-only work; does not patch binaries."""
from pathlib import Path
from PIL import Image
import hashlib, subprocess, sys
asset_dir, deb = map(Path, sys.argv[1:3])
expected = "2120480166170c5f71b12a595bed7a5ab892fbd84038ef878eca8e8243062e9a"
assert deb.is_file() and hashlib.sha256(deb.read_bytes()).hexdigest() == expected, "baseline SHA mismatch"
for name in ("app_picker_APPROVED.png", "fullscreen_APPROVED.png", "swap_APPROVED_REFERENCE_MOCKUP.png"):
    with Image.open(asset_dir / name) as im: im.verify()
    print("INPUT_OK", name)
print("SPLASH_REJECTED: background concept not approved")
print("SWAP_REQUIRES_EXTRACTION: mockup is not a standalone icon")
assert subprocess.check_output(["dpkg-deb", "-f", str(deb), "Package"], text=True).strip() == "com.duoface.app"
print("BASELINE_OK")
print("NOT_READY_FOR_RELEASE: no binary runtime image patch implemented")
