"""Read-only original Native12 verification; requires capstone 5.0.9.
Usage: python verify_preview_reference.py ORIGINAL.deb OUTPUT_DIRECTORY
"""
import hashlib,json,pathlib,struct,subprocess,sys,tempfile
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
DEB='2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad'
DASH='9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea'
p=pathlib.Path(sys.argv[1]);out=pathlib.Path(sys.argv[2]);out.mkdir(parents=True,exist_ok=True)
assert hashlib.sha256(p.read_bytes()).hexdigest()==DEB
with tempfile.TemporaryDirectory() as d:
 subprocess.run(['dpkg-deb','-x',str(p),d],check=True)
 data=(pathlib.Path(d)/'var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib').read_bytes()
assert hashlib.sha256(data).hexdigest()==DASH
assert struct.unpack_from('<I',data)[0]==0xfeedfacf
n=struct.unpack_from('<I',data,16)[0];pos=32;segments=[]
for _ in range(n):
 cmd,size=struct.unpack_from('<II',data,pos)
 if cmd==0x19:
  vm,vms,off,fs=struct.unpack_from('<QQQQ',data,pos+24);segments.append((vm,off,fs))
 pos+=size
def raw(vm,size):
 for base,off,length in segments:
  if base<=vm and vm+size<=base+length:return data[off+vm-base:off+vm-base+size]
 raise ValueError(hex(vm))
cs=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
lines=[]
for a,b in [(0xa6434,0xa6488),(0x9efe0,0x9ff00)]:
 for i in cs.disasm(raw(a,b-a),a):lines.append(f'{i.address:x}: {i.mnemonic} {i.op_str}')
(out/'ORIGINAL_PREVIEW_CAPSTONE.txt').write_text('\n'.join(lines)+'\n')
# Selection is independent of the preset integer, proved at caller + callee.
for expected in ['a6434: cmp x26, x27','a6438: cset w21, eq','a6474: mov x0, x26','a6478: mov x1, x21','a6484: bl #0x9efe0','9f010: mov x24, x1','9f014: mov x19, x0','9f130: cbz w24, #0x9f158']:
 assert expected in lines,expected
literals={hex(a):struct.unpack('<d',raw(a,8))[0] for a in [0x30f9b8,0x30f9c0,0x30f9c8,0x30fab8,0x30fac8,0x30faf8,0x310c80,0x310cb0,0x310cc8,*range(0x3116c0,0x311740,8)]}
targets=[0x9f290+4*v for v in struct.unpack('<9H',raw(0x310d3e,18))]
assert targets==[0x9f290,0x9f2fc,0x9f384,0x9f408,0x9f4f4,0x9f5c4,0x9f690,0x9f760,0x9fdd4]
r={'deb_sha256':DEB,'dashboard_sha256':DASH,'selection_argument_verified':True,'jump_targets':[hex(v) for v in targets],'literals':literals,'device_pixel_parity':False}
(out/'REFERENCE_VERIFIED.json').write_text(json.dumps(r,indent=2)+'\n')
print('ORIGINAL_DEB_DASHBOARD_SELECTION_ARGUMENT_NINE_CASES_LITERAL_BYTES_PASS')
