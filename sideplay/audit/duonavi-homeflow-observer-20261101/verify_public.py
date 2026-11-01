#!/usr/bin/env python3
import argparse,concurrent.futures,hashlib,json,urllib.request
from pathlib import Path
SITE="https://chuongnguyen89dn-ui.github.io/carplaydsp/"
PINS={"com.duoface.qa.duonaviobserver_0.0.3~homeflow1_iphoneos-arm64.deb":"1dd94e842bb82e5fefc6c0fe7af862d6b15a9169290ea82bf9ac96e31d7c9e64","com.duoface.qa.duonaviobserver_0.0.2~dockabi2_iphoneos-arm64.deb":"f3e3e04b74ef76b09f529954e708ae0521f13d139313405f18b1390b28999f40"}
p=argparse.ArgumentParser();p.add_argument("out",type=Path);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
def get(path):
 with urllib.request.urlopen(SITE+path,timeout=25) as r:return r.read()
raw=get("Packages");rows=[]
for block in raw.decode().split("\n\n"):
 d=dict(l.split(": ",1) for l in block.splitlines() if ": " in l and not l.startswith(" "))
 if d:rows.append(d)
obs=[r for r in rows if r.get("Package")=="com.duoface.qa.duonaviobserver"]
assert len(obs)==1 and obs[0]["Version"]=="0.0.3~homeflow1",obs
assert obs[0]["SHA256"]==PINS["com.duoface.qa.duonaviobserver_0.0.3~homeflow1_iphoneos-arm64.deb"]
assert obs[0]["Filename"]=="debs/com.duoface.qa.duonaviobserver_0.0.3~homeflow1_iphoneos-arm64.deb"
assert obs[0]["Name"]=="DuoNavi Observer (Home Flow)"
df=[r for r in rows if r.get("Package")=="com.duoface.jb.embedded"]
assert len(df)==1 and df[0]["Version"]=="0.0.156~nativebridge4"
assert df[0]["SHA256"]=="bcc54fecaf918afb77dda561a2ec1645a781ff5b56021e208f93482983c77642"
def check(item):
 name,pin=item;data=get("debs/"+name);assert hashlib.sha256(data).hexdigest()==pin
 (a.out/name).write_bytes(data);return name,{"sha256":pin,"bytes":len(data)}
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:downloads=dict(pool.map(check,PINS.items()))
report={"site":SITE,"observer_entry":obs[0],"download_checks":downloads,"previous_observer2_unchanged":True,"duoface4_index_unchanged":True,"device_capture_verified":False,"result":"PASS"}
(a.out/"PUBLIC_READBACK_RESULT.json").write_text(json.dumps(report,indent=2)+"\n");print("OBSERVER3_PUBLIC_SINGLE_INDEX_SIGNED_DOWNLOAD_OLD2_AND_DUOFACE4_PRESERVED_PASS")
