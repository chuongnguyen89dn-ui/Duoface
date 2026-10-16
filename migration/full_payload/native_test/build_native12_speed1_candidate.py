#!/usr/bin/env python3
"""Native12-based, reproducible speed-bubble test DEB. Does not publish to Sileo."""
import argparse,hashlib,json,pathlib,shutil,subprocess,tempfile
BASE=pathlib.Path("dist/payload-migration/native12/com.duoface.independent_0.1.0~native12_iphoneos-arm64.deb")
HASH="85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7"
VER="0.1.0~native12+speed1"
DIR=pathlib.Path("var/jb/Library/MobileSubstrate/DynamicLibraries")
SRC=("VietMapGoogleMapsSource","WazeGMapHUDSource","GofaGMapHUDSource")
ADD=("DuoFaceSpeedHUD","DuoFaceSpeedSources")
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def run(*args):subprocess.run([str(x) for x in args],check=True)
def snap(root):
    return {f.relative_to(root).as_posix():sha(f) for f in root.rglob("*")
        if f.is_file() and not f.is_symlink() and f.relative_to(root).parts[0]!="DEBIAN"}
def main():
    p=argparse.ArgumentParser()
    for name in ("stage","gmapreport","hud","observer","output","report"):
        p.add_argument("--"+name,type=pathlib.Path,required=True)
    a=p.parse_args()
    assert BASE.is_file() and sha(BASE)==HASH,"Incorrect Native12 base DEB"
    assert a.stage.is_dir() and not a.output.exists() and a.output!=BASE
    info=json.loads(a.gmapreport.read_text())
    assert info["original_native12_extracted"] and len(info["copied"])==8
    assert info["single_duoface_hud_only"]
    with tempfile.TemporaryDirectory(prefix="df-native12-speed1-") as tmp:
        original=pathlib.Path(tmp)/"original"
        run("dpkg-deb","-R",BASE,original)
        before=snap(original); staged=snap(a.stage)
        assert len(before)>30
        assert all(staged.get(k)==v for k,v in before.items()),"Native12 changed in stage"
        assert len(staged)-len(before)==8,"Not three GMap publishers + two licenses"
        assert not any(x in k for k in staged for x in
            ("GMapHUDOverspeedScreen","GMapHUDPlacementRelay","GoogleMapsVietMap"))
        for name in SRC:
            dll=a.stage/DIR/(name+".dylib")
            flt=a.stage/DIR/(name+".plist")
            assert dll.is_file() and flt.is_file()
            run("lipo",dll,"-verify_arch","arm64")
            run("ldid","-S",dll)
        mods={}
        for name,binary in zip(ADD,(a.hud,a.observer)):
            assert binary.is_file() and binary.stat().st_size>3000
            dll=a.stage/DIR/(name+".dylib")
            flt=a.stage/DIR/(name+".plist")
            assert not dll.exists() and not flt.exists()
            shutil.copy2(binary,dll);dll.chmod(0o755)
            shutil.copy2(pathlib.Path(name+".plist"),flt)
            run("ldid","-S",dll)
            run("lipo",dll,"-verify_arch","arm64")
            run("plutil","-lint",flt)
            mods[name]={"dylib_sha256":sha(dll),"filter_sha256":sha(flt)}
        ctrl=a.stage/"DEBIAN/control"
        text=ctrl.read_text()
        assert "Version: 0.1.0~native12" in text
        ctrl.write_text(text.replace("Version: 0.1.0~native12","Version: "+VER,1))
        after=snap(a.stage)
        assert all(after.get(k)==v for k,v in before.items())
        protected=("DuoFaceDashboard","DuoFaceFullscreenBridge",
            "DuoFaceVisualHook","DuoFaceLogoGripOnly")
        for name in protected:
            path=str(DIR/(name+".dylib"))
            assert before[path]==after[path]
        assert "var/jb/Applications/DuoFaceUI.app/DuoFaceUI" in before
        md5=[]
        for path in sorted(after):
            checksum=hashlib.md5((a.stage/path).read_bytes()).hexdigest()
            md5.append(checksum+"  "+path)
        (a.stage/"DEBIAN/md5sums").write_text("\n".join(md5)+"\n")
        a.output.parent.mkdir(parents=True,exist_ok=True)
        run("dpkg-deb","--build","--root-owner-group",a.stage,a.output)
    def meta(key):
        return subprocess.check_output(["dpkg-deb","-f",str(a.output),key],text=True).strip()
    assert (meta("Package"),meta("Version"),meta("Architecture"))==(
        "com.duoface.independent",VER,"iphoneos-arm64")
    report={"status":"NATIVE12_SPEED1_TEST_DEB_BUILT_NOT_DEVICE_TESTED",
        "base_sha256":HASH,"deb_sha256":sha(a.output),
        "version":VER,"modules":mods,"three_gmap_publishers":list(SRC),
        "old_native12_files_unchanged":True,"no_other_renderer":True,
        "sileo_published":False,"device_tested":False}
    a.report.parent.mkdir(parents=True,exist_ok=True)
    a.report.write_text(json.dumps(report,indent=2)+"\n")
    print(json.dumps(report))
if __name__=="__main__":main()
