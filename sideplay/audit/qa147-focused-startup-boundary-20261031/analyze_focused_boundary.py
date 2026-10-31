#!/usr/bin/env python3
"""Pin Log23 and isolate startup failures / swapped host geometry / missing ACK.
Observational evidence only: no inference of the unlogged UIKit throw site or PID.
"""
import argparse,collections,hashlib,json,re
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--log',type=Path,required=True);p.add_argument('--repo',type=Path,required=True)
a=p.parse_args();raw=a.log.read_bytes()
assert hashlib.sha256(raw).hexdigest()=='c327274898d8d7285259d4bdbfc04b623a81e3cb6263ccda7ccf948d9cca267d'
text=raw.decode();scene=[];native=[];wanted={}
for line in text.splitlines():
 m=re.search(r'\[DFStandalone144\] time=([0-9.]+) process=(\S+) stage=(\S+) (.*)',line)
 if m:native.append(dict(time=float(m[1]),process=m[2],stage=m[3],detail=m[4]))
 m=re.search(r'utc=([0-9.]+).*?area=scene .*?event=(\S+) bundle=(\S+) (.*)',line)
 if m:scene.append(dict(time=float(m[1]),event=m[2],bundle=m[3],detail=m[4]))
 m=re.search(r'stage=standalone-requested-not-yet-ready .*?uuid=(\S+) content=\{\{[^}]+\}, \{([^}]+)\}\}',line)
 if m:wanted[m[1]]=[float(x) for x in m[2].split(',')]
start=[r['time'] for r in native if r['stage']=='qa147-native-dock-result-consumer-installed'];assert len(start)==1
native=[r for r in native if r['time']>=start[0]];scene=[r for r in scene if r['time']>=start[0]]
requests=[r for r in native if r['stage']=='standalone-requested-not-yet-ready'];assert len(requests)==26
out=[]
for i,r in enumerate(requests):
 rid=re.search(r'uuid=(\S+)',r['detail'])[1];bid=re.search(r'bid=(\S+)',r['detail'])[1]
 stops=[x for x in native if x['stage']=='stopped' and rid in x['detail'] and x['time']>=r['time']]
 assert len(stops)==1
 end=min(stops[0]['time'],requests[i+1]['time'] if i+1<len(requests) else float('inf'))
 events=[x for x in scene if x['bundle']==bid and r['time']<=x['time']<=end]
 created=[x for x in events if x['event']=='host-created'];assert len(created)==1
 # Exclude teardown of an older same-bundle instance before this creation.
 events=[x for x in events if x['time']>=created[0]['time']]
 first=next(x for x in events if x['event']=='resize');size=[float(v) for v in re.search(r'\{([^}]+)\}',first['detail'])[1].split(',')]
 want=wanted[rid]
 same=all(abs(x-y)<.01 for x,y in zip(size,want));swap=all(abs(x-y)<.01 for x,y in zip(size,want[::-1]))
 assert same or swap
 fail=next((x for x in events if x['event']=='scene-failed'),None)
 relevant={'resize','mode-2-requested','scene-handle-observed-render-unverified','geometry-before-reference-setters','original-native12-scene-size-dispatch','native12-scene-settings-live-contract-requested','media-reference-committed-after-stable-viewport','youtube-app-handshake-ack','scene-failed'}
 out.append(dict(request_id=rid,bundle=bid,requested_size=want,first_host_size=size,
 first_host_size_swapped=swap,failure=fail['detail'] if fail else None,
 lifetime_seconds=stops[0]['time']-r['time'],
 timeline=[dict(after_seconds=x['time']-r['time'],event=x['event'],detail=re.sub(r'0x[0-9a-fA-F]+','<pointer>',x['detail'])) for x in events if x['event'] in relevant]))
failed=[x for x in out if x['failure']];assert len(failed)==8
for x in failed:
 names=[e['event'] for e in x['timeline']]
 assert names.index('resize')<names.index('scene-failed')
 assert 'mode-2-requested' not in names and 'geometry-before-reference-setters' not in names
 assert x['failure']=='Scene attach exception: bogus reference size'
swapped=[x for x in out if x['first_host_size_swapped']];assert len(swapped)==2
case=next(x for x in swapped if x['request_id']=='07D0259B-BF77-4072-8105-02E96679C3CF')
assert any(x['event']=='native12-scene-settings-live-contract-requested' and '663, 1190' in x['detail'] for x in case['timeline'])
assert any(x['event']=='youtube-app-handshake-ack' and 'app-reflow-measured' in x['detail'] for x in case['timeline'])
counts=dict(collections.Counter(x['stage'] for x in native));assert counts.get('scene-hosted-render-and-touch-unverified',0)==0 and counts.get('qa147-native-dock-active',0)==0
source=a.repo/'sideplay/duoface-native-scene-host/DFSceneHost.m';src=source.read_bytes()
assert hashlib.sha1(b'blob '+str(len(src)).encode()+b'\0'+src).hexdigest()=='ec2924c145be4edaaa27b7320bb869b18de12c6b'
s=src.decode();begin=s[s.index('- (void)start {'):s.index('- (void)layoutSubviews {')]
assert begin.index('[self addSubview:appView]')<begin.index('[self layoutScene]')<begin.index('DFHostInt(self.appController, @"setRequestedMode:", 2)')
print(json.dumps(dict(log_sha256=hashlib.sha256(raw).hexdigest(),scope='QA147 startup failure, aspect swap and ACK boundary only',
 requests=26,failed_attach_requests=failed,swapped_first_host_geometry=swapped,
 critical_youtube_case=case,native_stage_counts=counts,
 measured_throwing_operation=None,measured_rejected_ready_predicate=None,measured_verified_pid=None,
 conclusions=['All8 attach failures logged resize before failure and no completed mode2 startup checkpoint or geometry setter checkpoint.',
 'Two requests first observed host dimensions transposed relative to requested content size.',
 'CriticalYouTube case committed portrait-shaped target663x1190 and received app-reflow ACK despite landscape595x331 requested region.',
 'No successful standalone-ready outcome or nativeDock activation in this session.'],
 limits=['Scene events carry bundle and UTC, not requestID; association uses non-overlapping request windows and exactly one matching host-created per request.',
 'mode-2-requested event is logged after several calls: absent event does NOT prove setRequestedMode was never called.',
 'Resize can occur reentrantly inside addSubview; ordering does not identify the native exception throw site.',
 'No final pixel or touch verification, actual root-window readback, PID measurement or exact ACK guard result.']),indent=2))
