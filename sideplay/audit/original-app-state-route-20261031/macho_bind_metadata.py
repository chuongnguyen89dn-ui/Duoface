"""Independent metadata-only decoder for the pinned image's legacy bind stream.
References: LLVM BinaryFormat/MachO.h BindOpcode enum. 64-bit address arithmetic
wraps; large unsigned deltas in this image must not be interpreted as giant VAs.
Not a general MachO loader: threaded/chained binds are rejected; never executed.
"""
# Read-only legacy LC_DYLD_INFO bind decoding; no image loading.
import struct

def bindings(m):
 p=32;region=None
 for _ in range(m.ncmds):
  c,n=struct.unpack_from('<II',m.data,p)
  if c in (0x22,0x80000022):region=struct.unpack_from('<II',m.data,p+16)
  p+=n
 if region is None:raise ValueError('no legacy bind stream')
 data=m.data[region[0]:sum(region)];p=0;seg=0;off=0;sym=None;out={}
 def leb():
  nonlocal p
  v=0;shift=0
  while True:
   b=data[p];p+=1;v|=(b&127)<<shift
   if not b&128:return v
   shift+=7
 def emit():
  assert sym is not None and seg<len(m.segments)
  address=(m.segments[seg][0]+off)&0xffffffffffffffff
  assert any(base<=address<base+size for base,size,*_ in m.segments), 'bind outside image'
  out[address]=sym
 while p<len(data):
  byte=data[p];p+=1;op=byte&0xf0;imm=byte&15
  if op==0:break
  elif op in (0x10,0x30,0x50):pass
  elif op in (0x20,0x60):leb()
  elif op==0x40:
   end=data.index(0,p);sym=data[p:end].decode();p=end+1
  elif op==0x70:seg=imm;off=leb()
  elif op==0x80:off+=leb()
  elif op==0x90:emit();off+=8
  elif op==0xa0:emit();off+=8+leb()
  elif op==0xb0:emit();off+=8+imm*8
  elif op==0xc0:
   count=leb();skip=leb()
   for _ in range(count):emit();off+=8+skip
  else:raise ValueError(hex(byte))
 return out
