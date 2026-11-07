#!/usr/bin/env python3
"""Independent QA189 DEB and embedded Mach-O CodeDirectory page verifier."""
import hashlib
import json
import math
import pathlib
import plistlib
import struct
import subprocess
import sys

root = pathlib.Path(__file__).resolve().parent
filename = 'com.duoface.jb.embedded_0.0.189~mapsh1fix1_iphoneos-arm64.deb'
deb = root / filename
stage = root / 'expanded'
expected_sha = '463042ac5525807c2a924341b153dc5572334f03776a227a5e422c8d42537106'
expected_source = '0b34224cb5cd259e5c9909cc40593b55c74d5f6a'
actual_sha = hashlib.sha256(deb.read_bytes()).hexdigest()
assert actual_sha == expected_sha, (actual_sha, expected_sha)
provenance = json.loads((root / 'PACKAGING_PROVENANCE.json').read_text())
assert provenance['sha256'] == actual_sha
assert provenance['source_git_commit'] == expected_source
assert not provenance['sileo_published']

def field(name):
    return subprocess.check_output(['dpkg-deb','-f',str(deb),name],text=True).strip()
assert field('Package') == 'com.duoface.jb.embedded'
assert field('Version') == '0.0.189~mapsh1fix1'
assert field('Architecture') == 'iphoneos-arm64'
assert field('Depends') == 'firmware (>= 16.0), mobilesubstrate'
info = plistlib.loads((stage / 'var/jb/Applications/DuoFaceNativeHost.app/Info.plist').read_bytes())
assert info['CFBundleVersion'] == '188'
assert info['CFBundleShortVersionString'] == '0.1.188'
libdir = stage / 'var/jb/Library/MobileSubstrate/DynamicLibraries'
assert b'scene-frame-original-preserved' in (libdir / 'DFNativeMapPaneCoordinator.dylib').read_bytes()
assert b'presented-target-yield-expired-before-COMMITTED-STOP' in (libdir / 'DFNativeMapPaneCoordinator.dylib').read_bytes()
assert b'qa189-native-map-stage-changed' in (libdir / 'DFTouchOwnerProbe.dylib').read_bytes()
assert b'com.duoface.nativehost.maps-membership.changed.v1' in (libdir / 'DFNativeMapPaneCoordinator.dylib').read_bytes()
assert b'qa188-native-maps-saved-restore-request' in (libdir / 'DFTouchOwnerProbe.dylib').read_bytes()
assert b'qa188-native-maps-picker-request' in (libdir / 'DFTouchOwnerProbe.dylib').read_bytes()
assert b'qa188-background-owner-gate' in (stage / 'var/jb/Applications/DuoFaceNativeHost.app/DuoFaceNativeHost').read_bytes()
assert b'pane-layout-reconciled' in (libdir / 'DFNativeMapPaneCoordinator.dylib').read_bytes()
assert b'owned-host-layout-reconciled' in (libdir / 'DFTouchOwnerProbe.dylib').read_bytes()
assert all(p.as_posix().startswith('var/jb/') for p in (x.relative_to(stage) for x in stage.rglob('*') if x.is_file()))

MAGIC_SIGNATURE = 0xfade0cc0
MAGIC_CODE_DIRECTORY = 0xfade0c02
LC_CODE_SIGNATURE = 0x1d

def verify_macho_slice(content, path):
    assert struct.unpack_from('<I', content, 0)[0] == 0xfeedfacf, str(path)
    ncmds = struct.unpack_from('<I', content, 16)[0]
    cursor = 32
    code_sig = None
    for _ in range(ncmds):
        command, size = struct.unpack_from('<II', content, cursor)
        assert size >= 8
        if command == LC_CODE_SIGNATURE:
            code_sig = struct.unpack_from('<II', content, cursor + 8)
        cursor += size
    assert code_sig is not None, f'No LC_CODE_SIGNATURE {path}'
    dataoff, datasize = code_sig
    assert dataoff + datasize <= len(content)
    assert struct.unpack_from('>I', content, dataoff)[0] == MAGIC_SIGNATURE
    siglen, count = struct.unpack_from('>II', content, dataoff + 4)
    assert siglen <= datasize
    checked = []
    for i in range(count):
        slot_type, offset = struct.unpack_from('>II',content,dataoff+12+i*8)
        if slot_type not in (0,) and not (0x1000 <= slot_type < 0x1100):
            continue
        pos = dataoff + offset
        magic, length = struct.unpack_from('>II', content, pos)
        assert magic == MAGIC_CODE_DIRECTORY, (path,hex(magic))
        assert pos + length <= dataoff + siglen
        hash_off, ident_off, n_special, n_slots, code_limit = struct.unpack_from('>IIIII', content, pos + 16)
        hash_size, hash_type, platform, page_exp = struct.unpack_from('BBBB',content,pos + 36)
        version = struct.unpack_from('>I',content,pos + 8)[0]
        if version >= 0x20300 and code_limit == 0:
            code_limit = struct.unpack_from('>Q',content,pos + 56)[0]
        page_size=1 << page_exp
        assert page_size >= 4096 and page_size <= 65536
        assert n_slots == (code_limit + page_size - 1) // page_size
        assert hash_type in (1,2,3), (path,hash_type)
        assert code_limit <= dataoff
        assert hash_off + hash_size*n_slots <= length
        for idx in range(n_slots):
            block=content[idx*page_size:min((idx+1)*page_size,code_limit)]
            digest=(hashlib.sha1(block).digest() if hash_type==1 else hashlib.sha256(block).digest())[:hash_size]
            target=content[pos+hash_off+idx*hash_size:pos+hash_off+(idx+1)*hash_size]
            assert digest==target, f'Code page mismatch {path.name} slot={idx}'
        checked.append({'hash_type':hash_type,'pages':n_slots,'hash_size':hash_size,'page_size':page_size,'slot_type':slot_type})
    assert checked, f'No CodeDirectory {path}'
    return {'checks':checked}

def verify_macho(path):
    buf = path.read_bytes()
    if buf[:4] == bytes.fromhex('cafebabe'):
        num = struct.unpack_from('>I',buf,4)[0]
        assert 1 <= num <= 8
        slices=[]
        for i in range(num):
            cpu, subtype, off, size, align=struct.unpack_from('>IIIII',buf,8+i*20)
            assert off+size <= len(buf)
            slices.append({'cpu':cpu,'subtype':subtype,**verify_macho_slice(buf[off:off+size],path)})
    else:
        slices=[verify_macho_slice(buf,path)]
    return {'path':str(path.relative_to(stage)),'slices':slices}

machs = sorted(libdir.glob('*.dylib')) + [stage / 'var/jb/Applications/DuoFaceNativeHost.app/DuoFaceNativeHost']
assert len(machs)==11, len(machs)
results = [verify_macho(path) for path in machs]
report={
  'status':'PASS',
  'package':filename,
  'size_bytes':deb.stat().st_size,
  'sha256':actual_sha,
  'source_sha':expected_source,
  'signature_verification':'Independent Mach-O CodeDirectory hashed pages; not hardware trust validation',
  'signed_macho_checked':len(results),
  'macho_results':results,
  'required_runtime_markers':'PASS',
  'sileo_published':False,
  'real_device_tested':False,
  'package_conflicts':field('Conflicts'),
}
out=root/'INDEPENDENT_QA189_PACKAGE_VERIFICATION.json'
out.write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({k:v for k,v in report.items() if k != 'macho_results'},indent=2))
