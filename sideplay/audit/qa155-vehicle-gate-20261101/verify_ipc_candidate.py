#!/usr/bin/env python3
"""Verify the archived private IPC candidate, not CarPlay device behavior."""
import argparse,hashlib,json,pathlib,plistlib,struct,subprocess,tempfile
p=argparse.ArgumentParser();p.add_argument("deb");p.add_argument("--expected-sha256",required=True)
a=p.parse_args();deb=pathlib.Path(a.deb).resolve();raw=deb.read_bytes()
assert hashlib.sha256(raw).hexdigest()==a.expected_sha256
meta=subprocess.check_output(["dpkg-deb","-f",str(deb),"Package","Version","Architecture"],text=True)
assert "com.duoface.jb.embedded" in meta and "0.0.156~nativebridge2" in meta and "iphoneos-arm64" in meta
# Full listing must finish: avoid the historical dpkg-deb | head broken pipe.
subprocess.run(["dpkg-deb","-c",str(deb)],stdout=subprocess.DEVNULL,check=True)
with tempfile.TemporaryDirectory() as temp:
 subprocess.run(["dpkg-deb","-x",str(deb),temp],check=True)
 base=pathlib.Path(temp)/"var/jb/Library/MobileSubstrate/DynamicLibraries"
 source=pathlib.Path(__file__).resolve().parents[2]/"duoface-native-scene-host"
 expected=plistlib.loads((source/"DF155GeneralAppStateRelay.plist").read_bytes())
 assert plistlib.loads((base/"DF155GeneralAppStateRelay.plist").read_bytes())==expected
 result={"sha256":a.expected_sha256,"bytes":len(raw),"metadata":meta.strip(),"filter":expected,"binaries":{}}
 for name in ["DFTouchOwnerProbe.dylib","DF155GeneralAppStateRelay.dylib"]:
  binary=(base/name).read_bytes();assert b"com.duoface.ipc.v156" in binary
  # These shipping binaries are thin arm64 Mach-O, with an embedded signing blob.
  assert binary[:4]==b"\xcf\xfa\xed\xfe"
  ncmds=struct.unpack_from("<I",binary,16)[0];offset=32;signature=False
  for _ in range(ncmds):
   cmd,size=struct.unpack_from("<II",binary,offset);assert size>=8
   if cmd==0x1d:
    start,length=struct.unpack_from("<II",binary,offset+8)
    assert length>0 and start+length<=len(binary)
    assert binary[start:start+4]==b"\xfa\xde\x0c\xc0";signature=True
   offset+=size
  assert signature
  result["binaries"][name]={"darwin_ipc_marker":True,"embedded_signature":True,"sha256":hashlib.sha256(binary).hexdigest()}
 # Dedicated pre-existing YouTube relay still has its own old center path.
 assert b"NSDistributedNotificationCenter" not in (base/"DF155GeneralAppStateRelay.dylib").read_bytes()
 print(json.dumps(result,indent=2))
