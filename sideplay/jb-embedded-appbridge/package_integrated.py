#!/usr/bin/env python3
"""Build ONE staged rootless package from OWN DuoFace module DEBs.
Does not install, import or copy proprietary SidePlay/DuoNavi/CarBridge payload.
It is not a proof of physical CarPlay app admission.
"""
import argparse,hashlib,json,os,pathlib,plistlib,shutil,subprocess,tempfile
ROOT=pathlib.Path(__file__).resolve().parents[2]
OUT=ROOT/"sideplay/jb-embedded-appbridge/packages"
ORDER=[
 ("com.duoface.mytweak.v1a.preflight","sideplay/mytweak-independent-v1a/packages/com.duoface.mytweak.v1a.preflight_0.2.1~divider1_iphoneos-arm64.deb"),
 ("com.duoface.carplay.nativebridgeqa","sideplay/mytweak-native-bridgeqa/packages/com.duoface.carplay.nativebridgeqa_0.0.8~divider1_iphoneos-arm64.deb"),
 ("com.duoface.carplay.firstpartyadmission","sideplay/firstparty-carplay-admission/packages/com.duoface.carplay.firstpartyadmission_0.0.6~sbpair1_iphoneos-arm64.deb"),
 ("com.duoface.carplay.nativescenehost","sideplay/duoface-native-scene-host/packages/com.duoface.carplay.nativescenehost_0.1.115~app-recover1_iphoneos-arm64.deb"),
]
NAME="com.duoface.jb.embedded"
VERSION="0.0.115~app-recover1"
EXCLUDED=("com.sideplay","com.duonavi","com.bvn.carbridge","com.leftyfl1p.carbridge","com.cortex.carplayenable","com.sensetechlab.duodash")
def execute(args):
 return subprocess.run(args,capture_output=True,text=True,check=True).stdout
