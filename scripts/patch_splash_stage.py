#!/usr/bin/env python3
"""Neutralize two original DuoFace splash slogans in a STAGING-ONLY DEB.

Not a production patch: the blank labels can still occupy layout space.
Never publish or install this artifact as the final DuoFace release.
"""
from pathlib import Path
import hashlib, subprocess, sys, tempfile
paths=("var/jb/Applications/DuoFaceUI.app/DuoFaceUI",
       "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib")
strings=(b"TWO SCREENS. ZERO LIMITS.",b"WORKS WITH APPLE CARPLAY")
def main(source, output):
    with tempfile.TemporaryDirectory() as tmp:
        root=Path(tmp)/"pkg"
        subprocess.run(["dpkg-deb","-R",str(source),str(root)],check=True)
        pending=[]
        for rel in paths:
            p=root/rel
            before=p.read_bytes()
            if before[:4]!=bytes.fromhex("cafebabe"):
                raise ValueError(f"Unexpected Mach-O format: {rel}")
            after=before
            for s in strings:
                count=after.count(s+b"\0")
                if count!=2:
                    raise ValueError(f"Unexpected count {count}: {rel} {s!r}")
                after=after.replace(s+b"\0",b" "*len(s)+b"\0")
            if len(after)!=len(before):
                raise AssertionError("Binary size changed")
            pending.append((p,after,before))
        for p,after,before in pending:
            p.write_bytes(after)
            print("SPLASH_TEXT_PATCHED",p.relative_to(root),
                  "changed_bytes",sum(a!=b for a,b in zip(before,after)))
        control=root/"DEBIAN/control"
        ctl=control.read_text()
        if "Version: 1.0.3-10~assets-stage" not in ctl:
            raise ValueError("Expected visual-assets staging package version")
        control.write_text(ctl.replace("Version: 1.0.3-10~assets-stage",
                                       "Version: 1.0.3-10~splash-text-stage"))
        subprocess.run(["dpkg-deb","--build","--root-owner-group",
                        str(root),str(output)],check=True)
    print("STAGING_ONLY",output,"SHA256",hashlib.sha256(Path(output).read_bytes()).hexdigest())
if __name__=="__main__":
    if len(sys.argv)!=3:
        raise SystemExit("usage: patch_splash_stage.py ASSETS_STAGE.deb OUTPUT_STAGE.deb")
    main(*sys.argv[1:])
