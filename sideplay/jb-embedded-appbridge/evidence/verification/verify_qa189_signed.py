#!/usr/bin/env python3
"""Independently inspect signed rootless DuoFace QA189 artifact in extracted ZIP.
Validates binary CodeDirectory pages, package metadata, source provenance,
rootless file inventory and QA189 runtime markers. This is not a device test.
"""
import hashlib, json, os, pathlib, plistlib, struct, subprocess, sys

archive = pathlib.Path(sys.argv[1]).resolve()
root = archive.parent
name = 'com.duoface.jb.embedded_0.0.189~mapsh1fix1_iphoneos-arm64.deb'
deb = root/name
stage = root/'qa189_expanded'
assert deb.is_file(), f'Missing package {deb}'
sha = hashlib.sha256(deb.read_bytes()).hexdigest()
manifest = root/'QA189_SHA256SUMS.txt'
assert manifest.is_file(), 'Missing signed run sha manifest'
expected, artifact = manifest.read_text().strip().split(None,1)
assert sha == expected, f'QA189 hash mismatch: {sha} != {expected}'
assert pathlib.Path(artifact.replace('*','')).name == name, artifact
prov = json.loads((root/'PACKAGING_PROVENANCE.json').read_text())
assert prov['sha256'] == sha, 'Provenance SHA mismatch'
assert not prov.get('sileo_published',False)
assert prov['source_git_commit'] == sys.argv[2], (prov['source_git_commit'],sys.argv[2])

def field(item):
 return subprocess.check_output(['dpkg-deb','-f',str(deb),item],text=True).strip()
assert field('Package')=='com.duoface.jb.embedded'
assert field('Version')=='0.0.189~mapsh1fix1'
assert field('Architecture')=='iphoneos-arm64'
assert field('Depends')=='firmware (>= 16.0), mobilesubstrate'
stage.mkdir(exist_ok=True)
subprocess.run(['dpkg-deb','-x',str(deb),str(stage)],check=True)
info=plistlib.loads((stage/'var/jb/Applications/DuoFaceNativeHost.app/Info.plist').read_bytes())
assert info['CFBundleVersion']=='189' and info['CFBundleShortVersionString']=='0.1.189'
libs=stage/'var/jb/Library/MobileSubstrate/DynamicLibraries'
required={
 'DFNativeMapPaneCoordinator.dylib':[b'presented-target-yield-expired-before-COMMITTED-STOP',b'com.duoface.nativehost.maps-membership.changed.v1',b'pane-member-committed'],
 'DFTouchOwnerProbe.dylib':[b'qa189-native-map-stage-changed',b'com.duoface.nativehost.maps-membership.changed.v1',b'qa188-h1-app-touch-wake'],
 'DF155GeneralAppStateRelay.dylib':[b'com.duoface.apptouch177.wake',b'com.duoface.controls188.hidden'],
}
for fname, needles in required.items():
 buf=(libs/fname).read_bytes()
 for value in needles: assert value in buf, (fname,value)

MAGIC_CS=0xfade0cc0
MAGIC_CD=0xfade0c02
LC_CODE_SIGNATURE=0x1d

def slice_verify(content,filename):
 assert len(content)>32 and struct.unpack_from('<I',content,0)[0]==0xfeedfacf, filename
 ncmds=struct.unpack_from('<I',content,16)[0]
 ptr=32; signature=None
 for _ in range(ncmds):
  cmd,size=struct.unpack_from('<II',content,ptr)
  assert size>=8
  if cmd==LC_CODE_SIGNATURE: signature=struct.unpack_from('<II',content,ptr+8)
  ptr+=size
 assert signature, filename
 off,sz=signature
 assert off+sz<=len(content) and struct.unpack_from('>I',content,off)[0]==MAGIC_CS
 siglen,count=struct.unpack_from('>II',content,off+4)
 assert siglen<=sz
 checked=0
 for i in range(count):
  typ,rel=struct.unpack_from('>II',content,off+12+i*8)
  if typ!=0 and not 0x1000<=typ<0x1100: continue
  pos=off+rel
  magic,length=struct.unpack_from('>II',content,pos)
  assert magic==MAGIC_CD and pos+length<=off+siglen
  hash_off,ident_off,n_special,n_slots,code_limit=struct.unpack_from('>IIIII',content,pos+16)
  hash_sz,hash_type,platform,page_exp=struct.unpack_from('BBBB',content,pos+36)
  version=struct.unpack_from('>I',content,pos+8)[0]
  if version>=0x20300 and code_limit==0: code_limit=struct.unpack_from('>Q',content,pos+56)[0]
  page_sz=1<<page_exp
  assert 4096<=page_sz<=65536 and n_slots==(code_limit+page_sz-1)//page_sz
  assert hash_type in (1,2,3) and code_limit<=off
  assert hash_off+hash_sz*n_slots<=length
  for j in range(n_slots):
   block=content[j*page_sz:min((j+1)*page_sz,code_limit)]
   actual=(hashlib.sha1(block).digest() if hash_type==1 else hashlib.sha256(block).digest())[:hash_sz]
   target=content[pos+hash_off+j*hash_sz:pos+hash_off+(j+1)*hash_sz]
   assert actual==target, f'CodeDirectory hash mismatch: {filename} slot {j}'
  checked+=n_slots
 assert checked, filename
 return checked

def macho_verify(path):
 buf=path.read_bytes()
 if buf[:4]==bytes.fromhex('cafebabe'):
  n=struct.unpack_from('>I',buf,4)[0]
  assert 1<=n<=8
  total=0
  for i in range(n):
   cpu,sub,off,size,align=struct.unpack_from('>IIIII',buf,8+i*20)
   assert off+size<=len(buf)
   total+=slice_verify(buf[off:off+size],str(path))
  return total
 return slice_verify(buf,str(path))

bins=sorted(libs.glob('*.dylib')) + [stage/'var/jb/Applications/DuoFaceNativeHost.app/DuoFaceNativeHost']
assert len(bins)==11, f'Expected 11 binaries, got {len(bins)}'
pages=sum(macho_verify(p) for p in bins)
assert all(str(p.relative_to(stage)).startswith('var/jb/') for p in stage.rglob('*') if p.is_file())
report={'status':'PASS','file':name,'bytes':deb.stat().st_size,'sha256':sha,'source_sha':sys.argv[2],
 'version':field('Version'),'architecture':field('Architecture'),'signed_macho_checked':len(bins),
 'verified_code_pages':pages,'qa189_markers':'PASS','conflicts':field('Conflicts'),
 'sileo_published':False,'device_tested':False,'verification_scope':'independent Mach-O CodeDirectory pages, package metadata, provenance; not iPhone/CarPlay runtime'}
(root/'QA189_INDEPENDENT_VERIFICATION.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n')
print(json.dumps(report,indent=2,ensure_ascii=False))
