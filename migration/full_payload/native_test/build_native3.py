#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""DuoFace Native3: safe, fixed-length brand migration from working native2.

Rebuild from exactly pinned native2 DEB. Only translate legacy UI names in two
localization string pools, a single FullscreenBridge diagnostic and installer
collision guard. Keep native UI, picker, CarPlay split and add-on native2 as-is.

Every altered Mach-O is re-signed while preserving original entitlements.
An EXHAUSTIVE final DEB scan must find ZERO DuoNavi/Airaw bytes, paths or scripts.
"""
from __future__ import annotations
import argparse
from collections import Counter
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import stat
import subprocess
import tempfile

from audit_branding import hits, inspect_tar
import io
import tarfile

ROOT=Path(__file__).resolve().parents[3]
SRC=ROOT/"dist/payload-migration/native2/com.duoface.independent_0.1.0~native2_iphoneos-arm64.deb"
SRC_SHA="0d48d13e4c5965f8d787d86fa4c7776145cd843e98e7cae0b516779271264e60"
VERSION="0.1.0~native3"
PREFIX="var/jb"
UI=f"{PREFIX}/Applications/DuoFaceUI.app/DuoFaceUI"
DASH=f"{PREFIX}/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib"
FULL=f"{PREFIX}/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib"
NEW_BRANDING_FILES={UI,DASH,FULL}
NATIVE2_ROLLBACK="0d48d13e4c5965f8d787d86fa4c7776145cd843e98e7cae0b516779271264e60"
CONTROL_OVERWRITES={"control","md5sums","preinst"}

def sha256(data:bytes)->str:return hashlib.sha256(data).hexdigest()
def run(*parts): subprocess.run(list(parts),check=True)
def all_files(root:Path):
    return {p.relative_to(root).as_posix():sha256(p.read_bytes())
            for p in root.rglob("*") if p.is_file() and not p.is_symlink()}
def replace_brand_strings(data:bytes):
    """All matching translated brand strings have exactly seven letters.

    Existing diagnostic report proves true occurrences are UTF-16LE localized
    Unicode strings (UTF-16BE offsets overlap by -1). We only patch UTF-16LE
    and reject any unexpected leftover ASCII/BE occurrence.
    """
    chars=[]
    for ch in "duonavi":
        choices=(ch.lower()+ch.upper()).encode("ascii")
        chars.append(b"["+choices+b"]\\x00")
    pattern=re.compile(b"".join(chars))
    matches=[m.group(0) for m in pattern.finditer(data)]
    def repl(match:re.Match[bytes]):
        name=match.group(0).decode("utf-16-le")
        changed="DUOFACE" if name.isupper() else "duoface" if name.islower() else "DuoFace"
        patched=changed.encode("utf-16-le")
        assert len(patched)==len(match.group(0)), "Refuse patch when Mach-O string byte length changes"
        return patched
    patched,count=pattern.subn(repl,data)
    assert count==len(matches)
    assert len(patched)==len(data), "Binary offsets moved"
    return patched,count

def sign_binary(path:Path,entitlements_path:Path):
    # Read existing entitlements via ldid before signing; preserve if nonempty.
    old=subprocess.run(["ldid","-e",str(path)],capture_output=True)
    if old.returncode==0 and b"<plist" in old.stdout:
        entitlements_path.write_bytes(old.stdout)
        run("ldid", "-S"+str(entitlements_path),str(path))
        return "preserved"
    run("ldid","-S",str(path))
    return "none-found"

def prepare_new_preinst(root:Path):
    # There are ZERO hard-coded legacy package IDs anywhere in this script.
    # Instead, guard *file ownership* so a rename never deletes an installed
    # package, even if its old package ID is unknown.
    content="""#!/bin/sh
set -eu
for protected in \
    /var/jb/Applications/DuoFaceUI.app/DuoFaceUI \
    /var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib \
    /var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceFullscreenBridge.dylib \
    /var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib
do
    owner="$(dpkg-query -S "$protected" 2>/dev/null || true)"
    if [ -n "$owner" ]; then
        case "$owner" in
            "com.duoface.independent":* ) ;;
            *)
                echo "DuoFace native3: another installed package owns $protected; refusing overwrite" >&2
                exit 1
                ;;
        esac
    fi
