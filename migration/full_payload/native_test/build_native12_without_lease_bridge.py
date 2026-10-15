#!/usr/bin/env python3
"""Create reversible native12 trial removing the ENTIRE obsolete license-only hook.

This removes the separate A_DuoFaceNativeNoLease.dylib and its injection
.plist from the signed native11 package. It never truncates or renames any
Objective-C class/selector data in the main Dashboard or application Mach-O.

Rationale: all 10 explicit callback target methods in the hook's published
source already have ABI-compatible replacement bodies in native4. Still,
cross-process dynamic references cannot be ruled out by this static audit.
This is a CANDIDATE; not proven to work until actual device tests.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile

from build_native5 import cmd, sha
from build_native8 import files_and_digests

ROOT=Path(__file__).resolve().parents[3]
BASE=ROOT/"dist/payload-migration/native11/com.duoface.independent_0.1.0~native11_iphoneos-arm64.deb"
BASE_SHA="f51180308e7bfd3a86af011c7370290eee4be59d6c7aced5c5ff790e685dc2c5"
NATIVE10_SHA="3d39b181d0089ae9a7797eb1ca05790155d1b242e50ca2cff362e0a818ff8d29"
VERSION="0.1.0~native12"
PREFIX="var/jb/Library/MobileSubstrate/DynamicLibraries/"
REMOVALS={
    PREFIX+"A_DuoFaceNativeNoLease.dylib",
    PREFIX+"A_DuoFaceNativeNoLease.plist",
}
HOOK=ROOT/"migration/full_payload/native_test/DuoFaceNoLeaseBridge.mm"
NEUTRALIZED=ROOT/"dist/payload-migration/native4/BAO_CAO.json"

EXPECTED_MANAGER={
    "isLicenseCurrentlyValid","remainingLicenseSeconds",
    "actualLicenseExpirationTimestamp","checkAndSyncLicenseIfNeeded",
    "checkAndSyncLicenseIfNeededWithSource:","resolvedLicenseServerEndpoint",
}
EXPECTED_BRIDGE={
    "startLicenseWatchdogTimer","stopLicenseWatchdogTimer",
    "licenseWatchdogTimerFired:","presentLicenseWarningModalWithType:",
}

def source_check() -> dict:
    source=HOOK.read_text(encoding="utf-8")
    assert "DFITargetProcess" in source and "DFIHookMethod" in source
    a=set(re.findall(r'DFIInstallMethodForValue\(manager,@"([^"]+)"',source))
    b=set(re.findall(r'DFIHookMethod\(manager,@"([^"]+)"',source))
    c=set(re.findall(r'DFIHookMethod\(bridge,@"([^"]+)"',source))
    assert a|b==EXPECTED_MANAGER,(a|b,EXPECTED_MANAGER)
    assert c==EXPECTED_BRIDGE,(c,EXPECTED_BRIDGE)
    assert len(a)+len(b)+len(c)==10
    patched=json.loads(NEUTRALIZED.read_text(encoding="utf-8"))["method_bodies"]
    summary={}
    for binary,obj in patched.items():
        methods=obj["patched_methods"]
        expected={(m["class"],m["selector"]) for m in methods}
        for selector in EXPECTED_MANAGER:
            assert ("CBLicenseSyncManager",selector) in expected,(binary,selector)
        if binary=="DuoFaceDashboard":
            for selector in EXPECTED_BRIDGE:
                assert ("CBBridgeManager",selector) in expected,(binary,selector)
        summary[binary]={
            "license_manager_hook_selectors_previously_neutralized":len(EXPECTED_MANAGER),
            "bridge_hook_selectors_previously_neutralized":len(EXPECTED_BRIDGE)
            if binary=="DuoFaceDashboard" else 0,
        }
    return summary

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--out",required=True,type=Path)
    ap.add_argument("--report",required=True,type=Path)
    args=ap.parse_args()
    assert BASE.is_file() and sha(BASE.read_bytes())==BASE_SHA
    assert not args.out.exists(),"Refuse overwrite of package or previous release"
    assert subprocess.check_output(["dpkg-deb","-f",str(BASE),"Version"],text=True).strip()=="0.1.0~native11"
    assert subprocess.check_output(["dpkg-deb","-f",str(BASE),"Package"],text=True).strip()=="com.duoface.independent"
    assert subprocess.check_output(["dpkg-deb","-f",str(BASE),"Architecture"],text=True).strip()=="iphoneos-arm64"
    source_trace=source_check()
    with tempfile.TemporaryDirectory(prefix="duoface-native12-strip-module-") as td:
        stage=Path(td)/"stage"
        cmd("dpkg-deb","-R",BASE,stage)
        before=files_and_digests(stage)
        assert set(REMOVALS)<=set(before),"Baseline module or filter absent"
        orig_control=(stage/"DEBIAN/control").read_text()
        assert "Version: 0.1.0~native11" in orig_control
        sizes={}
        for relative in REMOVALS:
            file=stage/relative
            assert file.is_file() and not file.is_symlink()
            sizes[relative]=file.stat().st_size
            file.unlink()
        assert sizes[PREFIX+"A_DuoFaceNativeNoLease.dylib"]>1000
        # Check all other files, including DEBIAN scripts, for literal
        # dynamic-load references. A runtime ObjC callback is a separate risk.
        any_refs={}
        needle=b"A_DuoFaceNativeNoLease"
        for f in stage.rglob("*"):
            # md5sums is *expected* to mention removed files until the next
            # step regenerates it. All executable/config/maintainer files are
            # still searched; only the stale inventory is excluded.
            if f.relative_to(stage).as_posix()=="DEBIAN/md5sums":
                continue
            if f.is_file() and not f.is_symlink() and needle in f.read_bytes():
                any_refs[f.relative_to(stage).as_posix()]=True
        assert not any_refs,any_refs
        control=stage/"DEBIAN/control"
        control.write_text(orig_control.replace(
            "Version: 0.1.0~native11","Version: "+VERSION),encoding="utf-8")
        checksums=[]
        for f in sorted(stage.rglob("*")):
            if f.is_file() and not f.is_symlink() and f.relative_to(stage).parts[0]!="DEBIAN":
                checksums.append(hashlib.md5(f.read_bytes()).hexdigest()+
                                 "  "+f.relative_to(stage).as_posix())
        (stage/"DEBIAN/md5sums").write_text("\n".join(checksums)+"\n")
        after=files_and_digests(stage)
        assert set(before)-set(after)==REMOVALS
        assert not (set(after)-set(before))
        changed=sorted(k for k in before if k in after and before[k]!=after[k])
        assert changed==["DEBIAN/control","DEBIAN/md5sums"],changed
        assert len(before)-len(after)==2
        assert len(before)>30
        args.out.parent.mkdir(parents=True,exist_ok=True)
        cmd("dpkg-deb","--build","--root-owner-group",stage,args.out)
    assert subprocess.check_output(["dpkg-deb","-f",str(args.out),"Version"],text=True).strip()==VERSION
    assert subprocess.check_output(["dpkg-deb","-f",str(args.out),"Package"],text=True).strip()=="com.duoface.independent"
    assert subprocess.check_output(["dpkg-deb","-f",str(args.out),"Architecture"],text=True).strip()=="iphoneos-arm64"
    report={
        "status":"NATIVE12_WHOLE_OBSOLETE_LEASE_HOOK_LIBRARY_AND_FILTER_REMOVED_FROM_REAL_DEB",
        "source_native11_sha256":BASE_SHA,
        "source_native10_verified_by_user_sha256":NATIVE10_SHA,
        "package":"com.duoface.independent","version":VERSION,
        "architecture":"iphoneos-arm64",
        "files_physically_removed":sorted(REMOVALS),
        "bytes_removed_uncompressed":sum(sizes.values()),
        "size_by_removed_file":sizes,
        "selector_hooks_previously_neutralized_in_native4":source_trace,
        "matching_hook_selector_count":10,
        "all_other_payload_files_byte_identical":True,
        "all_8_carplay_method_bodies_byte_identical":True,
        "all_app_and_dashboard_code_and_objc_metadata_byte_identical":True,
        "full_screen_logo_divider_ui_unchanged":True,
        "main_macho_license_class_metadata_still_present":True,
        "all_license_code_and_metadata_fully_removed":False,
        "dynamic_objc_or_process_dependency_proven_absent":False,
        "only_existing_files_changed":changed,
        "baseline_module_load_name_references_in_other_files":any_refs,
        "new_deb_on_sileo":False,"device_tested":False,
        "native10_and_native11_rollback_preserved":True,
        "deb_sha256":sha(args.out.read_bytes()),
        "deb_size":args.out.stat().st_size,
    }
    args.report.parent.mkdir(parents=True,exist_ok=True)
    args.report.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(report,indent=2,ensure_ascii=False))

if __name__=="__main__":
    main()
