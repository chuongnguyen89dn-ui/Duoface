#!/usr/bin/env python3
"""Prepare transparent approved DuoFace visual assets; does not patch app behavior."""
from pathlib import Path
from PIL import Image, ImageChops
import sys, hashlib
src, dst = map(Path, sys.argv[1:3])
dst.mkdir(parents=True, exist_ok=True)
for source, output in [("app_picker_APPROVED.png","duoface-picker.png"),("fullscreen_APPROVED.png","duoface-fullscreen.png")]:
    im=Image.open(src/source).convert("RGBA")
    r,g,b=im.convert("RGB").split()
    mx=ImageChops.lighter(ImageChops.lighter(r,g),b)
    a=mx.point(lambda x: 0 if x<8 else min(255,int((x-8)*255/35)))
    im.putalpha(a)
    bounds=a.getbbox()
    assert bounds,source
    im=im.crop(bounds)
    im.save(dst/output)
    print(output,im.size,hashlib.sha256((dst/output).read_bytes()).hexdigest())
swap=Path(sys.argv[3])
assert swap.is_file()
im=Image.open(swap).convert("RGBA")
assert im.size==(188,188)
im.save(dst/"duoface-swap.png")
print("duoface-swap.png",im.size,hashlib.sha256((dst/"duoface-swap.png").read_bytes()).hexdigest())
