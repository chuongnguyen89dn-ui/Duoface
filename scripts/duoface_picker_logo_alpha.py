#!/usr/bin/env python3
"""Generate a MENU-ONLY alpha candidate from the checksum-pinned approved logo.

Never replace duoface-logo.png, which is also used outside the picker.
Read-only wrt source artwork. This is an asset preview, NOT a DEB build.
Usage: python3 scripts/duoface_picker_logo_alpha.py
Requires Pillow (pip install Pillow).
"""
from __future__ import annotations

from collections import deque
import hashlib
import json
from pathlib import Path
from PIL import Image

BASE = Path("dist/visual-1.0.3-12/assets")
ORIGINAL = BASE / "duoface-logo.png"
OUTPUT = BASE / "duoface-logo-picker-alpha.png"
REPORT = Path("audit/duoface-picker-logo-alpha-report.json")
SOURCE_SHA = "78450d8ee4759353bdc21f27a06016c03fab61038ae60109ba21515c087b0089"

assert hashlib.sha256(ORIGINAL.read_bytes()).hexdigest() == SOURCE_SHA
image = Image.open(ORIGINAL).convert("RGBA")
assert image.size == (960, 240)
w, h = image.size
pixels = image.load()

# Black background is physically opaque in the approved source PNG.
# Only eliminate the connected near-black component reachable from the
# OUTER CANVAS, rather than turning ALL black pixels transparent: that would
# erase the dark face belonging to the approved two-face logo.
def background(y: int, x: int) -> bool:
    r, g, b, _ = pixels[x, y]
    return max(r, g, b) <= 28 and max(r, g, b) - min(r, g, b) <= 18

mask = bytearray(w * h)
queue = deque()
for x in range(w):
    for y in (0, h - 1):
        at = y * w + x
        if not mask[at] and background(y, x):
            mask[at] = 1
            queue.append((x, y))
for y in range(h):
    for x in (0, w - 1):
        at = y * w + x
        if not mask[at] and background(y, x):
            mask[at] = 1
            queue.append((x, y))

while queue:
    x, y = queue.popleft()
    for xx, yy in ((x-1, y), (x+1, y), (x, y-1), (x, y+1)):
        if 0 <= xx < w and 0 <= yy < h:
            at = yy * w + xx
            if not mask[at] and background(yy, xx):
                mask[at] = 1
                queue.append((xx, yy))

transparent = sum(mask)
if transparent < 100_000 or transparent > 225_000:
    raise RuntimeError(f"Unexpected background component size: {transparent}")
result = image.copy()
dst = result.load()
for y in range(h):
    for x in range(w):
        if mask[y * w + x]:
            r, g, b, _ = pixels[x, y]
            dst[x, y] = (r, g, b, 0)

# Crop away the large now-transparent canvas margins. Retain the original
# RGB values of all foreground pixels (white face, dark face, red lips, text).
bounds = result.getbbox()
assert bounds is not None
result = result.crop(bounds)
OUTPUT.parent.mkdir(parents=True, exist_ok=True)
result.save(OUTPUT, optimize=True)
REPORT.parent.mkdir(parents=True, exist_ok=True)
report = {
    "status": "ALPHA_PREVIEW_NOT_DEVICE_VALIDATED_NOT_DEB",
    "source": str(ORIGINAL),
    "source_sha256": SOURCE_SHA,
    "candidate": str(OUTPUT),
    "candidate_sha256": hashlib.sha256(OUTPUT.read_bytes()).hexdigest(),
    "source_dimensions": [w, h],
    "foreground_bounds": list(bounds),
    "output_dimensions": list(result.size),
    "canvas_pixels_removed": transparent,
    "method": "4-connected edge flood on achromatic RGB<=28; original foreground colors retained",
    "warning": "Verify visually that BOTH white and dark faces survive; never silently overwrite the original."
}
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
print(REPORT.read_text())
