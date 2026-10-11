#!/usr/bin/env python3
"""Extract approved two-face emblem from the DuoFace UI reference mockup.
This only exports a PNG. It does not patch any app or touch handling.
"""
from PIL import Image, ImageDraw
from pathlib import Path
import sys
src, dest = map(Path, sys.argv[1:3])
im = Image.open(src).convert("RGBA")
assert im.size == (1619, 971), f"Unexpected reference dimensions: {im.size}"
left, top, diameter = 66, 721, 188
icon = im.crop((left, top, left + diameter, top + diameter))
mask = Image.new("L", (diameter, diameter), 0)
ImageDraw.Draw(mask).ellipse((1, 1, diameter - 2, diameter - 2), fill=255)
icon.putalpha(mask)
dest.parent.mkdir(parents=True, exist_ok=True)
icon.save(dest)
assert icon.getpixel((0, 0))[3] == 0
assert icon.getpixel((diameter // 2, diameter // 2))[3] == 255
print("EXTRACTED", dest, icon.size)
