#!/usr/bin/env python3
"""Replace only the visible DuoFace Settings subtitle in two Mach-O binaries."""
from pathlib import Path
import subprocess, tempfile, sys, hashlib
FILES=('var/jb/Applications/DuoFaceUI.app/DuoFaceUI',
       'var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib')
OLD='Tự mở DuoNavi khi cắm CarPlay'.encode('utf-16le')
NEW='Tự mở DuoFace khi cắm CarPlay'.encode('utf-16le')
assert len(OLD)==len(NEW)
def run(source,output):
    with tempfile.TemporaryDirectory() as d:
        root=Path(d)/'pkg'
        subprocess.run(['dpkg-deb','-R',str(source),str(root)],check=True)
        pending=[]
        for rel in FILES:
            p=root/rel
            data=p.read_bytes()
            count=data.count(OLD)
            if count!=2:raise RuntimeError(f'{rel}: expected two Settings captions, got {count}')
            changed=data.replace(OLD,NEW)
            assert len(changed)==len(data) and changed.count(OLD)==0 and changed.count(NEW)==2
            pending.append((p,changed))
        for p,changed in pending:
            p.write_bytes(changed)
            print('PATCHED_SETTINGS',p.relative_to(root))
        ctl=root/'DEBIAN/control'
        text=ctl.read_text()
        assert 'Version: 1.0.3-10~brand-stage' in text
        ctl.write_text(text.replace('Version: 1.0.3-10~brand-stage','Version: 1.0.3-10~settings-stage'))
        subprocess.run(['dpkg-deb','--build','--root-owner-group',str(root),str(output)],check=True)
    print('STAGING_NOT_RELEASED',output,'SHA256',hashlib.sha256(Path(output).read_bytes()).hexdigest())
if __name__=='__main__':
    if len(sys.argv)!=3:sys.exit('usage: patch_settings_brand_stage.py INPUT_STAGE.deb OUTPUT_STAGE.deb')
    run(*sys.argv[1:])
