#!/usr/bin/env python3
"""SHA-pinned original OmniCar: enumerate true hosted CarPlay VC/pane owners.

This V5 studies SCPHostedAppVC and SCPCarPane (confirmed V4 classes),
which were previously missing from the main SCPCarSplit-only method audit.
Read-only data, not runtime proof or transferable vendor implementation.
"""
import argparse,hashlib,json,struct,subprocess,tempfile,re
from pathlib import Path
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
from audit_omnicar_native_maps_dispatch_20261028 import SHA,arm64_fat,original_methods
from audit_original_omnicar_native_map_cfstrings_v2 import cfstring

CLASSES=("SCPHostedAppVC","SCPCarPane","SCPCarSplit")
TARGET_SPLIT=("adopt:slot:","sceneOfViewController:","openApp:slot:",
              "pushSceneSizes","verifySceneOfPane:expected:retry:",
              "scene:destroyedForViewController:ownScene:","hostApp:inPane:",
              "closeSlot:background:","sendLaunch:bundle:tries:")
def scan(binary):
    methods=original_methods(binary)
    dis=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
    starts=sorted(set(methods.values()))
    groups={}
    for cls in CLASSES:
        active=[(sel,pc) for (cl,sel),pc in methods.items()
                if cl==cls and (cls!="SCPCarSplit" or sel in TARGET_SPLIT)]
        inspected=[]
        for selector,start in sorted(active,key=lambda v:v[1]):
            end=next((q for q in starts if q>start),len(binary))
            if end<=start or end-start>65536:raise RuntimeError("invalid bound "+cls+"."+selector)
            ops=list(dis.disasm(binary[start:end],start))
            if not ops:raise RuntimeError("No original ARM64 instructions "+selector)
            constants=[]
            for i,o in enumerate(ops[:-1]):
                if o.mnemonic!="adrp" or ops[i+1].mnemonic!="add":continue
                m=re.fullmatch(r"(x\d+),\s*#(0x[0-9a-f]+)",o.op_str)
                if not m:continue
                reg,page=m.groups()
                z=re.fullmatch(r"("+reg+r"),\s*("+reg+r"),\s*#(0x[0-9a-f]+)",ops[i+1].op_str)
                if not z:continue
                c=cfstring(binary,int(page,16)+int(z.group(3),16))
                if c:
                    constants.append({"at":hex(o.address),"value":c})
            inspected.append({"selector":selector,"imp":hex(start),"end":hex(end),
                             "instruction_count":len(ops),"cfstrings":constants,
                             "leading_arm64":[hex(o.address)+" "+o.mnemonic+" "+o.op_str for o in ops[:16]]})
        groups[cls]={"num_methods":len(inspected),"methods":inspected}
    return {"status":"PINNED_ORIGINAL_V5_HOSTED_CARPLAY_VC_PANE_OWNER_READONLY",
            "sha256_original_deb":SHA,
            "classes":groups,
            "limits":["Original method names and literals prove code, not live CarPlay map scene ownership",
                      "No copying original binary, methods or licensing into DuoFace",
                      "Native CPWindow reuse must be proven before changing app scene lifecycle",
                      "No speculative map zoom"]}
def main():
    arg=argparse.ArgumentParser()
    arg.add_argument("--deb",type=Path,required=True)
    arg.add_argument("--out",type=Path,required=True)
    p=arg.parse_args()
    if hashlib.sha256(p.deb.read_bytes()).hexdigest()!=SHA:raise RuntimeError("Original SHA mismatch")
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(["dpkg-deb","-x",str(p.deb),tmp],check=True)
        file=Path(tmp)/"var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarSplitScreen.dylib"
        data=scan(arm64_fat(file.read_bytes()))
    p.out.parent.mkdir(parents=True,exist_ok=True)
    p.out.write_text(json.dumps(data,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    for cls,group in data["classes"].items():
        print("ORIGINAL_CARPLAY_HOST_CLASS",cls,group["num_methods"])
        for m in group["methods"]:
            print("ORIGINAL_METHOD",cls,m["selector"],m["imp"],"literals="+
                  ",".join(x["value"] for x in m["cfstrings"][:10]))
    print("OMNICAR_ORIGINAL_V5_HOST_OWNER_CLASS_METHODS_PASS")
if __name__=="__main__":main()
