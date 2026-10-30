#!/usr/bin/env python3
"""Read-only original OmniCar ABHost method and screen-unblank owner audit.

Source: SHA-pinned signed OmniCar 1.0.3 DEB, ARM64 (not an iPhone test).
Resolves bounded local Objective-C method tables and binary data references.
Does not rewrite, transplant, patch or execute proprietary tweak code.
"""
import argparse
import hashlib
import json
import re
import struct
import subprocess
import tempfile
from pathlib import Path
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
from audit_native12_license_class_xrefs import MachO, select_arm64
from resolve_omnicar_bks_imports_and_callbacks import (
    PIN, REL, string_at, slice_at, imports
)

CS = Cs(CS_ARCH_ARM64, CS_MODE_ARM)
TRACED = (0x9688,0x9674,0x9668,0x958c,0x777c,0x9694,0x77b0)
MAX_METHODS = 500
TRACE_CLASSES = {"ABHost"}
FOCUS_SEL = {"count", "shared", "carDisconnected", "carConnected", "hideForApp:"}

def candidates(val):
    return list(dict.fromkeys((val,val & 0xffffffff)))

def pointer(m, vm):
    return struct.unpack_from("<Q",m.data,m.map(vm))[0]

def safe_cstr(m, vm):
    if not vm:
        return None
    try:
        off=m.map(vm)
        s=string_at(m.data,off)
        if s is not None and 0<len(s)<=180 and all(31 < ord(c)<127 for c in s):
            return s
    except (ValueError,IndexError,AssertionError,KeyError,struct.error):
        pass
    return None

def valid_vm(m,word):
    for vm in candidates(word):
        try:
            m.map(vm)
            return vm
        except (ValueError,IndexError,AssertionError,KeyError,struct.error):
            pass
    return None

def decode_method_table(m, cls_vm, kind):
    info={"kind":kind,"class_vm":hex(cls_vm),"methods":[]}
    try:
        # objc_class64: isa, superclass, cache, vtable, dataBits.
        metabit=pointer(m,cls_vm+32)
        ro=valid_vm(m,metabit&~7)
        info["data_bits_raw"]=hex(metabit)
        if ro is None:
            info["error"]="class_ro_t not file-mappable"
            return info
        info["class_ro_vm"]=hex(ro)
        nameword=pointer(m,ro+24)
        namevm=valid_vm(m,nameword)
        info["name"]=safe_cstr(m,namevm) if namevm is not None else None
        method_word=pointer(m,ro+32)
        table=valid_vm(m,method_word)
        info["methods_head_raw"]=hex(method_word)
        if table is None:
            info["status"]="no readable method list"
            return info
        info["methods_head_vm"]=hex(table)
        flags=struct.unpack_from("<I",m.data,m.map(table))[0]
        cnt=struct.unpack_from("<I",m.data,m.map(table+4))[0]
        info["flags"]=hex(flags);info["count"]=cnt
        if cnt>MAX_METHODS:
            info["error"]="method list exceeds bound"
            return info
        rel=bool(flags&0x80000000)
        stride=12 if rel else 24
        for i in range(cnt):
            entry=table+8+stride*i
            try:
                if rel:
                    n=struct.unpack_from("<i",m.data,m.map(entry))[0]
                    t=struct.unpack_from("<i",m.data,m.map(entry+4))[0]
                    f=struct.unpack_from("<i",m.data,m.map(entry+8))[0]
                    nameptr=entry+n
                    if not flags&0x40000000:
                        try:nameptr=valid_vm(m,pointer(m,nameptr))
                        except (ValueError,IndexError,AssertionError,KeyError,struct.error): nameptr=None
                    imp=entry+8+f
                    types=entry+4+t
                else:
                    nameptr=valid_vm(m,pointer(m,entry))
                    imp=valid_vm(m,pointer(m,entry+16))
                    types=valid_vm(m,pointer(m,entry+8))
                name=safe_cstr(m,nameptr) if nameptr is not None else None
                info["methods"].append({
                    "selector":name,
                    "entry_vm":hex(entry),
                    "imp_vm":hex(imp) if imp is not None else None,
                    "types":safe_cstr(m,types) if types is not None else None
                })
            except (ValueError,IndexError,AssertionError,KeyError,struct.error) as ex:
                info["methods"].append({"entry_vm":hex(entry),"error":type(ex).__name__})
        info["status"]="decoded"
    except (ValueError,IndexError,AssertionError,KeyError,struct.error) as ex:
        info["error"]=str(ex)[:180]
    return info

def all_classes(m):
    classes=[]
    for sec in m.sections:
        if sec["name"]!="__objc_classlist" or sec["size"]>100000:
            continue
        for e in range(sec["vm"],sec["vm"]+sec["size"],8):
            try:
                vm=valid_vm(m,pointer(m,e))
                if vm is None: continue
                instance=decode_method_table(m,vm,"-")
                meta=valid_vm(m,pointer(m,vm))
                static=decode_method_table(m,meta,"+") if meta else {"kind":"+","error":"unmapped metaclass"}
                if not instance.get("name") and not static.get("name"):
                    continue
                classes.append({"classlist_entry":hex(e),"class_vm":hex(vm),
                                "class":instance.get("name") or static.get("name"),
                                "instance":instance,"class_methods":static})
            except (ValueError,IndexError,AssertionError,KeyError,struct.error):
                continue
    return classes

