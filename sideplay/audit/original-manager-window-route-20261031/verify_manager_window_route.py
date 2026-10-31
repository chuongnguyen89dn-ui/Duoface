#!/usr/bin/env python3
"""Pinned read-only branch/ivar/window checkpoints, not full CFG or device proof."""
import argparse,hashlib,importlib.util,json,struct
from pathlib import Path
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--binary',type=Path,required=True);p.add_argument('--parser',type=Path,required=True)
a=p.parse_args();raw=a.binary.read_bytes();pin='44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15'
assert hashlib.sha256(raw).hexdigest()==pin
assert hashlib.sha256(a.parser.read_bytes()).hexdigest()=='13e1de1371d02f22b3749878ad5ea1134b630616e82f823c2fef72f25b0eb9ed'
spec=importlib.util.spec_from_file_location('metadata_parser',a.parser);mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
m=mod.MachO(mod.select_arm64(raw));cs=Cs(CS_ARCH_ARM64,CS_MODE_ARM);checks=[]
def ins(pc,op,args,meaning):
 i=next(cs.disasm(m.data[m.map(pc):m.map(pc)+4],pc))
 assert (i.mnemonic,i.op_str)==(op,args),(hex(pc),i.mnemonic,i.op_str)
 checks.append(dict(kind='instruction',pc=hex(pc),meaning=meaning))
def call(pc,meaning):ins(pc,'bl','#0x313780',meaning)
def sel(slot,name):
 assert m.cstr(m.ptr(slot))==name
 checks.append(dict(kind='selector',slot=hex(slot),selector=name))
def ivars(cls):
 c=m.classes()[cls]['class_ptr'];ro=m.ptr(c+32)&~7;h=m.ptr(ro+48)
 stride=m.p32(h);count=m.p32(h+4);assert 0<stride<=64 and count<100
 return {m.cstr(m.ptr(h+8+n*stride+8)):dict(offset=m.p32(m.ptr(h+8+n*stride)),type=m.cstr(m.ptr(h+8+n*stride+16))) for n in range(count)}
ivs={}
for cls,expected in {'CBBridgeManager':{'_activated':8,'_bundleIdentifier':56,'_window':64,'_currentApp':72,'_appFrame':96,'_renderSize':128,'_autoResumeBundleID':48},'CBWindow':{'_rootWindow':32,'_rootViewController':40,'_contentView':48,'_appFrame':80}}.items():
 found=ivars(cls);ivs[cls]={k:found[k] for k in expected}
 for key,offset in expected.items():assert found[key]['offset']==offset
 checks.append(dict(kind='ivar_metadata',class_name=cls,verified_offsets=expected))
for pc,op,args,meaning in [
 (0x15b5c8,'cbz','w0, #0x15b7a8','inactive request takes teardown branch'),
 (0x15b5f0,'cbz','x22, #0x15b7a8','missing bundle takes teardown branch'),
 (0x15b65c,'cbz','w8, #0x15b854','inactive manager takes direct load branch'),
 (0x15b6a0,'cbz','w23, #0x15b808','different bundle takes replace branch'),
 (0x15b80c,'cbnz','w8, #0x15b844','active replacement deactivates before loading'),
 (0x15b6a8,'cbz','x0, #0x15b814','same bundle missing window reloads'),
 (0x15b6b8,'cbz','w0, #0x15b814','same bundle invalid display reloads'),
 (0x15b6cc,'cbz','w0, #0x15b814','same bundle hidden window reloads'),
 (0x15b6d4,'cbz','x0, #0x15b814','same bundle missing app reloads'),
 (0x15b714,'cbz','x24, #0x15b814','same bundle app view lacks window reloads'),
 (0x15b804,'b','#0x15b868','inactive request returns after deactivation'),
 (0x192880,'strb','w8, [x9, #8]','host continuation stores manager activated flag'),
 (0x192858,'mov','x8, #0x4049000000000000','activation app-frame dimension threshold constant 50.0'),
 (0x192864,'fcmp','d1, d0','activation tests app-frame width against threshold'),
 (0x192870,'fcmp','d12, d0','activation tests app-frame height against threshold'),
 (0x192878,'and','w8, w8, w9','both greater-than comparisons determine activated flag'),
 (0x15b4f0,'stp','d8, d9, [x20, #0x60]','request parser stores app frame origin'),
 (0x15b4f4,'stp','d10, d11, [x20, #0x70]','request parser stores app frame size'),
 (0x15b518,'stp','d0, d1, [x20, #0x80]','request parser stores doubled rounded render size'),
 (0xb3cbc,'tbnz','w0, #0, #0xb3e0c','pointInside accepts usable content area'),
 (0xb3dfc,'mov','w21, #0','pointInside rejects outside window or no eligible subview hit'),
 (0xb3e0c,'mov','w21, #1','pointInside accepts content or eligible subview hit'),
 (0xb3ba8,'cmp','x0, x19','hitTest compares superclass result to root window'),
 (0xb3bac,'b.eq','#0xb3bc8','hitTest discards root-window self hits'),
 (0xb3bc8,'mov','x21, #0','root-window self hit becomes nil'),
 (0xb2888,'mov','w2, #0','show unhides root window'),
 (0x1bf1c4,'cbz','x19, #0x1bf1d4','dismiss checks supplied completion'),
 (0x1bf1d0,'blr','x8','dismiss invokes completion after deactivation')]:ins(pc,op,args,meaning)
