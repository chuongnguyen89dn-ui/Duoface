"""Extract Home and actual GOFA ACK evidence; does not infer visible icons."""
import argparse,collections,hashlib,json,re
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('log');p.add_argument('--out',required=True);args=p.parse_args()
raw=Path(args.log).read_bytes();s=raw.decode('utf-8')
infos=collections.defaultdict(collections.Counter)
for b,d in re.findall(r'\[DFHome140\].*admitted-info bundle=(\S+) declaration=([^;\s]+)',s):infos[b][d]+=1
samples=[]
rect=r'"\{\{([^}]+)\}, \{([^}]+)\}\}"'
def size(block,key):
 m=re.search(r'\b'+key+r' = '+rect,block)
 return [float(x.strip()) for x in m[2].split(',')] if m else None
for m in re.finditer(r'^\[DuoFaceScene\] event=gofa-owned-app-layout-observed140 .*?\n\}',s,re.M|re.S):
 block=m[0];maps=[]
 for v in re.finditer(r'bounds = '+rect+r';\s+class = "([^"]+)";',block):
  maps.append({'class':v[3],'size':[float(x.strip()) for x in v[2].split(',')]})
 row={'line':s[:m.start()].count('\n')+1,'pid':int(re.search(r'\bpid = (\d+)',block)[1]),'appActivation':int(re.search(r'appActivation = (\d+)',block)[1]),'sceneActivation':int(re.search(r'sceneActivation = (\d+)',block)[1]),'window':size(block,'windowBounds'),'root':size(block,'rootBounds'),'maps':maps}
 row['mismatch']=any(v['size']!=row['window'] for v in maps if v['class'] in ('GOFA.GofaMapView','MapboxMaps.MapView','MapboxMaps.MetalView'))
 samples.append(row)
report={'input_git_blob':'e01382c76292b4d806f0be899f5ff3278580a236','input_sha256':hashlib.sha256(raw).hexdigest(),'input_bytes':len(raw),'input_lines':s.count('\n'),'admitted_info':{b:dict(c) for b,c in infos.items()},'selected_declaration_created':len(re.findall('selected-declaration-created',s)),'selected_original_policy':len(re.findall('selected-original-policy',s)),'gofa_samples':samples,'gofa_mismatches':sum(x['mismatch'] for x in samples),'gofa_active_mismatches':sum(x['mismatch'] and x['appActivation']==0 and x['sceneActivation']==0 for x in samples),'device_icon_success':False,'device_fix_verified':False}
Path(args.out).write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:v for k,v in report.items() if k not in ('admitted_info','gofa_samples')},indent=2))
