#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Construct an experimental DuoFace native4 from byte-pinned native3.

Remove inactive subscription/payment/expiry implementation bodies while
preserving runtime selectors and Objective-C ABI to avoid stale call crashes.
The original CarPlay split manager, app picker, geometry and assets are kept.
Only ARM64 is packaged: this avoids mismatched arm64e metadata/fixup patches.
Report actual changed method bytes, never call this full-source recompilation.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile

from audit_native4_license_code import inspect, slurp_slices
from audit_branding import hits

ROOT=Path(__file__).resolve().parents[3]
SOURCE=ROOT/"dist/payload-migration/native3/com.duoface.independent_0.1.0~native3_iphoneos-arm64.deb"
EXPECTED="7040338f37ebb1d1d2bee5adffd9cc0558b595b1ebcb9283169ab8d7f71bf2df"
VERSION="0.1.0~native4"
UI="var/jb/Applications/DuoFaceUI.app/DuoFaceUI"
DASH="var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib"
PRESERVE_MANAGER={
    "init","sharedInstance","dealloc",".cxx_destruct",
    "isCarPlayScreenConnected",
    "isCarPlayScreen:","isCarPlayScreenConnectedExcludingScreen:",
}
PRESERVE_UI_LIFECYCLE={"dealloc",".cxx_destruct"}
SPECIFIC_UI={
    ("XXRootViewController","checkAndPresentLicenseModalIfNeeded"),
    ("CBGeneralSettingsViewController","openSubscriptionScreen"),
}
BRIDGE_METHODS={
    "presentLicenseWarningModalWithType:","dismissLicenseWarningModal",
    "startLicenseWatchdogTimer","stopLicenseWatchdogTimer",
    "licenseWatchdogTimerFired:","licenseWarningModal","setLicenseWarningModal:",
}
NOP=struct.pack("<I",0xd503201f)
RET=struct.pack("<I",0xd65f03c0)
MOV_X0_ZERO=struct.pack("<I",0xd2800000)
MOV_W0_ZERO=struct.pack("<I",0x52800000)
MOV_W0_ONE=struct.pack("<I",0x52800020)
MOV_X0_ONE=struct.pack("<I",0xd2800020)
# 0xffffffff as a stable, time-independent uptime compatibility scalar:
MOVZ_X0_FFFF=struct.pack("<I",0xd29fffe0)
MOVK_X0_FFFF_LSL16=struct.pack("<I",0xf2bfffe0)

def sha(b:bytes):return hashlib.sha256(b).hexdigest()
def run(*args):subprocess.run(list(map(str,args)),check=True)
def eligible(name,selector):
    if (name,selector) in SPECIFIC_UI:return True
    if name.startswith("CBSubscription") or name=="CBLicenseExpiredModalViewController":
        return selector not in PRESERVE_UI_LIFECYCLE
    if name in ("CBLicenseShieldIconView","CBLicenseWarningModalView"):
        return selector not in PRESERVE_UI_LIFECYCLE
    if name=="CBLicenseSyncManager":
        return selector not in PRESERVE_MANAGER
    if name=="CBBridgeManager":return selector in BRIDGE_METHODS
    return False

def original_abi_stub(method):
    ret_type=method["return_type"]
    selector=method["selector"]
    if ret_type=="v":return RET
    if ret_type=="B" or ret_type=="c":
        return (MOV_W0_ONE if selector in ("isLicenseCurrentlyValid","installAndVerifyLicensePayload:errorMsg:") else MOV_W0_ZERO)+RET
    if ret_type in ("Q","q","I","i","l","L","S","s"):
        if selector in ("remainingLicenseSeconds","actualLicenseExpirationTimestamp"):
            return MOVZ_X0_FFFF+MOVK_X0_FFFF_LSL16+RET
        return MOV_X0_ZERO+RET
    if ret_type=="@":
        if selector.startswith("init") or selector=="sharedInstance":return RET
        return MOV_X0_ZERO+RET
    raise ValueError(f"Unhandled original ABI {ret_type!r} {method['class']}.{selector}")

