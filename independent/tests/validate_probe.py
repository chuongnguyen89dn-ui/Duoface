#!/usr/bin/env python3
"""Kiểm tra nguồn nguyên mẫu độc lập; KHÔNG xác nhận tính năng chạy trên CarPlay."""
from pathlib import Path
import json
import plistlib
import re

root = Path(__file__).resolve().parents[2]
source_paths = [
    root / "independent/DFIProbe.mm",
    root / "independent/DFISplitLayout.h",
    root / "independent/DFISplitLayout.mm",
]
for p in source_paths:
    assert p.is_file(), f"Thiếu: {p}"
    assert p.stat().st_size > 100, f"Tệp quá nhỏ: {p}"

probe = source_paths[0].read_text(encoding="utf-8")
layout = source_paths[2].read_text(encoding="utf-8")
header = source_paths[1].read_text(encoding="utf-8")
combined = "\n".join(p.read_text(encoding="utf-8") for p in source_paths)
makefile = (root / "Makefile.independent").read_text(encoding="utf-8")
filter_plist = plistlib.loads((root / "DuoFaceIndependentProbe.plist").read_bytes())

# Cấm đóng kèm hoặc phụ thuộc danh tính/lõi thương mại kế thừa.
for banned in (
    r"com\.duonavi", r"DuoNavi", r"CBBridgeManager",
    r"CBBridgedSplitApp", r"CBMultitaskingOverlayView",
    r"com\.999\.airaw", r"Airaw\.dylib"
):
    assert re.search(banned, combined, re.IGNORECASE) is None, f"Nguồn độc lập có phụ thuộc: {banned}"

assert "DFIEnabledFile" in probe and "fileExistsAtPath:DFIEnabledFile" in probe
assert "notify_register_dispatch" in probe
assert "NSClassFromString" in probe
assert "DBDashboardWorkspaceOwner" in probe
assert "DFIOriginalWorkspaceInit(self, cmd, owner)" in probe, "Không được chặn init gốc"
assert "DFIActive = YES;" in probe
assert "requestStateChange:" in probe and "activateApplication:" in probe
assert "objc_msgSend" not in probe, "Bộ đo chưa được quyền tự mở ứng dụng"
assert "new UIWindow" not in probe and "initWithFrame" not in probe
assert "attachLeftHostView:" in header and "rightHostView:" in header
assert "leftHost.superview != nil" in layout
assert "rightHost.superview != nil" in layout
assert "[self detach]" in layout and "UIViewAutoresizingNone" in layout
assert "DuoFaceIndependentProbe_FILES" in makefile
assert "independent/DFIProbe.mm independent/DFISplitLayout.mm" in makefile
assert "THEOS_PACKAGE_SCHEME := rootless" in makefile
assert "arm64" in makefile

filt = filter_plist["Filter"]
allowed = {"com.apple.springboard", "com.apple.CarPlay", "com.apple.CarPlayApp", "com.apple.dashboard"}
assert set(filt["Bundles"]) == allowed, filt
assert set(filt["Executables"]) == {"SpringBoard", "CarPlay", "CarPlayApp", "Dashboard"}

report = {
    "status": "STATIC_ONLY_NOT_DEVICE_TESTED",
    "target": "iPhone jailbreak / CarPlay / rootless arm64",
    "source_files": [str(p.relative_to(root)) for p in source_paths],
    "feature_gate": "/var/mobile/Library/Preferences/com.duoface.independent.probe.enabled",
    "read_only_probe": True,
    "split_layout_requires_two_live_host_views": True,
    "two_scenes_created": False,
    "two_apps_verified": False,
    "deb_built": False,
    "sileo_published": False,
}
print(json.dumps(report, indent=2, ensure_ascii=False))