def build(expected_nativehost_sha256,expected_source_sha):
 actual_source_sha=execute(["git","rev-parse","HEAD"]).strip()
 if actual_source_sha!=expected_source_sha:
  raise RuntimeError("Git checkout differs from requested nativehost source commit: "+actual_source_sha)
 if not expected_nativehost_sha256 or len(expected_nativehost_sha256)!=64 or any(c not in "0123456789abcdef" for c in expected_nativehost_sha256):
  raise RuntimeError("Must pass exactly verified newly signed native host SHA256")
 if not expected_source_sha or len(expected_source_sha)!=40 or any(c not in "0123456789abcdef" for c in expected_source_sha):
  raise RuntimeError("Must pass exact current checkout Git commit SHA; refuse unverifiable old artifact")
 provenance=[]
 with tempfile.TemporaryDirectory() as temporary:
  temp=pathlib.Path(temporary)
  stage=temp/"stage"
  (stage/"DEBIAN").mkdir(parents=True)
  seen={}
  for i,(pkg,relpath) in enumerate(ORDER):
   archive=ROOT/relpath
   if not archive.is_file():raise RuntimeError("Missing own module "+relpath)
   if pkg=="com.duoface.carplay.nativescenehost":
    observed=hashlib.sha256(archive.read_bytes()).hexdigest()
    if observed!=expected_nativehost_sha256:
     raise RuntimeError("Native Host artifact differs from SHA-verified current-source signed build: "+observed)
   package=execute(["dpkg-deb","-f",str(archive),"Package"]).strip()
   if package!=pkg:raise RuntimeError("Wrong package "+package)
   if any(x in package for x in EXCLUDED):raise RuntimeError("Vendor module not allowed")
   home=temp/("part"+str(i))
   home.mkdir()
   execute(["dpkg-deb","-x",str(archive),str(home)])
   paths=[]
   for src in sorted(home.rglob("*")):
    if src.is_dir() and not src.is_symlink():continue
    rel=src.relative_to(home)
    if not str(rel).startswith("var/jb/"):raise RuntimeError("Nonrootless payload "+str(rel))
    if str(rel) in seen:raise RuntimeError("Overlapping file "+str(rel)+ " in "+pkg+" and "+seen[str(rel)])
    seen[str(rel)]=pkg
    dest=stage/rel
    dest.parent.mkdir(parents=True,exist_ok=True)
    if src.is_symlink():os.symlink(os.readlink(src),dest)
    elif src.is_file():shutil.copy2(src,dest)
    else:raise RuntimeError("Unknown payload type "+str(src))
    paths.append(str(rel))
   provenance.append({
    "package":pkg,"input":relpath,
    "version":execute(["dpkg-deb","-f",str(archive),"Version"]).strip(),
    "sha256":hashlib.sha256(archive.read_bytes()).hexdigest(),
    "payload_count":len(paths),
    "paths":paths})
  # .74 restores the .37 host contract; app-process relay is not shipped.
  if any("DFAppViewportRelay" in path for path in seen):
   raise RuntimeError("Unexpected obsolete app viewport relay in recovery package")
  # Require the new receiver and its exact YouTube-only filter in the merged payload.
  relay=stage/"var/jb/Library/MobileSubstrate/DynamicLibraries/DFYouTubeOrientationRelay"
  if not relay.with_suffix(".dylib").is_file():raise RuntimeError("YouTube relay missing")
  with relay.with_suffix(".plist").open("rb") as file:
   if plistlib.load(file)!={"Filter":{"Bundles":["com.google.ios.youtube"]}}:
    raise RuntimeError("YouTube relay filter broadened")
  # A genuine CarPlay process-only, user-armed native Maps UIKit pane
  # experiment, shipped INSIDE the one DuoFace package (never standalone).
  # Default OFF. No SpringBoard injection and no vendor/CPWindow payload.
  native_map=stage/"var/jb/Library/MobileSubstrate/DynamicLibraries/DFNativeMapPaneCoordinator"
  if not native_map.with_suffix(".dylib").is_file():
   raise RuntimeError("Missing first-party native Maps pane coordinator")
  with native_map.with_suffix(".plist").open("rb") as file:
   p=plistlib.load(file)
  if p!={"Filter":{"Executables":["CarPlay","CarPlayApp"]}}:
   raise RuntimeError("Native Maps coordinator must be CarPlay-process-only")
  if not (stage/"var/jb/Applications/DuoFaceNativeHost.app/DuoFaceNativeHost").is_file():
   raise RuntimeError("Missing nativehost iPhone opt-in UI")
  # Merged DEBs lose their source maintainer scripts during dpkg-deb -x.
  # Explicitly supply minimal uicache scripts for the ONE DuoFace app.
  scripts=ROOT/"sideplay/jb-embedded-appbridge/scripts"
  for kind in ("postinst","postrm"):
   src=scripts/kind
   if not src.is_file():raise RuntimeError("Missing registration script "+str(src))
   target=stage/"DEBIAN"/kind
   shutil.copy2(src,target)
   target.chmod(0o755)
  controls=[
    "Package: "+NAME,
    "Name: DuoFace Independent (Integrated CarPlay Beta)",
    "Version: "+VERSION,
    "Architecture: iphoneos-arm64",
    "Section: Applications",
    "Priority: optional",
    "Maintainer: DuoFace Independent",
    "Depends: firmware (>= 16.0), mobilesubstrate",
    # The old first-party QA icon must not be shipped as a second visible
    # app in a final integrated DuoFace. Conflict with the old QA package
    # without blindly deleting its files or user data in maintainer scripts.
    # Prevent a former first-party DuoFace scene/chrome package from drawing
    # the OLD divider below our new transparent grip. Sileo must resolve
    # conflicts explicitly; do not silently delete other packages/files.
    "Conflicts: "+", ".join([x[0] for x in ORDER]+["com.duoface.qa.controlapp",
               "com.duoface.independent","com.duoface.sideplaydisplay",
               "com.duonavi.app","com.duoface.app"]),
    "Replaces: "+", ".join([x[0] for x in ORDER]+["com.duoface.qa.controlapp"]),
    "Description: Independent rootless iOS16 CarPlay DuoFace beta in one DEB with integrated app bridge, scene host and DuoFace UI; no separate CarBridge required. Native12-inspired controls include app picker, split, logo move, swap and zoom. CarPlay hardware behavior and media playback are not yet verified. Replaces conflicting older first-party DuoFace QA modules; review changes before installation.",
  ]
  (stage/"DEBIAN/control").write_text("\n".join(controls)+"\n")
  OUT.mkdir(parents=True,exist_ok=True)
  destination=OUT/(NAME+"_"+VERSION+"_iphoneos-arm64.deb")
  execute(["dpkg-deb","--root-owner-group","--build",str(stage),str(destination)])
  data={"kind":"code-packaging-only-not-carplay-validation","output":str(destination.relative_to(ROOT)),
    "sha256":hashlib.sha256(destination.read_bytes()).hexdigest(),
    "source_packages":provenance,"files":len(seen),
    "nativehost_build_sha256":expected_nativehost_sha256,
    "source_git_commit":expected_source_sha,
    "original_reference_native12_speed8compact_sha256":"2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad",
    "native12_speed8_hud_independent_parity_proven":False,
    "contains_third_party_carbridge":False,
    "only_original_duoface_code":True,
    "separate_carbridge_dependency":False,
    "requires_replacing_old_qa_packages":True,
    "sileo_published":False,
    "device_carplay_icon_tested":False,
    "real_two_app_scene_tested":False,
    "native_content_receiver_compiled":True,
    "native_map_optin_controller_coordinator_compiled":True,
    "native_map_tiles_device_verified":False,
    "native_map_navigation_continuity_verified":False,
    "native_content_receiver_device_verified":False,
    "uicache_registration_scripts_included":True,
    "auto_respring_on_install":False,
    "risks":["SpringBoard injection present in own V1BC module; baseline not validated on this exact phone",
             "old QA packages conflict; do NOT install this staged package in place",
             "Home app roster/CarPlay scene admission still needs actual device proof",
             "System-issued scene CAContext receiver exists but touch and device overlay are unverified"]}
  (OUT/"PACKAGING_PROVENANCE.json").write_text(json.dumps(data,indent=2,ensure_ascii=False)+"\n")
  print("DUOFACE_JB_EMBEDDED_CANDIDATE_BUILT",destination,data["sha256"],len(seen))
def main():
 p=argparse.ArgumentParser()
 p.add_argument("--build",action="store_true",required=True)
 p.add_argument("--expected-nativehost-sha256",required=True,help="SHA256 measured after building new current-source 0.1.49 signed native host")
 p.add_argument("--expected-source-sha",required=True,help="Immutable 40-char SHA of current Git checkout")
 args=p.parse_args()
 build(args.expected_nativehost_sha256,args.expected_source_sha)
if __name__=="__main__":main()
