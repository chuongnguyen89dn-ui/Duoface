#!/usr/bin/env python3
"""Read-only SHA-pinned reference-deb versus independent candidate verification.

Only extracts archives; NEVER loads original binaries or copies their Mach-O
into the candidate. Machine-readable output distinguishes static signatures
from runtime equivalence and records the exact immutable inputs.
"""
import argparse, hashlib, json, pathlib, subprocess, tempfile

NATIVE_SHA="2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
REFERENCE_COMMIT="1286a3ef868cf7e29804bcddf7e20b2eae707ce1"
ORIGINAL_MARKERS=("CBBridgeManager","checkAndSyncLicenseIfNeeded",
                  "CBSplitSplashScreenView","CBMultitaskingOverlayView",
                  "CBDividerView","CBBridgedSplitApp","CBWindow")
OWN_MARKERS=("DFNative12Chrome","SBAppViewController","DFSceneHost")
OWN_ASSETS=("duoface-logo.png","duoface-logo-vert.png",
            "duoface-logo-picker-alpha-v2.png","duoface-picker.png",
            "duoface-fullscreen.png","duoface-swap.png")
def run(*args):
    return subprocess.run(args,check=True,capture_output=True,text=True).stdout
def verify_sha(path,expected):
    sha=hashlib.sha256(path.read_bytes()).hexdigest()
    if expected and sha!=expected:
        raise ValueError(f"{path.name}: expected SHA256 {expected}; got {sha}")
    return sha
def extract(path,root):
    run("dpkg-deb","-x",str(path),str(root))
    return {"package":run("dpkg-deb","-f",str(path),"Package").strip(),
            "version":run("dpkg-deb","-f",str(path),"Version").strip(),
            "architecture":run("dpkg-deb","-f",str(path),"Architecture").strip()}
def signature(root):
    found=set()
    binaries=[]
    for f in root.rglob("*"):
        if not f.is_file() or f.stat().st_size>18000000:continue
        if f.suffix==".dylib" or f.name in ("DuoFaceUI","DuoNaviUI","DuoFaceNativeHost",
                                           "duoface_cboptimize_helper"):
            data=f.read_bytes()
            if data[:4] not in (b"\xcf\xfa\xed\xfe",b"\xce\xfa\xed\xfe",
                                 b"\xca\xfe\xba\xbe",b"\xbe\xba\xfe\xca",
                                 b"\xca\xfe\xba\xbf",b"\xbf\xba\xfe\xca"):
                continue
            strings=run("strings","-a",str(f))
            found.update(x for x in ORIGINAL_MARKERS+OWN_MARKERS if x in strings)
            binaries.append(str(f.relative_to(root)))
    return sorted(found),sorted(binaries)
def assess(label,path,sha,extract_dir):
    actual=verify_sha(path,sha)
    record=extract(path,extract_dir)
    markers,binaries=signature(extract_dir)
    record.update({"sha256":actual,"binary_files":binaries,"markers":markers})
    return record
def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--native12",type=pathlib.Path,required=True)
    ap.add_argument("--candidate",type=pathlib.Path,required=True)
    ap.add_argument("--out",type=pathlib.Path,required=True)
    a=ap.parse_args()
    with tempfile.TemporaryDirectory() as directory:
        base=pathlib.Path(directory)
        native=assess("Native12",a.native12,NATIVE_SHA,base/"native")
        candidate=assess("Independent",a.candidate,None,base/"candidate")
        if candidate["package"]!="com.duoface.carplay.nativescenehost":
            raise ValueError("Unexpected output package")
        if candidate["architecture"]!="iphoneos-arm64":
            raise ValueError("Unexpected rootless architecture")
        if not native["binary_files"]:
            raise ValueError("Native12 reference did not unpack Mach-O content")
        if "SBAppViewController" not in candidate["markers"]:
            raise ValueError("Independent host source is not present in candidate Mach-O")
        if any(x in candidate["markers"] for x in ("CBBridgeManager","checkAndSyncLicenseIfNeeded")):
            raise ValueError("Forbidden proprietary bridge/license symbols found in new Mach-O")
        root=base/"candidate"/"var"/"jb"/"Library"/"Application Support"/"DuoFaceNativeHost"/"VisualAssets"
        assets={item:(root/item).is_file() for item in OWN_ASSETS}
        if not all(assets.values()):
            raise ValueError("Independent candidate missing original-approved artwork")
        report={
           "kind":"STATIC_DEB_CONTENT_COMPARISON_NOT_HARDWARE_VERIFICATION",
           "reference_git_commit":REFERENCE_COMMIT,
           "scope":"ONLY_NATIVE12_VS_NEW_DUOFACE_NO_DUONAVI",
           "original_native12":native,
           "independent_candidate":candidate,"candidate_assets":assets,
           "licensed_original_manager_excluded":True,
           "original_binary_copied":False,
           "touch_split_swap_zoom_video_hardware_verified":False,
           "missing_runtime_parity":["Native12 8 split presets/4 slots",
             "per-slot fullscreen dock management","HUD8/settings/voice",
             "video playback Safe Mode repro+crash trace",
             "exact pixel and original splash timing"]
        }
        a.out.parent.mkdir(parents=True,exist_ok=True)
        a.out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
        print("NATIVE12_ONLY_DEB_COMPARISON_STATIC_PASS")
        print("native12="+native["sha256"],"candidate="+candidate["sha256"])
if __name__=="__main__":main()
