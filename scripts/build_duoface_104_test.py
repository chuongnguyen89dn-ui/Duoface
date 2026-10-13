#!/usr/bin/env python3
"""DuoFace 1.0.4 test packaging. Requires verified original 1.0.4 and v12 DEBs; no Sileo publish."""
import argparse,hashlib,json,plistlib,shutil,subprocess,tempfile
from pathlib import Path
BASE="f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd"
V12="ed50ed8258762510974c763c15e9d59e082dea3474d618e9626141c8df9182e5"
HOOK="var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook"
ASSET="var/jb/Library/Application Support/DuoFace"
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def run(*x):subprocess.run(x,check=True)
def snapshot(p):return {str(x.relative_to(p)):sha(x) for x in p.rglob("*") if x.is_file() and not x.is_symlink()}
def main():
 p=argparse.ArgumentParser()
 for k in ("base","v12","output"):p.add_argument("--"+k,required=True,type=Path)
 a=p.parse_args()
 assert sha(a.base)==BASE and sha(a.v12)==V12,"Input DEB checksum mismatch"
 with tempfile.TemporaryDirectory() as d:
  root=Path(d)/"root";v=Path(d)/"v12"
  run("dpkg-deb","-R",str(a.base),str(root));run("dpkg-deb","-R",str(a.v12),str(v))
  before=snapshot(root)
  for ext in (".dylib",".plist"):
   target=root/(HOOK+ext);target.parent.mkdir(parents=True,exist_ok=True)
   shutil.copy2(v/(HOOK+ext),target)
  filt=root/(HOOK+".plist");cfg=plistlib.loads(filt.read_bytes())
  bundles=cfg.setdefault("Filter",{}).setdefault("Bundles",[])
  if "com.duonavi.duonaviui" not in bundles:bundles.append("com.duonavi.duonaviui")
  filt.write_bytes(plistlib.dumps(cfg))
  shutil.copytree(v/ASSET,root/ASSET,dirs_exist_ok=True)
  ctl=root/"DEBIAN/control"
  rows=[("Name: DuoFace" if s.startswith("Name: ") else "Version: 1.0.4-1~duofacetest" if s.startswith("Version: ") else "Icon: https://chuongnguyen89dn-ui.github.io/carplaydsp/duoface-icon.png" if s.startswith("Icon: ") else s) for s in ctl.read_text().splitlines() if not s.startswith("SileoDepiction:")]
  ctl.write_text("\n".join(rows)+"\n")
  sums=root/"DEBIAN/md5sums"
  if sums.exists():
   sums.write_text("\n".join(hashlib.md5(x.read_bytes()).hexdigest()+"  "+str(x.relative_to(root)) for x in sorted(root.rglob("*")) if x.is_file() and not str(x.relative_to(root)).startswith("DEBIAN/"))+"\n")
  after=snapshot(root);changed=[k for k in before if after.get(k)!=before[k]]
  assert set(before)<=set(after) and set(changed)<={"DEBIAN/control","DEBIAN/md5sums"},changed
  a.output.parent.mkdir(parents=True,exist_ok=True)
  run("dpkg-deb","--build","--root-owner-group",str(root),str(a.output))
  assert subprocess.check_output(["dpkg-deb","-f",str(a.output),"Package"],text=True).strip()=="com.duonavi.app"
  report={"sha256":sha(a.output),"version":"1.0.4-1~duofacetest","original_104_changed":changed,"carplay_runtime":"NOT_TESTED","sileo":"NOT_PUBLISHED"}
  a.output.with_suffix(".json").write_text(json.dumps(report,indent=2)+"\n");print(json.dumps(report,indent=2))
if __name__=="__main__":main()
