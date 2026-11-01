#!/usr/bin/env python3
"""Parse NEW observer3 export; no guessed native identities or page labels."""
import argparse,collections,json,hashlib
from pathlib import Path
def analyze(text):
 records=[]
 for n,line in enumerate(text.splitlines(),1):
  if not line.startswith("{"):continue
  try:r=json.loads(line)
  except json.JSONDecodeError:continue
  if r.get("observer_version")!="0.0.3~homeflow1":continue
  r["export_line"]=n;records.append(r)
 calls=collections.defaultdict(list)
 for r in records:
  if r.get("event")=="home_flow_call":calls[(r.get("process"),r.get("pid"),r.get("run"),r.get("call"))].append(r)
 rows=[]
 for key,group in calls.items():
  phases={r.get("phase"):r for r in group};first=group[0]
  rows.append({"process":key[0],"pid":key[1],"run":key[2],"call":key[3],"selector":first.get("selector"),"owner":first.get("declared_owner"),"phases":phases,"incomplete":not("enter" in phases and ("return" in phases or "throw-unwind" in phases))})
 home=[r for r in rows if r["selector"]=="homeButtonUp:"]
 installed=[r for r in records if r.get("event")=="home_flow_hook_ready" and r.get("installed")]
 refused=[r for r in records if r.get("event")=="home_flow_hook_refused"]
 return {"new_version_records":len(records),"calls":rows,"home_calls":home,"installed_hooks":installed,"refused_hooks":refused,"original_manager_calls":sum(str(r["owner"] or "").startswith("CBBridgeManager") for r in rows),"incomplete_calls":sum(r["incomplete"] for r in rows),"limits":["A hook-ready record is not execution; calls require enter/return records.","Before/after controller trees are raw readback, not app chooser/Home pixel classification.","Native and commercial app IDs must come from actual snapshots/arguments.","Cross-process ordering uses timestamps; no invented wire transaction or call parent IDs.","Missing phases may result from rotation/export truncation; not necessarily original failure.","Snapshots affect timing; not a bridge speed benchmark."]}
if __name__=="__main__":
 p=argparse.ArgumentParser();p.add_argument("log",type=Path);p.add_argument("out",type=Path);a=p.parse_args();raw=a.log.read_bytes();report=analyze(raw.decode());report["input_sha256"]=hashlib.sha256(raw).hexdigest();a.out.write_text(json.dumps(report,indent=2)+"\n");print({"version3_records":report["new_version_records"],"Home_calls":len(report["home_calls"]),"original_manager_calls":report["original_manager_calls"],"incomplete":report["incomplete_calls"],"refused":len(report["refused_hooks"])})
