#!/usr/bin/env python3
"""Read-only imported-function and direct-caller tracing on SHA-pinned vendor DEB.

This scans real Mach-O LC_SYMTAB/LC_DYSYMTAB indirect symbol records, ARM64
stubs and branches. No vendor code is reused, no runtime phone claims.
"""
import argparse, hashlib, json, re, struct, subprocess, tempfile
from pathlib import Path
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
from audit_native12_license_class_xrefs import MachO, select_arm64

PIN="d9297b010cdc08e401439b7332413f79cb1a056a05159a5deb673e218d76d9fd"
REL="var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarAppBridge.dylib"
TARGETS=[0x243e0,0x245f0,0x25420,0x2480c,0x24830,0x27b20,0x24788,0x2441c,0x247f4,0x247ac,0x25100,0x25900,0x24548,0x245cc,0x254c0]
OWNERS=[0x9688,0x9674,0x958c,0x9520,0x777c]
CS=Cs(CS_ARCH_ARM64,CS_MODE_ARM)

def string_at(raw,off):
 if off<0 or off>=len(raw):return None
 end=raw.find(b"\0",off)
 if end==-1:return None
 return raw[off:end].decode("utf-8","replace")

def imports(data):
 """Mach-O 64 bit indirect symbols; not sufficient for chained fixups."""
 if struct.unpack_from("<I",data)[0]!=0xfeedfacf:
  raise ValueError("Expected selected little endian Mach-O 64")
 ncmds=struct.unpack_from("<I",data,16)[0]
 p=32; symtab=None; dysym=None; sections=[]; commands=[]
 for _ in range(ncmds):
  cmd,size=struct.unpack_from("<II",data,p)
  if size<8 or p+size>len(data):raise ValueError("bad load command")
  commands.append(hex(cmd))
  if cmd==0x2:
   symtab=struct.unpack_from("<6I",data,p)
  if cmd==0xb:
   dysym=struct.unpack_from("<20I",data,p)
  if cmd==0x19:
   nsects=struct.unpack_from("<I",data,p+64)[0]
   s=p+72
   for _ in range(nsects):
    if s+80>p+size:raise ValueError("bad section size")
    row=struct.unpack_from("<16s16sQQIIIIIIII",data,s)
    sections.append({"name":row[0].split(b"\0")[0].decode("ascii","replace"),
                     "segment":row[1].split(b"\0")[0].decode("ascii","replace"),
                     "vm":row[2],"size":row[3],"fileoff":row[4],
                     "type":row[8]&255,"indirect_start":row[9],
                     "stub_size":row[10]})
    s+=80
  p+=size
 if not symtab or not dysym:return {"status":"missing classic symtab/dysymtab","bindings":{},"commands":commands}
 _,_,symoff,nsyms,stroff,strsize=symtab
 ioff,nindirect=dysym[14],dysym[15]
 if symoff+16*nsyms>len(data) or ioff+4*nindirect>len(data):
  raise ValueError("out of bounds symtab")
 inds=struct.unpack_from("<"+str(nindirect)+"I",data,ioff) if nindirect else []
 bindings={}
 for sec in sections:
  if sec["type"] not in (6,7,8):continue
  width=sec["stub_size"] if sec["type"]==8 else 8
  if not width:continue
  slots=min(sec["size"]//width,100000)
  for n in range(slots):
   i=sec["indirect_start"]+n
   if i>=len(inds):break
   symidx=inds[i]
   if symidx & 0xc0000000 or symidx>=nsyms:continue
   strx=struct.unpack_from("<I",data,symoff+16*symidx)[0]
   name=string_at(data,stroff+strx) if strx<strsize else None
   vm=sec["vm"]+n*width
   bindings[hex(vm)]={"name":name,"section":sec["name"],"kind":"stub" if sec["type"]==8 else "pointer",
                      "index":symidx}
 return {"status":"classic_indirect_symbols_parsed","bindings":bindings,"commands":commands,
         "indirect_symbols_count":nindirect,"sym_count":nsyms}

def text_ins(m):
 items=[]
 for sec in m.sections:
  if sec["name"]=="__text":
   items.extend(CS.disasm(m.data[sec["fileoff"]:sec["fileoff"]+sec["size"]],sec["vm"]))
 return items

def slice_at(m,pc,count=18):
 i=list(CS.disasm(m.data[m.map(pc):m.map(pc)+4*count],pc))
 return [f"{z.address:#x} {z.mnemonic} {z.op_str}" for z in i]

def stub_import(m,table,pc):
 seq=slice_at(m,pc,3)
 res={"pc":hex(pc),"instructions":seq,"binding":table.get(hex(pc)),
      "resolved_via":"classic indirect Mach-O symbol table"}
 # ARM64: adrp x16, #PAGE; ldr x16,[x16,#OFFSET]; br x16
 if len(seq)>=2:
  a=re.search(r"adrp x16, #(0x[0-9a-f]+)",seq[0])
  b=re.search(r"ldr x16, \[x16, #(0x[0-9a-f]+)\]",seq[1])
  if a and b:
   slot=int(a.group(1),16)+int(b.group(1),16)
   res.update(pointer_slot=hex(slot),pointer_binding=table.get(hex(slot)))
 return res

def chained_imports(m):
 """Inspect dyld chained import names; map no pointer unless format known."""
 d=m.data; p=32;ncmds=struct.unpack_from("<I",d,16)[0]
 for _ in range(ncmds):
  cmd,size=struct.unpack_from("<II",d,p)
  if cmd==0x80000034:
   doff,dsize=struct.unpack_from("<II",d,p+8)
   base=doff
   if doff+dsize>len(d):raise ValueError("invalid chained fixups load")
   ver,starts,imps,symbols,count,fmt,symfmt=struct.unpack_from("<7I",d,base)
   out=[]
   for n in range(min(count,200000)):
    row=base+imps+n*({1:4,2:8,3:16}.get(fmt,0))
    if fmt in (1,2):
     word=struct.unpack_from("<I",d,row)[0]
     nameoff=word>>9
    elif fmt==3:
     word=struct.unpack_from("<Q",d,row)[0]
     nameoff=word>>32
    else:return {"status":"unsupported_import_format","fmt":fmt,"count":count}
    name=string_at(d,base+symbols+nameoff)
    out.append(name)
   return {"status":"read_only_chained_import_names","fmt":fmt,"count":count,"names":out}
  p+=size
 return {"status":"no_dyld_chained_fixups","names":[]}

def raw_classref(m,vm,imps):
 result={"classref_vm":hex(vm)}
 try:
  raw=struct.unpack_from("<Q",m.data,m.map(vm))[0]
  result["raw_pointer_word"]=hex(raw)
  result["auth_bit63"]=bool(raw&(1<<63))
  result["bind_bit62"]=bool(raw&(1<<62))
  result["bind_bit63"]=bool(raw&(1<<63))
  # Arm64e chained pointers commonly encode import ordinals in low 16/24
  # bits. Emit explicit candidates only, never label class without verifying
  # the dyld pointer-format for the containing segment.
  names=imps.get("names",[])
  opts={}
  for bits in (16,24):
   idx=raw&((1<<bits)-1)
   if idx<len(names):opts[str(bits)]={"ordinal":idx,"import":names[idx]}
  result["ordinal_candidates_UNCONFIRMED"]=opts
  # Locally defined class: ref may be image-relative rebased pointer.
  # Walk only validated Mach-O file offsets, class->dataBits->class_ro_t->name.
  for vmclass in dict.fromkeys((raw,raw&0xffffffff)):
   try:
    coff=m.map(vmclass)
    dataword=struct.unpack_from("<Q",m.data,coff+32)[0]
    for ro in dict.fromkeys((dataword&~7,(dataword&0xffffffff)&~7)):
     try:
      roff=m.map(ro)
      nameword=struct.unpack_from("<Q",m.data,roff+24)[0]
      for namevm in dict.fromkeys((nameword,nameword&0xffffffff)):
       try:
        name=string_at(m.data,m.map(namevm))
        if name and 1<len(name)<130 and re.fullmatch(r"[A-Za-z_$][A-Za-z0-9_.$-]*",name):
         result["local_class_name_candidate"]=name
         result["local_class_vm_candidate"]=hex(vmclass)
         result["class_ro_vm_candidate"]=hex(ro)
         result["name_vm_candidate"]=hex(namevm)
         result["identity_basis"]="validated local class64 dataBits/class_ro_t/name pointers, static only"
         break
       except (ValueError,IndexError,AssertionError,KeyError,struct.error):pass
      if result.get("local_class_name_candidate"):break
     except (ValueError,IndexError,AssertionError,KeyError,struct.error):pass
    if result.get("local_class_name_candidate"):break
   except (ValueError,IndexError,AssertionError,KeyError,struct.error):pass
  result["class_identity_proven"]=bool(result.get("local_class_name_candidate"))
 except (ValueError,IndexError,AssertionError,KeyError,struct.error) as ex:
  result["error"]=str(ex)[:180]
 return result

def resolve_objc_selref(m,vm):
 """Inspect original selector-reference word; do not fabricate rebasing."""
 result={"selref_vm":hex(vm)}
 try:
  fileoff=m.map(vm)
  word=struct.unpack_from("<Q",m.data,fileoff)[0]
  result["raw_pointer_word"]=hex(word)
  # Direct classic pointer and nonauthenticated 32-bit offset form. Do not
  # assume that a chained/authenticated pointer has been rebased.
  for candidate in dict.fromkeys((word,word & 0xffffffff)):
   try:
    pos=m.map(candidate)
    value=string_at(m.data,pos)
    if value and 0<len(value)<180 and all(31<ord(c)<127 for c in value):
     result["candidate_selector_text"]=value
     result["candidate_pointer_vm"]=hex(candidate)
     result["confidence"]="raw VM resolves to NUL-terminated printable string; not runtime message recipient proof"
     break
   except (ValueError,IndexError,AssertionError,KeyError,struct.error):
    pass
  else:result["confidence"]="unresolved raw/chained fixup; do not name selector"
 except (ValueError,IndexError,AssertionError,KeyError,struct.error) as ex:
  result["error"]=str(ex)[:180]
 return result

def branch_xrefs(inst,dests):
 refs={hex(t):[] for t in dests}
 for i,z in enumerate(inst):
  if z.mnemonic not in ("bl","b","b.eq","b.ne","cbz","cbnz","tbz","tbnz"):continue
  nums=re.findall(r"0x[0-9a-f]+",z.op_str)
  if not nums:continue
  target=int(nums[-1],16)
  if target in dests:
   refs[hex(target)].append({"pc":hex(z.address),"mnemonic":z.mnemonic,
        "near":[f"{y.address:#x} {y.mnemonic} {y.op_str}" for y in inst[max(0,i-5):i+2]]})
 return {k:v[:60] for k,v in refs.items()}

def main():
 ap=argparse.ArgumentParser()
 ap.add_argument("--deb",type=Path,required=True)
 ap.add_argument("--out",type=Path,required=True)
 args=ap.parse_args()
 data=args.deb.read_bytes()
 digest=hashlib.sha256(data).hexdigest()
 if digest!=PIN:raise RuntimeError("FAIL CLOSED OmniCar SHA256: "+digest)
 with tempfile.TemporaryDirectory() as temp:
  subprocess.run(["dpkg-deb","-x",str(args.deb),temp],check=True)
  full=(Path(temp)/REL).read_bytes()
  m=MachO(select_arm64(full))
  imp=imports(m.data)
  chain=chained_imports(m)
  bindings=imp["bindings"]
  instructions=text_ins(m)
  result={
   "evidence":"Original 1.0.3 ARM64 Mach-O classic indirect symtab and static branches",
   "original_deb_sha256":digest,
   "original_dylib_sha256":hashlib.sha256(full).hexdigest(),
   "instrumented_on_iphone":False,
   "runtime_blank_policy_proven":False,
   "classic_import_status":imp["status"],
   "dyld_chained_import_status":{k:v for k,v in chain.items() if k!="names"},
   "class_reference_behind_shared_count":raw_classref(m,0x3e2e0,chain),
   "original_unblank_neighbor_class_literal":{
      "objc_getClass_cstring_0x29667":string_at(m.data,m.map(0x29667)),
      "bks_dlsym_cstring_0x293ee":string_at(m.data,m.map(0x293ee))},
   "load_commands":imp["commands"],
   "stub_imports":{hex(pc):stub_import(m,bindings,pc) for pc in TARGETS},
   "direct_code_xrefs":branch_xrefs(instructions,set(OWNERS+[0x25420])),
   "objc_dispatch_candidates":{
      "0x25420_selector_ref":resolve_objc_selref(m,0x3d548),
      "0x27b20_selector_ref":resolve_objc_selref(m,0x3df08),
      "0x25100_selector_ref":resolve_objc_selref(m,0x3d480),
      "0x25900_selector_ref":resolve_objc_selref(m,0x3d680),
      "0x25420_full_stub":slice_at(m,0x25420,6)},
   "conditional_context":{
     "blank_one_handler_0x777c":slice_at(m,0x778c,39),
     "original_unblank_entry_0x9688":slice_at(m,0x9688,4),
     "preceding_candidate_function_0x958c":slice_at(m,0x958c,36),
     "before_0x9520":slice_at(m,0x9500,32)},
   "limits":"Indirect symbol names are static imports, not executed calls. LC_DYLD_CHAINED_FIXUPS or GOT without classic indirect indices may leave names unknown. Direct branch xrefs omit objc_msgSend/blocks/indirect callbacks. Function ownership, timing, UI display luminosity, and user Play remain unproven."
  }
  args.out.parent.mkdir(parents=True,exist_ok=True)
  args.out.write_text(json.dumps(result,indent=2,ensure_ascii=False)+"\n")
  for k in ("0x243e0","0x25420","0x245f0"):
   v=result["stub_imports"][k]
   print("OMNICAR_STUB",k,"slot",v.get("pointer_slot"),
         "symbol",(v.get("pointer_binding") or v.get("binding") or {}).get("name"))
  for k,v in result["direct_code_xrefs"].items():
   print("OMNICAR_DIRECT_XREF",k,len(v))
  print("OMNICAR_REAL_DEB_SHA_VERIFIED_IMPORT_AND_BRANCH_FORENSICS_ONLY")

if __name__=="__main__":main()
