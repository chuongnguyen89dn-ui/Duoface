#!/usr/bin/env python3
"""Read-only SHA-verified OmniCar original: process injection + map owner selectors.

V4 is deliberately different from V2/V3: prove WHICH process receives native
SCPCarSplit, from original Debian package filters and ObjC class hierarchy.
Never import vendor code into independent DuoFace or execute original payload.
"""
import argparse,hashlib,json,plistlib,struct,subprocess,tempfile
from pathlib import Path
from audit_omnicar_native_maps_dispatch_20261028 import SHA,arm64_fat,original_methods

def parse_linked_frameworks(data):
    if len(data)<32 or struct.unpack_from("<I",data,0)[0]!=0xfeedfacf:
        raise RuntimeError("Bad Mach-O arm64")
    ncommands,sizecommands=struct.unpack_from("<II",data,16)
    off=32
    names=[]
    for i in range(ncommands):
        if off+8>len(data):raise RuntimeError("MachO load command bounds")
        cmd,sz=struct.unpack_from("<II",data,off)
        if sz<8 or off+sz>len(data):raise RuntimeError("MachO load size")
        if cmd & 0x7fffffff in (0xc,0x18,0x1f,0x23):
            k=struct.unpack_from("<I",data,off+8)[0]
            if k<sz:
                b=data[off+k:off+sz].split(b"\0",1)[0]
                names.append(b.decode("utf8","replace"))
        off+=sz
    return names

def objc_classes(b):
    mask=(1<<48)-1
    u=lambda pos: struct.unpack_from("<Q",b,pos)[0]
    out=[]
    # Class list range proven by ORIGINAL V2 method audit; no source derivation.
    for off in range(0x7fd80,0x7fdd8,8):
        cl=u(off)&mask
        ro=u(cl+32)&mask
        n=u(ro+24)&mask
        end=b.find(b"\0",n)
        if end<0:raise RuntimeError("Bad ObjC class string")
        name=b[n:end].decode("utf8","replace")
        superior=u(cl+8)&mask
        out.append({"class":name,"class_struct":hex(cl),
                    "superclass_pointer_or_bind":hex(superior),
                    "objc_category_or_class": "class metadata in original binary"})
    return out

def execute(deb):
    if hashlib.sha256(deb.read_bytes()).hexdigest()!=SHA:raise RuntimeError("Original DEB hash mismatch")
    with tempfile.TemporaryDirectory() as temp:
        dest=Path(temp)/"root";control=Path(temp)/"control"
        subprocess.run(["dpkg-deb","-x",str(deb),str(dest)],check=True)
        subprocess.run(["dpkg-deb","-e",str(deb),str(control)],check=True)
        fields=subprocess.run(["dpkg-deb","-f",str(deb),"Package","Version","Architecture"],
                               capture_output=True,text=True,check=True).stdout
        filters=[]
        dl=[]
        for file in sorted((dest/"var/jb/Library/MobileSubstrate/DynamicLibraries").glob("*.dylib")):
            plist=file.with_suffix(".plist")
            obj=None
            if plist.exists():
                try:obj=plistlib.loads(plist.read_bytes())
                except Exception as e:obj={"parse_error":str(e)}
            arm=arm64_fat(file.read_bytes()) if file.read_bytes()[:4]==b"\xca\xfe\xba\xbe" else None
            metadata={"dylib":file.name,
                      "sha256":hashlib.sha256(file.read_bytes()).hexdigest(),
                      "filter_plist":plist.name if plist.exists() else None,
                      "filter":obj.get("Filter") if isinstance(obj,dict) else None,
                      "linked_frameworks":parse_linked_frameworks(arm) if arm else [],
                      "has_arm64_fat_slice":bool(arm)}
            dl.append(metadata)
        script_names=sorted(p.name for p in control.iterdir())
        binary=(dest/"var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarSplitScreen.dylib").read_bytes()
        arm=arm64_fat(binary)
        classes=objc_classes(arm)
        methods=original_methods(arm)
        sc={sel:hex(pc) for (cl,sel),pc in methods.items() if cl=="SCPCarSplit"
            and any(x in sel.lower() for x in ("scene","adopt","host","launch","carplay","foreground","background","slot"))}
    return {"status":"ORIGINAL_SHA_PINNED_PACKAGE_FILTER_OWNER_V4_NO_RUNTIME",
            "source_deb_sha256":SHA,"deb_control_fields":fields.strip(),
            "maintainer_script_names_only":script_names,
            "runtime_dylibs":dl,
            "objc_classes_from_original_image":classes,
            "original_split_owner_methods":sc,
            "limits":["Filter proves permitted processes, not that SpringBoard or CarPlay actually loaded this dylib",
                      "Native CarPlay app scene cannot be inferred from bundleID alone",
                      "No copied code, no dynamic execution or entitlement spoofing",
                      "Cannot prove concurrent Maps CPWindow display from static metadata"]}

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--deb",required=True,type=Path)
    p.add_argument("--out",required=True,type=Path)
    a=p.parse_args()
    result=execute(a.deb)
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(result,indent=2,ensure_ascii=False)+"\n",encoding="utf8")
    print("OMNICAR_ORIGINAL_V4_PROCESS_OWNER_PASS")
    for d in result["runtime_dylibs"]:
        print("ORIGINAL",d["dylib"],"FILTER",json.dumps(d["filter"]),
              "LINKED",",".join(x for x in d["linked_frameworks"] if any(z in x for z in ("CarPlay","SpringBoard","UIKit","FrontBoard"))))
    print("ORIGINAL_CLASSES",",".join(x["class"] for x in result["objc_classes_from_original_image"]))
if __name__=="__main__":main()