def rewrite_arm64(original:bytes,name:str):
    slices=[x for x in slurp_slices(original) if x["arch"]=="arm64:0"]
    assert len(slices)==1,f"Missing generic arm64 architecture: {name}"
    raw=bytearray(slices[0]["bytes"])
    metadata=inspect(bytes(raw))
    items=metadata["license_named_methods"]
    assert items and not metadata["methods_without_safe_text_start"]
    selected=[]
    # Never overwrite shared host functions: each method starts at LC_FUNCTION_STARTS
    # and ends at the next recorded function start. Remove only exact methods.
    for m in items:
        if eligible(m["class"],m["selector"]):
            if not m["listed_in_lc_function_starts"] or not m["inside_executable_text"]:
                raise ValueError("Function start not established "+m["class"]+"."+m["selector"])
            off=int(m["imp_file_offset"],16)
            span=m["estimated_function_span"]
            stub=original_abi_stub(m)
            if not isinstance(span,int) or span< len(stub) or span%4!=0:
                raise ValueError("Invalid instruction span "+str(m))
            assert off%4==0
            selected.append((off,span,stub,m))
    if name=="DuoFaceUI":assert len(selected)>170,(name,len(selected))
    else:assert len(selected)>=35,(name,len(selected))
    selected.sort(key=lambda x:x[0])
    spans=[]
    for i,(off,size,stub,method) in enumerate(selected):
        if i>0 and off<selected[i-1][0]+selected[i-1][1]:
            raise ValueError("Function spans overlap: "+method["class"]+"."+method["selector"])
        assert off+size<=len(raw)
        if len(raw[off:off+size])!=size:raise ValueError("Truncated method")
        before=sha(raw[off:off+size])
        raw[off:off+size]=stub+NOP*((size-len(stub))//4)
        spans.append({
            "class":method["class"],"selector":method["selector"],
            "original_type":method["type_encoding"],
            "file_offset":off,"bytes_replaced":size,
            "previous_span_sha256":before,"stub_bytes":len(stub),
            "remaining_original_instruction_bytes_inside_span":0,
        })
    assert all(not hits(bytes(raw)) for _ in [0]),"Old vendor name reintroduced"
    return bytes(raw),spans,metadata

def patch(root:Path,work:Path):
    report={}
    for name,rel in (("DuoFaceUI",UI),("DuoFaceDashboard",DASH)):
        file=root/rel
        before=file.read_bytes()
        slim,methods,metadata=rewrite_arm64(before,name)
        # Narrow universal binaries to one tested generic ARM64 slice. Both
        # arm64/arm64e devices can load arm64 binaries; device testing required.
        original=work/(name+".before")
        original.write_bytes(before)
        build=work/(name+".thin")
        run("lipo","-thin","arm64","-output",build,original)
        assert sha(build.read_bytes())==sha(next(x["bytes"] for x in slurp_slices(before) if x["arch"]=="arm64:0"))
        file.write_bytes(slim)
        run("ldid","-S",file)
        post=subprocess.check_output(["lipo","-archs",str(file)],text=True).strip()
        assert post=="arm64",(name,post)
        newbytes=file.read_bytes()
        # Re-signing can adjust Mach-O load commands, but must not restore any
        # of the deactivated method instruction bodies.
        active=inspect(newbytes)
        assert active["method_count_license_related"]==metadata["method_count_license_related"]
        report[name]={
            "original_sha256":sha(before),"patched_sha256":sha(newbytes),
            "original_arches":[sl["arch"] for sl in slurp_slices(before)],
            "packaged_arches":["arm64"],
            "method_body_count":len(methods),
            "method_bytes_overwritten":sum(m["bytes_replaced"] for m in methods),
            "patched_methods":methods,
            "selector_tables_left_for_compatibility":True,
        }
    return report

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--out",type=Path,required=True)
    ap.add_argument("--report",type=Path,required=True)
    args=ap.parse_args()
    assert SOURCE.is_file()
    assert sha(SOURCE.read_bytes())==EXPECTED,"Never rebuild from an unknown DEB"
    with tempfile.TemporaryDirectory(prefix="duoface-native4-") as tmp:
        root=Path(tmp)/"stage"
        run("dpkg-deb","-R",SOURCE,root)
        before={p.relative_to(root).as_posix():sha(p.read_bytes())
                for p in root.rglob("*") if p.is_file() and not p.is_symlink()}
        patched=patch(root,Path(tmp))
        control=root/"DEBIAN/control"
        data=control.read_text()
        assert "Version: 0.1.0~native3" in data
        control.write_text(data.replace("Version: 0.1.0~native3","Version: "+VERSION))
        md5sums=[]
        for p in sorted(root.rglob("*")):
            if p.is_file() and not p.is_symlink() and p.relative_to(root).parts[0]!="DEBIAN":
                md5sums.append(hashlib.md5(p.read_bytes()).hexdigest()+"  "+p.relative_to(root).as_posix())
        (root/"DEBIAN/md5sums").write_text("\n".join(md5sums)+"\n")
        changed={p.relative_to(root).as_posix() for p in root.rglob("*")
                 if p.is_file() and not p.is_symlink() and sha(p.read_bytes())!=before.get(p.relative_to(root).as_posix())}
        assert changed=={UI,DASH,"DEBIAN/control","DEBIAN/md5sums"},changed
        for p in root.rglob("*"):
            if p.is_file() and not p.is_symlink():
                assert not hits(p.read_bytes()),"Vendor names found in resulting file "+str(p)
        args.out.parent.mkdir(parents=True,exist_ok=True)
        run("dpkg-deb","--build","--root-owner-group",root,args.out)
    assert subprocess.check_output(["dpkg-deb","-f",str(args.out),"Package"],text=True).strip()=="com.duoface.independent"
    assert subprocess.check_output(["dpkg-deb","-f",str(args.out),"Version"],text=True).strip()==VERSION
    report={
        "status":"NATIVE4_EXPERIMENTAL_CODE_BODIES_REPLACED_NOT_CARPLAY_TESTED",
        "package":"com.duoface.independent","version":VERSION,
        "baseline_native3_sha256":EXPECTED,
        "method_bodies":patched,
        "changed_payload_paths":sorted(changed),
        "untouched_original_files":len(before)-len(changed),
        "compiled_original_carplay_picker_source_rewritten":False,
        "all_embedded_license_strings_removed":False,
        "all_embedded_license_code_proven_removed":False,
        "what_removed":"Selected original method implementation bodies replaced by ABI-compatible inert return stubs; selector metadata retained.",
        "no_remote_license_sync_in_replaced_methods":True,
        "other_unknown_code_paths_may_still_exist":True,
        "source_native3_preserved_for_rollback":True,
        "device_tested":False,"sileo_published":False,
        "deb_sha256":sha(args.out.read_bytes()),"deb_size":args.out.stat().st_size,
    }
    args.report.parent.mkdir(parents=True,exist_ok=True)
    args.report.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({
        "version":VERSION,"status":report["status"],
        "methods_removed":{k:v["method_body_count"] for k,v in patched.items()},
        "bytes_replaced":{k:v["method_bytes_overwritten"] for k,v in patched.items()},
        "deb_sha256":report["deb_sha256"],"deb_size":report["deb_size"],
    },ensure_ascii=False,indent=2))
if __name__=="__main__":main()
