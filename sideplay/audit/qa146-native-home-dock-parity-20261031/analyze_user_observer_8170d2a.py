#!/usr/bin/env python3
"""SHA-locked user's actual iOS16.7.16 observer capture; metadata is not execution."""
import argparse,collections,hashlib,json,pathlib
EXPECTED={
 ('DBAppHistory','_bundleIdentifierDidBecomeVisible:previousBundleIdentifier:'):'v32@0:8@16@24',
 ('DBAppDockViewController','setActiveBundleIdentifier:animated:'):'v28@0:8@16B24',
 ('DBAppDockViewController','_refreshAppDock'):'v16@0:8',
 ('DBAppDockViewController','appHistory'):'@16@0:8',
 ('DBStatusBarHomeButton','setDisplayState:'):'v24@0:8Q16',
 ('DBWorkspace','requestStateChange:'):'v24@0:8@16',
 ('DBMutableWorkspaceStateChangeRequest','activateApplication:'):'v24@0:8@16',
 ('DBMutableWorkspaceStateChangeRequest','deactivateApplication:'):'v24@0:8@16',
}
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--log',type=pathlib.Path,required=True)
 ap.add_argument('--output',type=pathlib.Path,required=True);a=ap.parse_args()
 raw=a.log.read_bytes();blob=hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()
 assert blob=='15c05af45d227e42cb2572df339eceaec9dd231e' and len(raw)==435387,(blob,len(raw))
 rows=[]
 for line in raw.decode().splitlines():
  if line.startswith('{'):rows.append(json.loads(line))
 counts=dict(collections.Counter(r.get('event') for r in rows))
 classes=[r for r in rows if r.get('event')=='native_dock_class_abi']
 nodes=[r for r in rows if r.get('event')=='native_dock_scene_node']
 samples=[r for r in rows if r.get('event')=='native_dock_sample_complete']
 assert [r['sample'] for r in samples]==list(range(1,25))
 signatures=[]
 for (cls,sel),encoding in EXPECTED.items():
  observed=[(r,m) for r in classes if r['class']==cls for m in r['declared_methods'] if m['selector']==sel]
  assert len(observed)==24 and all(m['encoding']==encoding for r,m in observed),(cls,sel)
  assert all(r['image']=='/System/Library/PrivateFrameworks/DashBoard.framework/DashBoard' for r,m in observed)
  signatures.append({'class':cls,'selector':sel,'encoding':encoding,'samples':len(observed)})
 dock=[r for r in nodes if r['controller_class']=='DBAppDockViewController']
 assert len(dock)==24 and all(r['parent_class']=='DBRootStatusBarViewController' and r['window_class']=='DBStatusBarWindow' for r in dock)
 unique={}
 for r in nodes:
  k=tuple(r.get(n) for n in ('controller_class','parent_class','window_class','scene_role','window_frame','orientation','window_hidden'))
  unique[k]={n:r.get(n) for n in ('controller_class','parent_class','window_class','scene_role','window_frame','orientation','window_hidden')}
 report={'source_main_commit':'8170d2ac92cf5fad400efa289b4b928b194438f8',
  'source_path':'sideplay/log/DuoNaviObserver-13F1C6F7-9C8D-4DB1-93FE-023925D68C47.txt',
  'blob':blob,'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw),'event_counts':counts,
  'sample_count':len(samples),'capture_start_utc':samples[0]['utc'],'capture_end_utc':samples[-1]['utc'],
  'capture_span_seconds':samples[-1]['utc']-samples[0]['utc'],
  'carplay_pids':sorted({r['pid'] for r in samples}),'declaring_class_count':len({r['class'] for r in classes}),
  'verified_method_metadata':signatures,'dock_public_containment_observed':True,
  'public_window_controller_snapshots':list(unique.values()),
  'manual_mark_count':counts.get('manual_mark',0),
  'limitations':['Class metadata proves ABI availability, not actual method execution or arguments.',
    'Dock controller instance is present in public containment; private appHistory instance value was not read.',
    'Home display-state unsigned enum values were not measured; do not invent values.',
    'orientation=0 is unknown, not a verified wrong landscape direction.',
    'Initial status window x=-45 then x=0 is transient metadata, not proof of the black-gap root cause.',
    'CarPlay controller tree presence does not prove which app pixels were visible on the display.',
    'No app IDs, user action markers, broker RequestIDs, app-side ACK or touch latency in this capture.',
    'Observer does not independently inventory installed active bridges; QA146 identity not established by this TXT alone.'],
  'device_fix_verified':False}
 a.output.write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n')
 print('PINNED_USER_CAPTURE_VERIFIED',blob,'samples',len(samples),'signatures',len(signatures),'dock_nodes',len(dock))
if __name__=='__main__':main()
