"""Decode modern Mach-O __objc_stubs -> __objc_selrefs -> selector string.

No execution, only bytes. ARM64 objc stub loads a selector pointer with
ADRP x1,<selref page> / LDR x1,[x1,#offset] before objc_msgSend jump.
Uses LLVM disassembly for stub PCs and section_64 to translate VM to file.
This proves the selector NAME loaded by that stub; the ObjC receiver type
remains dynamic and can NEVER be established by selector alone.
"""
import pathlib,re,struct,subprocess
def sections_for_binary(path):
 blob=pathlib.Path(path).read_bytes()
 if struct.unpack_from('<I',blob,0)[0]!=0xfeedfacf:
  raise ValueError('arm64 Mach-O 64 little-endian required')
 n=struct.unpack_from('<I',blob,16)[0]
 pos=32;sections={}
 for _ in range(n):
  cmd,sz=struct.unpack_from('<II',blob,pos)
  if cmd==0x19:
   nsects=struct.unpack_from('<I',blob,pos+64)[0]
   for i in range(nsects):
    off=pos+72+80*i
    name=blob[off:off+16].split(b'\0',1)[0].decode('latin1')
    va,size,fileoff=struct.unpack_from('<QQI',blob,off+32)
    sections[name]=(va,size,fileoff)
  pos+=sz
 def read_va(addr,size):
  for va,sectsize,fileoff in sections.values():
   if va<=addr and addr+size<=va+sectsize:
    return blob[fileoff+addr-va:fileoff+addr-va+size]
  return None
 return sections,read_va
def decode_objc_stubs(path,tool='llvm-objdump'):
 sections,read=sections_for_binary(path)
 if '__objc_stubs' not in sections:return {}
 result=subprocess.run([tool,'--disassemble','--section=__objc_stubs',
              '--no-show-raw-insn',str(path)],capture_output=True,text=True,
              errors='replace')
 if result.returncode:raise RuntimeError(result.stderr[-300:])
 ret={};page=entry=None
 for line in result.stdout.splitlines():
  x=re.match(r'^\s*([0-9a-f]+):\s+(adrp|ldr)\s+x1,\s*(.+)',line)
  if not x:continue
  pc=int(x.group(1),16)
  if x.group(2)=='adrp':
   y=re.search(r'0x[0-9a-fA-F]+',x.group(3))
   if y:page=int(y.group(),16);entry=pc
  elif page is not None:
   y=re.search(r'\[x1,\s*#(0x[0-9a-fA-F]+)\]',x.group(3))
   if not y:continue
   selref=page+int(y.group(1),16)
   ptr=read(selref,8)
   if ptr is None:continue
   tagged=int.from_bytes(ptr,'little')
   # arm64e/dyld rebases encode high-bit metadata; VM pointer is low 48 bits.
   string_addr=tagged & ((1<<48)-1)
   data=None
   for size in (192,128,64,32,16,8):
    data=read(string_addr,size)
    if data:break
   if not data:continue
   name=data.split(b'\0',1)[0].decode('utf-8','replace')
   if name and re.fullmatch(r'[\x20-\x7e]{1,150}',name):
    ret[entry]={'selector':name,'stub_pc':hex(entry),
                'selref_pc':hex(selref),'name_pc':hex(string_addr)}
 return ret
