#!/usr/bin/env python3
"""Reproducible *unverified* DuoFace v12 -> v13 sync-domain experiment.
Inputs: original DuoFace v12 DEB, device-2 five-year test DEB.
Does not transplant a device-specific license blob.
"""
import hashlib, pathlib, plistlib, subprocess, sys, tempfile

def run(*args):
    subprocess.run(args, check=True)

def main():
    if len(sys.argv) != 4:
        raise SystemExit("usage: python build_duoface13_syncprobe.py DUOFACE12.deb DEVICE2_5YEAR_TEST.deb OUTPUT.deb")
    source, test, dest = map(pathlib.Path, sys.argv[1:])
    with tempfile.TemporaryDirectory() as t, tempfile.TemporaryDirectory() as s:
        root, ref = pathlib.Path(t), pathlib.Path(s)
        run("dpkg-deb", "-R", str(source), str(root))
        run("dpkg-deb", "-x", str(test), str(ref))
        control = root / "DEBIAN/control"
        data = control.read_text()
        assert "Package: com.duoface.app" in data
        assert "Version: 1.0.3-12~visualtest" in data
        control.write_text(data.replace("Version: 1.0.3-12~visualtest", "Version: 1.0.3-13~syncprobe"))
        original = ref / "var/mobile/Library/Preferences/com.duonavi.sync.plist"
        prefs = plistlib.loads(original.read_bytes())
        target = root / "var/mobile/Library/Preferences/com.duoface.sync.plist"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(plistlib.dumps(prefs, fmt=plistlib.FMT_XML))
        dest.parent.mkdir(parents=True, exist_ok=True)
        run("dpkg-deb", "--build", "--root-owner-group", str(root), str(dest))
        print("SHA256", hashlib.sha256(dest.read_bytes()).hexdigest())
        print("WARNING: unverified sync-domain probe; no device activation or CarPlay runtime validation")

if __name__ == "__main__":
    main()
