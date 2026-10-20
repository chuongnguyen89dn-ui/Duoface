#!/usr/bin/env python3
"""Read-only audit of original reference DEBs. Never install or redistribute binaries."""
import argparse,hashlib,json,pathlib,plistlib,re,subprocess,tempfile
ROOT=pathlib.Path(__file__).resolve().parents[3]
DEBS={"SidePlay 1.0.4":"com.sideplay_1.0.4-1_iphoneos-arm64.deb",
      "DuoNavi 1.0.4":"dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb"}
MARKERS=("CarBridge","CARCapableApp","SBStarkCapable","entitlementValueForKey",
 "entitlementValuesForKeys","LSBundleInfoCachedValues","FBSApplicationLibrary",
 "CARApplication","_newApplicationLibrary","_proxyPassesInclusionFilter",
 "DBApplicationController","DBWorkspace","requestStateChange",
 "UIApplicationSceneManifest","UIWindowSceneSessionRoleCarPlay",
 "CPTemplateApplicationScene","LSApplicationProxy","SpringBoard",
 "CarPlayApp","MSHookMessageEx","CarBridgeManager","CBBridgeManager",
 "bridgedApps","bridgeDidActivate","activateApplication")
MAGICS=(b"\xcf\xfa\xed\xfe",b"\xce\xfa\xed\xfe",b"\xca\xfe\xba\xbe",b"\xbe\xba\xfe\xca",b"\xca\xfe\xba\xbf",b"\xbf\xba\xfe\xca")
def invoke(argv):
 return subprocess.run(argv,check=True,text=True,capture_output=True).stdout
def audit(label,relative):
 path=ROOT/relative
 if not path.exists():raise FileNotFoundError(relative)
 item=dict(label=label,repo_path=relative,sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
           control=invoke(["dpkg-deb","-f",str(path)]).strip(),filter_plists=[],macho=[],maintenance={})
 with tempfile.TemporaryDirectory() as work:
  root=pathlib.Path(work)
  invoke(["dpkg-deb","-x",str(path),str(root)])
  invoke(["dpkg-deb","-e",str(path),str(root/"DEBIAN")])
  for file in (root/"DEBIAN").glob("*"):
   if file.name in ("postinst","preinst","postrm","prerm"):
    contents=file.read_text(errors="replace")
    item["maintenance"][file.name]={"chars":len(contents),
      "restart_commands":bool(re.search("sbreload|ldrestart|killall.*SpringBoard",contents,re.I))}
  files=[f for f in root.rglob("*") if f.is_file()]
  item["total_files"]=len(files)
  for file in files:
   rel=str(file.relative_to(root))
   if file.suffix==".plist" and ("/DynamicLibraries/" in rel or "/TweakInject/" in rel):
    try:
     p=plistlib.loads(file.read_bytes())
     item["filter_plists"].append({"path":rel,"filter":p.get("Filter",{})})
    except Exception:pass
   if 4<file.stat().st_size<9000000:
    with file.open("rb") as stream:magic=stream.read(4)
    if magic in MAGICS:
     strings=invoke(["strings","-a",str(file)])
     marks=[m for m in MARKERS if m.lower() in strings.lower()]
     item["macho"].append({"path":rel,"bytes":file.stat().st_size,"markers":marks})
 return item
def main():
 parser=argparse.ArgumentParser()
 parser.add_argument("--out",type=pathlib.Path,required=True)
 arg=parser.parse_args()
 data={"method":"static dpkg extraction + magic + strings only; no binary inclusion",
       "entries":[audit(name,path) for name,path in DEBS.items()],
       "source_code_copied":False,"installed_or_executed":False}
 arg.out.parent.mkdir(parents=True,exist_ok=True)
 arg.out.write_text(json.dumps(data,indent=2,ensure_ascii=False)+"\n")
 print("DEB_AUDIT_COMPLETE entries="+str(len(data["entries"])))
if __name__=="__main__":main()
