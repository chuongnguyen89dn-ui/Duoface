#!/usr/bin/env python3
"""Extract original DuoNavi 1.0.4 teardown functions and referenced local blocks.
Read-only static evidence, not a runtime fix or proof of object ownership.
"""
import argparse,bisect,hashlib,json,re,subprocess,sys,tempfile
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'migration/full_payload/native_test'))
from audit_native12_license_class_xrefs import MachO,select_arm64
from audit_native12_carplay_add_app_chain import methods,disassemble
from audit_visual12_sync_callers import function_starts,imported_stubs
EXPECTED='f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd'
TARGETS={'CBBridgedUIAppView':['-dismiss','-dealloc'],
         'CBWindow':['-destroyWindows','-dismiss','-dealloc'],
         'CBBridgedSplitApp':['-closeSlot:','-closeAllSlots','-stop']}
def main():
    p=argparse.ArgumentParser();p.add_argument('--deb',type=Path,required=True);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    assert hashlib.sha256(a.deb.read_bytes()).hexdigest()==EXPECTED
    with tempfile.TemporaryDirectory() as td:
        subprocess.run(['dpkg-deb','-x',str(a.deb),td],check=True)
        raw=(Path(td)/'var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.dylib').read_bytes()
    m=MachO(select_arm64(raw)); starts=function_starts(m); startset=set(starts); imports=imported_stubs(m)
    queue=[]; labels={}
    for cls,sels in TARGETS.items():
        mm=methods(m,cls)
        for sel in sels:
            meta=mm[sel];addr=meta['vm'];assert addr in startset
            labels[addr]=cls+' '+sel;queue.append((addr,0))
    result={}
    while queue:
        start,depth=queue.pop(0)
        if hex(start) in result:continue
        end=starts[bisect.bisect_right(starts,start)]
        lines=disassemble(m,start,end); refs=[]
        for i,line in enumerate(lines):
            match=re.search(r': (?:bl|b) #(0x[0-9a-f]+)',line)
            if match:
                dest=int(match[1],16)
                if dest in imports:lines[i]+=' ; IMPORT '+imports[dest]
            match=re.search(r': adr x\d+, #(0x[0-9a-f]+)',line)
            if match and int(match[1],16) in startset:
                dest=int(match[1],16); refs.append(hex(dest))
                if depth<2:queue.append((dest,depth+1))
        result[hex(start)]={'label':labels.get(start,'referenced local function; block candidate'),
            'end':hex(end),'depth':depth,'local_function_addresses':refs,
            'truncated':len(lines)>=1400 or end-start>40000,'instructions':lines}
    cls=m.classes()['CBBridgedUIAppView'];ro=m.ptr(cls['class_ptr']+32)&~7;head=m.ptr(ro+48)
    stride,count=m.p32(head),m.p32(head+4);ivars=[]
    for i in range(count):
        entry=head+8+i*stride;slot=m.ptr(entry)
        ivars.append({'offset_slot':hex(slot),'offset':m.p32(slot),
            'name':m.cstr(m.ptr(entry+8)),'type':m.cstr(m.ptr(entry+16))})
    report={'status':'ORIGINAL104_TEARDOWN_STATIC_ONLY','deb_sha256':EXPECTED,
        'CBBridgedUIAppView_ivars':ivars,
        'binary_sha256':hashlib.sha256(raw).hexdigest(),'functions':result,
        'limitations':['Address-taking does not by itself prove a block invocation.',
        'Disassembly selector annotations are hints; indirect calls/runtime hooks may alter behavior.',
        'No device test, no binary edit, no build/deploy.']}
    a.out.parent.mkdir(parents=True,exist_ok=True);a.out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({k:{'label':v['label'],'lines':len(v['instructions']),'truncated':v['truncated']} for k,v in result.items()}))
if __name__=='__main__':main()
