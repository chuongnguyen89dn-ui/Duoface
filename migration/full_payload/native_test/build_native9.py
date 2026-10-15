#!/usr/bin/env python3
"""Native9 CarPlay repair candidate: native6 ORIGINAL visuals + isolated logo.

This script intentionally does NOT rebuild/replace DuoFaceVisualHook.dylib.
Only the 39 x 2 already audited static license-display literals are masked,
and a separately compiled/signed DuoFaceLogoGripOnly.dylib + EXACT original
Substrate injection filter are added. Native divider pan is not hooked.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import plistlib
import subprocess
import tempfile
from pathlib import Path
from build_native5 import FILES, preserve_entitlements_and_resign, sha, cmd
from build_native7 import SOURCE, EXPECTED, AUDIT, UI_COPY, mask_selected
from build_native8 import files_and_digests
from audit_branding import hits

ROOT = Path(__file__).resolve().parents[3]
VERSION = "0.1.0~native9"
BASE_VISUAL = "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib"
BASE_FILTER = BASE_VISUAL.removesuffix(".dylib") + ".plist"
GRIP_DYLIB = "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceLogoGripOnly.dylib"
GRIP_FILTER = GRIP_DYLIB.removesuffix(".dylib") + ".plist"
ORIGINAL_VISUAL_SHA256 = "4ebf68b630c102dee1bbaac87dcadddd3e13f618331cacd9c47ae1a27437959d"

def validate_source():
    standalone = (ROOT/"src/DuoFaceLogoGripOnly.m").read_text(encoding="utf-8")
    gesture = (ROOT/"src/DFDividerLogoGrip.inc").read_text(encoding="utf-8")
    assert "#define DF_LOGO_PRESERVE_NATIVE_DIVIDER_PAN 1" in standalone
    assert '#include "DFDividerLogoGrip.inc"' in standalone
    assert "DFInstallLogoGripHooks(hook, divider)" in standalone
    assert "kDFLogoHoldThreshold = 0.30" in gesture
    assert "DFLogoMoveWithHold" in gesture
    assert "setSplitRatio:" not in gesture
    assert "DFSetButtonBackgroundColor" not in standalone
    assert "_expandButton" not in standalone and "_restoreButton" not in standalone
    assert "DFLogoDividerPan" not in standalone
    for marker in ("DFLogoGripHold", "DFLogoGripDown", "DFLogoGripUp",
                   "DFLogoRestorePositionBeforeLayout"):
        assert marker in gesture
    qa = json.loads((ROOT/"audit/native9/LOGO_ISOLATION_SOURCE_ONLY.json").read_text(encoding="utf-8"))
    assert qa["status"] == "SOURCE_ONLY_NATIVE9_LOGO_ISOLATION_ROUTE_PASS"
    assert all(qa["cases"].values()) and len(qa["cases"]) == 16
    return {
        "grip_only_source_sha256": sha((ROOT/"src/DuoFaceLogoGripOnly.m").read_bytes()),
        "gesture_source_sha256": sha((ROOT/"src/DFDividerLogoGrip.inc").read_bytes()),
        "source_only_qa_report_sha256": sha((ROOT/"audit/native9/LOGO_ISOLATION_SOURCE_ONLY.json").read_bytes()),
    }

def package():
    parser=argparse.ArgumentParser()
    parser.add_argument("--hook", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--report", required=True, type=Path)
    args=parser.parse_args()
    sources=validate_source()
    assert sha(SOURCE.read_bytes()) == EXPECTED, "native6 baseline SHA changed"
    old_catalog=json.loads(AUDIT.read_text(encoding="utf-8"))
    assert old_catalog["native6_sha256"]==EXPECTED and old_catalog["raw_deb_unchanged"]
    assert len(UI_COPY)==len(set(UI_COPY))==39
    assert args.hook.is_file() and args.hook.stat().st_size>10000
    hook=args.hook.read_bytes()
    assert hook[:4]==bytes.fromhex("cffaedfe"), "not ARM64 Mach-O"
    assert b"DuoFaceGripOnly" in hook and b"DuoFaceGrip" in hook
    assert subprocess.check_output(["dpkg-deb","-f",str(SOURCE),"Package"],text=True).strip()=="com.duoface.independent"
    assert subprocess.check_output(["dpkg-deb","-f",str(SOURCE),"Version"],text=True).strip()=="0.1.0~native6"
    assert subprocess.check_output(["dpkg-deb","-f",str(SOURCE),"Architecture"],text=True).strip()=="iphoneos-arm64"

    args.out.parent.mkdir(parents=True,exist_ok=True)
    assert not args.out.exists(), "Refuse to overwrite existing native9 DEB"
    masks=[]
    signed={}
    with tempfile.TemporaryDirectory(prefix="duoface-native9-") as td:
        temp=Path(td)
        stage=temp/"stage"
        cmd("dpkg-deb","-R",SOURCE,stage)
        before=files_and_digests(stage)
        assert BASE_VISUAL in before and BASE_FILTER in before
        assert GRIP_DYLIB not in before and GRIP_FILTER not in before
        for rel in FILES.values(): assert rel in before
        base_filter=(stage/BASE_FILTER).read_bytes()
        filter_plist=plistlib.loads(base_filter)
        # No made-up process list: the additive tweak inherits EXACT native6 filter.
        assert filter_plist.get("Filter") and filter_plist["Filter"].get("Bundles")
        assert sha((stage/BASE_VISUAL).read_bytes())==ORIGINAL_VISUAL_SHA256

        for name,rel in FILES.items():
            target=stage/rel
            src=target.read_bytes()
            masked,found=mask_selected(name,src,old_catalog["binaries"][name]["strings"])
            assert len(src)==len(masked)
            target.write_bytes(masked)
            signed[name]=preserve_entitlements_and_resign(target,src,temp,name)
            assert not hits(target.read_bytes())
            masks.extend(found)
        assert len(masks)==78
        assert all(x["state"]=="temporarily_hidden_native7" for x in masks)

        grip=stage/GRIP_DYLIB
        grip.parent.mkdir(parents=True,exist_ok=True)
        grip.write_bytes(hook)
        # This independent MRC hook has no dedicated entitlement dependency.
        cmd("ldid","-S",grip)
        signed_grip_sha=sha(grip.read_bytes())
        (stage/GRIP_FILTER).write_bytes(base_filter)
        assert (stage/GRIP_FILTER).read_bytes()==(stage/BASE_FILTER).read_bytes()
        assert not hits(grip.read_bytes())

        control=stage/"DEBIAN/control"
        initial_control=control.read_text(encoding="utf-8")
        assert "Package: com.duoface.independent" in initial_control
        assert "Version: 0.1.0~native6" in initial_control
        control.write_text(initial_control.replace("Version: 0.1.0~native6", "Version: "+VERSION),
                           encoding="utf-8")

        md5=[]
        for p in sorted(stage.rglob("*")):
            if p.is_file() and not p.is_symlink() and p.relative_to(stage).parts[0]!="DEBIAN":
                md5.append(hashlib.md5(p.read_bytes()).hexdigest()+"  "+p.relative_to(stage).as_posix())
        (stage/"DEBIAN/md5sums").write_text("\n".join(md5)+"\n")
        after=files_and_digests(stage)
        assert set(after)-set(before)=={GRIP_DYLIB,GRIP_FILTER}
        assert not (set(before)-set(after)), "Existing payload cannot lose any files"
        changed=sorted(k for k in before if before[k]!=after[k])
        expected=sorted([*FILES.values(),"DEBIAN/control","DEBIAN/md5sums"])
        assert changed==expected,(changed,expected)
        assert before[BASE_VISUAL]==after[BASE_VISUAL]==ORIGINAL_VISUAL_SHA256
        assert before[BASE_FILTER]==after[BASE_FILTER]
        assert len(after)==len(before)+2
        assert sum(1 for x in masks if x["binary"]=="DuoFaceUI")==39
        assert sum(1 for x in masks if x["binary"]=="DuoFaceDashboard")==39
        cmd("dpkg-deb","--build","--root-owner-group",stage,args.out)

    assert subprocess.check_output(["dpkg-deb","-f",str(args.out),"Package"],text=True).strip()=="com.duoface.independent"
    assert subprocess.check_output(["dpkg-deb","-f",str(args.out),"Version"],text=True).strip()==VERSION
    assert subprocess.check_output(["dpkg-deb","-f",str(args.out),"Architecture"],text=True).strip()=="iphoneos-arm64"
    result={
        "status":"NATIVE9_ORIGINAL_VISUAL_PLUS_GRIP_ONLY_STAGED_NEEDS_CARPLAY_DEVICE_QA",
        "native6_base_sha256":EXPECTED,
        "package":"com.duoface.independent",
        "version":VERSION,
        "architecture":"iphoneos-arm64",
        "license_labels_selected":39,
        "license_copy_occurrences_hidden":len(masks),
        "literal_selected_bytes":sum(m["byte_count"] for m in masks),
        "actual_changed_literal_bytes_expected":sum(
            sum(x!=0x20 for x in m["label"].encode("utf-8")) for m in masks),
        "masks":masks,
        "original_visual_sha256_unchanged":ORIGINAL_VISUAL_SHA256,
        "original_visual_filter_sha256_unchanged":before[BASE_FILTER],
        "new_grip_dylib":GRIP_DYLIB,
        "new_grip_sha256":signed_grip_sha,
        "new_grip_filter":GRIP_FILTER,
        "new_grip_filter_sha256":before[BASE_FILTER],
        "hook_input_sha256":sha(hook),
        "hook_src":sources,
        "changed_existing_paths":changed,
        "added_paths":sorted([GRIP_DYLIB,GRIP_FILTER]),
        "untouched_existing_payload_files":len(before)-len(changed),
        "resigned_existing":signed,
        "native_divider_pan_hooked":False,
        "fullscreen_legacy_visual_hook_replaced":False,
        "source_native6_rollback_preserved":True,
        "native8_rollback_preserved":True,
        "logo_hold_duration_seconds":0.30,
        "license_code_fully_removed":False,
        "device_tested":False,
        "sileo_published":False,
        "deb_sha256":sha(args.out.read_bytes()),
        "deb_bytes":args.out.stat().st_size,
    }
    args.report.parent.mkdir(parents=True,exist_ok=True)
    args.report.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({k:v for k,v in result.items() if k!="masks"},ensure_ascii=False,indent=2))

if __name__=="__main__":
    package()