def backlinks(m,target):
    refs=[]
    for sec in m.sections:
        if not sec["segment"].startswith(("__DATA","__AUTH","__OBJC")) or sec["size"]>16000000:
            continue
        if sec["name"]=="__bss":continue
        content=m.data[sec["fileoff"]:sec["fileoff"]+sec["size"]]
        # 64-bit absolute pointers and version-tagged/fixup-chained 64-bit
        # words are candidates, never claim a relocated runtime pointer.
        for i in range(0,len(content)-7,8):
            val=struct.unpack_from("<Q",content,i)[0]
            if val==target or (val&0xffffffff)==target:
                refs.append({"section":sec["name"],"pc":hex(sec["vm"]+i),
                             "kind":"raw_64_or_low32_target","raw":hex(val),
                             "confidence":"candidate ONLY, not proven resolved pointer"})
        # ObjC compact relative method IMP pointers: IMP field is entry+8
        # + signed relative offset. Aligned 4-byte slots are enough.
        for i in range(0,len(content)-3,4):
            val=struct.unpack_from("<i",content,i)[0]
            vm=sec["vm"]+i
            if vm+val==target:
                refs.append({"section":sec["name"],"pc":hex(vm),
                             "kind":"signed_rel32_target",
                             "raw":hex(val&0xffffffff),
                             "confidence":"candidate; entry must be confirmed as objc metadata"})
    return refs[:70]

def focus_methods(m,classes):
    methods=[]
    for c in classes:
        for kind in ("instance","class_methods"):
            for method in c[kind].get("methods",[]):
                imp=method.get("imp_vm")
                if not imp:continue
                pc=int(imp,16)
                if (c["class"] in TRACE_CLASSES or method.get("selector") in FOCUS_SEL
                    or any(abs(pc-z)<140 for z in TRACED)):
                    out={"class":c["class"],"kind":kind,"selector":method.get("selector"),
                         "imp_vm":imp}
                    try:out["instructions"]=slice_at(m,pc,40)
                    except (ValueError,AssertionError,KeyError,IndexError,struct.error):
                        out["instructions"]=[]
                    methods.append(out)
    return methods[:130]

def target_proximity(methods):
    ordered=[]
    for m in methods:
        if m["imp_vm"]:ordered.append((int(m["imp_vm"],16),m["class"],m["kind"],m.get("selector")))
    ordered.sort()
    out={}
    for target in TRACED:
        cand=[v for v in ordered if v[0]<=target]
        if cand:
            vm,clazz,kind,sel=cand[-1]
            out[hex(target)]={"previous_objc_method":clazz+" "+kind+" "+str(sel),
                               "entry":hex(vm),"distance":target-vm,
                               "same_method_proven":False}
        else:out[hex(target)]={"status":"no preceding decoded ObjC IMP"}
    return out

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--deb",required=True,type=Path)
    ap.add_argument("--out",required=True,type=Path)
    a=ap.parse_args()
    pin=hashlib.sha256(a.deb.read_bytes()).hexdigest()
    if pin!=PIN:raise SystemExit("FAIL-CLOSED: original OmniCar signed DEB SHA256 mismatch: "+pin)
    with tempfile.TemporaryDirectory() as t:
        subprocess.run(["dpkg-deb","-x",str(a.deb),t],check=True)
        raw=(Path(t)/REL).read_bytes()
        m=MachO(select_arm64(raw))
        cs=all_classes(m)
        methods=focus_methods(m,cs)
        result={"kind":"original OmniCar 1.0.3 class IMP / callback data-reference audit",
                "source_deb_sha256":pin,
                "source_dylib_sha256":hashlib.sha256(raw).hexdigest(),
                "machine_read_only":True,"user_phone_runtime_proven":False,
                "class_count":len(cs),
                "ABHost":[c for c in cs if c["class"]=="ABHost"],
                "focused_methods":methods,
                "target_reference_candidates":{hex(vm):backlinks(m,vm) for vm in TRACED},
                "target_nearest_prior_method_NOT_proven_owner":target_proximity(methods),
                "cautions":[
                    "low32 candidate pointer must not be treated as valid without checked image mapping",
                    "relative-data backlinks include false positives; confirm method entry/section before ownership claim",
                    "nearest preceding ObjC IMP does not prove function boundary or a live call",
                    "no iPhone backlight, screen brightness, Play ACK, or CarPlay scene was executed"]}
        a.out.parent.mkdir(parents=True,exist_ok=True)
        a.out.write_text(json.dumps(result,indent=2,ensure_ascii=False)+"\n")
        print("OMNICAR_SHA_PINNED_CLASS_COUNT",len(cs))
        for c in result["ABHost"]:
            for kind in ("instance","class_methods"):
                print("OMNICAR_ABHOST_METHODS",kind,
                      [(x.get("selector"),x.get("imp_vm")) for x in c[kind].get("methods",[])])
        for target,rs in result["target_reference_candidates"].items():
            print("OMNICAR_CALLBACK_DATA_REFS",target,len(rs),rs[:5])
        print("OMNICAR_ORIGINAL_METHOD_TABLE_AND_UNBLANK_XREF_SCAN_ONLY_NOT_DEVICE")
if __name__=="__main__":
    main()
