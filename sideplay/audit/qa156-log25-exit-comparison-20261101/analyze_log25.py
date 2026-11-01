#!/usr/bin/env python3
"""Reproduce observed bridge exits; never attribute anonymous Home to a native app."""
import argparse,collections,datetime,hashlib,json,pathlib,re
p=argparse.ArgumentParser();p.add_argument('log');p.add_argument('--expected-blob',required=True)
a=p.parse_args();raw=pathlib.Path(a.log).read_bytes();blob=hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()
assert blob==a.expected_blob,(blob,a.expected_blob)
text=raw.decode();lines=text.splitlines();section='';events=[];pulses=[]
for n,line in enumerate(lines,1):
 if line.startswith('==='):section=line
 if section.startswith('=== DuoFaceStandalone144.log'):
  m=re.search(r'time=([\d.]+) process=(\S+) stage=(\S+)(.*)',line)
  if m:
   rid=re.search(r'(?:req|uuid)=([A-Z0-9-]{36})',m[4]);bid=re.search(r'bid=(\S+)',m[4]);phase=re.search(r'phase=(\S+) count=(\d+)',m[4])
   events.append(dict(time=float(m[1]),line=n,process=m[2],stage=m[3],request=rid[1] if rid else None,bundle=bid[1] if bid else None,phase=phase[1] if phase else None,count=int(phase[2]) if phase else None,detail=m[4].strip()))
 if section.startswith('=== DuoFaceDeepTrace.log (') and 'qa146-native-home-standalone-stop-notified' in line:
  m=re.search(r'utc=([\d.]+)',line)
  if m:pulses.append(dict(time=float(m[1]),line=n))
start=max(e['time'] for e in events if e['stage']=='independent-standalone-receiver-registered')
events=[e for e in events if e['time']>=start];pulses=[e for e in pulses if e['time']>=start]
stops=[e for e in events if e['stage']=='stopped'];groups=collections.defaultdict(list)
for event in events:
 if event['request']:groups[event['request']].append(event)
requests=[];excerpts=[]
for rid,group in groups.items():
 launch=next((e for e in group if e['stage']=='standalone-requested-not-yet-ready'),None)
 if not launch:continue
 stop=next((e for e in group if e['stage']=='stopped'),None)
 pulse=max((e for e in pulses if stop and 0<=stop['time']-e['time']<.5),key=lambda e:e['time'],default=None)
 dock=next((e for e in events if stop and e['stage']=='qa147-native-dock-restored' and abs(e['time']-stop['time'])<.5),None)
 acks=[e for e in group if e['stage']=='qa155-app-side-ack']
 restored=[e for e in acks if e['phase']=='restored']
 requests.append(dict(request=rid,bundle=launch['bundle'],launch=launch,stop=stop,pulse=pulse,dock=dock,ack_count=len(acks),ack_phases=dict(collections.Counter(e['phase'] for e in acks)),restored=restored,home_to_stop_ms=round(1000*(stop['time']-pulse['time']),3) if stop and pulse else None,home_to_dock_ms=round(1000*(dock['time']-pulse['time']),3) if dock and pulse else None))
 for event in [launch,pulse,stop,dock,*[e for e in acks if e['phase'] in ('restored','window-adjusted')]]:
  if event:excerpts.append(event['line'])
unknown=[e for e in pulses if not any(0<=s['time']-e['time']<.5 for s in stops)]
identities={b:sum(b in line for line in lines) for b in ['com.apple.mobilecal','com.apple.mobileipod','com.apple.Music']}
result=dict(input_git_blob=blob,input_sha256=hashlib.sha256(raw).hexdigest(),input_bytes=len(raw),export_header=lines[:6],session_start_utc=datetime.datetime.fromtimestamp(start,datetime.timezone.utc).isoformat(),session_start_ict=datetime.datetime.fromtimestamp(start,datetime.timezone(datetime.timedelta(hours=7))).isoformat(),stage_counts=dict(collections.Counter(e['stage'] for e in events)),requests=requests,home_pulses=len(pulses),unattributed_home_pulses=unknown,native_app_identity_occurrences=identities,limits=['Native Calendar/Music app-specific exit is not captured; anonymous pulses cannot identify them.','ACK proves app-process callback/scene match, not visible icon or touch.','Millisecond correlation is observational; Apple original callback entry/return not logged.','YouTube has its own relay; Wyn is outside the exact14 general receiver scope.'])
print(json.dumps(result,indent=2))
pathlib.Path(__file__).with_name('EXIT_EXCERPTS.txt').write_text('\n'.join(f'Log25 L{n}: {lines[n-1]}' for n in sorted(set(excerpts)))+'\n')
