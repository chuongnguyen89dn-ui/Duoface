#!/usr/bin/env python3
"""native21 from verified native20: hide obsolete in-car add button,
restore the EXACT native12 native Auto Resume selectors and leave everything
else including SmartConnection 10s, license UI, and iPhone picker unchanged.
Source-staged modules are recompiled; this does not claim real device QA.
"""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile
import re

BASE = Path("dist/payload-migration/native20/com.duoface.independent_0.1.0~native20_iphoneos-arm64.deb")
PIN="020ec9c99eac4b8afc4e96c96c0769e1a83fcd5e687af0e37224e9a8af8778ef"
VERSION="0.1.0~native21"
PREFIX="var/jb/Library/MobileSubstrate/DynamicLibraries/"
INCAR=PREFIX+"DuoFaceInCarAddApps.dylib"
SMART=PREFIX+"DuoFaceSmartConnection.dylib"
SAFE_10S_MARKERS=["scheduleMandatoryDisconnectWatchdog",
                  "enforceMandatoryDisconnectKill",
                  "DFConnectionVerifiedDisconnected",
                  "trackBridgedBundleID:"]
OLD_AUTOSTART_HOOKS=["- (NSString *)effectiveAutoLaunchBundleID {",
                     "- (void)performAutoResume {"]
INCAR_CODE=Path("runtime/appbridge/DFRemoveOldAddAppTile.xm")
SMART_CODE=Path("runtime/connection/DFConnectionNativeHooks.xm")

def sha(v):return hashlib.sha256(v).hexdigest()
def run(*cmd):subprocess.run(list(map(str,cmd)),check=True)
def payload(root):
    return {p.relative_to(root).as_posix():sha(p.read_bytes()) for p in root.rglob("*")
      if p.is_file() and not p.is_symlink() and p.relative_to(root).parts[0]!="DEBIAN"}
def assertions():
    s=SMART_CODE.read_text()
    assert all(marker in s for marker in SAFE_10S_MARKERS)
    assert all(marker not in s for marker in OLD_AUTOSTART_HOOKS)
    assert "lastOwnedAppBundleID" not in s and "DFSaveRememberedApp" not in s
    assert "DFConnectionManagedAppActivated(bundleID, nil)" in s
    assert "DFConnectionLoadRememberedApp(nil)" in s
    assert "kDisconnectGraceMs = 10000" in Path("runtime/connection/DFConnectionPolicy.hpp").read_text()
    p=INCAR_CODE.read_text()
    assert "DFRemoveAddControls" in p
    assert "actionsForTarget:target forControlEvent:UIControlEventTouchUpInside" in p
    assert "addMoreAppsTapped:" in p and "setupAppPickerCardsInCardW:" in p
    assert "%orig;" not in p or p.count("%orig;")==2
    assert "DFSaveToNativePreferences" not in p
    for word in ("Dừng xe an toàn","Chưa xác minh","Thêm ứng dụng","mở DuoFace trên iPhone"):
        assert word not in p, word
    return {"native12_auto_resume_hooks_removed":True,
            "native12_effectiveAutoLaunchBundleID_untouched":True,
            "native12_performAutoResume_untouched":True,
            "ten_second_close_policy_preserved":True,
            "in_car_app_selection_sheet_removed":True,
            "obsolete_add_button_removed_by_native_target_action":True}
