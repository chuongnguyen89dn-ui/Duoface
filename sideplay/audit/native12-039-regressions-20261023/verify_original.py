"""Read-only Native12 vs .39 evidence. Usage: python verify_original.py ORIGINAL.deb CANDIDATE.deb OUT"""
import hashlib,json,pathlib,struct,subprocess,sys,tempfile
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
original,candidate,out=map(pathlib.Path,sys.argv[1:]);out.mkdir(parents=True,exist_ok=True)
expected=['2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad','08183c187d0aeb2e68e721531cc599c32edb4e4981c208cb26a031c1b9467317']
assert [hashlib.sha256(p.read_bytes()).hexdigest() for p in [original,candidate]]==expected
with tempfile.TemporaryDirectory() as tmp:
 subprocess.run(['dpkg-deb','-x',str(original),tmp],check=True)
 data=(pathlib.Path(tmp)/'var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib').read_bytes()
assert hashlib.sha256(data).hexdigest()=='9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea'
pos=32;segments=[]
for _ in range(struct.unpack_from('<I',data,16)[0]):
 cmd,size=struct.unpack_from('<II',data,pos)
 if cmd==0x19:
  vm,vms,off,fs=struct.unpack_from('<QQQQ',data,pos+24);segments.append((vm,off,fs))
 pos+=size
def raw(a,n):
 for vm,off,sz in segments:
  if vm<=a and a+n<=vm+sz:return data[off+a-vm:off+a-vm+n]
 raise ValueError(hex(a))
def selector(a):
 p=int.from_bytes(raw(a,8),'little')&((1<<48)-1)
 return raw(p,80).split(b'\0')[0].decode()
assert selector(0x37eaf8)=='appDockViewController'
assert selector(0x37de90)=='buttonWithType:'
cs=Cs(CS_ARCH_ARM64,CS_MODE_ARM);lines=[]
for a,b in [(0xa2fa4,0xa2fc0),(0x1217d8,0x121884)]:
 lines.extend(f'{i.address:x}: {i.mnemonic} {i.op_str}' for i in cs.disasm(raw(a,b-a),a))
assert 'a2fb8: mov x2, #0' in lines
(out/'original-button-dock-arm64.txt').write_text('\n'.join(lines)+'\n')
result={'original_sha256':expected[0],'candidate_039_sha256':expected[1], 'original_button_type':0,'original_dock_getter':selector(0x37eaf8),'original_dock_getter_selref':'0x37eaf8','runtime_crash_root_cause_verified':False,'device_test':False}
for name,p in [('original',original),('candidate_039',candidate)]:
 result[name+'_control']=subprocess.check_output(['dpkg-deb','-f',str(p)],text=True)
(out/'binary-verification.json').write_text(json.dumps(result,indent=2)+'\n')
print('SHA_PINNED_ORIGINAL_BUTTON_CUSTOM_AND_APPDOCK_VIEW_CONTROLLER_VERIFIED')
