#!/usr/bin/env python3
"""Read immutable signed candidate, never install or execute its contents."""
import argparse,hashlib,json,plistlib,struct,subprocess,tempfile
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument("deb",type=Path);p.add_argument("sha256");p.add_argument("out",type=Path);a=p.parse_args()
raw=a.deb.read_bytes();assert hashlib.sha256(raw).hexdigest()==a.sha256
out=a.out;out.mkdir(parents=True,exist_ok=True)
control=subprocess.check_output(["dpkg-deb","-f",str(a.deb)],text=True)
assert "Package: com.duoface.jb.embedded\n" in control
assert "Version: 0.0.156~nativebridge4\n" in control
assert "Architecture: iphoneos-arm64\n" in control
(out/"CONTROL.txt").write_text(control)
listing=subprocess.check_output(["dpkg-deb","-c",str(a.deb)],text=True)
(out/"FULL_FILE_LIST.txt").write_text(listing)
assert listing.splitlines()[0].split()[:2]==["drwxr-xr-x","root/root"]
assert all(line.split()[1]=="root/root" for line in listing.splitlines())
def has_codesign(data):
 if data[:4] in (bytes.fromhex("cafebabe"),bytes.fromhex("cafebabf")):
  wide=data[:4]==bytes.fromhex("cafebabf");slices=[]
  for i in range(struct.unpack_from(">I",data,4)[0]):
   at=8+i*(32 if wide else 20);off,n=struct.unpack_from(">QQ" if wide else ">II",data,at+8)
   slices.append(data[off:off+n])
  return bool(slices) and all(has_codesign(x) for x in slices)
 assert data[:4]==bytes.fromhex("cffaedfe"),data[:4].hex()
 pos=32
 for _ in range(struct.unpack_from("<I",data,16)[0]):
  cmd,n=struct.unpack_from("<II",data,pos)
  if cmd==0x1d:
   off,size=struct.unpack_from("<II",data,pos+8)
   return size>12 and off+size<=len(data) and data[off:off+4]==bytes.fromhex("fade0cc0")
  pos+=n
 return False
with tempfile.TemporaryDirectory() as tmp:
 subprocess.run(["dpkg-deb","-x",str(a.deb),tmp],check=True)
 scripts=Path(tmp)/"control";subprocess.run(["dpkg-deb","-e",str(a.deb),str(scripts)],check=True)
 script_hashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in scripts.iterdir() if p.is_file()}
 root=Path(tmp)/"var/jb";libs=root/"Library/MobileSubstrate/DynamicLibraries"
 info=plistlib.loads((root/"Applications/DuoFaceNativeHost.app/Info.plist").read_bytes());assert info["CFBundleVersion"]=="156"
 car=(libs/"DFCarPlayDockOwner.dylib").read_bytes()
 for token in (b"native-dashboard-context-verified",b"native-dashboard-context-refused",b"native-chooser-ready",b"native-scene-workspace-bundle-mismatch",b"_currentDashboard",b"currentDashboard",b"sharedApplicationLibrary",b"applicationInfoForBundleIdentifier:",b"qa147-native-dock-restored"):
  assert token in car,token
 assert (libs/"DFYouTubeOrientationRelay.dylib").is_file() and (libs/"DFGofaMapResize141.dylib").is_file()
 expected=["com.apple.mobilesafari","org.videolan.vlc-ios","com.facebook.Facebook","com.ss.iphone.ugc.Ame","com.openai.chat","com.google.gemini","com.netflix.Netflix","tv.twitch","com.google.ios.youtubemusic","com.google.chrome.ios","com.spotify.client","com.google.Maps","com.waze.iphone","com.zhiliaoapp.musically"]
 assert plistlib.loads((libs/"DF155GeneralAppStateRelay.plist").read_bytes())=={"Filter":{"Bundles":expected}}
 filters={p.name:plistlib.loads(p.read_bytes()) for p in libs.glob("*.plist")}
 binaries=list(libs.glob("*.dylib"))+[root/"Applications/DuoFaceNativeHost.app/DuoFaceNativeHost"]
 signatures={p.name:has_codesign(p.read_bytes()) for p in binaries};assert all(signatures.values()),signatures
 report={"sha256":a.sha256,"bytes":len(raw),"version":"0.0.156~nativebridge4","full_list_extract":True,"root_ownership":True,"actual_context_markers":True,"app_filters":filters,"maintainer_script_sha256":script_hashes,"embedded_signature_superblob_present":signatures,"signature_limit":"Static signature presence only; CI also ldid entitlement extraction. No device install or trust validation.","device_tested":False,"result":"PASS"}
 (out/"READBACK_RESULT.json").write_text(json.dumps(report,indent=2)+"\n")
 print("NATIVEBRIDGE4_FULL_IMMUTABLE_READBACK_PASS",a.sha256,len(raw))
