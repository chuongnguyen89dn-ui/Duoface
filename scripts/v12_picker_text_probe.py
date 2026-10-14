#!/usr/bin/env python3
"""Read-only search of exact v12 DEB for localized picker menu text and CFStrings.

Run at repository root: python3 scripts/v12_picker_text_probe.py
No patching, repackaging, signing, or device access.
"""
import hashlib
import re
import struct
import subprocess
import tarfile
import unicodedata
from pathlib import Path

SOURCE = Path("dist/visual-1.0.3-12/com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb")
DEB_SHA = "8b7dedf77b9ec05465b83fdb6e2d7127800eac232a34ecf12f2c08b3983a481a"
DASH_SHA = "bc1df854ec7a2ddfeec4cb81b080ead34b54df80143d4a8f6254bb8b618003ce"
VI_LABELS = ("Ứng dụng", "Bố cục", "Đang mở")
TERMS = VI_LABELS + (
    "Applications", "Apps", "App Picker", "Recent", "Layout", "Open",
    "appSegment", "layoutSegment", "recentSegment", "MultitaskingOverlay",
)
REGEX = re.compile(
    r"ứng\s*dụng|bố\s*cục|đang\s*mở|\bapps?\b|application|recent|"
    r"layout|app.?picker|multitasking|segment", re.I
)

def u32(buf, off):
    return struct.unpack_from("<I", buf, off)[0]

def u64(buf, off):
    return struct.unpack_from("<Q", buf, off)[0]

def matching(text):
    return bool(REGEX.search(unicodedata.normalize("NFC", text)))

def matches_bytes(payload):
    hits = []
    for label in TERMS:
        for encoding in ("utf-8", "utf-16le", "utf-16be"):
            needle = label.encode(encoding)
            low = payload.lower() if encoding == "utf-8" and label.isascii() else payload
            target = needle.lower() if encoding == "utf-8" and label.isascii() else needle
            at = low.find(target)
            if at >= 0:
                hits.append((label, encoding, at))
    return hits

def report_resource(name, payload):
    if len(payload) < 3:
        return
    hits = matches_bytes(payload)
    if hits:
        print(f"FILE {name} size={len(payload)}")
        for label, encoding, at in hits[:40]:
            print(f"  BYTE_MATCH label={label!r} encoding={encoding} offset=0x{at:x}")
    if name.lower().endswith((".strings", ".stringsdict", ".plist", ".json", ".txt", ".xml")) and len(payload) < 1_000_000:
        for encoding in ("utf-8", "utf-16le", "utf-16be"):
            try:
                decoded = payload.decode(encoding)
            except UnicodeDecodeError:
                continue
            if not matching(decoded):
                continue
            print(f"  TEXT_RESOURCE {name} encoding={encoding}")
            seen = 0
            for line_no, line in enumerate(decoded.splitlines(), 1):
                if matching(line) and len(line) < 350:
                    print(f"    L{line_no}: {line!r}")
                    seen += 1
                    if seen == 25:
                        break
            break

def macho_strings(binary):
    # The exact v12 ARM64 slice is pinned in scripts/v12_host_recovery.py.
    p = binary[0x4000:0x4000 + 3741760]
    assert u32(p, 0) == 0xfeedfacf, "unexpected v12 Mach-O ARM64 magic"
    sections = {}
    cmd = 32
    for _ in range(u32(p, 16)):
        kind, size = struct.unpack_from("<II", p, cmd)
        if kind == 0x19:  # LC_SEGMENT_64
            for i in range(u32(p, cmd+64)):
                entry = cmd+72+80*i
                name = p[entry:entry+16].split(b"\x00", 1)[0].decode("ascii", "replace")
                addr, length = u64(p, entry+32), u64(p, entry+40)
                sections[name] = (addr, length)
        cmd += size

    print("=== ALL MATCHING OBJC CFSTRING OBJECTS (ADDRESS AND VALUE) ===")
    base, length = sections["__cfstring"]
    counts = {"cfstring": 0, "cstring": 0, "ustring": 0}
    for at in range(base, base+length, 32):
        if at+32 > len(p):
            break
        flags, target, chars = u32(p, at+8), u64(p, at+16), u64(p, at+24)
        if chars > 1000 or target >= len(p) or chars == 0:
            continue
        try:
            data = p[target:target+chars*(2 if flags & 0x10 else 1)]
            string = data.decode("utf-16le" if flags & 0x10 else "utf-8")
        except (UnicodeDecodeError, ValueError):
            continue
        if matching(string):
            counts["cfstring"] += 1
            if counts["cfstring"] <= 180 or string in VI_LABELS or string.startswith(('TAB_', 'OVERLAY_')):
                print(f"  CFSTRING addr=0x{at:x} target=0x{target:x} flags=0x{flags:x} value={string!r}")

    print("=== MATCHING ASCII/UTF8 STRING TABLE VALUES ===")
    for sec in ("__cstring", "__objc_methname"):
        if sec not in sections:
            continue
        base, length = sections[sec]
        i = base
        for part in p[base:base+length].split(b"\x00"):
            if part and len(part) <= 700:
                value = part.decode("utf-8", "replace")
                if matching(value):
                    counts["cstring"] += 1
                    if counts["cstring"] <= 180:
                        print(f"  {sec} addr=0x{i:x} value={value!r}")
            i += len(part)+1

    print("=== MATCHING UTF16LE SECTION VALUES ===")
    if "__ustring" in sections:
        base, length = sections["__ustring"]
        utf16 = p[base:base+length].decode("utf-16le", "replace")
        for idx, term in enumerate(utf16.split("\x00")):
            if matching(term):
                counts["ustring"] += 1
                if counts["ustring"] <= 120 or term in VI_LABELS:
                    print(f"  __ustring match_index={idx} value={term[:200]!r}")
    print(f"COUNTS {counts}")

print("=== EXACT V12 DEB / PICKER TEXT TRACE ===")
assert SOURCE.exists(), str(SOURCE)
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == DEB_SHA, "unexpected DEB checksum"
print("DEB_SHA256", DEB_SHA)
proc = subprocess.Popen(["dpkg-deb", "--fsys-tarfile", str(SOURCE)], stdout=subprocess.PIPE)
found = False
file_count = 0
with tarfile.open(fileobj=proc.stdout, mode="r|") as tar:
    for member in tar:
        if not member.isfile():
            continue
        file_count += 1
        payload = tar.extractfile(member).read()
        name = member.name
        if "Dashboard.dylib" in name or name.endswith((".strings", ".stringsdict", ".plist", ".json")):
            print(f"RESOURCE {name} length={len(payload)}")
        report_resource(name, payload)
        if name.endswith("/DuoFaceDashboard.dylib"):
            assert hashlib.sha256(payload).hexdigest() == DASH_SHA, "unexpected Dashboard checksum"
            print("DASHBOARD_SHA256", DASH_SHA)
            macho_strings(payload)
            found = True
assert proc.wait() == 0, "dpkg-deb exited nonzero"
assert found, "verified v12 Dashboard missing"
print(f"EXAMINED_FILES {file_count}")
print("=== END V12 PICKER TEXT TRACE ===")
