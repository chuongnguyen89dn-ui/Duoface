#!/usr/bin/env python3
"""Read-only DuoFace v12 / DuoNavi 1.0.4 hook contract audit."""
import argparse,json,pathlib,plistlib,subprocess,tempfile,hashlib
NAMES=['CBSlotPillView','CBDividerView','CBSplitSplashScreenView','_dotsButton','_expandButton','_restoreButton','_moveButtons','_logoImageView']
VOICE=['CBVoiceSessionManager','CBVoiceAudioCapture','CBVoiceAudioPlayer','CBVoiceSTTAppleOnDeviceProvider','CBVoiceSTTCloudStreamingProvider','CBVoiceDirectiveDispatcher','CBVoiceSceneDispatcher','CBAIBubbleView','CBAppLaunchDirectiveHandler']
def inspect(deb,folder):
 subprocess.run(['dpkg-deb','-R',str(deb),str(folder)],check=True,stdout=subprocess.DEVNULL)
 base=folder/'var/jb/Library/MobileSubstrate/DynamicLibraries'
 dash=next(base.glob('*Dashboard.dylib')); data=dash.read_bytes()
 config=plistlib.loads((base/(dash.stem+'.plist')).read_bytes())
 apps=folder/'var/jb/Applications'
 appid=next((plistlib.loads(p.read_bytes()).get('CFBundleIdentifier') for p in apps.glob('*.app/Info.plist')),None)
 hook_file=base/'DuoFaceVisualHook.dylib'
 hook_plist=base/'DuoFaceVisualHook.plist'
 hook_data=hook_file.read_bytes() if hook_file.exists() else b''
 hook_filter=plistlib.loads(hook_plist.read_bytes()).get('Filter',{}).get('Bundles',[]) if hook_plist.exists() else []
 return {'visual_hook_present':bool(hook_data),'visual_hook_filter':hook_filter,'visual_hook_targets_app':appid in hook_filter,'visual_hook_class_strings':{n:n.encode() in hook_data for n in ['CBSlotPillView','CBDividerView','CBSplitSplashScreenView']},'sha256':hashlib.sha256(data).hexdigest(),'dashboard':dash.name,'hook_contract':{n:data.count(n.encode()) for n in NAMES},'voice':{n:data.count(n.encode()) for n in VOICE},'filter_bundles':config.get('Filter',{}).get('Bundles',[]),'app_id':appid}
def main():
 ap=argparse.ArgumentParser()
 for arg in ['v12','upstream','output']:ap.add_argument('--'+arg,required=True,type=pathlib.Path)
 a=ap.parse_args()
 with tempfile.TemporaryDirectory() as t:
  v=inspect(a.v12,pathlib.Path(t)/'v12');u=inspect(a.upstream,pathlib.Path(t)/'up')
 report={'v12':v,'upstream':u,'contract_names_present_in_upstream':all(u['hook_contract'].values()),'voice_missing_from_v12':[n for n in VOICE if not v['voice'][n] and u['voice'][n]],'injection_app_identity_differs':v['app_id']!=u['app_id'],'native_dashboard_install_name_differs':v['dashboard']!=u['dashboard'],'runtime_hook_compatible_verified':False,'safe_to_publish':False,'upstream_app_covered_by_v12_hook_filter':u['app_id'] in v['visual_hook_filter'],'upstream_ui_class_strings_covered_by_v12_hook':all(v['visual_hook_class_strings'].values())}
 a.output.write_text(json.dumps(report,indent=2)+'\n')
 print(json.dumps(report,indent=2))
if __name__=='__main__':main()
