#!/usr/bin/env python3
"""Full read-back of immutable signed QA147, no pipe truncation or execution."""
import argparse,pathlib,hashlib,json,subprocess,tempfile,plistlib
p=argparse.ArgumentParser();p.add_argument('--deb',type=pathlib.Path,required=True);p.add_argument('--out',type=pathlib.Path,required=True);a=p.parse_args()
sha=hashlib.sha256(a.deb.read_bytes()).hexdigest()
assert sha=='4d330ae909dc6f1e12ead482aef5b0754bf93ea8678e3ed41f97bd6d8ea1b7a6'
a.out.mkdir(parents=True,exist_ok=True)
listing=subprocess.run(['dpkg-deb','-c',str(a.deb)],capture_output=True,text=True,check=True)
(a.out/'FULL_FILE_LIST.txt').write_text(listing.stdout)
assert listing.stdout.splitlines()[0].split()[:2]==['drwxr-xr-x','root/root']
assert all(line.split()[1]=='root/root' for line in listing.stdout.splitlines())
control=subprocess.run(['dpkg-deb','-f',str(a.deb)],capture_output=True,text=True,check=True).stdout
assert 'Version: 0.0.147~native-dock-sync1' in control
(a.out/'CONTROL.txt').write_text(control)
with tempfile.TemporaryDirectory() as t:
 subprocess.run(['dpkg-deb','-x',str(a.deb),t],check=True,capture_output=True)
 root=pathlib.Path(t)/'var/jb';info=plistlib.loads((root/'Applications/DuoFaceNativeHost.app/Info.plist').read_bytes())
 assert info['CFBundleVersion']=='147'
 libs=root/'Library/MobileSubstrate/DynamicLibraries'
 car=(libs/'DFCarPlayDockOwner.dylib').read_bytes();spring=(libs/'DFTouchOwnerProbe.dylib').read_bytes()
 for marker in (b'qa147-native-dock-active',b'qa147-native-dock-result-consumer-installed',b'qa147-native-dock-restored',b'setActiveBundleIdentifier:animated:',b'_bundleIdentifierDidBecomeVisible:previousBundleIdentifier:'):
  assert marker in car,marker
 assert b'VerifiedPID' in spring
 filters={f.name:plistlib.loads(f.read_bytes()) for f in libs.glob('*.plist')}
 assert filters['DFYouTubeOrientationRelay.plist']=={'Filter':{'Bundles':['com.google.ios.youtube']}}
 assert filters['DFGofaMapResize141.plist']=={'Filter':{'Bundles':['com.lumi.GOFA']}}
 assert len(list(libs.glob('*.dylib')))==8
 report={'artifact_commit':'886096a601cb0725ee5aacd2f8a04934b6fded19','sha256':sha,'bytes':a.deb.stat().st_size,'list_returncode':listing.returncode,'full_list_stderr':listing.stderr,'full_extract_success':True,'all_payload_root_ownership_verified':True,'root_0755_verified':True,'version':'0.0.147~native-dock-sync1','compiled_native_dock_markers_verified':True,'scoped_app_filters_preserved':True,'dylib_count':8,'device_tested':False}
 (a.out/'READBACK_RESULT.json').write_text(json.dumps(report,indent=2)+'\n');print('QA147_FULL_IMMUTABLE_PACKAGE_READBACK_PASS',sha)
