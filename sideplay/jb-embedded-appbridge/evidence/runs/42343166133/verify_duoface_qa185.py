import hashlib, json, pathlib, struct, subprocess, sys

root=pathlib.Path(sys.argv[1]); deb=next(root.glob('*.deb'))
expected_source=sys.argv[2]
def run(*args): return subprocess.check_output(args,text=True).strip()
meta={k:run('dpkg-deb','-f',str(deb),k) for k in ['Package','Version','Architecture','Depends']}
assert meta['Package']=='com.duoface.jb.embedded'
assert meta['Version']=='0.0.185~admission1'
assert meta['Architecture']=='iphoneos-arm64'
assert meta['Depends']=='firmware (>= 16.0), mobilesubstrate'
sha=hashlib.sha256(deb.read_bytes()).hexdigest()
manifest=next(root.glob('*SHA256SUMS.txt')).read_text()
assert sha in manifest
prov=json.loads((root/'PACKAGING_PROVENANCE.json').read_text())
assert expected_source in json.dumps(prov)
payload=root/'payload'; control=root/'control'
subprocess.run(['dpkg-deb','-x',str(deb),str(payload)],check=True)
subprocess.run(['dpkg-deb','-e',str(deb),str(control)],check=True)
assert (payload/'var/jb').is_dir()
assert all(p.name=='var' for p in payload.iterdir())
for name in ['postinst','postrm']:
    p=control/name; assert p.stat().st_mode & 0o111
    text=p.read_text(); assert all(s not in text for s in ['respring','killall','uicache -u'])

def verify_slice(b):
    magic=b[:4]
    assert magic in [b'\xcf\xfa\xed\xfe',b'\xce\xfa\xed\xfe'],magic.hex()
    header=32 if magic==b'\xcf\xfa\xed\xfe' else 28
    ncmd=struct.unpack_from('<I',b,16)[0]; pos=header; sig=None; uuid=None
    for _ in range(ncmd):
        cmd,size=struct.unpack_from('<II',b,pos); assert size>=8
        if cmd==0x1d: sig=struct.unpack_from('<II',b,pos+8)
        if cmd==0x1b: uuid=b[pos+8:pos+24].hex()
        pos+=size
    assert sig,'unsigned Mach-O'
    off,size=sig; sb=b[off:off+size]
    magic,length,count=struct.unpack_from('>III',sb)
    assert magic==0xfade0cc0 and length<=len(sb)
    checked=[]
    for i in range(count):
        kind,offset=struct.unpack_from('>II',sb,12+i*8)
        cmagic,clen=struct.unpack_from('>II',sb,offset)
        if cmagic!=0xfade0c02: continue
        cd=sb[offset:offset+clen]
        version,flags,hashoff,identoff,nspecial,ncode,limit=struct.unpack_from('>7I',cd,8)
        hsize,htype,platform,power=struct.unpack_from('4B',cd,36)
        if version>=0x20300:
            limit64=struct.unpack_from('>Q',cd,56)[0]
            if limit64: limit=limit64
        assert limit<=off
        page=(1<<power) if power else limit
        assert ncode==(limit+page-1)//page
        algorithm={1:'sha1',2:'sha256',3:'sha256',4:'sha384'}[htype]
        for slot in range(ncode):
            digest=hashlib.new(algorithm,b[slot*page:min((slot+1)*page,limit)]).digest()[:hsize]
            assert digest==cd[hashoff+slot*hsize:hashoff+(slot+1)*hsize],('invalid code page',slot)
        checked.append({'hash':algorithm,'pages':ncode,'codeLimit':limit,'flags':flags})
    assert checked,'no CodeDirectory'
    return {'uuid':uuid,'codeDirectories':checked}

machos=[]
for p in payload.rglob('*'):
    if not p.is_file() or p.is_symlink(): continue
    b=p.read_bytes(); slices=[]
    if b[:4] in [b'\xcf\xfa\xed\xfe',b'\xce\xfa\xed\xfe']:
        slices=[verify_slice(b)]
    elif b[:4]==b'\xca\xfe\xba\xbe':
        count=struct.unpack_from('>I',b,4)[0]
        for i in range(count):
            cpu,sub,off,size,align=struct.unpack_from('>IIIII',b,8+20*i)
            slices.append(verify_slice(b[off:off+size]))
    if slices: machos.append({'path':str(p.relative_to(payload)),'sha256':hashlib.sha256(b).hexdigest(),'slices':slices})
assert len(machos)==11,len(machos)
libs=payload/'var/jb/Library/MobileSubstrate/DynamicLibraries'
coordinator=(libs/'DFNativeMapPaneCoordinator.dylib').read_bytes()
probe=(libs/'DFTouchOwnerProbe.dylib').read_bytes()
for needle in [b'membership-reject-detail',b'launch-identity-captured',b'identity-admitted',b'post-admission-visibility',b'pane-member-committed',b'DBDashboardRootViewController.presentBase:post-original']:
    assert needle in coordinator,needle
assert b'picker-evidence185 saved=' in probe
assert b'build=0.0.185~admission1' in probe
import plistlib
info=plistlib.loads((payload/'var/jb/Applications/DuoFaceNativeHost.app/Info.plist').read_bytes())
assert info['CFBundleVersion']=='185'
report={'package':deb.name,'bytes':deb.stat().st_size,'sha256':sha,'metadata':meta,'source':expected_source,'machoCount':len(machos),'machos':machos,'codePageHashes':'PASS','diagnosticMarkers':'PASS','sileoPublished':False,'deviceTested':False}
(root/'INDEPENDENT_PACKAGE_VERIFICATION.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({k:v for k,v in report.items() if k!='machos'},indent=2))
