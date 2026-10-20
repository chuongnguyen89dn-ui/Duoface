#!/usr/bin/env python3
"""Build ONE staged rootless package from OWN DuoFace module DEBs.
Does not install, import or copy proprietary SidePlay/DuoNavi/CarBridge payload.
It is not a proof of physical CarPlay app admission.
"""
import argparse,hashlib,json,os,pathlib,plistlib,shutil,subprocess,tempfile
ROOT=pathlib.Path(__file__).resolve().parents[2]
OUT=ROOT/"sideplay/jb-embedded-appbridge/packages"
ORDER=[
 ("com.duoface.mytweak.v1a.preflight","sideplay/mytweak-independent-v1a/packages/com.duoface.mytweak.v1a.preflight_0.2.0~v1bc1_iphoneos-arm64.deb"),
 ("com.duoface.carplay.nativebridgeqa","sideplay/mytweak-native-bridgeqa/packages/com.duoface.carplay.nativebridgeqa_0.0.6~dockcrop1_iphoneos-arm64.deb"),
 ("com.duoface.carplay.firstpartyadmission","sideplay/firstparty-carplay-admission/packages/com.duoface.carplay.firstpartyadmission_0.0.5~ready1_iphoneos-arm64.deb"),
 ("com.duoface.carplay.nativescenehost","sideplay/duoface-native-scene-host/packages/com.duoface.carplay.nativescenehost_0.0.1~scenehost1_iphoneos-arm64.deb"),
 ("com.duoface.qa.controlapp","sideplay/duoface-qa-app/packages/com.duoface.qa.controlapp_0.1.7~ready1_iphoneos-arm64.deb"),
]
NAME="com.duoface.jb.embedded"
VERSION="0.0.1~candidate1"
EXCLUDED=("com.sideplay","com.duonavi","com.bvn.carbridge","com.leftyfl1p.carbridge","com.cortex.carplayenable","com.sensetechlab.duodash")
def execute(args):
 return subprocess.run(args,capture_output=True,text=True,check=True).stdout
def build():
 provenance=[]
 with tempfile.TemporaryDirectory() as temporary:
  temp=pathlib.Path(temporary)
  stage=temp/"stage"
  (stage/"DEBIAN").mkdir(parents=True)
  seen={}
  for i,(pkg,relpath) in enumerate(ORDER):
   archive=ROOT/relpath
   if not archive.is_file():raise RuntimeError("Missing own module "+relpath)
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
  controls=[
    "Package: "+NAME,
    "Name: DuoFace JB Embedded AppBridge (Quarantined Candidate)",
    "Version: "+VERSION,
    "Architecture: iphoneos-arm64",
    "Section: Development",
    "Priority: optional",
    "Maintainer: DuoFace Independent",
    "Depends: firmware (>= 16.0), mobilesubstrate",
    "Conflicts: "+", ".join(x[0] for x in ORDER),
    "Replaces: "+", ".join(x[0] for x in ORDER),
    "Description: Quarantined independent JB integrated source-only DuoFace app bridge. Combines existing own SpringBoard scene host, native Dashboard receiver, firstparty admission candidate, native host and iPhone control GUI. Does not require standalone CarBridge. Physical CarPlay icon and dual-app touch not verified; DO NOT PUBLISH or install without conflict/rollback review.",
  ]
  (stage/"DEBIAN/control").write_text("\n".join(controls)+"\n")
  OUT.mkdir(parents=True,exist_ok=True)
  destination=OUT/(NAME+"_"+VERSION+"_iphoneos-arm64.deb")
  execute(["dpkg-deb","--root-owner-group","--build",str(stage),str(destination)])
  data={"kind":"code-packaging-only-not-carplay-validation","output":str(destination.relative_to(ROOT)),
    "sha256":hashlib.sha256(destination.read_bytes()).hexdigest(),
    "source_packages":provenance,"files":len(seen),
    "contains_third_party_carbridge":False,
    "only_original_duoface_code":True,
    "separate_carbridge_dependency":False,
    "requires_replacing_old_qa_packages":True,
    "sileo_published":False,
    "device_carplay_icon_tested":False,
    "real_two_app_scene_tested":False,
    "risks":["SpringBoard injection present in own V1BC module; baseline not validated on this exact phone",
             "old QA packages conflict; do NOT install this staged package in place",
             "Home app roster/CarPlay scene admission still needs actual device proof"]}
  (OUT/"PACKAGING_PROVENANCE.json").write_text(json.dumps(data,indent=2,ensure_ascii=False)+"\n")
  print("DUOFACE_JB_EMBEDDED_CANDIDATE_BUILT",destination,data["sha256"],len(seen))
def main():
 p=argparse.ArgumentParser()
 p.add_argument("--build",action="store_true",required=True)
 p.parse_args()
 build()
if __name__=="__main__":main()
