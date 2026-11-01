#!/usr/bin/env python3
"""Bounded, read-only check of pinned original selectors and call sites.
Usage: python3 verify_original_context.py /path/to/DuoNaviDashboard.dylib
Requires capstone==5.0.7. Does not execute/patch vendor code or emit full code.
"""
import argparse,hashlib,json,struct
from pathlib import Path
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_LITTLE_ENDIAN
PIN="44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15"
p=argparse.ArgumentParser();p.add_argument("dylib");a=p.parse_args()
raw=Path(a.dylib).read_bytes();assert hashlib.sha256(raw).hexdigest()==PIN
# Thin or universal arm64; mappings are from selected Mach-O load commands.
if raw[:4] in (bytes.fromhex("cafebabe"),bytes.fromhex("cafebabf")):
 wide=raw[:4]==bytes.fromhex("cafebabf");data=None
 for i in range(struct.unpack_from(">I",raw,4)[0]):
  at=8+i*(32 if wide else 20);cpu,sub=struct.unpack_from(">II",raw,at)
  off,size=struct.unpack_from(">QQ" if wide else ">II",raw,at+8)
  if cpu==0x100000c and sub&0xffffff==0:data=raw[off:off+size];break
 assert data is not None
else:data=raw
assert data[:4]==bytes.fromhex("cffaedfe")
segments=[];at=32
for _ in range(struct.unpack_from("<I",data,16)[0]):
 cmd,n=struct.unpack_from("<II",data,at)
 if cmd==0x19:
  vm,vm_size,off,size=struct.unpack_from("<QQQQ",data,at+24);segments.append((vm,off,size))
 at+=n

def mapped(vm):
 for start,off,size in segments:
  if start<=vm<start+size:return off+vm-start
 raise ValueError(hex(vm))
def cstr(vm):
 off=mapped(vm);return data[off:data.index(b"\0",off)].decode()
def ptr(vm):return struct.unpack_from("<Q",data,mapped(vm))[0]
slots={0x3a9cc0:"_currentDashboard",0x3a9cc8:"dashboard",0x3aa0a8:"showingApp",
 0x3aa0b8:"_foregroundActiveScene",0x3aa0c0:"_activeBundleIdentifierForScene:",
 0x3aa0c8:"workspace",0x3aa050:"sharedApplicationLibrary",0x3a8360:"applicationInfoForBundleIdentifier:",
 0x3aa0d0:"deactivateApplication:",0x3aa0d8:"setCompletionHandler:",0x3a9b58:"requestStateChange:",
 0x3aa100:"setAppDockActiveBundleID:",0x3aa108:"setHomeButtonInApp:"}
for vm,name in slots.items():assert cstr(ptr(vm))==name,(hex(vm),name)
assert cstr(0x335f6e)=="currentDashboard"
cs=Cs(CS_ARCH_ARM64,CS_MODE_LITTLE_ENDIAN)
def instruction(vm):
 return next(cs.disasm(data[mapped(vm):mapped(vm)+4],vm))
# Bounded call addresses previously traced from named Objective-C methods.
calls={0x141580:"dashboard getter",0x2c6070:"showingApp",0x2c61c8:"foreground scene",
 0x2c6204:"scene bundle",0x2c6294:"application lookup",0x2c62d4:"workspace",
 0x2c6358:"deactivateApplication",0x2c6388:"completion",0x2c6398:"requestStateChange",
 0x2c7170:"clear Dock bundle",0x2c718c:"outside-app Home",0x2c7518:"Home display state"}
for vm in calls:
 i=instruction(vm);assert i.mnemonic in ("b","bl") and i.op_str=="#0x313780",(hex(vm),i.op_str)
args={0x2c716c:("mov","x2, #0"),0x2c7180:("mov","w2, #0"),0x2c750c:("eor","w2, w19, #1")}
for vm,expected in args.items():
 i=instruction(vm);assert (i.mnemonic,i.op_str)==expected
print(json.dumps({"original_sha256":PIN,"selectors":{hex(k):v for k,v in slots.items()},
 "fallback":"currentDashboard","bounded_objc_dispatch_sites":{hex(k):v for k,v in calls.items()},
 "terminal_arguments":{"Dock_bundle":"nil","Home_inApp":False,"Home_displayState":"inApp XOR1 =1 when outside app"},
 "limits":"Pinned static call-site evidence; not runtime Apple dispatch or physical navigation proof.","result":"PASS"},indent=2))
