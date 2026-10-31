#!/usr/bin/env python3
"""Sparse original app-state route checks; no runtime/full CFG equivalence claim."""
import argparse,hashlib,importlib.util,json,plistlib
from pathlib import Path
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
from macho_bind_metadata import bindings
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--binary',type=Path,required=True)
p.add_argument('--parser',type=Path,required=True)
p.add_argument('--filter',type=Path,required=True)
a=p.parse_args()
raw=a.binary.read_bytes();pin='44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15'
assert hashlib.sha256(raw).hexdigest()==pin
assert hashlib.sha256(a.parser.read_bytes()).hexdigest()=='13e1de1371d02f22b3749878ad5ea1134b630616e82f823c2fef72f25b0eb9ed'
spec=importlib.util.spec_from_file_location('metadata_parser',a.parser)
mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
m=mod.MachO(mod.select_arm64(raw));cs=Cs(CS_ARCH_ARM64,CS_MODE_ARM);checks=[]
def ins(pc,op,args,meaning):
 i=next(cs.disasm(m.data[m.map(pc):m.map(pc)+4],pc))
 assert (i.mnemonic,i.op_str)==(op,args),(hex(pc),i.mnemonic,i.op_str)
 checks.append(dict(kind='instruction',pc=hex(pc),meaning=meaning))
def call(pc,meaning):ins(pc,'bl','#0x313780',meaning)
def cf(addr,value):
 assert m.cstr(m.ptr(addr+16))==value
 checks.append(dict(kind='CFString',address=hex(addr),value=value))
for pc,text in [(0x2cf450,'listener checks persisted state during init'),
 (0x2cf468,'listener opens distributed notification center'),
 (0x2cf4b4,'listener registers app-state notification receiver'),
 (0x2cf4fc,'listener registers didBecomeActive receiver'),
 (0x2cf514,'listener requests current state during init'),
 (0x2cfcf4,'app active checks persisted state again'),
 (0x2cfb98,'app request dictionary contains one bundle key'),
 (0x26bdf8,'SB app request asks whether that bundle is currently bridged'),
 (0x26be14,'SB sends bridge state in response'),
 (0x1fb26c,'SB constructs eight-field app-state payload'),
 (0x1fb358,'SB posts app state with deliverImmediately when supported'),
 (0x1fb39c,'SB supported fallback notification post'),
 (0x2cfdf0,'receiver compares target bundle to process bundle'),
 (0x2ce1c4,'apply enumerates application windows'),
 (0x2ce714,'eligible window applies frame'),
 (0x2ce730,'eligible window applies bounds'),
 (0x2ce76c,'eligible window applies native orientation selector'),
 (0x2ce778,'eligible window requests layout'),
 (0x2cee70,'restore branch restores eligible window frame'),
 (0x2cee8c,'restore branch restores eligible window bounds'),
 (0x2d02bc,'app startup callback obtains CBAppStateListener singleton')]:call(pc,text)
for pc,target,meaning in [(0x313114,0x2d02a4,'app startup function invokes listener startup'),
 (0x2d0168,0x2ca88c,'notification continuation stores bridge-active state'),
 (0x2d018c,0x2ca8c4,'notification continuation stores dimensions'),
 (0x2d0194,0x2ca8a4,'notification continuation stores orientation'),
 (0x2d019c,0x2ca8d8,'notification continuation stores split state'),
 (0x2d01d4,0x2ce094,'active continuation enters window layout'),
 (0x2ce920,0x2ca88c,'restore resets active state'),
 (0x2ce930,0x2ca8c4,'restore resets dimensions'),
 (0x2ce938,0x2ca8a4,'restore resets orientation'),
 (0x2ce940,0x2ca8d8,'restore resets split state')]:ins(pc,'bl','#'+hex(target),meaning)
ins(0x2cfd0c,'b','#0x313780','app active tail-calls request current state again')
ins(0x2d0250,'b','#0x2ce8e0','inactive-after-active continuation enters restoration')
ins(0x2d009c,'adr','x9, #0x2d0148','receiver constructs state-application continuation')
ins(0x2d00d8,'bl','#0x313558','receiver dispatches application continuation')
ins(0x2d01dc,'mov','w1, #0xd180','first retry delay low bits')
ins(0x2d01e0,'movk','w1, #0x8f0, lsl #16','first retry total 150000000ns')
ins(0x2d0204,'mov','w1, #0x6500','second retry delay low bits')
ins(0x2d0208,'movk','w1, #0x1dcd, lsl #16','second retry total 500000000ns')
for literal,target in [(0x372380,0x2d0264),(0x3723a0,0x2d0284),
                       (0x372340,0x2cfae8),(0x372360,0x2cfb08)]:
 assert m.ptr(literal+16)==target
 checks.append(dict(kind='block_invoke',literal=hex(literal),target=hex(target)))
for pc in [0x2d0278,0x2d0298,0x2cfafc,0x2cfb1c]:
 ins(pc,'b','#0x2ce094','delayed callback re-enters layout after active-state check')
assert m.ptr(0x3aad58)==m.classes()['CBAppStateListener']['class_ptr']
assert m.cstr(m.ptr(0x3a82a0))=='sharedInstance'
checks.append(dict(kind='local_class_reference',slot='0x3aad58',class_name='CBAppStateListener'))

for addr,key in [(0x398b80,'bundleIdentifier'),(0x39d160,'shouldBridge'),
 (0x39d180,'bridgeToken'),(0x39d1a0,'fixedKeyboardWidth'),
 (0x39d1c0,'displayWidth'),(0x39d1e0,'displayHeight'),
 (0x39d200,'orientation'),(0x39d220,'isSplit'),
 (0x39d260,'bridgedBundleID'),(0x39d2a0,'activeBridgedBundleIDs'),(0x39d280,'size_%@')]:cf(addr,key)
b=bindings(m)
assert b[0x3aad20]=='_OBJC_CLASS_$_NSDistributedNotificationCenter'
checks.append(dict(kind='dyld_binding',slot='0x3aad20',symbol=b[0x3aad20]))
ins(0x2cf458,'ldr','x0, #0x3aad20','listener and sender resolve same distributed center class')
assert m.ptr(0x371da0+16)==0x26e784 and m.ptr(0x372410+16)==0x2d0448
l=m.data[m.map(0x342ac0):m.map(0x342ac0)+21]
r=m.data[m.map(0x3442ef):m.map(0x3442ef)+21]
assert l==r
checks.append(dict(kind='encoded_notification_literal_equality',bytes=21,sender='0x342ac0',receiver='0x3442ef',sha256=hashlib.sha256(l).hexdigest(),plaintext_decoded=False))
f=plistlib.loads(a.filter.read_bytes())['Filter']['Bundles']
assert 'com.google.Maps' in f and 'org.videolan.vlc-ios' in f and 'com.google.ios.youtube' in f
print(json.dumps(dict(binary_sha256=pin,mode='static_read_only',checks=checks,
 packaged_filter_bundles=f,packaged_filter_sha256=hashlib.sha256(a.filter.read_bytes()).hexdigest(),
 runtime_equivalence_proven=False,opaque_bridge_token_implementation_reproduced=False),indent=2))
