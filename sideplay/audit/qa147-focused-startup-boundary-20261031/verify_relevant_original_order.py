#!/usr/bin/env python3
"""Only original startup operations relevant to attach/frame/rotation failures."""
import argparse,hashlib,importlib.util,json,sys
from pathlib import Path
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'original-app-state-route-20261031'))
from macho_bind_metadata import bindings
p=argparse.ArgumentParser();p.add_argument('--binary',type=Path,required=True);p.add_argument('--parser',type=Path,required=True);a=p.parse_args()
b=a.binary.read_bytes();pin='44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15';assert hashlib.sha256(b).hexdigest()==pin
assert hashlib.sha256(a.parser.read_bytes()).hexdigest()=='13e1de1371d02f22b3749878ad5ea1134b630616e82f823c2fef72f25b0eb9ed'
spec=importlib.util.spec_from_file_location('metadata_parser',a.parser);mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod);m=mod.MachO(mod.select_arm64(b));cs=Cs(CS_ARCH_ARM64,CS_MODE_ARM);facts=[]
def ins(pc,op,arg,meaning):
 i=next(cs.disasm(m.data[m.map(pc):m.map(pc)+4],pc));assert (i.mnemonic,i.op_str)==(op,arg),(hex(pc),i.mnemonic,i.op_str)
 facts.append(dict(pc=hex(pc),meaning=meaning))
for pc,meaning in [(0xae228,'set occlusion flag'),(0xae254,'set lifecycle flag'),
 (0xae2d8,'get native host view'),(0xae310,'request mode2 if supported'),
 (0xae408,'set native host view transform'),(0xae414,'read wrapper bounds'),
 (0xae424,'set native host view frame from wrapper bounds'),
 (0xae44c,'add native host view into wrapper'),(0xae464,'add wrapper into bridge surface'),
 (0xae61c,'child reference-size setter2'),(0xae658,'child reference-size setter3'),
 (0xae690,'main reference-size setter'),(0xae9c8,'finish parent containment'),
 (0xb2834,'window.show resizes window hierarchy after hosted start on known manager path')]:ins(pc,'bl','#0x313780',meaning)
ins(0xae30c,'mov','w2, #2','original guarded request uses mode2')
ins(0xae420,'mov','x0, x28','frame setter receiver is the previously fetched host view')
ins(0xae448,'mov','x2, x28','same native host view is then mounted in wrapper')
ins(0xae458,'ldr','x2, [x20, x26]','wrapper is mounted into the surface')
assert m.cstr(m.ptr(0x3a8ec0))=='setRequestedMode:'
assert bindings(m)[0x3aab48]=='_OBJC_CLASS_$_UIViewController'
facts.append(dict(classref='0x3aab48',meaning='Original root controller uses UIViewController, as does current standalone; no missing custom rotation override proven.'))
print(json.dumps(dict(binary_sha256=pin,mode='read_only_static',facts=facts,
 note='Reference-size setters occur AFTER the original mount operations in this path; do not invent a before-mount setter order.',
 runtime_equivalence_proven=False),indent=2))
