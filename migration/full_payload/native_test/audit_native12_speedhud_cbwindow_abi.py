#!/usr/bin/env python3
"""Verify actual Native12 DuoFace CBWindow ABI before installing *any* speed HUD hooks.
Read-only; do not modify a binary, tweak or package.
"""
import argparse,hashlib,json,subprocess,tempfile
from pathlib import Path
from audit_native12_connection_hook_abi import TARGETS,inspect_bin
from audit_native12_license_class_xrefs import BINARIES,NATIVE12_SHA
EXPECTED={
    "-show":"v16@0:8",
    "-resizeWindows":"v16@0:8",
    "-destroyWindows":"v16@0:8",
    "-rootWindow":"@16@0:8",
    "-isVisible":"B16@0:8",
}
def main():
    a=argparse.ArgumentParser()
    a.add_argument("--deb",type=Path,required=True)
    a.add_argument("--out",type=Path,required=True)
    opts=a.parse_args()
    assert hashlib.sha256(opts.deb.read_bytes()).hexdigest()==NATIVE12_SHA
    TARGETS["DuoFaceDashboard"]={"CBWindow":set(EXPECTED)}
    with tempfile.TemporaryDirectory(prefix="df12-speed-hud-abi-") as tmp:
        subprocess.run(["dpkg-deb","-x",str(opts.deb),tmp],check=True)
        raw=(Path(tmp)/BINARIES["DuoFaceDashboard"]).read_bytes()
        info=inspect_bin("DuoFaceDashboard",raw)
    measured=info["classes"]["CBWindow"]
    for name,expected in EXPECTED.items():
        actual=measured[name]["type_encoding"]
        assert actual==expected,(name,expected,actual)
    report={"status":"PINNED_NATIVE12_CBWINDOW_ABI_EXACT_PASS",
       "deb_sha256":NATIVE12_SHA,"owner":"DuoFaceDashboard.dylib",
       "methods":measured,"device_tested":False}
    opts.out.parent.mkdir(parents=True,exist_ok=True)
    opts.out.write_text(json.dumps(report,indent=2)+"\n")
    print("PINNED_NATIVE12_CBWINDOW_ABI_EXACT_PASS",{
         name:measured[name]["type_encoding"] for name in EXPECTED})
if __name__=="__main__":main()