def main():
    pa=argparse.ArgumentParser()
    pa.add_argument("--picker",type=Path,required=True)
    pa.add_argument("--connection",type=Path,required=True)
    pa.add_argument("--out",type=Path,required=True)
    pa.add_argument("--report",type=Path,required=True)
    a=pa.parse_args()
    gates=assertions()
    assert BASE.is_file() and sha(BASE.read_bytes())==PIN,"native20 package is not the pinned verified release"
    assert not a.out.exists() and not a.report.exists(),"Never overwrite candidate"
    assert a.picker.is_file() and a.connection.is_file()
    assert subprocess.check_output(["dpkg-deb","-f",str(BASE),"Version"],text=True).strip()=="0.1.0~native20"
    with tempfile.TemporaryDirectory(prefix="duoface-native21-rollback-autostart-") as t:
        root=Path(t)/"stage"
        run("dpkg-deb","-R",BASE,root)
        before=payload(root)
        assert len(before)==45,len(before)
        assert INCAR in before and SMART in before
        preserved_signatures={
            "var/jb/Applications/DuoFaceUI.app/DuoFaceUI":before["var/jb/Applications/DuoFaceUI.app/DuoFaceUI"],
            PREFIX+"DuoFaceDashboard.dylib":before[PREFIX+"DuoFaceDashboard.dylib"],
            PREFIX+"DuoFaceSettingsUIRestore.dylib":before[PREFIX+"DuoFaceSettingsUIRestore.dylib"]
        }
        changed={}
        for rel,compiled in ((INCAR,a.picker),(SMART,a.connection)):
            shutil.copy2(compiled,root/rel)
            run("ldid","-S",root/rel)
            run("lipo",root/rel,"-verify_arch","arm64")
            changed[rel]={"original_sha256":before[rel],"replacement_sha256":sha((root/rel).read_bytes())}
            assert changed[rel]["original_sha256"]!=changed[rel]["replacement_sha256"]
        after=payload(root)
        assert before.keys()==after.keys()
        assert set(p for p in before if before[p]!=after[p])=={INCAR,SMART}
        assert all(before[p]==after[p] for p in before if p not in {INCAR,SMART})
        for p,oldsha in preserved_signatures.items():
            assert after[p]==oldsha
        # Ensure filter .plists (process injection scope) remain byte identical.
        assert after[INCAR[:-6]+".plist"]==before[INCAR[:-6]+".plist"]
        assert after[SMART[:-6]+".plist"]==before[SMART[:-6]+".plist"]
        assert "com.duoface" in (root/"DEBIAN/control").read_text()
        ctrl=root/"DEBIAN/control"
        raw=ctrl.read_text()
        assert raw.count("Version: 0.1.0~native20")==1
        ctrl.write_text(raw.replace("Version: 0.1.0~native20","Version: "+VERSION,1))
        # Preserve exact migration installer bytes; settings owner stays DuoFace.
        orig_preinst=(root/"DEBIAN/preinst").read_bytes()
        run("sh","-n",root/"DEBIAN/preinst")
        assert b'cp -p "$old_store" "$new_store"' in orig_preinst
        (root/"DEBIAN/md5sums").write_text("\n".join(
           hashlib.md5((root/rel).read_bytes()).hexdigest()+"  "+rel
           for rel in sorted(after))+"\n")
        a.out.parent.mkdir(parents=True,exist_ok=True)
        run("dpkg-deb","--build","--root-owner-group",root,a.out)
        for k,expected in (("Package","com.duoface.independent"),("Version",VERSION),
                           ("Architecture","iphoneos-arm64")):
            assert subprocess.check_output(["dpkg-deb","-f",str(a.out),k],text=True).strip()==expected
        report={
           "status":"NATIVE21_NATIVE12_AUTOSTART_RESTORED_OBSOLETE_APP_TILE_REMOVED_NOT_DEVICE_TESTED",
           "version":VERSION,"package":"com.duoface.independent",
           "base_native20_sha256":PIN,
           "deb_sha256":sha(a.out.read_bytes()),
           "deb_size":a.out.stat().st_size,
           "original_payload_files":len(before),
           "unchanged_payload_files":len(before)-len(changed),
           "modified_payload_files":changed,
           "original_iphone_app_and_dashboard_binary_byte_identical":True,
           "previously_installed_apps_prefs_migration_unchanged":True,
           "process_filter_plists_byte_identical":True,
           "no_new_runtime_autostart_override":True,
           "restored_native12_method_owners":["CBBridgeManager.effectiveAutoLaunchBundleID",
                                              "CBBridgeManager.performAutoResume"],
           "native12_app_selection_on_iphone_preserved":True,
           "new_disconnection_grace_seconds":10,
           "source_contracts":gates,
           "full_layout_runtime_restoration_confirmed":False,
           "obsolete_button_device_tested":False,
           "license_modified":False,"dopamine_touched":False,
           "sileo_published":False,
           "notes":"Only 2 modules recompiled: revert extra single-app Auto Resume overrides while maintaining 10s close. Hide obsolete CarPlay Add App tile; iPhone native picker unchanged. Build/byte regressions cannot prove native UI restored on device."
        }
    a.report.parent.mkdir(parents=True,exist_ok=True)
    a.report.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
    print(json.dumps(report,ensure_ascii=False,indent=2))
if __name__=="__main__":main()
