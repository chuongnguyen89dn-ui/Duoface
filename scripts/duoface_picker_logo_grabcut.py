#!/usr/bin/env python3
"""Experimental GrabCut-backed alpha preview for approved DuoFace picker logo.

Runs only in the v12 static audit CI. Does not patch original PNG, Dashboard
binary, build DEB or release to Sileo. Compare on checkerboard before approval.
"""
from pathlib import Path
import hashlib
import json
import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

base = Path("dist/visual-1.0.3-12/assets")
original = base / "duoface-logo.png"
sha = "78450d8ee4759353bdc21f27a06016c03fab61038ae60109ba21515c087b0089"
assert hashlib.sha256(original.read_bytes()).hexdigest() == sha
image = Image.open(original).convert("RGB")
assert image.size == (960, 240)
rgb = np.asarray(image)
height, width = rgb.shape[:2]
max_rgb = rgb.max(axis=2)
mask = np.full((height, width), cv2.GC_PR_BGD, dtype=np.uint8)

# Outside the verified artwork region is definitely background; the upper
# hair and lower red contours may touch the top/bottom edges, so never erase
# the entire first/last row indiscriminately.
mask[:, :155] = cv2.GC_BGD
mask[:, 820:] = cv2.GC_BGD
mask[max_rgb >= 42] = cv2.GC_PR_FGD
mask[max_rgb >= 125] = cv2.GC_FGD

# The dark face is an intentional part of the approved TWO-face artwork.
# Protect its central shaded surfaces from being learned as black backdrop.
cv2.ellipse(mask, (309, 111), (26, 56), -12, 0, 360, cv2.GC_FGD, -1)
cv2.ellipse(mask, (311, 163), (16, 28), -19, 0, 360, cv2.GC_FGD, -1)

# Only the near-black region outside the artwork is an unambiguous seed.
outside = np.ones((height, width), dtype=bool)
outside[6:230, 160:809] = False
mask[outside & (max_rgb < 12)] = cv2.GC_BGD

bg = np.zeros((1, 65), np.float64)
fg = np.zeros((1, 65), np.float64)
cv2.grabCut(cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR), mask, None,
            bg, fg, 6, cv2.GC_INIT_WITH_MASK)
foreground = np.logical_or(mask == cv2.GC_FGD, mask == cv2.GC_PR_FGD)
alpha_img = Image.fromarray((foreground * 255).astype("uint8"), "L")
alpha_img = alpha_img.filter(ImageFilter.GaussianBlur(radius=0.65))
rgba = image.convert("RGBA")
rgba.putalpha(alpha_img)
bbox = rgba.getbbox()
assert bbox is not None
rgba = rgba.crop(bbox)
output = base / "duoface-logo-picker-grabcut-preview.png"
rgba.save(output, optimize=True)
checker = Image.new("RGBA", rgba.size, (0, 0, 0, 0))
d = ImageDraw.Draw(checker)
for y in range(0, rgba.height, 20):
    for x in range(0, rgba.width, 20):
        tone = 190 if (x // 20 + y // 20) % 2 else 235
        d.rectangle((x, y, x+19, y+19), fill=(tone, tone, tone, 255))
checker.alpha_composite(rgba)
preview = Path("audit/duoface-picker-logo-grabcut-checkerboard.png")
preview.parent.mkdir(parents=True, exist_ok=True)
checker.convert("RGB").save(preview, optimize=True)
report = Path("audit/duoface-picker-logo-grabcut-report.json")
report.write_text(json.dumps({
    "status": "PREVIEW_ONLY_NOT_APPROVED_NOT_DEVICE_PASS",
    "source_sha256": sha, "source": str(original),
    "candidate": str(output),
    "candidate_sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
    "checkerboard_preview": str(preview),
    "foreground_pixels": int(foreground.sum()),
    "output_dimensions": list(rgba.size),
    "bounds": list(bbox),
    "guard": "preserve original assets, all color values are taken from approved source"
}, indent=2)+"\n")
assert 22000 < int(foreground.sum()) < 130000
print(report.read_text())
