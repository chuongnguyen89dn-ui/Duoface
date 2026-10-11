#!/usr/bin/env python3
"""Stage DuoFace visual PNGs in a rootless package for inspection only.

The images are NOT connected to any runtime renderer. NEVER publish this DEB.
"""
from pathlib import Path
import hashlib, shutil, subprocess, sys, tempfile
from PIL import Image

BASE_SHA = "2120480166170c5f71b12a595bed7a5ab892fbd84038ef878eca8e8243062e9a"
NAMES = ("duoface-picker.png", "duoface-fullscreen.png", "duoface-swap.png")

def stage(deb, assets, output):
    deb, assets, output = map(Path, (deb, assets, output))
    assert hashlib.sha256(deb.read_bytes()).hexdigest() == BASE_SHA, "Baseline changed"
    for name in NAMES:
        with Image.open(assets / name) as im:
            im.verify()
    with tempfile.TemporaryDirectory() as temp:
        root = Path(temp) / "pkg"
        subprocess.run(["dpkg-deb", "-R", str(deb), str(root)], check=True)
        for name in ("Applications", "Library", "etc", "usr"):
            old = root / name
            if old.exists():
                new = root / "var/jb" / name
                new.parent.mkdir(parents=True, exist_ok=True)
                if new.exists():
                    raise RuntimeError(f"Conflict: {new}")
                shutil.move(old, new)
        for original, private in (
            ("var/jb/usr/bin/cboptimize", "var/jb/usr/bin/duoface-cboptimize"),
            ("var/jb/usr/libexec/cboptimize_helper", "var/jb/usr/libexec/duoface_cboptimize_helper"),
        ):
            old = root / original
            if old.exists():
                target = root / private
                target.parent.mkdir(parents=True, exist_ok=True)
                old.rename(target)
        (root / "var/jb/usr/lib/ellekit/OldABI.dylib").unlink(missing_ok=True)
        dest = root / "var/jb/Library/Application Support/DuoFace/VisualAssets"
        dest.mkdir(parents=True, exist_ok=True)
        for name in NAMES:
            shutil.copyfile(assets / name, dest / name)
        control = root / "DEBIAN/control"
        contents = control.read_text()
        contents = contents.replace("Version: 1.0.3-6", "Version: 1.0.3-10~assets-stage")
        contents = contents.replace(
            "Description: DuoFace full-payload rootless test, runtime and signature unverified.",
            "Description: INTERNAL STAGING ONLY. Visual PNG assets are not wired to UI; do not distribute.",
        )
        control.write_text(contents)
        output.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["dpkg-deb", "--build", "--root-owner-group", str(root), str(output)], check=True)
    listed = subprocess.check_output(["dpkg-deb", "-c", str(output)], text=True)
    for name in NAMES:
        assert "VisualAssets/" + name in listed, name
    print("STAGED_NOT_RELEASED", output, hashlib.sha256(output.read_bytes()).hexdigest())

if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit("usage: stage_visual_payload.py BASE.deb ASSET_DIR OUTPUT.deb")
    stage(*sys.argv[1:])
