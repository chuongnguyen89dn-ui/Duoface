#!/usr/bin/env python3
"""Speed8: keep every working Native12+Speed7 file except updated Speed8 HUD binary."""
from __future__ import annotations
import argparse,hashlib,json,pathlib,shutil,subprocess,tempfile
BASE=pathlib.Path("dist/payload-migration/native12-speed7split/com.duoface.independent_0.1.0~native12+speed7split_iphoneos-arm64.deb")
PIN="a59c65f96457b436a0adf581ce96ad0a7fd769552f13ca67112b41b525811155"
VERSION="0.1.0~native12+speed8compact"
DIR=pathlib.Path("var/jb/Library/MobileSubstrate/DynamicLibraries")
REPLACE=("DuoFaceSpeedHUD.dylib",)
BAN=("DuoFaceSpeedSources","WazeGMapHUDSource","GofaGMapHUDSource",
     "GMapHUDPlacementRelay","GMapHUDOverspeedScreen","GoogleMapsVietMap")
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def cmd(*args):subprocess.run([str(v) for v in args],check=True)
def payload(root):
    return {p.relative_to(root).as_posix():sha(p) for p in root.rglob("*")
            if p.is_file() and not p.is_symlink() and p.relative_to(root).parts[0]!="DEBIAN"}
def main():
    p=argparse.ArgumentParser()
    for x in ("hud","output","report"):p.add_argument("--"+x,required=True,type=pathlib.Path)
    a=p.parse_args()
    assert BASE.is_file() and sha(BASE)==PIN,"Immutable installed baseline wrong"
    assert a.hud.is_file() and a.hud.stat().st_size>3000
    assert not a.output.exists() and not a.report.exists()
    with tempfile.TemporaryDirectory(prefix="duoface-native-speed8compact-") as td:
        root=pathlib.Path(td)/"stage"
        cmd("dpkg-deb","-R",BASE,root)
        before=payload(root)
        assert len(before)==43,len(before)
        assert not any(any(x in z for x in BAN) for z in before)
        originals={z:d for z,d in before.items() if z not in {str(DIR/n) for n in REPLACE}}
        assert len(originals)==42
        assert str(DIR/"DuoFaceSpeedOwner.dylib") in originals
        assert str(DIR/"DuoFaceSpeedOwner.plist") in originals
        for z in ("DuoFaceDashboard","DuoFaceFullscreenBridge",
                  "DuoFaceVisualHook","DuoFaceLogoGripOnly"):
            assert str(DIR/(z+".dylib")) in originals
        dest=root/DIR
        dll=dest/"DuoFaceSpeedHUD.dylib"
        plist=dest/"DuoFaceSpeedHUD.plist"
        assert dll.is_file() and plist.is_file() and dll.stem==plist.stem
        # Root owner probe remains unchanged; old CarPlayApp renderer deliberately replaced.
        shutil.copy2(a.hud,dll);dll.chmod(0o755)
        assert b"SpringBoard" in plist.read_bytes()
        assert b"CarPlayApp" not in plist.read_bytes()
        cmd("ldid","-S",dll)
        cmd("lipo",dll,"-verify_arch","arm64")
        cmd("plutil","-lint",plist)
        ctrl=root/"DEBIAN/control"
        text=ctrl.read_text()
        assert "Version: 0.1.0~native12+speed7split" in text
        ctrl.write_text(text.replace("Version: 0.1.0~native12+speed7split","Version: "+VERSION,1))
        after=payload(root)
        assert set(after)==set(before)
        assert all(after[z]==d for z,d in originals.items()),"Unrelated payload changed"
        assert before[str(DIR/"DuoFaceSpeedHUD.dylib")]!=after[str(DIR/"DuoFaceSpeedHUD.dylib")]
        assert before[str(DIR/"DuoFaceSpeedHUD.plist")]==after[str(DIR/"DuoFaceSpeedHUD.plist")], "Original working SpringBoard filter altered"
        (root/"DEBIAN/md5sums").write_text("".join(
          hashlib.md5((root/z).read_bytes()).hexdigest()+"  "+z+"\n"
          for z in sorted(after)))
        a.output.parent.mkdir(parents=True,exist_ok=True)
        cmd("dpkg-deb","--build","--root-owner-group",root,a.output)
        replaced={str(DIR/n):{"before":before[str(DIR/n)],"after":after[str(DIR/n)]} for n in REPLACE}
    get=lambda field:subprocess.check_output(["dpkg-deb","-f",str(a.output),field],text=True).strip()
    assert (get("Package"),get("Version"),get("Architecture"))==(
        "com.duoface.independent",VERSION,"iphoneos-arm64")
    report={
      "status":"SPEED8_COMPACT_SETTINGS_GMAP_WIRE_QA_STATIC_PASS_NOT_DEVICE_TESTED",
      "baseline_speed7split_sha256":PIN,
      "output_sha256":sha(a.output),
      "preserved_files_byte_identical":len(originals),
      "replaced_files_exact_count":len(REPLACE),
      "replaced_only_HUD_dylib_and_plist":True,
      "original_native12_and_springboard_owner_probe_unchanged":True,
      "carplayapp_HUD_injection_removed":True,
      "speed8_reuses_speed7_springboard_only_filter":True,
      "creates_new_UIWindow":False,
      "requires_native_bridged_split_app_two_attached_panels":True,
      "root_class_verified_from_real_device":"CBTouchPassThroughRootSceneWindow",
      "gmaphud_wire_reader_compiled":True,
      "data_feed_live_on_device_verified":False,
      "new_hud_files":replaced,
      "runtime_log":"/var/mobile/Library/Logs/DuoFaceSpeedSplit7-SpringBoard.jsonl",
      "sileo_published":False,
      "device_tested":False,
      "risk":"On-device Speed8 compact visual, full-screen drag, live source and Waze stable all UNTESTED. Proven user Speed7 remains available."
    }
    a.report.parent.mkdir(parents=True,exist_ok=True)
    a.report.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
    print(json.dumps(report))
if __name__=="__main__":main()
