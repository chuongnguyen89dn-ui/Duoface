#!/usr/bin/env python3
"""Read-only SHA-pinned Native12 CBBridgedUIAppView ObjC ivar owner decoding.

Find class_t -> class_ro_t -> ivar_list in the ORIGINAL Dashboard Mach-O.
Resolve the *two actual* slot addresses loaded by dismiss IMP 0xaf01c:
  0x37fcec (controller x23) and 0x37fce8 (secondary x20).
Do not infer an Objective-C receiver merely from objc_msgSend annotations.
"""
import argparse
import hashlib
import json
import pathlib
import runpy
import struct

HERE=pathlib.Path(__file__).resolve().parent
ROOT=HERE.parents[1]
EXPECTED_SHA="9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea"
EXPECTED_DEB="2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad"
CLASS_NAME="CBBridgedUIAppView"
SLOTS={"controller_offset_slot":0x37fcec, "secondary_offset_slot":0x37fce8}

def main():
    arg=argparse.ArgumentParser()
    arg.add_argument("--binary",type=pathlib.Path,required=True)
    arg.add_argument("--out",type=pathlib.Path,required=True)
    args=arg.parse_args()
    binary=args.binary
    actual=hashlib.sha256(binary.read_bytes()).hexdigest()
    if actual!=EXPECTED_SHA:raise ValueError("WRONG_NATIVE12_DASHBOARD_SHA")
    parser=runpy.run_path(str(ROOT/"tools/native12_objc_stub_decoder.py"))
    sections,read=parser["sections_for_binary"](binary)
    if "__objc_classlist" not in sections:
        raise ValueError("Original Mach-O missing __objc_classlist")
    def raw(addr,length):
        v=read(addr,length)
        if v is None or len(v)!=length:
            raise ValueError("Original VM address not mapped "+hex(addr))
        return v
    def ptr(addr):
        return struct.unpack("<Q",raw(addr,8))[0]&((1<<48)-1)
    def u32(addr):
        return struct.unpack("<I",raw(addr,4))[0]
    def cstr(addr):
        for length in (128,64,32,16,8):
            v=read(addr,length)
            if v and b"\0" in v:
                return v.split(b"\0",1)[0].decode("utf-8")
        raise ValueError("Original ivar/class string unavailable "+hex(addr))
    classlist,count_bytes,_=sections["__objc_classlist"]
    if count_bytes%8:raise ValueError("Bad original objc_classlist size")
    found=[]
    for i in range(count_bytes//8):
        class_ptr=ptr(classlist+8*i)
        if not class_ptr:continue
        data=ptr(class_ptr+32)
        ro=data&~7
        name=cstr(ptr(ro+24))
        if name==CLASS_NAME:
            found.append((class_ptr,ro))
    if len(found)!=1:raise ValueError("Ambiguous Native12 class metadata "+str(found))
    cls,ro=found[0]
    ivar_list=ptr(ro+48)
    stride=u32(ivar_list)&0xffff
    count=u32(ivar_list+4)
    if not (32<=stride<=64 and 1<=count<=200):
        raise ValueError("Implausible original ivar metadata stride/count")
    rows=[]
    for i in range(count):
        entry=ivar_list+8+i*stride
        slot=ptr(entry)
        offset=u32(slot)
        name=cstr(ptr(entry+8))
        objc_type=cstr(ptr(entry+16))
        rows.append({"name":name,"type":objc_type,"offset_slot":hex(slot),
                     "offset":offset})
    mapped={}
    for key,slot in SLOTS.items():
        choices=[r for r in rows if int(r["offset_slot"],16)==slot]
        if len(choices)!=1:
            raise ValueError("Native12 teardown ivar slot not mapped "+key+" "+hex(slot))
        mapped[key]=choices[0]
    prior=json.loads((HERE/"gallery-media-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json").read_text())
    if prior["dashboard_macho_sha256"]!=EXPECTED_SHA:
        raise ValueError("Original instructions/dashboard mismatch")
    dismiss=next(m for m in prior["methods"] if m["class"]==CLASS_NAME
                 and m["selector"]=="dismiss" and m["imp"]=="0xaf01c")
    ins={int(s.split(":",1)[0],16):s for s in dismiss["instructions"]}
    for pc,piece in {0xaf05c:"ldrsw\tx23",0xaf194:"ldrsw\tx20",
                     0xaf060:"ldr\tx0, [x19, x23]",
                     0xaf198:"ldr\tx0, [x19, x20]",
                     0xaf1a0:"ldr\tx1, [x22, #0xb28]"}.items():
        if piece not in ins.get(pc,""):
            raise ValueError("Original teardown register mismatch at "+hex(pc))
    selref=json.loads((HERE/"dismiss-selref/ORIGINAL_DISMISS_SHARED_SELECTOR.json").read_text())
    if selref["exact_selector"]!="removeFromSuperview":
        raise ValueError("Original removeFromSuperview selector evidence changed")
    report={"kind":"ORIGINAL_NATIVE12_CB_BRIDGED_UI_APP_VIEW_IVAR_OWNER_NOT_RUNTIME",
        "original_deb_sha256":EXPECTED_DEB,"original_dashboard_sha256":EXPECTED_SHA,
        "class":CLASS_NAME,"class_vm":hex(cls),"class_ro_vm":hex(ro),
        "dismiss_imp":"0xaf01c","captured_ivars":rows,"callsite_owner_mapping":mapped,
        "secondary_receiver_selector":"removeFromSuperview",
        "secondary_receiver_selector_pcs":["0xaf1a0","0xaf1a4"],
        "runtime_receiver_identity_verified":False,
        "vendor_binary_included":False,"new_runtime_modified":False,
        "device_verified":False}
    args.out.mkdir(parents=True,exist_ok=True)
    output=args.out/"ORIGINAL_DISMISS_IVAR_OWNER.json"
    output.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n")
    print("NATIVE12_ORIGINAL_DISMISS_IVAR_OWNER_VERIFIED",
          mapped["controller_offset_slot"],mapped["secondary_offset_slot"])
if __name__=="__main__":
    main()
