#!/usr/bin/env python3
"""Build native 1.0.4 DuoFace test package. No entitlement modifications or publishing."""
import argparse,hashlib,json,pathlib,plistlib,shutil,subprocess,tempfile
def run(*a):subprocess.run(a,check=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
def files(p):return {str(f.relative_to(p)):hashlib.sha256(f.read_bytes()).hexdigest() for f in p.rglob('*') if f.is_file() and 'DEBIAN' not in f.relative_to(p).parts}
def main():
 p=argparse.ArgumentParser()
 for key in ['base','v12','output','report']:p.add_argument('--'+key,required=True,type=pathlib.Path)
 a=p.parse_args()
 with tempfile.TemporaryDirectory() as d:
  root=pathlib.Path(d)/'up';old=pathlib.Path(d)/'v12'
  run('dpkg-deb','-R',str(a.base),str(root));run('dpkg-deb','-R',str(a.v12),str(old));orig=files(root)
  hook='var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook'
  for ext in ['.dylib','.plist']:
   src=old/(hook+ext);dst=root/(hook+ext);dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
  # Preserve v12 injection targets and include the upstream app bundle identifier.
  # Without this, the visual hook is not injected into DuoNaviUI.app.
  hook_plist=root/(hook+'.plist')
  hook_config=plistlib.loads(hook_plist.read_bytes())
  upstream_app_info=plistlib.loads((root/'var/jb/Applications/DuoNaviUI.app/Info.plist').read_bytes())
  upstream_bundle=upstream_app_info['CFBundleIdentifier']
  filt=hook_config.setdefault('Filter',{})
  bundles=list(filt.get('Bundles',[]))
  if upstream_bundle not in bundles: bundles.append(upstream_bundle)
  filt['Bundles']=bundles
  hook_plist.write_bytes(plistlib.dumps(hook_config))
  assert upstream_bundle in plistlib.loads(hook_plist.read_bytes())['Filter']['Bundles']
  assets='var/jb/Library/Application Support/DuoFace';shutil.copytree(old/assets,root/assets,dirs_exist_ok=True)
  app=root/'var/jb/Applications/DuoNaviUI.app';oldapp=old/'var/jb/Applications/DuoFaceUI.app'
  for icon in app.glob('AppIcon*.png'):
   src=oldapp/icon.name
   if src.is_file():shutil.copy2(src,icon)
  meta=app/'Info.plist';info=plistlib.loads(meta.read_bytes())
  for key,val in [('CFBundleDisplayName','DuoFace'),('CFBundleName','DuoFace'),('CFBundleShortVersionString','1.0.4'),('CFBundleVersion','1.0.4')]:info[key]=val
  meta.write_bytes(plistlib.dumps(info))
  ctl=root/'DEBIAN/control';out=[]
  for line in ctl.read_text().splitlines():
   if line.startswith('Version:'):line='Version: 1.0.4-5~duofacetest'
   elif line.startswith('Name:'):line='Name: DuoFace'
   elif line.startswith('Icon:'):line='Icon: https://chuongnguyen89dn-ui.github.io/carplaydsp/duoface-icon.png'
   out.append(line)
  ctl.write_text('\n'.join(out)+'\n')
  now=files(root);assert set(orig)<=set(now)
  dashboard='var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.dylib'
  assert now[dashboard]==orig[dashboard] and b'CBVoiceSessionManager' in (root/dashboard).read_bytes()
  assert not (root/'var/jb/Applications/DuoFaceUI.app').exists()
  assert not (root/'var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib').exists()
  sums=root/'DEBIAN/md5sums'
  if sums.exists():sums.write_text('\n'.join(hashlib.md5(f.read_bytes()).hexdigest()+'  '+str(f.relative_to(root)) for f in sorted(root.rglob('*')) if f.is_file() and 'DEBIAN' not in f.relative_to(root).parts)+'\n')
  run('dpkg-deb','--build','--root-owner-group',str(root),str(a.output))
  report={'sha256':hashlib.sha256(a.output.read_bytes()).hexdigest(),'native_104_files':len(orig),'native_104_missing':len(set(orig)-set(now)),'added_files':sorted(set(now)-set(orig)),'visual_hook_targets_upstream_app':upstream_bundle in bundles,'native_branding_complete':False,'runtime_verified':False,'sileo_published':False}
  a.report.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
if __name__=='__main__':main()
