#!/usr/bin/env python3
"""Chuyển NGUYÊN VẸN ảnh DuoFace đã duyệt sang tên gói độc lập.

Chạy tại bất kỳ thư mục nào; nguồn thuộc chính repo Duoface.
TUYỆT ĐỐI KHÔNG chạm vào tài nguyên hoặc dữ liệu giấy phép của gói kế thừa.
"""
from __future__ import annotations
import hashlib
import json
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "dist" / "visual-1.0.3-12" / "assets"
EXPECTED = {
    "duoface-icon.png": "03f0a9e31bffced19419f06193d866bb2d66d824c5ba10c5c24eee8718217def",
    "duoface-logo.png": "78450d8ee4759353bdc21f27a06016c03fab61038ae60109ba21515c087b0089",
    "duoface-logo-vert.png": "7fa216e2fa89e4fc32e49045ab29d72f6bee3fef4f974444c98fb5bd631e25d2",
    "duoface-logo-picker-alpha-v2.png": "43b6dafb8fc0550c2b3032c11acae1e0712350ca5b4dd235b7dc14c7951c74f7",
    "VisualAssets/duoface-fullscreen.png": "10e52f01a16cb7d34a81330373a290bcac1bdb0ba9c91119527ef3dcb13cdb36",
    "VisualAssets/duoface-picker.png": "16a959b71a0d3d8ef86e2ac9163024af457aec180770c757fe4b16d2b0a85f8a",
    "VisualAssets/duoface-swap.png": "d3ec77c783a186896d63bb08732ee78e427f16e1c127c0785b36bf5eaa037275",
}

def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def main(stage: Path) -> None:
    if not SOURCE.is_dir() or not (SOURCE / "asset-manifest.json").is_file():
        raise SystemExit(f"Thiếu thư mục nguồn đã được duyệt: {SOURCE}")
    target = stage / "var/jb/Library/Application Support/DuoFaceIndependent"
    copied = {}
    for source in sorted(SOURCE.rglob("*")):
        if not source.is_file():
            continue
        rel = source.relative_to(SOURCE).as_posix()
        # Ignore transient editor files, transfer every approved source asset.
        if rel.startswith(".") or rel.endswith((".tmp", ".bak")):
            continue
        raw = source.read_bytes()
        digest = sha256(raw)
        if rel in EXPECTED and digest != EXPECTED[rel]:
            raise SystemExit(f"Sai SHA256 tài nguyên đã duyệt {rel}: {digest}")
        output = target / rel
        output.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, output)
        if sha256(output.read_bytes()) != digest:
            raise SystemExit(f"Sao chép không toàn vẹn: {rel}")
        copied[rel] = {"size": len(raw), "sha256": digest}
    missing = sorted(set(EXPECTED) - set(copied))
    if missing:
        raise SystemExit(f"Thiếu ảnh bắt buộc: {missing}")
    metadata = {
        "source": "Duoface/dist/visual-1.0.3-12/assets",
        "source_reference": "dist/candidates/menu-native1/BUILD_AUDIT.json",
        "destination": "/var/jb/Library/Application Support/DuoFaceIndependent",
        "files": copied,
        "source_hashes_verified": len(EXPECTED),
        "excludes": ["DuoFaceDashboard.dylib", "com.duonavi.sync.plist", "DuoFaceUI binary"],
        "status": "ASSETS_COPIED_BYTE_FOR_BYTE_NOT_RUNTIME_PARITY",
    }
    (target / "asset-transfer-manifest.json").write_text(
        json.dumps(metadata, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(f"DUOFACE_APPROVED_ASSETS_COPIED: {len(copied)} files; {len(EXPECTED)} hashes validated")
    for name, item in copied.items():
        print(f"{item['sha256']}  {name}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Cách dùng: transfer_approved_assets.py STAGING_ROOT")
    main(Path(sys.argv[1]))
