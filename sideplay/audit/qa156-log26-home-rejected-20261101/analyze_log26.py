#!/usr/bin/env python3
"""Read-only exact Log26 session/correlation. No anonymous native-app guesses."""
import argparse,collections,datetime,hashlib,json,re
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument("log",type=Path);p.add_argument("out",type=Path);a=p.parse_args()
raw=a.log.read_bytes();blob=hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest()
assert blob=="d376f820d6b4dc88f80b1c269e40257e5c5e4009"
lines=raw.decode().splitlines();section="";events=[];pulses=[]
for n,line in enumerate(lines,1):
 if line.startswith("==="):section=line
 if section.startswith("=== DuoFaceStandalone144.log"):
  m=re.search(r"time=([\d.]+) process=(\S+) stage=(\S+)(.*)",line)
  if m:
   rid=re.search(r"(?:req|uuid)=([A-Z0-9-]{36})",m[4]);bid=re.search(r"bid=(\S+)",m[4])
   events.append(dict(time=float(m[1]),line=n,process=m[2],stage=m[3],request=rid[1] if rid else None,bundle=bid[1] if bid else None,detail=m[4].strip()))
 if section.startswith("=== DuoFaceDeepTrace.log (") and "qa146-native-home-standalone-stop-notified" in line:
  m=re.search(r"utc=([\d.]+)",line)
  if m:pulses.append(dict(time=float(m[1]),line=n))
start=max(e["time"] for e in events if e["stage"]=="independent-standalone-receiver-registered")
events=[e for e in events if e["time"]>=start];pulses=[e for e in pulses if e["time"]>=start]
groups=collections.defaultdict(list)
for e in events:
 if e["request"]:groups[e["request"]].append(e)
requests=[];excerpt=set()
for rid,g in groups.items():
 launch=next((e for e in g if e["stage"]=="standalone-requested-not-yet-ready"),None)
 if not launch:continue
 def stage(name):return next((e for e in g if e["stage"]==name),None)
 stop=stage("stopped");pulse=max((e for e in pulses if stop and 0<=stop["time"]-e["time"]<.5),key=lambda e:e["time"],default=None)
 dock=min((e for e in events if stop and e["stage"]=="qa147-native-dock-restored" and abs(e["time"]-stop["time"])<.5),key=lambda e:abs(e["time"]-stop["time"]),default=None)
 ack=[e for e in g if e["stage"]=="qa155-app-side-ack"]
 phases=collections.Counter(re.search(r"phase=(\S+)",e["detail"])[1] for e in ack)
 row=dict(request=rid,bundle=launch["bundle"],context=stage("native-dashboard-context-verified"),workspace=stage("qa151-native-workspace-live-owner"),prepare=stage("qa152-native-prep-resume"),launch=launch,hosted=stage("scene-hosted-render-and-touch-unverified"),dock_active=stage("qa147-native-dock-active"),stop=stop,home_pulse=pulse,dock_restore=dock,ack_phases=dict(phases))
 row["launch_to_hosted_ms"]=round(1000*(row["hosted"]["time"]-launch["time"]),3) if row["hosted"] else None
 row["home_to_stop_ms"]=round(1000*(stop["time"]-pulse["time"]),3) if stop and pulse else None
 row["home_to_dock_ms"]=round(1000*(dock["time"]-pulse["time"]),3) if dock and pulse else None
 for e in row.values():
  if isinstance(e,dict) and "line" in e:excerpt.add(e["line"])
 requests.append(row)
stops=[e for e in events if e["stage"]=="stopped"]
unknown=[e for e in pulses if not any(0<=s["time"]-e["time"]<.5 for s in stops)]
result=dict(input_main_commit="c82247fac5fbe1029a150ec68a4dbef0a17a93f9",input_blob=blob,input_sha256=hashlib.sha256(raw).hexdigest(),bytes=len(raw),header=lines[:6],session_start_ict=datetime.datetime.fromtimestamp(start,datetime.timezone(datetime.timedelta(hours=7))).isoformat(),stage_counts=dict(collections.Counter(e["stage"] for e in events)),requests=requests,home_pulses=len(pulses),unattributed_home_pulses=unknown,native_identity_occurrences={b:sum(b in l for l in lines) for b in ["com.apple.mobilecal","com.apple.mobileipod","com.apple.Music"]},limits=["New production markers prove receiver fix executed; exact installed dpkg version/hash is not exported.","showingApp=NO is measured BEFORE launch only, not while hosted or at Home callback.","Stopped/Dock restore confirms cleanup, not Apple callback entry/return or destination.","No native Calendar/Music identity; anonymous Home cannot be assigned to them.","Home-button before/after displayState and Dashboard navigation state at Home are absent.","Hardcoded build0.0.90 is not downgrade proof."])
a.out.mkdir(parents=True,exist_ok=True);(a.out/"LOG26_RESULT.json").write_text(json.dumps(result,indent=2)+"\n")
(a.out/"LOG26_EXCERPTS.txt").write_text("\n".join(f"Log26 L{n}: {lines[n-1]}" for n in sorted(excerpt))+"\n")
assert len(requests)==5
assert all(r["context"] and r["workspace"] and "workspaceSame=1" in r["workspace"]["detail"] and r["prepare"]["detail"].endswith("native-chooser-ready") and r["hosted"] and r["dock_active"] and r["stop"] and r["dock_restore"] for r in requests)
print(json.dumps({"requests":len(requests),"bundles":dict(collections.Counter(r["bundle"] for r in requests)),"home_pulses":len(pulses),"unattributed":len(unknown),"ACK":sum(sum(r["ack_phases"].values()) for r in requests),"home_to_stop_ms":[r["home_to_stop_ms"] for r in requests],"home_to_dock_ms":[r["home_to_dock_ms"] for r in requests],"launch_to_hosted_ms":[r["launch_to_hosted_ms"] for r in requests],"native_ids":result["native_identity_occurrences"],"result":"LOG26_CONTEXT_FIXED_CLEANUP_CONFIRMED_NAVIGATION_STILL_USER_REJECTED"},indent=2))
