# Independent read-only selector extraction; no vendor implementation reproduced.
import lief,struct,json,argparse,hashlib
from pathlib import Path
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
parser=argparse.ArgumentParser();parser.add_argument('dylib');p=parser.parse_args().dylib
assert hashlib.sha256(Path(p).read_bytes()).hexdigest()=='44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15'
b=lief.MachO.parse(p).at(0);secs=list(b.sections)
def get(v,n):return bytes(b.get_content_from_virtual_address(v,n))
def ptr(v):return struct.unpack('<Q',get(v,8))[0]
def cstr(v):
 try:return get(v,200).split(b'\0')[0].decode()
 except:return ''
def annotate(v):
 sec=next((s for s in secs if s.virtual_address<=v<s.virtual_address+s.size),None)
 if sec is None:return None
 try:
  if sec.name=='__objc_selrefs':return cstr(ptr(v))
  if sec.name=='__cfstring':return cstr(ptr(v+16))
  if sec.name in ('__cstring','__objc_methname','__objc_classname'):return cstr(v)
 except:return None
cs=Cs(CS_ARCH_ARM64,CS_MODE_ARM);page={};out=[]
for x in cs.disasm(get(0x310a50,0x1100),0x310a50):
 import re
 op=x.mnemonic;s=x.op_str;t=None
 a=re.fullmatch(r'(x\d+), #(0x[0-9a-f]+)',s)
 if op in ('adrp','adr') and a:
  t=int(a[2],16)
  if op=='adrp':page[a[1]]=t
 if op=='ldr' and a:t=int(a[2],16)
 a=re.fullmatch(r'(x\d+), (x\d+), #(0x[0-9a-f]+)',s)
 if op=='add' and a and a[2] in page:t=page[a[2]]+int(a[3],16)
 a=re.fullmatch(r'(x\d+), \[(x\d+), #(0x[0-9a-f]+)\]',s)
 if op=='ldr' and a and a[2] in page:t=page[a[2]]+int(a[3],16)
 if t:
  name=annotate(t)
  if name:out.append({'pc':hex(x.address),'name':name})
print(json.dumps(out,ensure_ascii=False,indent=2))