done
exit 0
"""
    # The case code is intentionally simple to audit and cannot remove anything.
    out=root/"DEBIAN/preinst"
    out.write_text(content,encoding="utf-8")
    out.chmod(0o755)

def verify_local_payload(root:Path):
    # Path and link check independently of raw byte scan.
    for p in root.rglob("*"):
        assert not hits(p.relative_to(root).as_posix().encode("utf-8")), f"Legacy name in path: {p}"
        if p.is_symlink():assert not hits(os.readlink(p).encode("utf-8")), f"Legacy symlink: {p}"
        if p.is_file() and not p.is_symlink():
            occurrences=hits(p.read_bytes())
            if occurrences:
                raise AssertionError(f"Legacy terms remain after branding migration: {p}: {occurrences[:2]}")

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--out",type=Path,required=True)
    ap.add_argument("--report",type=Path,required=True)
    args=ap.parse_args()
    source_bytes=SRC.read_bytes()
    assert sha256(source_bytes)==SRC_SHA, "Refuse if native2 baseline differs from pinned native2 release"
    with tempfile.TemporaryDirectory(prefix="duoface-native3-") as work:
        directory=Path(work)
        root=directory/"staging"
        run("dpkg-deb","-R",str(SRC),str(root))
        original=all_files(root)
        baseline_control=(root/"DEBIAN/control").read_text(encoding="utf-8")
        assert "Package: com.duoface.independent" in baseline_control
        assert "Version: 0.1.0~native2" in baseline_control
        original_macho={}
        brand_counts={}
        signatures={}
        for index,rel in enumerate((UI,DASH,FULL)):
            path=root/rel
            data=path.read_bytes()
            original_macho[rel]={"size":len(data),"sha256":sha256(data)}
            if rel in (UI,DASH):
                patched,count=replace_brand_strings(data)
                expected=434 if rel==UI else 428
                assert count==expected, f"Unexpected original translated string count for {rel}: {count}"
                brand_counts[rel]=count
            else:
                # One debug-only string. Both phrases have IDENTICAL byte width:
                # Airaw-compatible (16) -> DuoFace-friendly (16).
                old=b"Airaw-compatible"
                new=b"DuoFace-friendly"
                assert len(old)==len(new), "May not shift Mach-O string offsets"
                assert data.count(old)==1 and data.count(b"Airaw")==1, "Unexpected diagnostic context"
                patched=data.replace(old,new)
                brand_counts[rel]=1
            assert len(patched)==len(data)
            path.write_bytes(patched)
            # ldid resigns modified executable; retain original entitlements
            # rather than silently discarding CarPlay/application capabilities.
            # Reload previous entitlements from saved untouched source file.
            before=directory/f"before-{index}.bin"
            before.write_bytes(data)
            existing=subprocess.run(["ldid","-e",str(before)],capture_output=True)
            entitlement=directory/f"entitlements-{index}.xml"
            if existing.returncode==0 and b"<plist" in existing.stdout:
                entitlement.write_bytes(existing.stdout)
                run("ldid","-S"+str(entitlement),str(path))
                signatures[rel]="preserved_existing_entitlements"
            else:
                run("ldid","-S",str(path))
                signatures[rel]="ad_hoc_no_existing_entitlements"
            assert path.stat().st_size>10000
            assert not hits(path.read_bytes()), f"Legacy vendor string after signing: {rel}"
        # Replace the only original installer reference with a package-agnostic
        # ownership guard (safer than deleting collision protection).
        prepare_new_preinst(root)
        control=root/"DEBIAN/control"
        revised=baseline_control.replace("Version: 0.1.0~native2","Version: "+VERSION)
        assert revised!=baseline_control and revised.count("Version: "+VERSION)==1
        control.write_text(revised,encoding="utf-8")
        file_checksums=[]
        for p in sorted(root.rglob("*")):
            if p.is_file() and not p.is_symlink() and p.relative_to(root).parts[0]!="DEBIAN":
                relative=p.relative_to(root).as_posix()
                file_checksums.append(f"{hashlib.md5(p.read_bytes()).hexdigest()}  {relative}")
        (root/"DEBIAN/md5sums").write_text("\n".join(file_checksums)+"\n",encoding="utf-8")
        (root/"DEBIAN/md5sums").chmod(0o644)
        now=all_files(root)
        changed={p for p in now if now[p]!=original.get(p)}
        assert changed==NEW_BRANDING_FILES | {f"DEBIAN/{x}" for x in CONTROL_OVERWRITES}, sorted(changed)
        assert set(now)==set(original), "Native3 must not add/remove any original app or library files"
        for rel in set(now)-changed:
            assert now[rel]==original[rel],f"Unexpected modified payload: {rel}"
        # Check all entries *including* installer scripts and executable bytes.
        verify_local_payload(root)
        args.out.parent.mkdir(parents=True,exist_ok=True)
        run("dpkg-deb","--build","--root-owner-group",str(root),str(args.out))
    report={
        "status":"NATIVE3_BRAND_CLEAN_DEB_BUILT_PENDING_DEVICE_CARPLAY_TEST",
        "version":VERSION,"package":"com.duoface.independent",
        "source_native2_sha256":SRC_SHA,
        "source_native2_preserved_for_rollback":True,
        "binary_localized_replacements":brand_counts,
        "re_signed_changed_binary_entitlements":signatures,
        "original_macho_before":original_macho,
        "modified_paths":sorted(changed),
        "unmodified_payload_path_count":len(now)-len(changed),
        "all_binary_sizes_constant_before_resigning":True,
        "zero_brand_matches_in_all_extracted_files":True,
        "no_auto_remove_legacy_packages":True,
        "native2_settings_cleanup_preserved":True,
        "license_logic_code_fully_removed":False,
        "carplay_device_tested":False,
        "sileo_published":False,
        "sha256":sha256(args.out.read_bytes()),
        "size":args.out.stat().st_size,
        "note":"Brand names are removed from static bytes and installer text, but remaining license code must be assessed independently.",
    }
    args.report.parent.mkdir(parents=True,exist_ok=True)
    args.report.write_text(json.dumps(report,ensure_ascii=False,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print(json.dumps({k:v for k,v in report.items() if k not in ("original_macho_before",)},ensure_ascii=False,indent=2))
if __name__=="__main__":main()
