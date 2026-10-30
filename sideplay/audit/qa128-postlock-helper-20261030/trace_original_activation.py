#!/usr/bin/env python3
"""Read only SHA-pinned original; parser-dir is existing first-party repo tooling."""
import argparse,bisect,hashlib,json,re,struct,sys
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--binary',required=True);p.add_argument('--parser-dir',required=True);p.add_argument('--out',required=True);a=p.parse_args()
sys.path.insert(0,a.parser_dir)
from audit_native12_license_class_xrefs import MachO,select_arm64
from audit_native12_carplay_add_app_chain import methods,disassemble
raw=Path(a.binary).read_bytes();sha=hashlib.sha256(raw).hexdigest()
if sha!='44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15':raise ValueError('wrong original binary SHA256')
m=MachO(select_arm64(raw));data=m.data
starts=[];pos=32;textbase=next(s[0] for s in m.segments if s[4]=='__TEXT')
for _ in range(m.ncmds):
 cmd,size=struct.unpack_from('<II',data,pos)
 if cmd==0x26:
  off,length=struct.unpack_from('<II',data,pos+8);cur=textbase;acc=shift=0
  for byte in data[off:off+length]:
   acc|=(byte&127)<<shift
   if byte&128:shift+=7;continue
   if acc==0:break
   cur+=acc;starts.append(cur);acc=shift=0
 pos+=size
assert starts==sorted(set(starts))
chosen={'home_hook_registration':0x30f1ac,'DB_homeButtonUp_replacement':0x30f4d4,'CAR_homeButtonUp_replacement':0x30f6c8}
for cl,sels in {'CBBridgeManagerDashboard':['-stopBridging','-stopBridgingWithCompletion:','-requestDismiss','-requestStateChange:','-handleStateDict:','-bridgeDidActivate:','-bridgeDidDeactivate'], 'CBBridgeManager':['-isUIAppBridging','-deactivateCurrentApp','-activated','-setActivated:']}.items():
 mm=methods(m,cl)
 for sel in sels:chosen[cl+sel]=mm[sel]['vm']
results={}
for name,start in chosen.items():
 if start not in starts:raise ValueError('start not in LC_FUNCTION_STARTS '+hex(start))
 end=starts[bisect.bisect_right(starts,start)]
 lines=[];literals=[]
 for line in disassemble(m,start,end):
  match=re.search(r': (ldr|adr) x\d+, #(0x[0-9a-f]+)$',line)
  if match:
   try:
    vm=int(match[2],16);txt=m.cstr(m.ptr(vm) if match[1]=='ldr' else vm)
    if txt and len(txt)<120 and all(32<=ord(c)<127 for c in txt):line+=' ; literal='+repr(txt);literals.append(txt)
   except (ValueError,IndexError,KeyError,AssertionError):pass
  lines.append(line)
 results[name]={'start':hex(start),'end':hex(end),'full_instruction_count':(end-start)//4,'decoded_count':len(lines),'literals':sorted(set(literals)),'instructions':lines}
 if len(lines)!=(end-start)//4:raise ValueError('incomplete function '+name)
selectors={hex(vm):m.cstr(m.ptr(vm)) for vm in [0x3aa8b8,0x3a9f98,0x3aa100,0x3aa108]}
assert selectors['0x3aa8b8']=='homeButtonUp:'
cfstrings={hex(vm):m.cstr(m.ptr(vm+16)) for vm in [0x39d940,0x39d9a0,0x39d400,0x39b7a0,0x39f000,0x39f020]}
assert m.ptr(0x3aad68)==m.classes()['CBBridgeManagerDashboard']['class_ptr']
obj={'home_receiver_class':'CBBridgeManagerDashboard','selector_refs':selectors,'cfstrings':cfstrings,'original_sha256':sha,'function_boundary':'LC_FUNCTION_STARTS','static_only':True,'functions':results}
out=Path(a.out);out.mkdir(parents=True,exist_ok=True)
(out/'ORIGINAL_ACTIVATION_AND_HOME_ARM64.json').write_text(json.dumps(obj,indent=2)+'\n')
for name,row in results.items():print(name,row['start'],row['end'],row['decoded_count'],row['literals'])
