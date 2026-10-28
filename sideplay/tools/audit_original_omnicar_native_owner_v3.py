#!/usr/bin/env python3
"""V3: SHA-locked original OmniCar native CarPlay scene/slot ownership, READ ONLY.

Decode exact ObjC method boundaries, ARM64 branch/call targets, CFString refs
and nearby instructions. Do NOT copy native binaries or vendor licensing.
Report proves STATIC code structure, NOT runtime behavior or CPWindow access.
"""
import argparse,hashlib,json,struct,subprocess,tempfile
from pathlib import Path
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
from audit_omnicar_native_maps_dispatch_20261028 import SHA,arm64_fat,original_methods
from audit_original_omnicar_native_map_cfstrings_v2 import cfstring

TARGETS=[
 "isCarPlayApp:","openApp:slot:","adopt:slot:","sceneOfViewController:",
 "verifySceneOfPane:expected:retry:","pushSceneSizes","paneSize:forBundle:",
 "relayoutAnimated:pushScenes:","scene:destroyedForViewController:ownScene:",
 "closeSlot:background:","launchPhoneAppIfNeeded:","hostApp:inPane:",
 "publishCarPlayApps","sendLaunch:bundle:tries:","sendHostFrameForPane:live:",
 "pushHostFramesLive:","removePaneAt:background:","paneForBundle:",
 "pendingSlotForBundle:","openAppsInOrder:","foregroundAppForBundle:",
]
MASK=(1<<48)-1

def inspect_binary(b,methods):
    starts=sorted(set(methods.values()))
    c=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
    mapping={v:[cls+"."+sel for (cls,sel),v2 in methods.items() if v2==v]
             for v in starts}
    results={}
    for name in TARGETS:
        start=methods.get(("SCPCarSplit",name))
        if start is None:
            results[name]={"present":False};continue
        end=next((p for p in starts if p>start),len(b))
        if end-start>65536 or end<=start:raise RuntimeError("invalid method boundary: "+name)
        code=list(c.disasm(b[start:end],start))
        if len(code)*4!=end-start:
            # Mach-O method padding can include non-instructions, but never
            # pretend to have analyzed a complete function if decoding stops.
            raise RuntimeError("incomplete disassembly "+name)
        matches=[]
        calls=[]
        branches=[]
        for i,x in enumerate(code):
            if x.mnemonic=="adrp" and i+1<len(code):
                import re
                m=re.fullmatch(r"(x\d+),\s*#(0x[0-9a-f]+)",x.op_str)
                y=code[i+1]
                if m and y.mnemonic=="add":
                    r,page=m.groups()
                    mm=re.fullmatch(r"("+r+r"),\s*("+r+r"),\s*#(0x[0-9a-f]+)",y.op_str)
                    if mm:
                        addr=int(page,16)+int(mm.group(3),16)
                        s=cfstring(b,addr)
                        if s:
                            window=code[max(0,i-3):min(len(code),i+15)]
                            matches.append({"at":hex(x.address),"literal":s,
                                "nearby":[hex(z.address)+" "+z.mnemonic+" "+z.op_str for z in window]})
            if x.mnemonic in ("bl","blr"):
                t=x.op_str.replace("#","")
                try:
                    pc=int(t,16);owner=mapping.get(pc)
                except ValueError:
                    owner=None
                if owner:
                    calls.append({"pc":hex(x.address),"direct_known_method":owner})
            if x.mnemonic in ("tbz","tbnz","cbz","cbnz","b.eq","b.ne","b.gt","b.le"):
                branches.append({"pc":hex(x.address),"op":x.mnemonic+" "+x.op_str})
        results[name]={"present":True,"imp":hex(start),"end":hex(end),
            "instructions":len(code),"native_method_calls":calls,
            "cfstrings":matches,"branch_count":len(branches),
            "branch_first":branches[:35],
            "head":[hex(x.address)+" "+x.mnemonic+" "+x.op_str for x in code[:min(len(code),60)]]}
    panes=[{"class":cl,"selector":sel,"imp":hex(pc)}
           for (cl,sel),pc in methods.items()
           if cl in ("SCPCarPane","SCPCarSplit") and
              any(k in sel.lower() for k in ("scene","adopt","slot","background","appbridge","carplay","hostview","hostapp","foreground","launch"))]
    return {"status":"ORIGINAL_ONLY_V3_NATIVE_SCENE_ROUTING_STATIC_NOT_DEVICE",
       "original_deb_sha256":SHA,
       "target_count":len(TARGETS),
       "targets_present":sum(int(v["present"]) for v in results.values()),
       "selector_inventory":panes,"methods":results,
       "limits":["Method metadata + branch PC are verified, but runtime scenes and owner are not",
                 "No dynamic private calls or vendor code/payload cloned into DuoFace",
                 "An existing navigation CPWindow must not be stolen or disabled",
                 "No app-specific map zoom guessed"]}

def main():
    a=argparse.ArgumentParser()
    a.add_argument("--deb",required=True,type=Path)
    a.add_argument("--out",required=True,type=Path)
    o=a.parse_args()
    if hashlib.sha256(o.deb.read_bytes()).hexdigest()!=SHA:raise RuntimeError("original hash mismatch")
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(["dpkg-deb","-x",str(o.deb),tmp],check=True)
        orig=Path(tmp)/"var/jb/Library/MobileSubstrate/DynamicLibraries/OmniCarSplitScreen.dylib"
        arm=arm64_fat(orig.read_bytes())
        output=inspect_binary(arm,original_methods(arm))
    o.out.parent.mkdir(parents=True,exist_ok=True)
    o.out.write_text(json.dumps(output,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print("ORIGINAL_OMNICAR_NATIVE_SCENE_ROUTING_V3_PASS",
          output["targets_present"],"of",output["target_count"])
    for n,v in output["methods"].items():
        if v["present"]:
            print("METHOD",n,v["imp"],"literal="+
                  ",".join(x["literal"] for x in v["cfstrings"] if any(k in x["literal"].lower()
                       for k in ("scene","carplay","appbridge","background","host","open"))))
if __name__=="__main__":main()
