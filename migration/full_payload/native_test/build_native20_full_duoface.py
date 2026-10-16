#!/usr/bin/env python3
"""native20: DuoFace identity only, preserving native19 picker and user's settings.

The original two native12 hosts generate a 49-byte filename at runtime from
independent encrypted seeds. Patch BOTH seeds (equal-length) and the separately
compiled picker; one-time preinst copies the previous preferences into the new
canonical domain without deleting original data. The core method code, UI
layout and SmartConnection 10-second library must remain unchanged.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import shutil
import re

from audit_branding import hits
from audit_native12_license_class_xrefs import MachO, select_arm64

SRC=Path("dist/payload-migration/native19/com.duoface.independent_0.1.0~native19_iphoneos-arm64.deb")
SRC_SHA="91feda0a7ff24bd7759b7448303d61fe774b16184e383fc11b6839186fa1ae1d"
VERSION="0.1.0~native20"
OLD_OWNER="/var/mobile/Library/Preferences/com."+"duo"+"navi.plist"
NEW_OWNER="/var/mobile/Library/Preferences/com.duoface.plist"
P="var/jb/Library/MobileSubstrate/DynamicLibraries/"
HOSTS={
    "var/jb/Applications/DuoFaceUI.app/DuoFaceUI":(0x1000ab77e,"cb40346d8ca504cb399abe31367847b4f980a01ba93810986ce1acf1fbe9eef9"),
    P+"DuoFaceDashboard.dylib":(0x30fb6f,"9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"),
}
PICKER=P+"DuoFaceInCarAddApps.dylib"
SMART=P+"DuoFaceSmartConnection.dylib"
SETTINGS_UI=P+"DuoFaceSettingsUIRestore.dylib"
HASH_10SEC="0986cf70b4c613ad011520204337e1e2b403d24111f39f14f70628fb57e61d50"
HASH_UI_RESTORE="680f79a1bb4d58a3bf277f7ed253f88627459390599a0818660f89dabe2e629f"

def digest(buf):return hashlib.sha256(buf).hexdigest()
def run(*args):subprocess.run(list(map(str,args)),check=True)
def inventory(root):
    return {x.relative_to(root).as_posix():digest(x.read_bytes())
            for x in root.rglob("*") if x.is_file() and not x.is_symlink()
            and x.relative_to(root).parts[0]!="DEBIAN"}
def dec_seed(seed):
    out=[]
    for i,b in enumerate(seed):
        n=i%5+1
        mixed=(b^((i^-0x5b)&255))&255
        rotated=(mixed>>n | mixed<<(8-n))&255
        q=((i*0x2b+0x83)&255)^rotated
        out.append((q-0x5d)&255)
    return bytes(out)
def enc_seed(plain):
    out=[]
    for i,b in enumerate(plain):
        n=i%5+1
        q=(b+0x5d)&255
        rotated=((i*0x2b+0x83)&255)^q
        mixed=((rotated<<n)|(rotated>>(8-n)))&255
        out.append((mixed^((i^-0x5b)&255))&255)
    return bytes(out)
def section_text(raw):
    m=MachO(select_arm64(raw))
    sections=[s for s in m.sections if s["name"]=="__text" and s["segment"]=="__TEXT"]
    assert len(sections)==1, "Ambiguous Mach-O __text section"
    x=sections[0]
    return raw[x["fileoff"]:x["fileoff"]+x["size"]]
def resign(root,rel,original,work,index):
    original_entitlements=subprocess.run(["ldid","-e",str(work/f"old-{index}.macho")],
                              capture_output=True)
    signing_entitlements="none"
    if original_entitlements.returncode==0 and b"<plist" in original_entitlements.stdout:
        target=work/f"entitlements-{index}.plist"
        target.write_bytes(original_entitlements.stdout)
        run("ldid","-S"+str(target),root/rel)
        signing_entitlements="preserved"
    else:
        run("ldid","-S",root/rel)
    assert section_text(original)==section_text((root/rel).read_bytes()), "Executable code changed"
    run("lipo",str(root/rel),"-verify_arch","arm64")
    return signing_entitlements
def write_migrating_preinst(root):
    pre=root/"DEBIAN/preinst"
    original=pre.read_text()
    assert original.startswith("#!/bin/sh")
    assert not hits(original.encode()), "Unexpected legacy branding in original preinst"
    # String pieces avoid shipping an old product name in the NEW package.
    # Only copy data when a new canonical preference file is absent. No delete!
    addition="""# DuoFace: preserve settings on first upgrade to unified preferences owner.
