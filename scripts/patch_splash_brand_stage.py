#!/usr/bin/env python3
"""STAGING ONLY: replace old DuoNavi splash slogans with approved DuoFace slogan.
Does not change layout, animation, or background. Do not publish without runtime test.
"""
from pathlib import Path
import subprocess, tempfile, hashlib, sys
BINS=('var/jb/Applications/DuoFaceUI.app/DuoFaceUI',
      'var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib')
OLD=b'TWO SCREENS. ZERO LIMITS.\0'
NEW=b'TWO FACES ONE SCREEN\0'
SECOND=b'WORKS WITH APPLE CARPLAY\0'
assert len(NEW)<=len(OLD)
def run(source,dest):
    with tempfile.TemporaryDirectory() as d:
        root=Path(d)/'pkg'
        subprocess.run(['dpkg-deb','-R',str(source),str(root)],check=True)
        pending=[]
        for rel in BINS:
            p=root/rel
            b=p.read_bytes()
            assert b[:4]==bytes.fromhex('cafebabe'),rel
            assert b.count(OLD)==2 and b.count(SECOND)==2,(rel,b.count(OLD),b.count(SECOND))
            updated=b.replace(OLD,NEW+b'\0'*(len(OLD)-len(NEW)))
            updated=updated.replace(SECOND,b'\0'*len(SECOND))
            assert len(updated)==len(b)
            assert updated.count(NEW)==2 and updated.count(OLD)==0 and updated.count(SECOND)==0
            pending.append((p,updated))
        for p,data in pending:p.write_bytes(data)
        ctl=root/'DEBIAN/control'
        content=ctl.read_text()
        assert 'Version: 1.0.3-10~assets-stage' in content
        ctl.write_text(content.replace('Version: 1.0.3-10~assets-stage','Version: 1.0.3-10~brand-stage'))
        subprocess.run(['dpkg-deb','--build','--root-owner-group',str(root),str(dest)],check=True)
    print('BRAND_SPLASH_STAGE_ONLY',dest,hashlib.sha256(Path(dest).read_bytes()).hexdigest())
if __name__=='__main__':
    if len(sys.argv)!=3:sys.exit('usage: patch_splash_brand_stage.py ASSET_STAGE.deb OUTPUT.deb')
    run(Path(sys.argv[1]),Path(sys.argv[2]))
