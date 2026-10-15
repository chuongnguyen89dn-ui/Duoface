#!/usr/bin/env python3
"""Simulate native3 preinst without touching the user's installed packages."""
from __future__ import annotations
import hashlib, io, os, pathlib, subprocess, tarfile, tempfile

P="dist/payload-migration/native3/com.duoface.independent_0.1.0~native3_iphoneos-arm64.deb"

def main():
    data=subprocess.check_output(["dpkg-deb","--ctrl-tarfile",P])
    with tarfile.open(fileobj=io.BytesIO(data)) as tar:
        pre=next(m for m in tar if m.name in ("./preinst","preinst"))
        content=tar.extractfile(pre).read()
    assert b"dpkg-query -S" in content
    assert b"dpkg -r" not in content and b"dpkg --remove" not in content
    with tempfile.TemporaryDirectory() as work:
        p=pathlib.Path(work)
        script=p/"preinst"
        script.write_bytes(content);script.chmod(0o755)
        binpath=p/"fakebin";binpath.mkdir()
        fake=binpath/"dpkg-query"
        fake.write_text("""#!/bin/sh
if [ "$1" != "-S" ]; then exit 2; fi
if [ "$FAKE_OWNER" = "none" ]; then exit 1; fi
printf '%s: %s\\n' "$FAKE_OWNER" "$2"
""")
        fake.chmod(0o755)
        for value,expected in [("none",0),("com.duoface.independent",0),("some.other.installed.app",1)]:
            env={**os.environ,"PATH":str(binpath)+":"+os.environ.get("PATH",""),"FAKE_OWNER":value}
            result=subprocess.run(["/bin/sh",str(script)],env=env,text=True,capture_output=True)
            assert result.returncode==expected,(value,result.returncode,result.stdout,result.stderr)
        print("NATIVE3_INSTALL_OWNERSHIP_GUARD_TEST_PASS: new install, upgrade and old-file owner collision")

if __name__=="__main__":main()