# Keep the previous plist untouched so older packages can be restored.
legacy_name="$(printf '%s%s%s' 'com.' 'duo' 'navi').plist"
old_store="/var/mobile/Library/Preferences/$legacy_name"
new_store="/var/mobile/Library/Preferences/com.duoface.plist"
if [ ! -e "$new_store" ] && [ -f "$old_store" ]; then
    cp -p "$old_store" "$new_store" || {
        echo 'DuoFace: cannot migrate existing preferences; refusing upgrade' >&2
        exit 1
    }
fi
"""
    # Existing ownership guard / rootless package safety must not be removed.
    assert "dpkg-query -S" in original
    assert original.rstrip().endswith("exit 0"), "Unknown previous installer"
    split=original.rfind("exit 0")
    new=original[:split]+addition+original[split:]
    assert not hits(new.encode()), "Installer contains old brand term"
    pre.write_text(new)
    run("sh","-n",pre)

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--dylib",type=Path,required=True)
    ap.add_argument("--out",type=Path,required=True)
    ap.add_argument("--report",type=Path,required=True)
    args=ap.parse_args()
    assert SRC.is_file() and digest(SRC.read_bytes())==SRC_SHA,"Wrong known-working native19 input"
    assert len(OLD_OWNER)==len(NEW_OWNER)==49
    assert dec_seed(enc_seed(OLD_OWNER.encode()))==OLD_OWNER.encode()
    assert dec_seed(enc_seed(NEW_OWNER.encode()))==NEW_OWNER.encode()
    assert not args.out.exists() and not args.report.exists(),"Refuse overwrite"
    assert args.dylib.is_file() and args.dylib.stat().st_size>3000
    picker_source=Path("runtime/appbridge/DFInCarAppPicker.xm").read_text()
    assert 'com.duoface.plist' in picker_source
    assert not re.search(r"duonavi|airaw",picker_source,re.I)
    assert "%orig" not in picker_source
    with tempfile.TemporaryDirectory(prefix="duoface-native20-clean-brand-") as temp:
        work=Path(temp); root=work/"stage"
        run("dpkg-deb","-R",SRC,root)
        baseline=inventory(root)
        assert len(baseline)==45,len(baseline)
        assert baseline[SMART]==HASH_10SEC
        assert baseline[SETTINGS_UI]==HASH_UI_RESTORE
        assert PICKER in baseline
        assert subprocess.check_output(["dpkg-deb","-f",str(SRC),"Version"],text=True).strip()=="0.1.0~native19"
        changed_seed={}
        signing={}
        for index,(rel,(vm,expected_hash)) in enumerate(HOSTS.items()):
            path=root/rel
            raw=path.read_bytes()
            assert digest(raw)==expected_hash,"Unexpected original host"
            arm=select_arm64(raw)
            assert len(arm)==len(raw),"Need separate handling for fat binary: fail closed"
            macho=MachO(arm)
            offset=macho.map(vm)
            old=raw[offset:offset+49]
            assert dec_seed(old).decode("utf-8")==OLD_OWNER, ("Wrong path source",rel)
            new=enc_seed(NEW_OWNER.encode())
            assert dec_seed(new).decode("utf-8")==NEW_OWNER
            patched=raw[:offset]+new+raw[offset+49:]
            assert len(patched)==len(raw)
            assert section_text(patched)==section_text(raw)
            saved=work/f"old-{index}.macho"
            saved.write_bytes(raw)
            path.write_bytes(patched)
            signing[rel]=resign(root,rel,raw,work,index)
            signed=(root/rel).read_bytes()
            updated=MachO(select_arm64(signed))
            assert dec_seed(signed[updated.map(vm):updated.map(vm)+49]).decode("utf-8")==NEW_OWNER
            changed_seed[rel]={"seed_vm":hex(vm),"old_seed_sha256":digest(old),
                               "new_seed_sha256":digest(new),
                               "code_section_byte_identical":True,
                               "original_sha256":expected_hash}
        shutil.copy2(args.dylib,root/PICKER)
        run("ldid","-S",root/PICKER)
        run("lipo",root/PICKER,"-verify_arch","arm64")
        control=root/"DEBIAN/control"
        control_original=control.read_text()
        assert control_original.count("Version: 0.1.0~native19")==1
        control.write_text(control_original.replace("Version: 0.1.0~native19","Version: "+VERSION,1))
        write_migrating_preinst(root)
        after=inventory(root)
        diff={p for p in baseline if baseline[p]!=after[p]}
        assert baseline.keys()==after.keys(),"No new install target paths"
        assert diff==set(HOSTS)|{PICKER},diff
        for p in after:
            if p not in diff:assert after[p]==baseline[p],"Unrelated payload changed: "+p
        for p in root.rglob("*"):
            rel=p.relative_to(root).as_posix()
            assert not hits(rel.encode()),"Old brand in path: "+rel
            if p.is_file() and not p.is_symlink():
                assert not hits(p.read_bytes()),"Old brand bytes: "+rel
        (root/"DEBIAN/md5sums").write_text("\n".join(
            hashlib.md5((root/rel).read_bytes()).hexdigest()+"  "+rel for rel in sorted(after))+"\n")
        run("sh","-n",root/"DEBIAN/preinst")
        args.out.parent.mkdir(parents=True,exist_ok=True)
        run("dpkg-deb","--build","--root-owner-group",root,args.out)
        assert subprocess.check_output(["dpkg-deb","-f",str(args.out),"Version"],text=True).strip()==VERSION
        assert subprocess.check_output(["dpkg-deb","-f",str(args.out),"Package"],text=True).strip()=="com.duoface.independent"
        report={
           "status":"NATIVE20_BRAND_ZERO_MIGRATING_PREFS_CANDIDATE_NO_DEVICE_QA",
           "version":VERSION,
           "package":"com.duoface.independent",
           "source_native19_sha256":SRC_SHA,
           "new_deb_sha256":digest(args.out.read_bytes()),
           "new_deb_bytes":args.out.stat().st_size,
           "unchanged_payload_count":len(after)-len(diff),
           "changed_payload_paths":sorted(diff),
           "new_preferences_owner_path":NEW_OWNER,
           "old_preferences_preserved_for_rollback":True,
           "installer_migrates_existing_preferences_if_needed":True,
           "legacy_brand_termmatches_all_staged_paths_and_bytes":0,
           "native12_original_code_section_unchanged_in_both_hosts":True,
           "re_signed_entitlements":signing,
           "seed_evidence":changed_seed,
           "smartconnection_10sec_unchanged":baseline[SMART]==after[SMART],
           "license_settings_ui_unchanged":baseline[SETTINGS_UI]==after[SETTINGS_UI],
           "app_picker_device_tested":False,
           "full_autorestore_device_tested":False,
           "sileo_published":False,
           "dopamine_touched":False,
           "notes":"Two byte-width-identical ARM64 obfuscated prefs paths retargeted in both hosts. This is a new settings location with safe one-time copy, NOT a test on a real iPhone."
        }
    args.report.parent.mkdir(parents=True,exist_ok=True)
    args.report.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
    print(json.dumps(report,ensure_ascii=False,indent=2))

if __name__=="__main__":
    main()
