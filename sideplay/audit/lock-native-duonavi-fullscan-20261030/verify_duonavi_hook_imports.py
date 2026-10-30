#!/usr/bin/env python3
"""Read-only exact imported MSHookMessageEx registration proof for two SHA-pinned original dashboards."""
import argparse,collections,hashlib,json,pathlib,struct
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
from audit_native12_license_class_xrefs import MachO,select_arm64
PINS={"Native12":"9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea",
      "DuoNavi":"44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15"}
def imported_stubs(m):
    data=m.data
    sym=None;dysym=None;stubs=[]
    pos=32
    for i in range(m.ncmds):
        cmd,sz=struct.unpack_from("<II",data,pos)
        if cmd==0x2:sym=struct.unpack_from("<IIII",data,pos+8)
        if cmd==0xb:dysym=struct.unpack_from("<II",data,pos+56)
        if cmd==0x19:
            nsects=struct.unpack_from("<I",data,pos+64)[0]
            for k in range(nsects):
                off=pos+72+k*80
                name=data[off:off+16].split(bytes((0,)))[0].decode("ascii","replace")
                if name!="__stubs":continue
                vm,size=struct.unpack_from("<QQ",data,off+32)
                reserved1,reserved2=struct.unpack_from("<II",data,off+68)
                stubs.append({"vm":vm,"size":size,"first_symbol_index":reserved1,"stride":reserved2})
        pos+=sz
    if not sym or not dysym or not stubs:raise RuntimeError("Original Mach-O missing symtab/dysymtab/imported __stubs section")
    symoff,nsyms,stroff,strsize=sym
    indirectoff,nindirect=dysym
    output={}
    for sec in stubs:
        if not sec["stride"]:raise RuntimeError("Stub stride missing")
        for i in range(sec["size"]//sec["stride"]):
            j=sec["first_symbol_index"]+i
            if j>=nindirect:continue
            ind=struct.unpack_from("<I",data,indirectoff+j*4)[0]
            if ind&0xC0000000:continue
            if ind>=nsyms:continue
            strx=struct.unpack_from("<I",data,symoff+ind*16)[0]
            if strx>=strsize:continue
            p=stroff+strx
            end=data.find(bytes((0,)),p,stroff+strsize)
            if end<0:continue
            name=data[p:end].decode("ascii","replace")
            output.setdefault(name,[]).append(sec["vm"]+i*sec["stride"])
    return output
def scan(path,name):
    b=pathlib.Path(path).read_bytes()
    m=MachO(select_arm64(b))
    h=hashlib.sha256(m.data).hexdigest()
    if h!=PINS[name]:raise RuntimeError("wrong original dylib SHA "+name+" "+h)
    imported=imported_stubs(m)
    names={k:v for k,v in imported.items() if any(x in k.lower() for x in ("mshook","objc_getclass","objc_msgsend","objc_getmetaclass","class_getinstancemethod"))}
    candidates={k:v for k,v in imported.items() if "mshookmessageex" in k.lower()}
    if not candidates:raise RuntimeError(name+" exact imported MSHookMessageEx not found, no fake static hook inference")
    target={p for v in candidates.values() for p in v}
    allhits=[]
    for sec in m.find_sections("__text"):
        off=sec["fileoff"];size=sec["size"];vm=sec["vm"]
        ins=Cs(CS_ARCH_ARM64,CS_MODE_ARM).disasm(m.data[off:off+size],vm)
        queue=collections.deque(maxlen=24)
        for x in ins:
            if x.mnemonic in ("bl","b"):
                try:t=int(x.op_str.removeprefix("#"),16)
                except ValueError:t=-1
                if t in target:
                    allhits.append({"pc":hex(x.address),"stub":hex(t),
                        "previous_arm64":[f"{y.address:#x}: {y.mnemonic} {y.op_str}" for y in queue]})
            queue.append(x)
    if not allhits:raise RuntimeError(name+" imported MSHookMessageEx proven but no direct call found")
    return {"sha256":h,"imports":names,"callCount":len(allhits),"calls":allhits}
def main():
    p=argparse.ArgumentParser()
    p.add_argument("--native12-dashboard",required=True)
    p.add_argument("--duonavi-dashboard",required=True)
    p.add_argument("--out",required=True)
    a=p.parse_args()
    native=scan(a.native12_dashboard,"Native12")
    duo=scan(a.duonavi_dashboard,"DuoNavi")
    out=pathlib.Path(a.out);out.mkdir(parents=True,exist_ok=True)
    data={"Native12":native,"DuoNavi":duo}
    # A known-good original fixture validates the import table parser and
    # all 11 exact Native12 hook PCs, avoiding false-positive DuoNavi claims.
    assert "0x2c7c88" in [x["pc"] for x in native["calls"]]
    assert "0x2c7e04" in [x["pc"] for x in native["calls"]]
    assert len([x for x in native["calls"] if 0x2c7c54<=int(x["pc"],16)<=0x2c7e04])==11
    (out/"DUONAVI_AND_NATIVE12_EXACT_MSHOOK_IMPORT_CALLS.json").write_text(json.dumps(data,indent=2,ensure_ascii=False)+"\n")
    lines=["# Original Native12 vs DuoNavi SHA-verified, imported MSHookMessageEx call provenance",
       "","This is binary evidence for a real call to imported MSHookMessageEx.",
       "It does NOT establish each class/selector without argument decoding.",
       "No vendor source or license copied; no runtime installed/tested.",""]
    for name,x in data.items():
        lines+=["## "+name,f"- Dashboard SHA256: {x['sha256']}",
                f"- Imported hook-related functions: {x['imports']}",
                f"- Machine-code direct MSHookMessageEx calls: {x['callCount']}",""]
        for hit in x["calls"]:
            lines+=[f"### hook call {hit['pc']} → {hit['stub']}"]
            lines+=["    "+t for t in hit["previous_arm64"]]
    (out/"DUONAVI_HOOK_IMPORT_CROSSCHECK.md").write_text("\n".join(lines)+"\n")
    print("EXACT_ORIGINAL_HOOK_IMPORT_CALLS_PASS",{"Native12":len(native["calls"]),"DuoNavi":len(duo["calls"])})
if __name__=="__main__":main()
