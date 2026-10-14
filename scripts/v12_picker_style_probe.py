#!/usr/bin/env python3
"""Read-only forensic probe: real DuoFace v12 picker tab geometry, typography and colors.

Run from repository root:
    python3 scripts/v12_picker_style_probe.py
No changes to the DEB, Dashboard, Sileo, or on-device state.
"""
from __future__ import annotations
import hashlib
import re
import struct
import subprocess
import tarfile
from pathlib import Path

BASE = Path("dist/visual-1.0.3-12/com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb")
EXPECTED_DEB = "8b7dedf77b9ec05465b83fdb6e2d7127800eac232a34ecf12f2c08b3983a481a"
EXPECTED_DASH = "bc1df854ec7a2ddfeec4cb81b080ead34b54df80143d4a8f6254bb8b618003ce"
AUDIT = Path("audit/v12-picker-header-20261014.txt")
assert hashlib.sha256(BASE.read_bytes()).hexdigest() == EXPECTED_DEB
assert AUDIT.is_file()
proc = subprocess.Popen(["dpkg-deb", "--fsys-tarfile", str(BASE)], stdout=subprocess.PIPE)
dashboard = None
with tarfile.open(fileobj=proc.stdout, mode="r|") as archive:
    for entry in archive:
        if entry.isfile() and entry.name.endswith("/DuoFaceDashboard.dylib"):
            dashboard = archive.extractfile(entry).read()
            break
# Stopping a streaming tar early can close the pipe while dpkg-deb is writing.
# Drain the pipe before waiting so checksum/error handling stays deterministic.
if proc.stdout is not None:
    proc.stdout.read()
assert proc.wait() == 0
assert dashboard and hashlib.sha256(dashboard).hexdigest() == EXPECTED_DASH
p = dashboard[0x4000:0x4000 + 3741760]
assert struct.unpack_from("<I", p)[0] == 0xfeedfacf
print("SOURCE v12", BASE)
print("DEB_SHA256", EXPECTED_DEB)
print("DASHBOARD_SHA256", EXPECTED_DASH)

# Constants below are ARM64 virtual offsets in the verified v12 slice, as found
# by Capstone in the already persisted setupCardContent disassembly.
constant_offsets = {
    "app_tab_color_r_or_g": 0x30fac0,
    "app_tab_color_b": 0x311730,
    "app_tab_color_alpha": 0x3116d0,
    "tab_selected_title_gray": 0x311798,
    "tab_border_white_alpha": 0x311778,
    "content_label_min_scale": 0x310cd8,
    "tab_blue_or_tint_red": 0x30fac8,
    "tab_blue_or_tint_green": 0x311790,
    "tab_background_extra_blue": 0x311788,
    "tab_background_extra_red": 0x311780,
    "picker_icon_tint": 0x311728,
    "compact_height_threshold": 0x311770,
    "compact_width_threshold": 0x311760,
    "picker_width_threshold": 0x311758,
    "picker_alpha_or_font": 0x311738,
    "second_picker_default": 0x310cd0,
}
print("\n=== EXACT BINARY DOUBLE CONSTANTS ===")
for label, offset in constant_offsets.items():
    value = struct.unpack_from("<d", p, offset)[0]
    raw = p[offset:offset+8].hex()
    print(f"0x{offset:06x} {label:30s} float64={value:.12g} raw={raw}")
# Read __data GOT pointers but do not invent the symbolic UIFontWeight
# if it requires arm64 chained fixups or library bindings.
for offset in (0x3440c0, 0x3440c8):
    val = struct.unpack_from("<Q", p, offset)[0]
    print(f"GLOBAL_POINTER 0x{offset:06x} raw64=0x{val:016x} UIFont weight unresolved statically")

text = AUDIT.read_text()
rows = []
for line in text.splitlines():
    m = re.match(r"^([0-9a-fA-F]{8}):\s+(\S+)\s+(.*)$", line)
    if m:
        rows.append((int(m.group(1), 16), line))

groups = (
    ("HEADER_LABEL_FONT_AND_TITLE", 0xa2e48, 0xa2f1c),
    ("MENU_BACKGROUND_FRAME_BORDER", 0xa2fb0, 0xa3158),
    ("FIRST_APP_TAB_FRAME_AND_TRANSLATED_TITLE", 0xa33d0, 0xa3540),
    ("APP_TAB_SELECTED_VS_INACTIVE_STYLES", 0xa3540, 0xa3730),
    ("SECOND_LAYOUT_TAB", 0xa3730, 0xa39f0),
    ("THIRD_RECENT_TAB", 0xa3a00, 0xa3d00),
)
print("\n=== EXACT RELEVANT CALLSITE ANNOTATIONS FROM PINNED V12 ===")
for name, start, end in groups:
    print(f"\n[{name}] 0x{start:x}-0x{end:x}")
    for addr, line in rows:
        if not start <= addr < end:
            continue
        # Selection layout, sizes, colors, text, state, and UIKit calls.
        if any(token in line for token in (
            " SEL ", " CLASS ", " NSString ", "fmov", "fadd", "fsub",
            "fmul", "fdiv", "fcsel", "fcmp",
        )) or re.search(r"ldr\s+d\d+,\s+\[x\d+,\s*#0x", line):
            print(line)
print("\nVERDICT: the three segment buttons are state-dependent and share"
      " their parent layout. Replicate style at runtime from the existing"
      " UIButton and its selected/unselected siblings; do NOT guess colors,"
      " font weights, frame width or make a video overlay.")
print("NO DEB BUILT")
