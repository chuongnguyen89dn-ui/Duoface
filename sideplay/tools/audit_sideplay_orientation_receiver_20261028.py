#!/usr/bin/env python3
"""Find the REAL receiver (if any) of SidePlay's original orientation IPC.
Read-only SHA-pinned original DEB/ARM64. No vendor payload copied to DuoFace.
An annotated selector call is evidence, not proof of dispatch/runtime ACK.
"""
import argparse
import hashlib
import json
import os
import plistlib
import re
import subprocess
import sys
import tempfile
from pathlib import Path

PIN="7f8520b9a29013988f0430414c3c90308206a46ec689190ba4e1e2d9a0703a9c"
DYLIB_PIN="0fc34c6c8e47283d2223d70facfe3e86ed76bd568958786b67a9430127242971"
NEEDLES=(
    "com.sideplay.orientation", "NSDistributedNotificationCenter",
    "UIApplicationDidChangeStatusBarOrientationNotification",
    "requestGeometryUpdateWithPreferences:errorHandler:",
    "setNeedsUpdateOfSupportedInterfaceOrientations",
    "attemptRotationToDeviceOrientation",
    "_setRotatableViewOrientation:duration:force:",
    "_adjustOrientationIfNecessaryInWindow:forViewController:preservingViewController:",
    "addObserverForName:object:queue:usingBlock:",
    "postNotificationName:object:userInfo:",
)
EXACT=re.compile(r"^\s*(?:0x)?([0-9a-fA-F]+):\s+(.+)$")
def digest(b): return hashlib.sha256(b).hexdigest()
def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--deb",required=True,type=Path)
    ap.add_argument("--out",required=True,type=Path)
    a=ap.parse_args()
    if digest(a.deb.read_bytes())!=PIN:raise ValueError("SidePlay original SHA mismatch")
    with tempfile.TemporaryDirectory(prefix="original-sideplay-ipc-") as d:
        dest=Path(d)/"pkg"
        subprocess.run(("dpkg-deb","-x",str(a.deb),str(dest)),check=True)
        payload=[]
        for f in sorted(dest.rglob("*")):
            if not f.is_file():continue
            if f.suffix==".plist":
                try:
                    x=plistlib.loads(f.read_bytes())
                    if isinstance(x,dict) and x.get("Filter"):
                        payload.append({"path":str(f.relative_to(dest)),"filter":x["Filter"]})
                except (ValueError,TypeError,plistlib.InvalidFileException):pass
        image_info={}
        target=[]
        for f in sorted(dest.rglob("*.dylib")):
            raw=f.read_bytes()
            hits={s:raw.count(s.encode("utf8")) for s in NEEDLES if s.encode("utf8") in raw}
            item={"path":str(f.relative_to(dest)),"sha256":digest(raw),
                  "bytes":len(raw),"needle_byte_counts":hits}
            image_info[f.name]=item
            if f.name=="SidePlay.dylib":target.append(f)
        if len(target)!=1:raise ValueError("SidePlay original image is not unique")
        dylib=target[0]
        if digest(dylib.read_bytes())!=DYLIB_PIN:raise ValueError("Original main dylib SHA mismatch")
        sys.path.insert(0,os.environ["NATIVE_PARSER_DIR"])
        from audit_native12_license_class_xrefs import select_arm64
        thin=select_arm64(dylib.read_bytes())
        image=Path(d)/"sideplay-arm64.dylib"
        image.write_bytes(thin)
        cmd=[os.getenv("OBJDUMP","llvm-objdump-18"),"--macho","--disassemble",
             "--no-show-raw-insn",str(image)]
        run=subprocess.run(cmd,capture_output=True,text=True,errors="replace")
        if run.returncode:raise RuntimeError("LLVM failed: "+run.stderr[-1200:])
        listing=[]
        for line in run.stdout.splitlines():
            m=EXACT.match(line)
            if m:listing.append({"pc":int(m.group(1),16),"asm":m.group(2)})
        if not listing:raise RuntimeError("original ARM64 listing empty")
        references={}
        for key in NEEDLES:
            # Exact cfstring/selector annotation in LLVM, not a loose binary string.
            ix=[i for i,x in enumerate(listing) if key in x["asm"]]
            targets=[]
            for i in ix[:25]:
                low=max(0,i-42);high=min(len(listing),i+70)
                targets.append({
                    "reference_pc":hex(listing[i]["pc"]),
                    "preceding_and_following_arm64":[
                        {"pc":hex(x["pc"]),"asm":x["asm"]}
                        for x in listing[low:high]]
                })
            references[key]={"arm64_annotation_count":len(ix),"callsite_windows":targets}
        # In the verified registration at PC 0x706c, x5 is the original
        # addObserverForName:object:queue:usingBlock: callback. Decode the
        # CONSTANT block literal's invoke pointer, rather than guessing a
        # receiver from coincidentally present UIKit selector strings.
        from audit_native12_license_class_xrefs import MachO
        macho=MachO(thin)
        registration=next((x for x in listing if x["pc"]==0x706c),None)
        callback={"registration_pc":"0x706c","status":"UNRESOLVED_OR_UNKNOWN_BLOCK_ABI"}
        if registration:
            m=re.search(r"\badr\s+x5,\s*#(0x[0-9a-fA-F]+|\d+)",registration["asm"])
            if m:
                block_addr=int(m.group(1),0)
                callback["block_literal_vm"]=hex(block_addr)
                try:
                    base=macho.map(block_addr)
                    import struct
                    # clang/ObjC ABI: isa, flags, reserved, invoke, descriptor.
                    isa,flags,reserved,invoke,descriptor=struct.unpack_from(
                        "<QIIQQ",thin,base)
                    invoke_unrebased=invoke & 0x0000FFFFFFFFFFFF
                    callback.update({
                        "block_header_isa":hex(isa),
                        "flags":hex(flags),
                        "reserved":hex(reserved),
                        "invoke_raw":hex(invoke),
                        "invoke_unrebased":hex(invoke_unrebased),
                        "descriptor_vm":hex(descriptor)})
                    if invoke_unrebased in {x["pc"] for x in listing}:
                        callback["status"]="INVOKE_ADDRESS_IN_ORIGINAL_ARM64"
                        pos=next(i for i,x in enumerate(listing)
                            if x["pc"]==invoke_unrebased)
                        callback["invoke_instructions"]=[
                            {"pc":hex(x["pc"]),"asm":x["asm"]}
                            for x in listing[pos:pos+230]]
                    else:
                        callback["status"]="RAW_BLOCK_POINTER_REQUIRES_CHAINED_FIXUP"
                except (ValueError,IndexError,struct.error) as ex:
                    callback["error"]=str(ex)[:150]
        result={
            "status":"SHA_PINNED_ORIGINAL_SIDEPLAY_ORIENTATION_RECEIVER_IPC_STATIC_NOT_DEVICE",
            "source_deb_sha256":PIN,
            "source_dylib_sha256":DYLIB_PIN,
            "original_dylib_filters":payload,
            "all_original_dylib_string_occurrences":image_info,
            "arm64_thin_sha256":digest(thin),
            "original_orientation_notification_registration_block":callback,
            "llvm_instruction_count":len(listing),
            "annotated_original_calls":references,
            "limits":[
                "String existence cannot establish which process handles the callback",
                "NSDistributedNotificationCenter sender does not prove receiver",
                "Do not port private UIWindow rotation calls from vendor to independent DuoFace",
                "YouTube player is not observed on physical device by this static tool"
            ]
        }
        a.out.parent.mkdir(parents=True,exist_ok=True)
        a.out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
        print("SIDEPLAY_ORIGINAL_RECEIVER_SHA_PASS",PIN)
        print("SIDEPLAY_ORIGINAL_MODULES",len(image_info),"FILTERS",len(payload))
        for key,val in references.items():
            print("ORIENTATION_RECEIVER_CALLSITE",key,val["arm64_annotation_count"])
        print("ORIGINAL_ORIENTATION_IPC_RECEIVER_REPORT",a.out)
if __name__=="__main__":main()
