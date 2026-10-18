#!/usr/bin/env python3
"""Preserve the uploaded SidePlay DEB as an unpacked *binary* reference.

Read-only inspection of the source archive. Never execute maintainer scripts
or application binaries. No binary rewriting, bypass, IPA/DEB build, or install.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import plistlib
import re
import shutil
import stat
import struct
import subprocess
from datetime import datetime, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
DEFAULT_DEB = REPO / "com.sideplay_1.0.4-1_iphoneos-arm64.deb"
EXPECTED_SHA256 = "7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c"
OUTPUT = REPO / "sideplay" / "extracted-1.0.4-1"
AUDIT = REPO / "sideplay" / "audit" / "deb-1.0.4-1"
STRINGS = AUDIT / "macho-strings"


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def run(command: list[str], dest: Path | None = None) -> str:
    result = subprocess.run(command, capture_output=True, text=True, errors="replace", check=True)
    if dest is not None:
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(result.stdout, encoding="utf-8")
    return result.stdout


def safe_json(obj):
    if isinstance(obj, bytes):
        return {"base64": __import__("base64").b64encode(obj).decode("ascii")}
    if isinstance(obj, datetime):
        return obj.isoformat()
    if isinstance(obj, plistlib.UID):
        return {"UID": obj.data}
    if isinstance(obj, dict):
        return {str(k): safe_json(v) for k, v in obj.items()}
    if isinstance(obj, (tuple, list)):
        return [safe_json(i) for i in obj]
    return obj


def macho_info(data: bytes):
    """Small Mach-O load-command scan; does not execute or modify binary."""
    if len(data) < 32:
        return None
    magics = {0xFEEDFACE: (">", False), 0xCEFAEDFE: ("<", False),
              0xFEEDFACF: (">", True), 0xCFFAEDFE: ("<", True)}
    be = struct.unpack_from(">I", data)[0]
    if be in (0xCAFEBABE, 0xCAFEBABF, 0xBEBAFECA, 0xBFBAFECA):
        return {"kind": "fat_macho", "magic": hex(be),
                "note": "fat slices retained; extract architecture slices separately before call-graph work"}
    if be not in magics:
        return None
    endian, is_64 = magics[be]
    header_size = 32 if is_64 else 28
    ncmds = struct.unpack_from(endian + "I", data, 16)[0]
    size_cmds = struct.unpack_from(endian + "I", data, 20)[0]
    info = {"kind": "macho64" if is_64 else "macho32",
            "magic": hex(be), "cpu_type": struct.unpack_from(endian + "I", data, 4)[0],
            "file_type": struct.unpack_from(endian + "I", data, 12)[0],
            "ncmds": ncmds, "sizeofcmds": size_cmds, "load_dylibs": [],
            "rpaths": [], "segments": [], "has_code_signature": False}
    off = header_size
    for _ in range(min(ncmds, 2000)):
        if off + 8 > len(data):
            info["truncated_commands"] = True
            break
        cmd, size = struct.unpack_from(endian + "II", data, off)
        if size < 8 or off + size > len(data):
            info["malformed_command_at"] = off
            break
        base_cmd = cmd & 0x7FFFFFFF
        if base_cmd in {0xC, 0x18, 0x1F, 0x23, 0x20, 0xD} and size >= 24:
            str_off = struct.unpack_from(endian + "I", data, off + 8)[0]
            if 0 < str_off < size:
                name = data[off + str_off:off + size].split(b"\x00", 1)[0].decode("utf-8", "replace")
                info["load_dylibs"].append({"command": hex(cmd), "name": name})
        elif base_cmd == 0x1C and size >= 12:
            str_off = struct.unpack_from(endian + "I", data, off + 8)[0]
            if 0 < str_off < size:
                info["rpaths"].append(data[off + str_off:off + size].split(b"\x00", 1)[0].decode("utf-8", "replace"))
        elif base_cmd in (0x1, 0x19) and size >= 24:
            info["segments"].append(data[off + 8:off + 24].split(b"\x00", 1)[0].decode("ascii", "replace"))
        elif base_cmd == 0x1D:
            info["has_code_signature"] = True
        off += size
    return info


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--deb", type=Path, default=DEFAULT_DEB)
    args = ap.parse_args()
    deb = args.deb.resolve()
    if not deb.is_file():
        raise SystemExit(f"DEB_NOT_FOUND: {deb}")
    actual_hash = sha256(deb)
    if actual_hash != EXPECTED_SHA256:
        raise SystemExit(f"SHA256_MISMATCH actual={actual_hash} expected={EXPECTED_SHA256}")
    if OUTPUT.exists() or AUDIT.exists():
        raise SystemExit("OUTPUT_ALREADY_EXISTS: refusing to overwrite saved extraction or audit")
    for program in ("dpkg-deb", "file"):
        if shutil.which(program) is None:
            raise SystemExit(f"MISSING_REQUIRED_TOOL: {program}")

    # --extract and --control only; never install or execute package scripts.
    rootfs = OUTPUT / "rootfs"
    ctrl = OUTPUT / "control"
    rootfs.mkdir(parents=True, exist_ok=False)
    ctrl.mkdir(parents=True, exist_ok=False)
    AUDIT.mkdir(parents=True, exist_ok=False)
    STRINGS.mkdir()
    run(["dpkg-deb", "-x", str(deb), str(rootfs)])
    run(["dpkg-deb", "-e", str(deb), str(ctrl)])
    run(["dpkg-deb", "-I", str(deb)], AUDIT / "package-info.txt")
    run(["dpkg-deb", "-c", str(deb)], AUDIT / "archive-file-list.txt")
    run(["dpkg-deb", "-f", str(deb)], AUDIT / "control-fields.txt")
    run(["ar", "t", str(deb)], AUDIT / "archive-members.txt")

    inventory = []
    macho = []
    plists = []
    image_assets = []
    for base, kind in ((rootfs, "rootfs"), (ctrl, "control")):
        for entry in sorted(base.rglob("*"), key=lambda x: str(x)):
            rel = str(entry.relative_to(base))
            lst = entry.lstat()
            record = {"scope": kind, "path": rel, "mode": oct(stat.S_IMODE(lst.st_mode))}
            if entry.is_symlink():
                record.update(type="symlink", target=os.readlink(entry))
            elif entry.is_dir():
                record.update(type="directory")
            elif entry.is_file():
                record.update(type="regular", size=lst.st_size, sha256=sha256(entry))
                rec_mime = run(["file", "-b", str(entry)]).strip()
                record["file_description"] = rec_mime
                try:
                    with entry.open("rb") as f:
                        buf = f.read()
                    info = macho_info(buf)
                except (OSError, struct.error, ValueError) as exc:
                    info = None
                    record["analysis_error"] = str(exc)
                if info:
                    info["path"] = f"{kind}/{rel}"
                    macho.append(info)
                    # Full printable string reference, ASCII only. Does not execute code.
                    matches = re.findall(rb"[\x20-\x7E]{4,}", buf)
                    string_file = STRINGS / f"{len(macho):03d}-{entry.name}.strings.txt"
                    string_file.write_text(
                        "\n".join(item.decode("ascii", "replace") for item in matches) + "\n",
                        encoding="utf-8")
                    info["strings_file"] = str(string_file.relative_to(REPO))
                    info["strings_count"] = len(matches)
                if entry.suffix.lower() == ".plist":
                    try:
                        parsed = plistlib.loads(buf)
                        plists.append({"path": f"{kind}/{rel}", "format": "binary" if buf.startswith(b"bplist") else "xml",
                                       "data": safe_json(parsed)})
                    except (ValueError, TypeError, OSError, OverflowError) as e:
                        plists.append({"path": f"{kind}/{rel}", "error": str(e)})
                if buf.startswith(b"\x89PNG\r\n\x1a\n") and len(buf) >= 24:
                    w, h = struct.unpack_from(">II", buf, 16)
                    image_assets.append({"path": f"{kind}/{rel}", "type": "PNG", "width": w, "height": h})
            else:
                record.update(type="other")
            inventory.append(record)

    summary = {
        "source_repository": "chuongnguyen89dn-ui/Duoface",
        "source_deb_path": str(deb.relative_to(REPO)) if deb.is_relative_to(REPO) else str(deb),
        "source_deb_size": deb.stat().st_size,
        "source_deb_sha256": actual_hash,
        "historical_unpacked_file_count": 136,
        "file_count_rootfs": sum(x["type"] == "regular" for x in inventory if x["scope"] == "rootfs"),
        "link_count_rootfs": sum(x["type"] == "symlink" for x in inventory if x["scope"] == "rootfs"),
        "directory_count_rootfs": sum(x["type"] == "directory" for x in inventory if x["scope"] == "rootfs"),
        "control_entries": sum(x["scope"] == "control" for x in inventory),
        "macho_count": len(macho), "plist_count": len(plists),
        "png_count": len(image_assets),
        "scan_utc": datetime.now(timezone.utc).isoformat(),
        "not_source_code": "Mach-O binaries are compiled. Extraction does not reconstruct .m/.h/.xm sources.",
        "not_device_tested": True,
        "maintainer_scripts_executed": False,
    }
    for name, data in (("summary.json", summary), ("inventory.json", inventory),
                       ("macho-load-commands.json", macho), ("plists-decoded.json", plists),
                       ("image-dimensions.json", image_assets)):
        (AUDIT / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (AUDIT / "SHA256SUMS.txt").write_text(
        f"{actual_hash}  {deb.name}\n" +
        "".join(f'{r["sha256"]}  {r["scope"]}/{r["path"]}\n' for r in inventory if r["type"] == "regular"),
        encoding="utf-8")
    (OUTPUT / "README.md").write_text(
        "# SidePlay 1.0.4-1 unpacked original\n\n"
        "rootfs/ = original package payload; control/ = Debian control scripts and metadata. "
        "Paths are unmodified. File integrity and original modes/symlinks are recorded in "
        "../audit/deb-1.0.4-1/inventory.json and archive-file-list.txt. "
        "Mach-O dylibs/app binaries are **compiled code, not editable source code**. "
        "Do not execute postinst/prerm or assume a compiled binary may be republished.\n",
        encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
