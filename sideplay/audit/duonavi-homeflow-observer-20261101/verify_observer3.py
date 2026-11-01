#!/usr/bin/env python3
import argparse,hashlib,json,plistlib,subprocess,tempfile,struct
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument("deb",type=Path);p.add_argument("out",type=Path);a=p.parse_args()
sha=hashlib.sha256(a.deb.read_bytes()).hexdigest();assert sha=="1dd94e842bb82e5fefc6c0fe7af862d6b15a9169290ea82bf9ac96e31d7c9e64"
a.out.mkdir(parents=True,exist_ok=True)
meta=subprocess.check_output(["dpkg-deb","-f",str(a.deb)],text=True);(a.out/"CONTROL.txt").write_text(meta)
assert "Version: 0.0.3~homeflow1\n" in meta and "Package: com.duoface.qa.duonaviobserver\n" in meta
assert "Architecture: iphoneos-arm64\n" in meta
assert not any(l.startswith(("Replaces:","Conflicts:","Breaks:")) for l in meta.splitlines())
listing=subprocess.check_output(["dpkg-deb","-c",str(a.deb)],text=True);(a.out/"FULL_FILE_LIST.txt").write_text(listing)
assert listing.splitlines()[0].split()[:2]==["drwxr-xr-x","root/root"]
assert all(l.split()[1]=="root/root" for l in listing.splitlines())
def signed(data):
 assert data[:4]==bytes.fromhex("cffaedfe")
 at=32
 for _ in range(struct.unpack_from("<I",data,16)[0]):
  cmd,size=struct.unpack_from("<II",data,at)
  if cmd==0x1d:
   off,n=struct.unpack_from("<II",data,at+8)
   return n>12 and off+n<=len(data) and data[off:off+4]==bytes.fromhex("fade0cc0")
  at+=size
 return False
with tempfile.TemporaryDirectory() as tmp:
 subprocess.run(["dpkg-deb","-x",str(a.deb),tmp],check=True);root=Path(tmp)/"var/jb"
 libs=root/"Library/MobileSubstrate/DynamicLibraries";app=root/"Applications/DuoNaviObserver.app"
 assert {f.name for f in libs.iterdir()}=={"DuoNaviObserver.dylib","DuoNaviObserver.plist"}
 filters=plistlib.loads((libs/"DuoNaviObserver.plist").read_bytes());assert filters=={"Filter":{"Executables":["SpringBoard","CarPlay","CarPlayApp"],"Bundles":["com.apple.springboard","com.apple.CarPlay","com.apple.CarPlayApp"]}}
 info=plistlib.loads((app/"Info.plist").read_bytes());assert info["CFBundleVersion"]=="3" and info["CFBundleIdentifier"]=="com.duoface.qa.duonaviobserver.app"
 binary=(libs/"DuoNaviObserver.dylib").read_bytes();exporter=(app/"DNObserverExport").read_bytes()
 for marker in [b"home_flow_call",b"home_flow_hook_ready",b"home_flow_hook_refused",b"homeButtonUp:",b"homeDisplayState",b"visible_native_tree",b"mixed_bridge_warning",b"0.0.3~homeflow1",b"CBBridgeManagerDashboard",b"setDisplayState:",b"after-%@ms"]:assert marker in binary,marker
 for marker in [b"RESULT_APP_CHOOSER",b"RESULT_CARPLAY_HOME",b"HOME FLOW export"]:assert marker in exporter,marker
 assert signed(binary) and signed(exporter)
report={"sha256":sha,"bytes":a.deb.stat().st_size,"version":"0.0.3~homeflow1","full_list_extract":True,"root_ownership":True,"scoped_filter":filters,"new_tracer_and_exporter_markers":True,"embedded_signature_presence":True,"signature_limit":"Static superblob presence; CI ldid entitlement extraction also passed. No device hook/capture proof.","device_tested":False,"result":"PASS"}
(a.out/"READBACK_RESULT.json").write_text(json.dumps(report,indent=2)+"\n");print("OBSERVER3_FULL_SIGNED_ARCHIVE_READBACK_PASS",sha,a.deb.stat().st_size)
