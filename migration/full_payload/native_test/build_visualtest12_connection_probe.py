#!/usr/bin/env python3
"""Stage exact VisualTest12 launchfix1 + a READ-ONLY connection telemetry dylib.

This is not a repair to activation, licence, CarBridge or screen detection.
The original core must remain byte-exact; never touches independent Hub.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[3]
ORIGINAL=ROOT/"dist/visualtest12-launchfix1/com.duonavi.app_1.0.3-12~visualtest12launch1_iphoneos-arm64.deb"
PIN="e30148affc767ce039040f0e0cccd9a0ecbd40e523ee66409ca96e6ef2085f02"
FILTER=ROOT/"runtime/visualtest12/DFVisual12ConnectionProbe.plist"
PKG="com.duonavi.app"
OLD_VERSION="1.0.3-12~visualtest12launch1"
VERSION="1.0.3-12~visualtest12launch2probe1"
TARGET="var/jb/Library/MobileSubstrate/DynamicLibraries"
LIB="DFVisual12ConnectionProbe.dylib"
PLIST="DFVisual12ConnectionProbe.plist"

def sha(b:bytes)->str:return hashlib.sha256(b).hexdigest()
def run(*cmd)->None:subprocess.run(list(map(str,cmd)),check=True)
def field(p:Path,key:str)->str:
    return subprocess.check_output(["dpkg-deb","-f",str(p),key],text=True).strip()
def all_files(p:Path)->dict[str,str]:
    return {f.relative_to(p).as_posix():sha(f.read_bytes()) for f in p.rglob("*")
            if f.is_file() and not f.is_symlink()}

def main()->None:
    ap=argparse.ArgumentParser()
    ap.add_argument("--dylib",type=Path,required=True)
    ap.add_argument("--out",type=Path,required=True)
    ap.add_argument("--report",type=Path,required=True)
    args=ap.parse_args()
    assert sha(ORIGINAL.read_bytes())==PIN
    assert field(ORIGINAL,"Package")==PKG
    assert field(ORIGINAL,"Version")==OLD_VERSION
    assert field(ORIGINAL,"Architecture")=="iphoneos-arm64"
    assert args.dylib.is_file() and args.dylib.stat().st_size>4000
    dylib=args.dylib.read_bytes()
    assert dylib[:4]==bytes.fromhex("cffaedfe"),"expected generic ARM64 signed Mach-O dylib"
    filters=plistlib.loads(FILTER.read_bytes())
    bundles=filters["Filter"]["Bundles"]
    assert set(bundles)=={"com.apple.springboard","com.duoface.duofaceui","com.duonavi.app"}
    assert args.out!=ORIGINAL and not args.out.exists()
    with tempfile.TemporaryDirectory(prefix="visual12-connect-probe-") as temp:
        root=Path(temp)/"stage"
        run("dpkg-deb","-R",ORIGINAL,root)
        before=all_files(root)
        for entry in (LIB,PLIST):
            assert (TARGET+"/"+entry) not in before
        loc=root/TARGET
        (loc/LIB).write_bytes(dylib)
        (loc/PLIST).write_bytes(FILTER.read_bytes())
        control=root/"DEBIAN/control"
        data=control.read_text()
        assert "Package: "+PKG+"\n" in data
        assert "Version: "+OLD_VERSION+"\n" in data
        control.write_text(data.replace("Version: "+OLD_VERSION+"\n",
                                        "Version: "+VERSION+"\n"))
        md5=[]
        for f in sorted(root.rglob("*")):
            if f.is_file() and not f.is_symlink() and f.relative_to(root).parts[0]!="DEBIAN":
                md5.append(hashlib.md5(f.read_bytes()).hexdigest()+"  "+f.relative_to(root).as_posix())
        (root/"DEBIAN/md5sums").write_text("\n".join(md5)+"\n")
        after=all_files(root)
        added=sorted(set(after)-set(before))
        removed=sorted(set(before)-set(after))
        changed=sorted(k for k in before if k in after and before[k]!=after[k])
        assert not removed,removed
        assert added==sorted((TARGET+"/"+LIB,TARGET+"/"+PLIST)),added
        assert changed==["DEBIAN/control","DEBIAN/md5sums"],changed
        assert all(before[k]==after[k] for k in before
                   if k.startswith("var/jb/Applications/") or
                      k.endswith("DuoFaceDashboard.dylib") or
                      k.endswith("DuoFaceVisualHook.dylib")), "original core changed"
        args.out.parent.mkdir(parents=True,exist_ok=True)
        run("dpkg-deb","--build","--root-owner-group",root,args.out)
    assert field(args.out,"Package")==PKG
    assert field(args.out,"Version")==VERSION
    assert field(args.out,"Architecture")=="iphoneos-arm64"
    result={
       "status":"VISUALTEST12_CONNECTION_PROBE_PRESERVES_ALL_EXISTING_CORE_BYTES",
       "source_sha256":PIN,"package":PKG,"version":VERSION,
       "source_version":OLD_VERSION,
       "added_files":added,"changed_files":changed,
       "removed_files":removed,"unchanged_original_core":True,
       "all_prior_payload_byte_identical_except_control_md5":True,
       "new_dylib_sha256":sha(dylib),"new_filter_sha256":sha(FILTER.read_bytes()),
       "filter_bundles":bundles,
       "read_only_telemetry":True,
       "writes":"/var/mobile/Documents/DuoFaceConnectionProbe/{SpringBoard,DuoFaceUI}.jsonl",
       "separate_hub_modified":False,
       "physical_carplay_connection_fixed":False,
       "license_completely_removed":False,
       "device_tested":False,"sileo_published":False,
       "output_deb_sha256":sha(args.out.read_bytes()),
       "output_deb_bytes":args.out.stat().st_size,
    }
    args.report.parent.mkdir(parents=True,exist_ok=True)
    args.report.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
    print(json.dumps(result,indent=2))
if __name__=="__main__":main()
