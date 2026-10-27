#!/usr/bin/env python3
"""Read-only DuoFace SpringBoard scene-crash replay. Never saves raw device logs."""
import argparse
import datetime as dt
import hashlib
import json
import re
from pathlib import Path

ALLOWED = ('mode-2-requested', 'scene-attached', 'scene-frame-readback',
           'native12-scene-settings-frame-requested', 'original-native12-scene-size-dispatch',
           'FocusRight', 'close-no-private-settings-restore', 'all-hosts-stopped')

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def ips_read(path):
    raw = path.read_text(errors='replace').splitlines()
    head = json.loads(raw[0])
    body = json.loads('\n'.join(raw[1:]))
    return head, body

def analyze(audit, paths):
    content = audit.read_text(errors='replace')
    marker = '=== DuoFaceDeepTrace.log (last 2 MiB; timestamped diagnostic build) ==='
    if marker not in content:
        raise ValueError('DuoFaceDeepTrace section absent')
    trace = content.split(marker, 1)[1].splitlines()
    records=[]
    rx=re.compile(r'^utc=([\d.]+)\s+.*?\bbuild=([^ ]+)\s+pid=(\d+)\s+process=([^ ]+)')
    for ln in trace:
        m=rx.search(ln)
        if m:
            records.append((float(m.group(1)), m.group(2), int(m.group(3)),m.group(4),ln))
    seen=set()
    print('audit_sha256',sha(audit),'deeptrace_records',len(records))
    for f in paths:
        head,body=ips_read(f)
        incident=head.get('incident_id') or body.get('incident')
        if incident in seen:
            print('duplicate_incident',f.name)
            continue
        seen.add(incident)
        pid=body.get('pid')
        when=dt.datetime.strptime(body['captureTime'], '%Y-%m-%d %H:%M:%S.%f %z')
        epoch=when.timestamp()
        stack=body.get('lastExceptionBacktrace') or []
        symbols=[v.get('symbol','') for v in stack]
        images={v.get('name','') for v in body.get('usedImages',[])}
        omni=sorted(n for n in images if n.startswith('OmniCar'))
        df=sorted(n for n in images if n.startswith('DF'))
        scene_observer=any('sceneHandle:didUpdateSettingsWithDiff:' in x for x in symbols)
        print('incident',f.name,'pid',pid,'capture_local',when.isoformat(),
              'sig',body.get('exception',{}).get('signal'),'scene_observer',scene_observer,
              'omni_loaded',omni,'duoface_loaded',df)
        for ts,build,proc_pid,process,line in records:
            if proc_pid!=pid or process!='SpringBoard' or ts<epoch-50 or ts>epoch:
                continue
            if any(s in line for s in ALLOWED):
                safe=line.split('area=',1)[-1]
                safe=re.sub(r'session=[^ ]+','session=[redacted]',safe)
                print('  T%+.3fs'%(ts-epoch),'build',build,safe[:240])
    print('unique_incidents',len(seen))

if __name__ == '__main__':
    ap=argparse.ArgumentParser()
    ap.add_argument('--audit',type=Path,required=True)
    ap.add_argument('--ips',type=Path,nargs='+',required=True)
    args=ap.parse_args()
    analyze(args.audit,args.ips)
