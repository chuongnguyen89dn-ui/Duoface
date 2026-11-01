#!/usr/bin/env python3
"""Read actual original Sileo/CDN without installing packages."""
import argparse,hashlib,json,urllib.request,concurrent.futures,subprocess
from pathlib import Path
SITE="https://chuongnguyen89dn-ui.github.io/carplaydsp/"
PKG="com.duoface.jb.embedded"
VERSIONS={"0.0.156~nativebridge4":"bcc54fecaf918afb77dda561a2ec1645a781ff5b56021e208f93482983c77642",
 "0.0.156~nativebridge3":"b3a89cfa4b6afd53ec555c16474023de1ce4e97e4e69e62e640d3d917b0355ef",
 "0.0.156~nativebridge2":"b64d78e9678cd36f05ab9a5a4512559254b044de61d2bd5f5e22e2da8225eb17",
 "0.0.156~nativebridge1":"9af1868794948317f1c9f1ebd15bb33b091c9132d99c815614287656b806e193"}
p=argparse.ArgumentParser();p.add_argument("out",type=Path);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
def get(path):
 with urllib.request.urlopen(SITE+path,timeout=25) as response:return response.read()
packages=get("Packages");(a.out/"Packages.txt").write_bytes(packages)
hits=[]
for block in packages.decode().split("\n\n"):
 d=dict(line.split(": ",1) for line in block.splitlines() if ": " in line and not line.startswith(" "))
 if d.get("Package")==PKG:hits.append(d)
assert len(hits)==1,hits
entry=hits[0];assert entry["Version"]=="0.0.156~nativebridge4",entry
assert entry["SHA256"]==VERSIONS[entry["Version"]]
assert entry["Filename"]=="debs/"+PKG+"_"+entry["Version"]+"_iphoneos-arm64.deb"
assert entry["Architecture"]=="iphoneos-arm64"
def check(item):
 version,pin=item;name=PKG+"_"+version+"_iphoneos-arm64.deb";raw=get("debs/"+name)
 assert hashlib.sha256(raw).hexdigest()==pin,(name,"sha256 mismatch")
 path=a.out/name;path.write_bytes(raw)
 actual=subprocess.check_output(["dpkg-deb","-f",str(path),"Version"],text=True).strip();assert actual==version
 return version,{"sha256":pin,"bytes":len(raw),"metadata_version":actual,"downloaded_url":SITE+"debs/"+name}
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:results=dict(pool.map(check,VERSIONS.items()))
report={"site":SITE,"index":entry,"download_checks":results,"single_live_package":True,"previous_3_2_1_unchanged":True,"device_tested":False,"result":"PASS"}
(a.out/"PUBLIC_READBACK_RESULT.json").write_text(json.dumps(report,indent=2)+"\n")
print("ORIGINAL_SILEO_NATIVEBRIDGE4_INDEX_DOWNLOAD_SHA_AND_3_2_1_ROLLBACK_PASS")