for pc,meaning in [
 (0x15b800,'inactive request deactivates current app'),
 (0x15b850,'replacement or stale-host branch deactivates current app'),
 (0x15b864,'load uses actual incoming request as argument'),
 (0x19299c,'host continuation constructs CBWindow with app frame'),
 (0x19293c,'valid existing window receives app frame'),
 (0x192950,'valid existing window resizes'),
 (0x192968,'invalid existing window destroys native windows'),
 (0x192a90,'host continuation constructs app after activation state assignment'),
 (0x192e10,'start hosted app in parent'),(0x192e34,'show window before publishing state'),
 (0x192e44,'publish manager state after start/show'),
 (0xb24ec,'resize obtains full CarPlay screen bounds'),
 (0xb250c,'resize obtains usable CarPlay bounds'),
 (0xb254c,'root window frame uses full screen bounds'),
 (0xb25d8,'root controller view frame uses full screen bounds'),
 (0xb2600,'content view frame uses usable bounds'),
 (0xb1c80,'set root window level from original constant'),
 (0xb28b8,'show makes key and visible where supported'),
 (0xb3cd8,'pointInside examines subviews outside usable content'),
 (0xb3d74,'pass-through checks subview hidden state'),
 (0xb3d84,'pass-through checks subview alpha'),
 (0xb3d98,'pass-through checks subview interaction'),
 (0xb3db4,'pass-through converts point to subview coordinates'),
 (0xb3dc4,'pass-through queries eligible subview pointInside'),
 (0x1bf1c0,'dismiss deactivates before completion')]:call(pc,meaning)
for slot,name in [(0x3a9d48,'isDisplayValid'),(0x3a9d50,'isVisible'),(0x3a9d88,'loadNewAppFromCurrentRequest:'),(0x3a9d90,'initWithAppFrame:'),(0x3a9d98,'setAppFrame:'),(0x3a8f38,'resizeWindows'),(0x3a8fd0,'carPlayScreenBounds'),(0x3a8df0,'carPlayUsableBounds'),(0x3a8d98,'hitTest:withEvent:'),(0x3a90f8,'pointInside:withEvent:'),(0x3a9100,'sendEvent:')]:sel(slot,name)
for addr,value in [(0x332be8,'UIRootSceneWindow'),(0x332bfa,'SBFTouchPassThroughWindow'),(0x332c14,'UIWindow'),(0x332d87,'CBTouchPassThroughRootSceneWindow')]:
 assert m.cstr(addr)==value;checks.append(dict(kind='class_name_literal',address=hex(addr),value=value))
level=struct.unpack_from('<d',m.data,m.map(0x33e860))[0];assert level==10000.0
checks.append(dict(kind='constant',address='0x33e860',name='original_root_window_level',value=level))
print(json.dumps(dict(binary_sha256=pin,mode='read_only_static',checks=checks,ivar_metadata=ivs,
 limits=['Not a full CFG; healthy same-bundle continuation crosses untraced code.',
 'Activation flag source is verified in this continuation; absence of all PID checks elsewhere is not claimed.',
 'Window policy must be considered with full touch/coordinate/ownership contract.',
 'No original runtime execution, new device evidence or behavioral acceptance.'],
 runtime_equivalence_proven=False),indent=2))
