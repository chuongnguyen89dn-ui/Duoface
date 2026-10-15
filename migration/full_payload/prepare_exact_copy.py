#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sao chép NGUYÊN VẸN payload DuoFace đã duyệt vào staging, kiểm từng file.

Quan trọng: đây là bản lưu/truy vấn KHÔNG CÀI ĐƯỢC; không đổi Package ID,
không đóng DEB, không vá/mở khóa phần cấp phép ở nhị phân. File trạng thái
giấy phép người dùng được loại khỏi staging. Hai binary lớn vẫn có logic
kiểm tra giấy phép -> tuyệt đối không được gọi là DuoFace độc lập.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import stat
import subprocess

EXPECTED_SHA256 = "ce971b42230d355421b2b1d99793a1f62ffb75008365ea74a3467d859cc1de3a"
LICENSE_STATE_PATHS = {
    "var/mobile/Library/Preferences/com.duonavi.sync.plist",
}
KEY_COMPONENTS = {
    "var/jb/Applications/DuoFaceUI.app/DuoFaceUI",
    "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib",
    "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib",
    "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib",
}
LICENSE_MARKERS = (
    b"isLicenseCurrentlyValid",
    b"remainingLicenseSeconds",
    b"installAndVerifyLicensePayload:errorMsg:",
    b"licenseWatchdogTimerFired:",
    b"LICENSE_KILL_TRACE",
    b"/api/v1/license/sync",
    b"com.duoface.license.sync",
)

def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def file_digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1048576), b""):
            h.update(block)
    return h.hexdigest()

