#!/usr/bin/env python3
"""Analyze only the pinned latest export already obtained by the four-log audit."""
import argparse, hashlib, json, re
from pathlib import Path
from collections import Counter
p=argparse.ArgumentParser()
p.add_argument('audit',type=Path)
p.add_argument('--out',type=Path,required=True)
a=p.parse_args()
data=a.audit.read_bytes()
assert hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()=='0db33be9fe28ecfa9dcc1bdc14749aadfda21bc3'
lines=data.decode('utf-8-sig').splitlines()
current=[(n,s) for n,s in enumerate(lines,1) if 'build=0.0.174~mapwake1 ' in s]
first=min(float(re.search(r'utc=(\S+)',s)[1]) for n,s in current)
standalone=[]
for n,s in enumerate(lines,1):
    if not s.startswith('[DFStandalone144]'): continue
    t=re.search(r'time=(\d+(?:\.\d+)?)',s)
    if t and float(t[1])>=first: standalone.append((n,s))
tokens=('qa179-logo-idle-red-border-hidden-visual-only','qa177-recall','qa179-recall','qa120-pane-tap','qa120-hosted-touch-hit','qa178-native-map-picker-request','qa178-native-map-picker-rejected','qa178-native-map-picker-ack','real-app-picker-open')
metrics={'current_records':len(current),'current_marker_counts':{k:sum(k in s for n,s in current) for k in tokens},'whole_new_export_marker_counts':{k:sum(k in s for s in lines) for k in tokens},'host_created':dict(Counter(re.search(r'bundle=(\S+)',s)[1] for n,s in current if 'event=host-created ' in s)),'google_home_clicks':[(n,re.search(r'time=(\S+)',s)[1]) for n,s in standalone if 'qa160-native-grid-icon-pressed bid=com.google.Maps' in s],'google_replacement_stops':sum('stage=stopped bid=com.google.Maps' in s and 'next-home-selection' in s for n,s in standalone),'app_side_unmatched':[(n,s) for n,s in standalone if 'phase=scene-unmatched' in s],'waze_current_stamped_records':sum('com.waze.iphone' in s for n,s in current),'waze_current_standalone_records':sum('com.waze.iphone' in s for n,s in standalone)}
selected=[2,6,12884,12885,15917,15919,15924,15925,15926,15927,15928,15929,15930,17035,17049,17052,17053,17075,17080,17082,17121,17375,17388,17394,17399,19394,36831,36832,36835,36848,36859,36860,36861,36907,36919,37113,37119,39971,39985,40117,40392,40759,40762,40951,40954,41340,41409,41413,41427,41430,41432,41434,41435,41443]
metrics['source_excerpts']=[{'line':n,'text':lines[n-1]} for n in selected]
a.out.write_text(json.dumps(metrics,indent=2,ensure_ascii=False)+'\n')
print(json.dumps({k:v for k,v in metrics.items() if k!='source_excerpts'},indent=2))
