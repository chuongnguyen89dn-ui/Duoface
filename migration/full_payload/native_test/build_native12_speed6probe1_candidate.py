#!/usr/bin/env python3
"""Exact Native12 + one CarPlay HUD dylib; no app adapters, TWHub file overlap or Waze hooks."""
from __future__ import annotations
import argparse,hashlib,json,pathlib,shutil,subprocess,tempfile
BASE=pathlib.Path("dist/payload-migration/native12/com.duoface.independent_0.1.0~native12_iphoneos-arm64.deb")
PIN="85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7"
VERSION="0.1.0~native12+speed6zprobe1"
DIR=pathlib.Path("var/jb/Library/MobileSubstrate/DynamicLibraries")
NEW=("DuoFaceSpeedHUD.dylib","DuoFaceSpeedHUD.plist")
BAN=("DuoFaceSpeedSources","WazeGMapHUDSource","GofaGMapHUDSource",
    "VietMapGoogleMapsSource","GMapHUDPlacementRelay","GMapHUDOverspeedScreen","GoogleMapsVietMap")
def hashfile(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def cmd(*args):subprocess.run([str(a) for a in args],check=True)
def entries(root):
    return {f.relative_to(root).as_posix():hashfile(f) for f in root.rglob("*")
      if f.is_file() and not f.is_symlink() and f.relative_to(root).parts[0]!="DEBIAN"}
def main():
    ap=argparse.ArgumentParser()
    for key in ("hud","output","report"):
        ap.add_argument("--"+key,type=pathlib.Path,required=True)
    a=ap.parse_args()
    assert BASE.is_file() and hashfile(BASE)==PIN,"Native12 immutable SHA256 mismatch"
    assert a.hud.is_file() and a.hud.stat().st_size>3000
    assert not a.output.exists() and not a.report.exists()
    with tempfile.TemporaryDirectory(prefix="duoface-speed6probe1-") as tmp:
        dest=pathlib.Path(tmp)/"stage"
        cmd("dpkg-deb","-R",BASE,dest)
        before=entries(dest)
        assert len(before)>30
        assert not any(any(name in path for name in BAN) for path in before)
        assert all(str(DIR/(name+".dylib")) in before for name in
          ("DuoFaceDashboard","DuoFaceFullscreenBridge","DuoFaceVisualHook","DuoFaceLogoGripOnly"))
        assert "var/jb/Applications/DuoFaceUI.app/DuoFaceUI" in before
        destlib=dest/DIR
        dll=destlib/NEW[0]
        plist=destlib/NEW[1]
        assert not dll.exists() and not plist.exists()
        assert dll.stem==plist.stem, "Substrate requires matching dylib and plist stem"
        shutil.copy2(a.hud,dll)
        dll.chmod(0o755)
        shutil.copy2("DuoFaceSpeedHUDSplit6.plist",plist)
        assert plist.name=="DuoFaceSpeedHUD.plist"
        assert b"com.apple.CarPlayApp" in plist.read_bytes()
        assert b"com.apple.CarPlayTemplateUIHost" not in plist.read_bytes()
        assert b"com.apple.springboard" not in plist.read_bytes()
        assert plist.read_text().count("com.apple.CarPlayApp")==1
        cmd("ldid","-S",dll)
        cmd("lipo",dll,"-verify_arch","arm64")
        cmd("plutil","-lint",plist)
        ctrl=dest/"DEBIAN/control"
        text=ctrl.read_text()
        assert "Version: 0.1.0~native12" in text
        ctrl.write_text(text.replace("Version: 0.1.0~native12","Version: "+VERSION,1))
        after=entries(dest)
        assert set(after)-set(before)=={str(DIR/name) for name in NEW}
        assert all(after.get(path)==digest for path,digest in before.items())
        assert not any(any(name in path for name in BAN) for path in after)
        (dest/"DEBIAN/md5sums").write_text("".join(
            hashlib.md5((dest/path).read_bytes()).hexdigest()+"  "+path+"\n"
            for path in sorted(after)))
        a.output.parent.mkdir(parents=True,exist_ok=True)
        cmd("dpkg-deb","--build","--root-owner-group",dest,a.output)
        appended={str(DIR/name):after[str(DIR/name)] for name in NEW}
    get=lambda field:subprocess.check_output(["dpkg-deb","-f",str(a.output),field],text=True).strip()
    assert (get("Package"),get("Version"),get("Architecture"))==(
        "com.duoface.independent",VERSION,"iphoneos-arm64")
    report={"status":"NATIVE12_SPEED6PROBE1_ISOLATION_DEB_STATIC_PASS_NOT_DEVICE_TESTED",
      "input_sha256":PIN,"output_sha256":hashfile(a.output),
      "new_module":appended,"original_file_count":len(before),
      "all_original_payload_bytes_unchanged":True,
      "no_third_party_injection_or_waze_hooks":True,
      "go_fa_original_hud_not_bundled":True,
      "scene_overlay_window_created":False,
      "speed6_live_sileo_unchanged_during_qa":True,
      "host_probe_only_no_gate_relaxation":True,
      "probe_log":"/var/mobile/Library/Logs/DuoFaceSpeed6-CarPlayApp.jsonl",
      "activation":"CarPlayApp only; keeps Speed6 native split-view host predicate untouched, adds read-only actual CBWindow class/gate snapshots with dedupe and 15s heartbeat",
      "fallback_display":"unchanged Speed6 HUD policy: one UIView on verified native split host; no global UIWindow/CarPlay Home scan; only adds diagnostic JSONL",
      "limitations":"No speed source adapters, no source selector UI; host ownership AND HUD visibility require real CarPlay device test",
      "sileo_published":False,"device_tested":False}
    a.report.parent.mkdir(parents=True,exist_ok=True)
    a.report.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n")
    print(json.dumps(report))
if __name__=="__main__":main()
