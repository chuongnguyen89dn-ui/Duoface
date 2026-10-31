#!/usr/bin/env python3
"""Pin real user Log23 and isolate current QA147 session, not old export labels."""
import argparse,pathlib,re,hashlib,collections,statistics,json
p=argparse.ArgumentParser();p.add_argument('--log',type=pathlib.Path,required=True);p.add_argument('--out',type=pathlib.Path,required=True);a=p.parse_args()
raw=a.log.read_bytes();blob=hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()
assert len(raw)==6998737 and blob=='18f4a8432d124b1acb96df2b49d7b826a1951b89'
s=raw.decode();native=[]
for line in s.splitlines():
 m=re.search(r'\[DFStandalone144\] time=([0-9.]+) process=(\S+) stage=(\S+) (.*)',line)
 if m:native.append({'time':float(m[1]),'process':m[2],'stage':m[3],'detail':m[4]})
starts=[r for r in native if r['stage']=='qa147-native-dock-result-consumer-installed'];assert len(starts)==1
start=starts[0]['time'];rows=[r for r in native if r['time']>=start]
counts=dict(collections.Counter(r['stage'] for r in rows))
traces=[]
for line in s.splitlines():
 m=re.search(r'utc=([0-9.]+).*?area=scene .*?event=(\S+) bundle=(\S+) (.*)',line)
 if m and float(m[1])>=start:traces.append({'time':float(m[1]),'event':m[2],'bundle':m[3],'detail':m[4]})
requests={}
for r in rows:
 u=re.search(r'(?:uuid|req)=([A-F0-9-]{36})',r['detail'])
 if u:requests.setdefault(u[1],{}).setdefault(r['stage'],r)
reqs=[];pending_lags=[];lifetimes=[]
for key,events in requests.items():
 r=events.get('standalone-requested-not-yet-ready')
 if not r:continue
 bundle=re.search(r'bid=(\S+)',r['detail'])[1]
 out={'request_id':key,'bundle':bundle,'request_time':r['time']}
 stop=events.get('stopped');end=stop['time'] if stop else float('inf')
 if stop:out['stop_after_seconds']=end-r['time'];out['stop_reason']=stop['detail'].split(key,1)[-1].strip();lifetimes.append(end-r['time'])
 if 'pending-scene' in events:out['pending_after_seconds']=events['pending-scene']['time']-r['time'];pending_lags.append(out['pending_after_seconds'])
 ready=[t for t in traces if t['bundle']==bundle and r['time']<=t['time']<end and t['event']=='scene-handle-observed-render-unverified']
 if ready:out['scene_observed_after_seconds']=ready[0]['time']-r['time']
 if 'failed' in events:out['failure']=events['failed']['detail']
 reqs.append(out)
assert counts.get('standalone-requested-not-yet-ready')==26
assert counts.get('scene-hosted-render-and-touch-unverified',0)==0
assert counts.get('qa147-native-dock-active',0)==0
assert sum('bid=(null)' in r['detail'] and r['stage']=='pending-scene' for r in rows)==8
report={'main_upload':'a067fbc931ce9ddf98f918bdfbd3a222eb662bb3','path':'sideplay/log/DuoFaceAudit 23.txt','blob':blob,'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest(),'qa147_consumer_start_utc':start,'stage_counts':counts,'scene_event_counts':dict(collections.Counter(r['event'] for r in traces)),
 'request_to_pending_seconds':{'n':len(pending_lags),'min':min(pending_lags),'median':statistics.median(pending_lags),'max':max(pending_lags)},
 'stops_between_9_5_and_11_5_seconds':sum(9.5<=x<=11.5 for x in lifetimes),'null_identity_pending_count':8,
 'requests':reqs,'geometry_precommit_readbacks':[r for r in traces if r['event']=='scene-frame-readback'],
 'ready_notification_path_failed_to_produce_solo_ack':True,
 'exact_failed_ready_predicate_measured':False,'real_pixel_or_first_touch_latency_measured':False,
 'hardware_behavior_accepted':False,'new_release_justified_from_this_analysis_alone':False,
 'limits':['No branch-specific logging inside sceneReady/PID verification; exact early-return predicate unknown.',
 'Near10s stop is consistent with QA147 pending timeout, but identical native-Home-exit reason is also used by real Home; not all stops attributable.',
 'Request-to-pending measures IPC/window attachment only, not first rendered frame/touch.',
 'scene-frame-readback is before settings commit, not evidence that later app frame stayed unchanged.',
 'Old exporter/deeptrace build0.0.90 text is a constant and does not disprove QA147 CarPlay consumer loading.']}
a.out.write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n')
print('LOG23_PINNED_FAILURE_CONFIRMED requests=26 solo_ready_ack=0 native_dock_active=0 attach_failures=8 null_pending=8')
print('REQUEST_PENDING_MEDIAN_SECONDS',statistics.median(pending_lags))
print('SCENE_READY_OBSERVED',report['scene_event_counts'].get('scene-handle-observed-render-unverified',0))