def inventory(root: Path) -> dict[str, dict[str, object]]:
    """Không theo các liên kết symlink, không mở dữ liệu giấy phép."""
    result = {}
    for entry in sorted(root.rglob("*")):
        rel = entry.relative_to(root).as_posix()
        if entry.is_symlink():
            result[rel] = {
                "kind": "symlink", "target": os.readlink(entry),
                "mode": oct(stat.S_IMODE(entry.lstat().st_mode)),
            }
        elif entry.is_file():
            if rel in LICENSE_STATE_PATHS:
                result[rel] = {"kind": "excluded_license_state", "size": entry.stat().st_size}
                continue
            result[rel] = {
                "kind": "file",
                "size": entry.stat().st_size,
                "mode": oct(stat.S_IMODE(entry.stat().st_mode)),
                "sha256": file_digest(entry),
            }
        elif entry.is_dir():
            result[rel] = {"kind": "directory", "mode": oct(stat.S_IMODE(entry.stat().st_mode))}
        else:
            raise RuntimeError(f"Đối tượng không mong muốn: {rel}")
    return result

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--deb", required=True, type=Path)
    parser.add_argument("--stage", required=True, type=Path)
    parser.add_argument("--report", required=True, type=Path)
    parser.add_argument("--allow-fixture", action="store_true", help="Chỉ dùng trong tests với DEB giả lập")
    args = parser.parse_args()
    src = args.deb.resolve()
    stage = args.stage.resolve()
    report = args.report.resolve()
    assert src.is_file(), src
    if not args.allow_fixture:
        assert file_digest(src) == EXPECTED_SHA256, "Nguồn DuoFace bị thay đổi: sai SHA256!"
    assert not stage.exists() or not any(stage.iterdir()), "Staging phải trống, không ghi đè bản cũ"
    stage.mkdir(parents=True, exist_ok=True)
    subprocess.run(["dpkg-deb", "--raw-extract", str(src), str(stage)], check=True)
    deb_control = {
        field: subprocess.check_output(["dpkg-deb", "-f", str(src), field], text=True).strip()
        for field in ("Package", "Version", "Architecture")
    }
    if not args.allow_fixture:
        assert deb_control == {
            "Package": "com.duonavi.app",
            "Version": "1.0.3-12+menu-native1",
            "Architecture": "iphoneos-arm64",
        }, deb_control

    original = inventory(stage)
    absent = LICENSE_STATE_PATHS - original.keys()
    if not args.allow_fixture:
        assert not absent, f"Trạng thái giấy phép được kỳ vọng nhưng thiếu: {absent}"
    for rel in LICENSE_STATE_PATHS:
        target = stage / rel
        if target.exists():
            assert target.is_file() and not target.is_symlink(), "Không xóa ngoài tệp đã nhận diện"
            target.unlink()

    copied = inventory(stage)
    assert all(path not in copied for path in LICENSE_STATE_PATHS)
    assert copied == {k: v for k, v in original.items() if k not in LICENSE_STATE_PATHS}, (
        "Một hoặc nhiều file ngoài trạng thái cấp phép đã bị thay đổi"
    )
    if not args.allow_fixture:
        assert KEY_COMPONENTS.issubset(copied), KEY_COMPONENTS - copied.keys()
        assert len([p for p in copied.values() if p["kind"] == "file"]) >= 33

    # Chỉ đọc các chuỗi selector tĩnh, KHÔNG trích dữ liệu người dùng hoặc khóa xác thực.
    binary_flags = {}
    for relative in sorted(KEY_COMPONENTS):
        binary = stage / relative
        if not binary.is_file():
            if not args.allow_fixture:
                raise RuntimeError(f"Thiếu lõi nguyên bản: {relative}")
            continue
        data = binary.read_bytes()
        binary_flags[relative] = {
            "size": len(data),
            "sha256": sha256(data),
            "license_marker_offsets_hex": {
                label.decode(): [hex(m.start()) for m in list(re.finditer(re.escape(label), data))[:10]]
                for label in LICENSE_MARKERS if label in data
            },
        }

    embedded = {
        name: info["license_marker_offsets_hex"]
        for name, info in binary_flags.items() if info["license_marker_offsets_hex"]
    }
    if not args.allow_fixture:
        app = "var/jb/Applications/DuoFaceUI.app/DuoFaceUI"
        dash = "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib"
        assert app in embedded, "Không tìm thấy chuỗi giấy phép trong DuoFaceUI, phải phân tích lại"
        assert dash in embedded, "Không tìm thấy chuỗi giấy phép trong DuoFaceDashboard, phải phân tích lại"

    info = stage / "var/jb/Applications/DuoFaceUI.app/Info.plist"
    bundle = plistlib.loads(info.read_bytes()).get("CFBundleIdentifier") if info.exists() else None
    result = {
        "status": "EXACT_PAYLOAD_STAGED_LICENSE_CODE_EMBEDDED_NOT_INDEPENDENT",
        "approved_source": str(args.deb),
        "source_sha256": file_digest(src),
        "source_control": deb_control,
        "original_app_bundle_id": bundle,
        "staging_root": str(args.stage),
        "staging_is_installable": False,
        "new_package_id_applied": False,
        "binary_code_patched": False,
        "source_file_count": sum(v["kind"] in ("file", "excluded_license_state") for v in original.values()),
        "copied_file_count": sum(v["kind"] == "file" for v in copied.values()),
        "excluded_only": sorted(k for k in LICENSE_STATE_PATHS if k in original),
        "byte_identical_files": True,
        "license_check_code_still_present": bool(embedded),
        "license_markers_in_binaries": embedded,
        "binary_component_hashes": binary_flags,
        "all_staged_entries": copied,
        "remaining_problem": "Hai binary DuoFaceUI và DuoFaceDashboard vẫn có logic cấp phép nhúng. Chưa chứng minh chức năng chạy độc lập. Không đưa staging này lên Sileo.",
        "device_tested": False,
        "published_to_sileo": False,
    }
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({
        "status": result["status"],
        "source_sha256": result["source_sha256"],
        "source_file_count": result["source_file_count"],
        "copied_file_count": result["copied_file_count"],
        "excluded_only": result["excluded_only"],
        "binary_license_markers": {k: list(v) for k,v in embedded.items()},
    }, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
