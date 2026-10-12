#!/usr/bin/env python3
"""Check the persisted DuoFace visual build without modifying the package."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1] / "dist" / "visual-1.0.3-12"
report = json.loads((root / "verification.json").read_text())
assert report["native_app_and_dashboard_byte_identical"] is True
assert report["runtime_device_test"] == "NOT_PERFORMED"
assert (root / "com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb").is_file()
deb = root / "com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb"
expected = "a4b1ed0ef049d3fd5af10f5a0067b7f5ed5890a2ed29e39d3060d4cfcd4feddd"
assert hashlib.sha256(deb.read_bytes()).hexdigest() == expected
print("PASS: v12 package integrity; native runtime is unchanged and untested")
