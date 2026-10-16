#!/usr/bin/env python3
"""Emergency native15 from exact native13, undo only native14 experimental ObjC class erasure.
Preserve signed 2 feature modules and immutable native12 host binaries.
This is NOT a restoration of old neutralized 312 license method bodies.
"""
import argparse, hashlib, json, pathlib, re, subprocess, tempfile
BASE=pathlib.Path("dist/payload-migration/native13/com.duoface.independent_0.1.0~native13_iphoneos-arm64.deb")
ORIGINAL=pathlib.Path("dist/payload-migration/native12/com.duoface.independent_0.1.0~native12_iphoneos-arm64.deb")
SOURCE_SHA="cff76573be10a73bfd423e988b803812e3375af4db6567a9229c1b04156f2cf3"
ORIGINAL_SHA="85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7"
VERSION="0.1.0~native15"
DIR="var/jb/Library/MobileSubstrate/DynamicLibraries/"
UI="var/jb/Applications/DuoFaceUI.app/DuoFaceUI"
DASH=DIR+"DuoFaceDashboard.dylib"
MODS=("DuoFaceSmartConnection","DuoFaceInCarAddApps")
def sha(data):return hashlib.sha256(data).hexdigest()
def cmd(*args):return subprocess.check_output(args,stderr=subprocess.STDOUT,text=True).strip()
def files(root):return {p.relative_to(root).as_posix():sha(p.read_bytes()) for p in root.rglob("*") if p.is_file() and p.relative_to(root).parts[0]!="DEBIAN"}
def main():
    a=argparse.ArgumentParser()
    a.add_argument("--out",type=pathlib.Path,required=True)
    a.add_argument("--report",type=pathlib.Path,required=True)
    p=a.parse_args()
    assert sha(BASE.read_bytes())==SOURCE_SHA,"native13 candidate input hash mismatch"
    assert sha(ORIGINAL.read_bytes())==ORIGINAL_SHA,"native12 tested baseline hash mismatch"
    assert cmd("dpkg-deb","-f",str(BASE),"Package")=="com.duoface.independent"
    assert cmd("dpkg-deb","-f",str(BASE),"Version")=="0.1.0~native13"
    assert not p.out.exists(),"candidate must not overwrite"
    with tempfile.TemporaryDirectory(prefix="duoface-native15-recovery-") as td:
        stage=pathlib.Path(td)/"native15"
        base12=pathlib.Path(td)/"native12"
        subprocess.run(["dpkg-deb","-R",str(BASE),str(stage)],check=True)
        subprocess.run(["dpkg-deb","-x",str(ORIGINAL),str(base12)],check=True)
        initial=files(stage);ref12=files(base12)
        assert set(initial)-set(ref12)=={DIR+x+ext for x in MODS for ext in (".dylib",".plist")}
        assert all(initial[k]==value for k,value in ref12.items()),"native13 host drift from tested native12"
        assert UI in initial and DASH in initial
        for m in MODS:
            assert DIR+m+".dylib" in initial and DIR+m+".plist" in initial
        assert not any("A_DuoFaceNativeNoLease" in k for k in initial)
        # Native14 altered only these hosts. Native15 source is pre-excision native13
        # and must preserve their exact bytes, not patch a corrupted metadata table.
        ui_bytes=(stage/UI).read_bytes()
        dash_bytes=(stage/DASH).read_bytes()
        from audit_native12_license_class_xrefs import MachO, select_arm64
        classes_ui=MachO(select_arm64(ui_bytes)).classes()
        classes_dash=MachO(select_arm64(dash_bytes)).classes()
        restored_ui=(
            "CBLicenseExpiredModalViewController","CBSubscriptionCheckoutCell",
            "CBSubscriptionGiftcodeInputCell","CBSubscriptionGiftcodeRedeemCell",
            "CBSubscriptionHardwareIDCell","CBSubscriptionOrderCoordinator",
            "CBSubscriptionPendingOrderCell","CBSubscriptionPlanCardCell",
            "CBSubscriptionStatusCell","CBSubscriptionViewController",
            "CBSubscriptionVIPCardCell","CBSubscriptionVIPStatusCell",
        )
        restored_dash=("CBLicenseShieldIconView","CBLicenseWarningModalView")
        assert all(c in classes_ui for c in restored_ui), "12 original UI license classes not all registered"
        assert all(c in classes_dash for c in restored_dash), "2 original dashboard license classes missing"
        assert len(classes_ui)==27 and len(classes_dash)==36, "original ObjC class counts have changed"
        ctl=stage/"DEBIAN/control"
        raw=ctl.read_text()
        assert re.search(r"(?m)^Version: 0\.1\.0~native13$",raw)
        ctl.write_text(re.sub(r"(?m)^Version: 0\.1\.0~native13$",f"Version: {VERSION}",raw,count=1))
        after=files(stage)
        assert after==initial, "original app/dylib bytes changed during repackaging"
        for k in (UI,DASH):
            assert after[k]==ref12[k]
        checks=[]
        for name in sorted(after):
            checks.append(hashlib.md5((stage/name).read_bytes()).hexdigest()+"  "+name)
        (stage/"DEBIAN/md5sums").write_text("\n".join(checks)+"\n")
        p.out.parent.mkdir(parents=True,exist_ok=True)
        subprocess.run(["dpkg-deb","--build","--root-owner-group",str(stage),str(p.out)],check=True)
        assert cmd("dpkg-deb","-f",str(p.out),"Version")==VERSION
        assert cmd("dpkg-deb","-f",str(p.out),"Architecture")=="iphoneos-arm64"
        assert cmd("dpkg-deb","-f",str(p.out),"Package")=="com.duoface.independent"
        report={
           "status":"NATIVE15_RESTORED_14_CLASS_REGISTRATIONS_FROM_NATIVE13_FEATURES_PRESERVED",
           "package":"com.duoface.independent","version":VERSION,
           "native15_sha256":sha(p.out.read_bytes()),"source_native13_sha256":SOURCE_SHA,
           "known_device_working_native12_sha256":ORIGINAL_SHA,
           "input_native14_experimental_license_class_removal_reused":False,
           "restored_original_objc_license_classes":14,
           "restored_UI_class_names":list(restored_ui),"restored_Dashboard_class_names":list(restored_dash),
           "registered_UI_classes":len(classes_ui),"registered_Dashboard_classes":len(classes_dash),
           "both_new_features_present":True,
           "two_signed_hook_modules":{m:{"dylib_sha256":after[DIR+m+".dylib"],"plist_sha256":after[DIR+m+".plist"]} for m in MODS},
           "all_legacy_payload_entries_exactly_equal_to_native12":True,
           "all_native13_payload_entries_unchanged":True,
           "older_native12_preexisting_license_method_stubs_restored":False,
           "complete_original_license_system_restored":False,
           "device_tested":False,"sileo_published":False,
           "warning":"Only undo experimental native14 erasure; native12 pre-existing method neutralizations remain, because native12 was last known device-working baseline."
        }
        p.report.parent.mkdir(parents=True,exist_ok=True)
        p.report.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
        print(json.dumps(report,ensure_ascii=False,indent=2))
if __name__=="__main__":main()
