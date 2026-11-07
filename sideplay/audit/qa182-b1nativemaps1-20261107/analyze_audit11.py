"""Reproduce QA182 B1 event/ownership findings from the exact immutable Audit11."""
import argparse,collections,hashlib,json,pathlib,re
p=argparse.ArgumentParser();p.add_argument('log');p.add_argument('--output',required=True);a=p.parse_args()
b=pathlib.Path(a.log).read_bytes()
blob=hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()
assert len(b)==6869806 and blob=='8c884b1ac2b24c7ab3407df50812b9117f8a286b'
lines=b.decode().splitlines();groups=collections.OrderedDict();timed=[];counts=collections.Counter()
for number,line in enumerate(lines,1):
 t=re.search(r'utc=(\d+\.\d+)',line)
 if t:timed.append((number,float(t[1]),line))
 if 'area=qa182-b1 ' not in line:continue
 event=re.search(r'event=(\S+)',line)[1];aid=re.search(r'assignment=(\S+)',line)[1]
 counts[event]+=1;groups.setdefault(aid,[]).append((event,number,float(t[1]),line))
rows=[]
for aid,events in groups.items():
 first={}
 for event,number,t,line in events:first.setdefault(event,(number,t,line))
 created=first['b1-assignment-created'];placed=first['b1-frame-placed'];revoked=first['b1-assignment-revoked']
 scope=[(n,t,l) for n,t,l in timed if created[1]<=t<=revoked[1]]
 wd=[(n,l) for n,t,l in scope if 'event=watchdog-detach' in l]
 seen=first['b1-scene-seen'];block='\n'.join(lines[seen[0]-1:seen[0]+18])
 sid=re.search(r'sceneID = "([^"]+)"',block)
 row={'assignment':aid,'session':re.search(r'session=(\S+)',created[2])[1],
  'created_line':created[0],'catalog_line':first['b1-catalog-reconciled'][0],
  'launch_line':first['b1-launch-issued'][0],'scene_line':seen[0],
  'scene_id':sid[1] if sid else 'unknown','placed_line':placed[0],
  'revoked_line':revoked[0],'restore_line':first['b1-lifecycle-restored'][0],
  'placed_to_revoke_seconds':round(revoked[1]-placed[1],6),
  'revoke_reason':revoked[2].split('reason=')[-1],
  'background_lines':[n for n,t,l in scope if 'qa125-background-boundary' in l],
  'native_owner_inactive_lines':[n for n,t,l in scope if 'native-owner-state' in l and 'active=0' in l],
  'watchdog':[{'line':n,'age':float(re.search(r'age=([\d.]+)',l)[1]),
     'active':re.search(r'active=(\S+)',l)[1],
     'session_match':re.search(r'session-match=(\S+)',l)[1]} for n,l in wd],
  'stock_settings':'unknown'}
 rows.append(row)
out={'main_commit':'ba2ff26cbe6cfe9eafda3d7877b2173c2c1e26c7',
 'path':'sideplay/log/DuoFaceAudit 11.txt','git_blob':blob,'bytes':len(b),
 'line_count':len(lines),'export_vietnam':'2026-11-07T07:47:38+07:00',
 'runtime':'0.0.182~b1nativemaps1','event_counts':dict(counts),'assignments':rows,
 'watchdog_revocations':sum(bool(r['watchdog']) for r in rows),
 'app_replacements':sum(r['revoke_reason']=='app-replaced-in-native-slot' for r in rows),
 'verdict':{'native_scene_observed':8,'sustained_split':'FAIL','global_frame_acceptance':'FAIL',
  'stock_off_on_comparison':'UNVERIFIED','touch':'UNVERIFIED'}}
assert len(rows)==8 and out['watchdog_revocations']==7 and out['app_replacements']==1
pathlib.Path(a.output).write_text(json.dumps(out,indent=2)+'\n')
print(json.dumps({'assignments':len(rows),'native_scenes':8,'watchdog_revocations':7,
 'app_replacements':1,'output':a.output}))
